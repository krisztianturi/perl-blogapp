package BlogApp::Controller::Auth;
use strict;
use warnings;
use Mojo::Base 'Mojolicious::Controller';
use Authen::Passphrase::BlowfishCrypt;
use Authen::Passphrase;

sub login_form {
    my ($c) = @_;
    $c->render(template => 'auth/login');
}

sub login {
    my ($c) = @_;

    my $username = $c->param('username');
    my $password = $c->param('password');

    my $db = $c->pg->db;
    my $user = $db->query('SELECT id, username, password FROM users WHERE username = ?', $username)->hash;

    if ($user) {
        my $ppr = Authen::Passphrase->from_rfc2307($user->{password});

        if ($ppr->match($password)) {
            $c->session(
                user_id  => $user->{id},
                username => $user->{username}
            );
            return $c->redirect_to('/');
        }
    }

    $c->flash(error => 'Invalid login');
    $c->redirect_to('/login');
}

sub logout {
    my ($c) = @_;
    $c->session(expires => 1);
    $c->redirect_to('/login');
}

sub register_form {
    my ($c) = @_;
    $c->render(template => 'auth/register');
}

sub register {
    my ($c) = @_;

    my $username = $c->param('username');
    my $password = $c->param('password');

    unless ($username && $password) {
        $c->flash(error => 'All fields required');
        return $c->redirect_to('/register');
    }

    if ($password !~ /^.{4,}$/) {
        $c->flash(error_pass => 'Password must be at least 4 characters');
        return $c->redirect_to('/register');
    }

    my $db = $c->pg->db;
    my $existing = $db->query('SELECT id FROM users WHERE username = ?', $username)->hash;

    if ($existing) {
        $c->flash(error => 'User already exists');
        return $c->redirect_to('/register');
    }

    my $ppr = Authen::Passphrase::BlowfishCrypt->new(
    cost => 12,
    salt_random => 1,
    passphrase => $password,
    );

    my $hash = $ppr->as_rfc2307;

    $db->query('INSERT INTO users (username, password) VALUES (?, ?)', $username, $hash);

    $c->flash(message => 'Registration successful');
    $c->redirect_to('/login');
}

1;