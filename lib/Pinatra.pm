package Pinatra;
use strict;
use warnings;
our $VERSION = '0.01';
use Carp 'croak';
use Router::Simple;
use Try::Tiny;
use Plack::Request;
use JSON;

my $_ROUTER = Router::Simple->new;

sub import {
    my $caller = caller;

    no strict 'refs';
    no warnings 'redefine';

    # main
    *{"${caller}::pina"} = \&pina;

    # HTTP methods
    my @http_methods = qw/get post/;
    for my $http_method (@http_methods) {
        *{"${caller}\::$http_method"} = sub { goto \&$http_method };
    }

    # render
    my @render_methods = qw/html text json/;
    for my $render_method (@render_methods) {
        *{"${caller}\::$render_method"} = sub { goto \&$render_method };
    }

    # resoponse shortcut
    *{"${caller}::res"} = \&res;
}

sub _stub {
    my $name = shift;
    return sub { croak "Can't call $name() outside pina block" };
}

{
    my @Declarations = qw(get post);
    for my $keyword (@Declarations) {
        no strict 'refs';
        *$keyword = _stub $keyword;
    }
}

sub pina (&) {
    my $block = shift;

    if ($block) {
        no warnings 'redefine';
        local *get  = sub { do_get(@_) };
        local *post = sub { do_post(@_) };
        $block->();
        return sub { dispatch(shift) }
    }
}

# HTTP Methods
sub route {
    my ( $pattern, $code, $method ) = @_;
    $_ROUTER->connect( $pattern, { action => $code }, { method => $method } );
}

sub do_get {
    my ( $pattern, $code ) = @_;
    route( $pattern, $code, 'GET' );
}

sub do_post {
    my ( $pattern, $code ) = @_;
    route( $pattern, $code, 'POST' );
}

# render
sub html {
    return [ 200, [ 'Content-Type' => 'text/html; charset=UTF-8' ], [shift] ];
}

sub text {
    return [ 200, [ 'Content-Type' => 'text/plain; charset=UTF-8' ],
        [shift] ];
}

sub json {
    return [
        200,
        [ 'Content-Type' => 'application/json; charset=UTF-8' ],
        [ JSON::encode_json(shift) ]
    ];
}

# response
sub res {
    my $req = shift;
    $req->new_response(200);
}

# dispatch
sub dispatch {
    my $env = shift;
    if ( my $match = $_ROUTER->match($env) ) {
        my $code = $match->{action};
        if ( ref $code eq 'CODE' ) {
            my $req = Plack::Request->new($env);
            my $res = try {
                &$code( $req, $match );
            }
            catch {
                my $e = shift;
                return [ 500, [], ['Internal server error'] ];
            };
            return try { $res->finalize } || $res;
        }
        else {
            return [ 500, [], ['Internal server error'] ];
        }
    }
    else {
        [ 404, [], ['Not Found'] ];
    }

}

1;

__END__

=encoding utf-8

=head1 NAME

Pinatra - Minimalistic sugar for your Plack

=head1 SYNOPSIS

  use Pinatra;
  my $app = pina {
    get '/api' => sub {
      json { foo => 'bar' };
    },
    post '/comment/{id}' => sub {
      my ($req, $args)  = @_;
      my $id = $args->{id};
      my $res = res($req);
      $res;
    }
  };
=head1 DESCRIPTION

Pinatra is Minimalistic sugar for your Plack

=head1 SOURCE AVAILABILITY

This source is in Github:

  http://github.com/dann/p5-pinatra

=head1 CONTRIBUTORS

Many thanks to:

=head1 AUTHOR

dann E<lt>techmemo@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
