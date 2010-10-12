use inc::Module::Install;
name 'Pinatra';
all_from 'lib/Pinatra.pm';

requires(
    'Router::Simple' => 0.07,
    'Try::Tiny'      => 0,
    'JSON'           => 0,
    'Plack::Request' => 0,
    'Try::Tiny'      => 0,
);
test_requires( 'Test::More' => 0, );
use_test_base;
auto_include;
WriteAll;
