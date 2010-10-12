use Pinatra;
my $app = pina {
    get '/api' => sub {
        json { foo => 'bar' };
    },
    post '/comment/{id}' => sub {
        my ($req, $args)  = @_;
        my $id = $args->{id};
        warn $id;
        my $res = res($req);
        $res;
    }
};

