package BlogApp;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Pg;

sub startup ($self) {

  $self->routes->namespaces(['BlogApp::Controller']);
  my $config = $self->plugin('NotYAMLConfig');
  $self->secrets($config->{secrets});

  my $pg = Mojo::Pg->new($config->{pg});
  $self->helper(pg => sub { $pg });
  $pg->migrations->name('blog')->from_file('migrations/blog.sql')->migrate;


  my $r = $self->routes;

    $r->get('/')->to('Post#list');
    $r->get('/post/:id')->to('post#show');
  
    $r->get('/login')->to('auth#login_form');
    $r->post('/login')->to('auth#login');
    $r->get('/logout')->to('auth#logout');

    $r->get('/register')->to('auth#register_form');
    $r->post('/register')->to('auth#register');

    my $auth = $r->under(sub {
        my $c = shift;
        return 1 if $c->session('user_id');
        $c->redirect_to('/login');
        return undef;
    });

    $auth->get('/post/new')->to('post#new');
    $auth->post('/post/new')->to('post#create');
}

1;
