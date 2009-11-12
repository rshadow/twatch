package TWatchGtk::Config;

=head1 TWatchGtk::Config

Модуль загрузки конфигурации

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);

use base qw(Exporter);
our @EXPORT=qw(config DieDumper Dumper);

use TWatch::Config;

=head2

Кеширование работы с конфигурацией

=cut

{
    no warnings "redefine";
    sub config
    {
        our $config;
        return $config if $config;

        $config = TWatchGtk::Config->new;
        return unless $config;

        # Загрузим конфиг
        $config->load;

        return $config;
    }
}

=head2 new

Конфигурация

=cut
sub new
{
    my ($class, %opts) = @_;
    my %config;

    # Основные директории
#    $config{dir}{config} = '~/.twatch-gtk.conf';
    $config{dir}{config} = '/home/rubin/workspace/twatch/trunk/twatch-gtk/config/twatch-gtk.conf';

    my $self = bless \%config ,$class;
    return $self;
}

################################################################################
# Функции работы с конфигурацией
################################################################################

=head2 load

Load current config

=cut
sub load
{
    my ($self) = @_;

    # Load config
    warn sprintf( 'Config file not exists in: %s', $self->{dir}{config})
        unless -f $self->{dir}{config};

    open my $file, '<', $self->{dir}{config}
        or warn sprintf('Can`t read config file %s : %s',
            $self->{dir}{config}, $!);

    $self->{param} = {
        map{ split m/\s*=\s*/, $_, 2 }
        grep m/=/,
        map { s/#\s.*//; s/^\s*#.*//; s/\s+$//; s/^\s+//; $_ } <$file>};

    close $file;

    return 1;
}

=head2 get

Функция получения данных конфигурационного файла

=cut
sub get
{
    my ($self, $name) = @_;
    return $self->{param}{$name};
}

=head2 daemon

Функция получения объекта конфигурации демона

=cut
sub daemon
{
    return TWatch::Config::config;
}
1;