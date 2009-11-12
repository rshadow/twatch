#!/usr/bin/perl
package TWatchGtk::Controller::Settings;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config;

sub init
{
    my ($self) = @_;

    # Инициализация параметров:

    # Строковые параметры
    $self->{builder}->get_object( $_ )->set_text( config->daemon->get_orig( $_ ) )
        for (qw(Project Save Complete EMail));

    # Уровень отсылки уведомлений
    for( @{ config->daemon->get('EmailLevel') } )
    {
        $self->{builder}->get_object($_)->set_active( 1 )
            if $self->{builder}->get_object( $_ );
    }

    # Использование прокси
    $self->{builder}->get_object('NoProxy')->set_active(
        config->daemon->is_noproxy
    );
}

sub on_button_ok_pressed
{
    my ($self, $window) = @_;

    # Массив с новыми пользовательскими параметрами
    my @config;

    # Если что-то изменилось то сохраним в локальном файле настроек пользователя

    # Строковые параметры
    for (qw(Project Save Complete EMail))
    {
        my $value = $self->{builder}->get_object( $_ )->get_text();

        push @config, {name => $_, value => $value}
            if config->daemon->get_orig( $_ ) ne $value;
    }

    # Уровень отсылки уведомлений
    {
        my @value;
        for my $type ( qw(info error) )
        {
            my $new = $self->{builder}->get_object($type)->get_active();
            my $old = grep {$_ eq $type} @{ config->daemon->get('EmailLevel') };
            push @value, $type if $new != $old;
        }
        push @config, {name => 'EmailLevel', value => join ',', @value}
            if @value;
    }

    # Использование прокси
    {
        my $value = $self->{builder}->get_object('NoProxy')->get_active();
        push @config, {name => 'NoProxy', value => $value}
            if config->daemon->is_noproxy != $value;
    }

    # Выйдем если пользователь ничего не менял
    $self->{window}->destroy,
    return TRUE
        unless @config;

    # Найдем подходящий (в директории пользователя) путь к файлу конфигурации
    my $config;
    for ( @{ config->daemon->{dir}{config} } )
    {
        next unless m/^$ENV{HOME}/;
        # Удалим home
        s/^~/$ENV{HOME}/;
        $config = $_;
        last;
    }

    warn sprintf('Can`t find path to store user config file'),
    $self->{window}->destroy,
    return FALSE
        unless $config;

    # Запишем конфиг в файл
    open my $file, '>', $config
        or warn sprintf('Can`t save config file %s : %s', $config, $!);

    $self->{window}->destroy,
    return FALSE
        unless $file;

    print $file sprintf( "%s = %s\n", $_->{name}, $_->{value} ) for @config;
    close $file;

    $self->{window}->destroy;
    return TRUE;
}

sub on_button_cancel_pressed
{
    my ($self, $window) = @_;
    $self->{window}->destroy;
    return TRUE;
}

1;