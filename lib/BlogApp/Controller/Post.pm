package BlogApp::Controller::Post;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;

sub list {
  warn "list MODULE LOADED";
  my $c = shift;

  my $posts = $c->pg->db->query(
    'SELECT * FROM posts ORDER BY created_at DESC'
  )->hashes;

  $c->stash(posts => $posts);
  $c->render(template => 'post/list');
}

sub create {
  my $c = shift;

  my $title = $c->param('title');
  my $content = $c->param('content');
  my $user_id = $c->session('user_id');

  $c->pg->db->query(
    'INSERT INTO posts (user_id, title, content) VALUES (?, ?, ?)',
    $user_id, $title, $content
  );

  $c->redirect_to('/');
}
1;
