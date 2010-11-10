package TWatchGtk::Controller::Settings;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config;

sub init
{
    my ($self) = @_;

    # Инициализация параметров демона:

    # Строковые параметры
    $self->{builder}->get_object( $_ )->set_text( config->daemon->get_orig( $_ ) )
        for (qw(Project Save Complete Email));

    # Уровень отсылки уведомлений
    for( @{ config->daemon->get('EmailLevel') } )
    {
        $self->{builder}->get_object($_)->set_active( 1 )
            if $self->{builder}->get_object( $_ );
    }

    # Использование прокси
    $self->{builder}->get_object('NoProxy')->set_active(
        config->daemon->get('NoProxy')
    );

    # Инициализация параметров GUI:

    # Использование прокси
    $self->{builder}->get_object('ShowCronDialog')->set_active(
        config->get('ShowCronDialog')
    );
}

sub on_button_ok_pressed
{
    my ($self, $window) = @_;

    # Массив с новыми пользовательскими параметрами
    my @config = ();

    # TWatch ###################################################################
    # Если что-то изменилось то сохраним в локальном файле настроек пользователя

    # Строковые параметры
    for (qw(Project Save Complete))
    {
        my $value = $self->{builder}->get_object( $_ )->get_text();

        push @config, {name => $_, value => $value}
            if config->daemon->get_orig( $_ ) ne $value;
        config->daemon->set($_, $value);
    }

    # Строковые параметры
    for (qw(Email))
    {
        my $value = $self->{builder}->get_object( $_ )->get_text();

        push( @config, {name => $_, value => $value}),
        config->daemon->set($_, $value)
            if config->daemon->get( $_ ) ne $value;
    }

    # Уровень отсылки уведомлений
    {
        my @value;
        for my $type ( qw(info error) )
        {
            push @value, $type
                if $self->{builder}->get_object($type)->get_active();
        }

        push( @config, {name => 'EmailLevel', value => join ',', @value} ),
        config->daemon->set('EmailLevel', \@value)
            unless @value ~~ @{ config->daemon->get('EmailLevel') };
    }

    # Использование прокси
    {
        my $value =
            $self->{builder}->get_object('NoProxy')->get_active();
        push( @config, {name => 'NoProxy', value => $value || 'no'} ),
        config->daemon->set('NoProxy', $value)
            if config->daemon->get('NoProxy') != $value;
    }

    # Выйдем если пользователь ничего не менял
    if( @config )
    {
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

        warn sprintf('Can`t find path to store user twatch config file'),
        $self->{window}->destroy,
        return FALSE
            unless $config;

        # Запишем конфиг в файл
        open my $file, '>', $config
            or warn sprintf(
                'Can`t save twatch config file %s : %s', $config, $!);

        $self->{window}->destroy,
        return FALSE
            unless $file;

        print $file sprintf( "%s = %s\n", $_->{name}, $_->{value} ) for @config;
        close $file;
    }

    # GUI ######################################################################
    @config = ();

    # Использование прокси
    {
        my $value =
            $self->{builder}->get_object('ShowCronDialog')->get_active();
        push( @config, {name => 'ShowCronDialog', value => $value || 'no'}),
        config->set('ShowCronDialog', $value)
            if config->get('ShowCronDialog') != $value;
    }

    # Выйдем если пользователь ничего не менял
    if( @config )
    {
        # Найдем подходящий (в директории пользователя) путь к файлу конфигурации
        my $config;
        for ( @{ config->{dir}{config} } )
        {
            next unless m/^$ENV{HOME}/;
            # Удалим home
            s/^~/$ENV{HOME}/;
            $config = $_;
            last;
        }

        warn sprintf('Can`t find path to store user twatch-gtk config file'),
        $self->{window}->destroy,
        return FALSE
            unless $config;

        # Запишем конфиг в файл
        open my $file, '>', $config
            or warn sprintf(
                'Can`t save twatch-gtk config file %s : %s', $config, $!);

        $self->{window}->destroy,
        return FALSE
            unless $file;

        print $file sprintf( "%s = %s\n", $_->{name}, $_->{value} ) for @config;
        close $file;
    }


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