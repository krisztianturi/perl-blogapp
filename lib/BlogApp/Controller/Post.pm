package BlogApp::Controller::Post;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;
use BlogApp::SafeMarkdown qw(render_content);


sub list {
  my $c = shift;

  my $search = $c->param('search') // '';
  my $posts;
  my $total;

  if($search){
    $total = $c->pg->db->query('SELECT COUNT(*) FROM posts
                                        WHERE title ILIKE ? OR content ILIKE ?',"%$search%", "%$search%")->array->[0];
  } else{
    $total = $c->pg->db->query('SELECT COUNT(*) FROM posts')->array->[0];
  }

  my $page = $c->param('page') || 1;
  $page = 1 if $page < 1;
  my $per_page = 5;
  my $offset = ($page - 1) * $per_page;

  my $total_pages = int(($total + $per_page - 1) / $per_page);
  $page = $total_pages if $page > $total_pages && $total_pages > 0;

  if($search){
    if ($search =~ /^#(.+)/) {
      $search = $1;
      $posts = $c->pg->db->query('SELECT DISTINCT posts.*
                              FROM posts
                              JOIN post_tags pt ON pt.post_id = posts.id
                              JOIN tags t ON t.id = pt.tag_id
                              WHERE t.name ILIKE ?
                              ORDER BY posts.created_at DESC LIMIT ? OFFSET ?',"%$search%", $per_page, $offset)->hashes;
    }
    else{
      $posts = $c->pg->db->query('SELECT * FROM posts                                          
                                  WHERE title ILIKE ? OR content ILIKE ?  
                                  ORDER BY created_at DESC LIMIT ? OFFSET ?',
                                  "%$search%", "%$search%", $per_page, $offset)->hashes;   

    }
                                      
  }else{
        $posts = $c->pg->db->query('SELECT * FROM posts ORDER BY created_at DESC LIMIT ? OFFSET ?', $per_page, $offset)->hashes;         
  }

  for my $p (@$posts){
    render_content($p);
  }
  
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

    my @errors = checking_errors($title, $content);

    if (@errors) {
        $c->flash(error => join('. ', @errors));
        return $c->redirect_to($c->req->headers->referrer || '/');
    }

    my $db = $c->pg->db;

    my $post = $c->pg->db->query(
     'INSERT INTO posts (user_id, title, content)
      VALUES (?, ?, ?)
      RETURNING id',
      $user_id, $title, $content)->hash;

    my $post_id = $post->{id};

    my $tags_raw = $c->param('tags') // '';
    my @tags = split /,/, $tags_raw;

    for my $t (@tags) {
      $t =~ s/^\s+|\s+$//g;
    }
    @tags = grep { $_ ne '' } @tags;


    $_ = lc $_ for @tags;
    # for my $t (@tags) {
    # $t = lc $t;
    # }


    for my $tag (@tags) {

    my $tag_row = $c->pg->db->query(
      'INSERT INTO tags (name)
      VALUES (?)
      ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id',
      $tag
    )->hash;

    my $tag_id = $tag_row->{id};

    $c->pg->db->query(
      'INSERT INTO post_tags (post_id, tag_id)
      VALUES (?, ?)
      ON CONFLICT DO NOTHING',
      $post_id, $tag_id
    );
  }


  $c->redirect_to('/');
}

sub show {
  my $c = shift;

  my $id = $c->param('id');

  my $post = $c->pg->db->query('SELECT * FROM posts WHERE id = ?', $id)->hash;

  return $c->reply->not_found unless $post;

  my $comments = $c->pg->db->query(
  'SELECT c.*, u.username
   FROM comments c
   JOIN users u ON c.user_id = u.id
   WHERE c.post_id = ?
   ORDER BY c.created_at ASC', $id)->hashes;

  my $tags = $c->pg->db->query('SELECT t.name
    FROM tags t
    JOIN post_tags pt ON pt.tag_id = t.id
    WHERE pt.post_id = ?',$id)->hashes;

  $post->{tags} = $tags;  

  render_content($post);

  for my $c (@$comments){
    render_content($c);
  }

  $c->stash(post => $post, comments => $comments);
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
