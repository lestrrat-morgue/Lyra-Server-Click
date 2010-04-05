package App::Lyra::Click;
use lib "../Lyra-Core/lib";
use Moose;
use AnyEvent;
use Lyra::Server::Click;
use Lyra::Log::Storage::File;
use File::Spec;
use namespace::autoclean;

with
    'Lyra::Trait::App::WithLogger' => {
        loggers => [
            {
                prefix => 'click',
            },
        ],
    },
    'Lyra::Trait::App::StandaloneServer',
;

has '+psgi_server' => (
    default => 'Twiggy'
);

has dsn => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    documentation => "DSN for database containing the ads"
);

has user => (
    is => 'ro',
    isa => 'Str',
);

has password => (
    is => 'ro',
    isa => 'Str',
);

sub build_app {
    my $self = shift;

    my $storage = $self->build_click_log;

    my $cv = AE::cv;

    my $dbh = AnyEvent::DBI->new(
        $self->dsn,
        $self->user,
        $self->password,
        on_connect => sub {
            $cv->send($_[0]);
        },
        exec_server => 1,
        RaiseError => 1,
        AutoCommit => 1,
    );

    $cv->recv;

    Lyra::Server::Click->new(
        dbh => $dbh,
        log_storage => $storage,
    )->psgi_app;
}

__PACKAGE__->meta->make_immutable();

1;

