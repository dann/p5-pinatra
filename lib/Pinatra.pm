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
    *{"${caller}::get"}  = sub { goto &do_get };
    *{"${caller}::post"} = sub { goto &do_post };

    # req-res
    *{"${caller}::req"} = \&req;
    *{"${caller}::res"} = \&res;

    *{"${caller}::html"} = \&html;
    *{"${caller}::text"} = \&text;
    *{"${caller}::json"} = \&json;
}

sub pina (&) {
    my $block = shift;

    if ($block) {
        no warnings 'redefine';
        local *get  = sub { do_get(@_) };
        local *post = sub { do_post(@_) };
        $block->();
        return sub { _find_and_run(shift) }
    }
}

# HTTP Methods
sub route {
    my ( $pattern, $code, $method ) = @_;
    $_ROUTER->connect( $pattern, { action => $code }, { method => $method } );
}

sub do_get {
    my ($pattern, $code) = @_;
    route( $pattern, $code, 'GET' );
}

sub do_post {
    my ($pattern, $code) = @_;
    route( $pattern, $code, 'POST' );
}

# response
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

# request-response
sub res {
    my $req = shift;
    $req->new_response(200);
}

# dispatch
sub _find_and_run {
    my $env = shift;
    _dispatch($env);
}

sub _dispatch {
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
                warn $e;
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
