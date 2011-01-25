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

################################################################################
# This section contains some paths for use in this program
# Edit this for some OS
# I think no any place to change. If it`s wrong, please inform me.
# (Except config file and *.glade file)
################################################################################
# Paths to system and user config files
use constant TWATCH_GTK_SYSTEM_CONFIG_PATH =>
                        '/etc/twatch/twatch-gtk.conf';
use constant TWATCH_GTK_CONFIG_PATH => '~/.twatch/twatch-gtk.conf';
# Path to glade interface files
#use constant TWATCH_GTK_GLADE_PATH  => '/usr/share/twatch-gtk/';
use constant TWATCH_GTK_GLADE_PATH  =>
                        '/home/rubin/workspace/twatch/trunk/twatch-gtk/glade/';
# Path to twatch
#use constant TWATCH_PATH            => '/usr/bin/twatch';
use constant TWATCH_PATH            =>
                        '/home/rubin/workspace/twatch/trunk/twatch/twatch';
# Path to example crontab
use constant TWATCH_CRONTAB_PATH    => '/usr/share/doc/twatch/examples/crontab';
###############################################################################

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
        return $config;
    }
}

=head2 new

Конфигурация

=cut
sub new
{
    my ($class, %opts) = @_;
    my %config = (dir => {}, param => {});

    # Основные директории
    $config{dir}{config} = [
         TWATCH_GTK_SYSTEM_CONFIG_PATH,
         TWATCH_GTK_CONFIG_PATH];

    my $self = bless \%config ,$class;

    # Загрузим конфиг
    $self->load;

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

    # Флаг удачной загрузки конфига
    my $loaded = 'no';

    # Загрузка конфигов: сначала дефолтового, затем поверх него польз-го
    for my $config ( @{$self->{dir}{config}} )
    {
        # Удалим home
        $config =~ s/^~/$ENV{HOME}/;

        # Пропустим если конфига нет
        next unless -f $config;

        # Откроем файл конфига. Если не получиться поругаемся и перейдем к
        # другому файлу конфигурации
        open my $file, '<', $config
            or warn sprintf('Can`t read config file %s : %s', $config, $!);
        next unless $file;

        # Прочитаем файл и распарсим данные. Данные от пользователя приоритетны
        %{ $self->{param} } = (
            %{ $self->{param} },
            (
                map{ split m/\s*=\s*/, $_, 2 }
                grep m/=/,
                map { s/#\s.*//; s/^\s*#.*//; s/\s+$//; s/^\s+//; $_ } <$file>
            )
        );

        # Закроем файл и пометим что загрузка была удачной
        close $file;
        $loaded = 'yes';
    }

    # Выйдем если не удалось загрузить ниодного конфига
    die 'Config file not exists' unless $loaded eq 'yes';

    # Сохраним оригинал т.к. дальше он может преобразововаться
    %{ $self->{orig} } = %{ $self->{param} };

    for(qw(ShowCronDialog))
    {
        $self->{param}{$_} =
            ($self->{param}{$_} =~ m/^(?:1|yes|true|on)$/i) ?1 :0;
    }

    $self->{param}{twatch}  = TWATCH_PATH;
    $self->{param}{crontab} = TWATCH_CRONTAB_PATH;
    $self->{param}{glade}   = TWATCH_GTK_GLADE_PATH;

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

=head2 set

Функция установки данных конфигурации

=cut
sub set
{
    my ($self, $name, $value) = @_;
    $self->{param}{$name} = $value;
}

=head2 daemon

Функция получения объекта конфигурации демона

=cut
sub daemon
{
    return TWatch::Config::config;
}

1;