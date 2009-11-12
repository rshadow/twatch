package TWatch::Config;

=head1 TWatch::Config

Модуль загрузки конфигурации

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

=head2

Кеширование работы с конфигурацией

=cut

sub config
{
    our $config;
    return $config if $config;

    $config = TWatch::Config->new;
    return unless $config;

    # Загрузим конфиг
    $config->load;

    # Проверка конфига
#    $config->check;

    # Создание папок
    $config->create_dir;

    return $config;
}

=head2 new

Конфигурация

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
        # Пропустим если конфига нет
        next unless -f $config;

        # Откроем файл конфига. Если не получиться поругаемся и перейдем к
        # другому файлу конфигурации
        open my $file, '<', $config
            or warn sprintf('Can`t read config file %s : %s', $config, $!);
        next unless $file;

        # Прочитаем файл и распарсим данные
        $self->{param} = {
            map{ split m/\s*=\s*/, $_, 2 }
            grep m/=/,
            map { s/#\s.*//; s/^\s*#.*//; s/\s+$//; s/^\s+//; $_ } <$file>,
            $self->{param}};

        # Закроем файл и пометим что загрузка была удачной
        close $file;
        $loaded = 'yes';
    }

    # Выйдем если не удалось загрузить ниодного конфига
    die 'Config file not exists' unless $loaded eq 'yes';

    # Преобразуем в массив уровней
    $self->{param}{EmailLevel} = [ split ',', $self->{param}{EmailLevel} ];
    s/^\s*//, s/\s*$// for @{ $self->{param}{EmailLevel} };

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

=head2 noproxy

Флаг "Не использовать прокси"

=cut
sub is_noproxy
{
    my ($self) = @_;
    return 1 if $self->get('NoProxy') =~ m/^(1|yes|true|on)$/;
    return 0;
}

################################################################################
# Другие функции
################################################################################

=head2 create_dir

Создает директории в пользовательской папке

=cut
sub create_dir
{
    my ($self) = @_;

    # Создадим директории для файлов
    for my $param ('Save', 'Project', 'Complete')
    {
        # Получим путь к директории
        my $path = $self->get($param);
        # Сохраним оригинал
        $self->{orig}{$param} = $path;
        # Удалим home
        $path =~ s/^~/$ENV{HOME}/;
        # Установим абсолютный путь во время выполнения
        $self->set($param, $path);
        # Получим директорию
        my $dir = $path;
        $dir = dirname( $dir ) if $dir =~ m/\Q*.xml\E$/;
        # Пропустим если директория уже создана
        next if -d $dir;
        # Создадим директорию если ее еще нет
        eval{ make_path $dir; };
        die sprintf("Can`t create store directory: %s, %s\n", $dir, $@) if $@;
    }
}


=head2 DieDumper

Функция для отладки

=cut
sub DieDumper
{
    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 0;
    my $dump = Data::Dumper->Dump([@_]);
    # юникодные символы преобразуем в них самих
    # вметсто \x{уродство}
#    $dump=~s/(\\x\{[\da-fA-F]+\})/eval "qq{$1}"/eg;
    die $dump;
}

=head2 Dumper

=cut
sub Dumper
{
    require Data::Dumper;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
    $Data::Dumper::Maxdepth = 0;
    my $dump = Data::Dumper->Dump([@_]);

    return $dump;
}
1;