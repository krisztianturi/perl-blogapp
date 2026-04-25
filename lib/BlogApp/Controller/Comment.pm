package BlogApp::Controller::Comment;
use Mojo::Base 'Mojolicious::Controller';

sub create {
  my $c = shift;

  my $post_id = $c->param('id');
  my $content  = $c->param('content');
  my $user_id  = $c->session('user_id');

  return $c->redirect_to('/login') unless $user_id;
  return $c->redirect_to("/post/$post_id") unless $content;

  $c->pg->db->query('INSERT INTO comments (post_id, user_id, content) VALUES (?, ?, ?)', $post_id, $user_id, $content);

  $c->redirect_to("/post/$post_id");
}

sub delete {
  my $c = shift;

  my $comment_id = $c->param('comment_id');
  my $user_id    = $c->session('user_id');

  my $result = $c->pg->db->query(
    'DELETE FROM comments WHERE id = ? AND user_id = ?',
    $comment_id, $user_id
  );

  my $rows = $result->rows;

  if ($rows) {
    $c->flash(message => 'Comment deleted');
  } else {
    $c->flash(error => 'Comment not found or not yours');
  }

  $c->redirect_to("/post/" . $c->param('post_id'));
}

1;