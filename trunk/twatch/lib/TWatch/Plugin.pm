package TWatch::Plugin;

=head1 TWatch::Plugin

Модуль загрузки и исполнения плагинов

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use File::Basename qw(dirname);
use File::Path qw(make_path);

use base qw(Exporter);
our @EXPORT=qw(config DieDumper Dumper);

use TWatch::Config;

=head2 new

=cut
sub new
{
    my ($class, %opts) = @_;
    my %config = (dir => {}, param => {});

    # Версии конфигов
    $config{dir}{config} = [
        '/etc/twatch/twatch.conf',
        '~/.twatch/twatch.conf',
    ];

    my $self = bless \%config ,$class;
    return $self;
}

=head2 post

Функция выполнения плагинов постобработки

=cut
sub post
{
    my ($self, $twatch) = @_;

    my @modules = glob(config->get('Plugin'));
    for my $module ( @modules )
    {
        # Получим имя модуля плагина
        s/^.*\/(.*?)\.pm$/$1/, s/^(.*)$/TWatch::Plugin::$1/ for $module;

        # Загрузим плагин
        eval "require $module";
        printf("Can`t load plugin \"%s\": %s\n", $module, $@), next if $@;

        # Создадим объект плагина. Передадим ему текущий конфиг.
        my $plugin = eval{ $module->new( config ) };
        printf("Can`t create plugin \"%s\": %s\n", $module, $@), next
            if $@ or !$plugin;

        # Выполним плагин. Передадим ему объект закачек.
        eval{ $plugin->run( $twatch ) };
        printf("Can`t run plugin \"%s\": %s\n", $module, $@), next if $@;
    }
}
################################################################################
# Функции работы с конфигурацией
################################################################################

################################################################################
# Другие функции
################################################################################

1;