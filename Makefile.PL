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

auto_set_repository;
WriteAll;
