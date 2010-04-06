use inc::Module::Install;

name 'Lyra-Server-Click';
all_from 'lib/Lyra/Server/Click.pm';

requires 'AnyEvent';
requires 'Cwd';
requires 'File::Basename';
requires 'File::Spec';
requires 'Moose';
requires 'Twiggy';
requires 'URI';
requires 'namespace::autoclean';

postamble <<EOM;
gitmodules:
\tcd modules/core && \$(FULLPERLRUN) Makefile.PL && make
EOM

auto_set_repository;
WriteAll;

if (-f 'Makefile') {
    open my $fh, '+<', 'Makefile' or
        die "Failed to open Makefile: $!";
    my $content = do { local $/; <$fh> };
    seek $fh, 0, 0;

    $content =~ s/pure_all :: config pm_to_blib subdirs linkext/pure_all :: config pm_to_blib subdirs linkext gitmodules/;
    
    print $fh $content;
    close $fh;
}
