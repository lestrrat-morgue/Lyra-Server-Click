package Lyra::Server::Click;
use Moose;
use AnyEvent;
use Lyra::Extlib;
use Lyra::Util qw(NOOP);
use URI;
use namespace::autoclean;

our $VERSION = '0.00001';

with qw(
    Lyra::Trait::Async::WithMemcached
    Lyra::Trait::Async::WithDBI
    Lyra::Trait::Async::PsgiApp
);

has ad_id_query_key => (
    is => 'ro',
    isa => 'Str',
    default => 'ad',
);

has log_storage => (
    is => 'ro',
    handles => {
        log_click => 'store',
    },
);

sub process {
    my ($self, $start_response, $env) = @_;

    # Stuff that gets logged at the end goes here
    my %log_info = (
        remote_addr => $env->{REMOTE_ADDR},
        query       => $env->{QUERY_STRING},
    );

    # This is the CV that gets called at the end
    my $cv = AE::cv {
        my ($status, $header, $content) = $_[0]->recv;
        respond_cb($start_response, $status, $header, $content);
        if ($status eq 302) { # which is success for us
            $self->log_click( \%log_info );
        }
        undef %log_info;
        undef $status;
        undef $header;
        undef $content;
    };

    # check for some conditions
    my ($status, @headers, $content);

    if ($env->{REQUEST_METHOD} ne 'GET') {
        $cv->send( 400 );
        return;
    }

    # if we got here, then we're just going to redirect to the
    # landing page. 
    my %query = URI->new('http://dummy/?' . ($env->{QUERY_STRING} || ''))->query_form;

    my $ad_id = $query{ $self->ad_id_query_key };

    $self->load_ad( $ad_id, $cv );
}

sub load_ad {
    my ($self, $ad_id, $final_cv) = @_;

    # try memcached first
    $self->cache->get( $ad_id, sub { 
        my $ad = shift;
        if ($ad) {
            $final_cv->send( 302, [ Location => $ad->[0] ] );
        } else {
            $self->load_ad_from_db( $final_cv, $ad_id );
        }
    } );
}

sub load_ad_from_db {
    my ($self, $final_cv, $ad_id) = @_;

    $self->execsql(
        "SELECT landing_uri FROM lyra_ads_master WHERE id = ?",
        $ad_id,
        sub {
            my $rows = $_[1];
            if (! defined $rows) {
                confess "PANIC: loading from DB returned undef";
            }

            if (@$rows > 0) {
                $self->cache->set( $ad_id, $rows->[0], \&NOOP );
                $final_cv->send( 302, [ Location => $rows->[0]->[0] ] );
            } else {
                $final_cv->send( 404 );
            }
        }
    );
}

1;
