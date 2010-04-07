use strict;
use Test::More;
use LWP::UserAgent;
use URI;
use Lyra::Extlib;
use Lyra::Test qw(dbic_schema click_server);

my $click_server = click_server
    name => "002_access"
;

my $schema = dbic_schema();
my $rs = $schema->resultset('AdsMaster');

my $ua = LWP::UserAgent->new(
    max_redirect => 0, # don't redirect us for this test
);
my $base = URI->new("http://127.0.0.1:" . $click_server->port);
while (my $row = $rs->next) {
    $base->query_form( ad => $row->id );
    my $res = $ua->get( $base );

    if (! (
        is( $res->code, '302', "status is 302" ) &&
        is( $res->header('Location'), $row->landing_uri, "redirect uri is correct" )
    ) ) {
        diag( "Unexpected response" );
        diag( $res->as_string );
    }
}

done_testing();