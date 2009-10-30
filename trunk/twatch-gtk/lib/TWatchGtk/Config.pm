#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

=head1 TWatchGtk::Config

Модуль загрузки конфигурации

=cut

package TWatchGtk::Config;

use base qw(Exporter);

our @EXPORT=qw(config DieDumper Dumper);

=head2

Кеширование работы с конфигурацией

=cut

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

=head2 new

Конфигурация

=cut
sub new
{
    my ($class, %opts) = @_;
    my %config;

    # Основные директории
    $config{dir}{config} = '~/.twatch-gtk.conf';

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

################################################################################
# Другие функции
################################################################################


=head2 DieDumper

Функция для отладки

=cut
sub DieDumper($@)
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