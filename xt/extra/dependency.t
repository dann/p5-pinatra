use Test::Dependencies
    exclude => [qw/Test::Dependencies Test::Base Test::Perl::Critic Pinatra/],
    style   => 'light';
ok_dependencies();
