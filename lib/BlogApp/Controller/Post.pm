package BlogApp::Controller::Post;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;

sub list {
  my $c = shift;

  my $page = $c->param('page') || 1;
  $page = 1 if $page < 1;
  my $per_page = 5;
  my $offset = ($page - 1) * $per_page;

  my $posts = $c->pg->db->query('SELECT * FROM posts ORDER BY created_at DESC LIMIT ? OFFSET ?', $per_page, $offset)->hashes;

  my $total = $c->pg->db->query('SELECT COUNT(*) FROM posts')->array->[0];

  my $total_pages = int(($total + $per_page - 1) / $per_page);
  $page = $total_pages if $page > $total_pages && $total_pages > 0;
  $c->stash(posts => $posts, page => $page, total_pages => $total_pages);

  $c->render(template => 'post/list');
}

sub create_form {
  my $c = shift;
  $c->render(template => 'post/new');
}

sub delete{
  my ($c) = @_;
  my $id = $c->param('id');
  my $user_id = $c->session('user_id');

    my $result = $c->pg->db->query('DELETE FROM posts WHERE id = ? AND user_id = ?', $id, $user_id);
    my $rows = $result->rows;

    if ($rows) {
        $c->flash(message => 'Post deleted');
    } else {
        $c->flash(error => 'Post not found or not yours');
    }

    $c->redirect_to('/');
}

sub edit {
    my $c = shift;
    my $id = $c->param('id');

    my $post = $c->pg->db->query('SELECT * FROM posts WHERE id = ?', $id)->hash;

    return $c->reply->not_found unless $post;

    $c->stash(post => $post);
    $c->render(template => 'post/edit');
}

sub update {
    my ($c) = @_;

    my $id = $c->param('id');
    my $title = $c->param('title');
    my $content = $c->param('content');
    my $user_id = $c->session('user_id');

    my @errors = checking_errors($title, $content);

    if (@errors) {
        $c->flash(error => join('. ', @errors));
        return $c->redirect_to($c->req->headers->referrer || '/');
    }

    my $result = $c->pg->db->query('UPDATE posts SET title=?, content=? WHERE id = ? AND user_id = ?', $title, $content, $id, $user_id);
    my $rows = $result->rows;

    if ($rows){
        $c->flash(message => 'Post updated');
    } else {
        $c->flash(error => 'Post not found or not yours');
    }
    
    $c->redirect_to('/');
}

sub create {
  my $c = shift;

    my $title   = $c->param('title');
    my $content = $c->param('content');
    my $user_id = $c->session('user_id');

    #return if checking_errors($c,$title,$content,'/post/new');
    my @errors = checking_errors($title, $content);

    if (@errors) {
        $c->flash(error => join('. ', @errors));
        return $c->redirect_to($c->req->headers->referrer || '/');
    }

    my $db = $c->pg->db;

    $db->query('INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)', $user_id, $title, $content);


  $c->redirect_to('/');
}

sub show {
  my $c = shift;
  my $id = $c->param('id');

  my $post = $c->pg->db->query(
    'SELECT * FROM posts WHERE id = ?',
    $id
  )->hash;

  return $c->render(text => 'Post not found', status => 404) unless $post;

  $c->stash(post => $post);
  $c->render(template => 'post/show');
}

sub checking_errors {
    my ($title, $content) = @_;
    my @errors;

    $title   =~ s/^\s+|\s+$//g if defined $title;
    $content =~ s/^\s+|\s+$//g if defined $content;

    push @errors, "Title is required" unless $title && $title =~ /\S/;
    push @errors, "Title can't exceed 255 characters" if $title && length($title) > 255;
    push @errors, "Content is required" unless $content && $content =~ /\S/;

    return @errors;
}
1;
