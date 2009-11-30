#!/usr/bin/perl
package TWatchGtk::Controller::Cron;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config;


sub on_button_yes_pressed
{
    my ($self, $window) = @_;

    # Получим текущие задания для пользователя
    my $current = `crontab -l` || '';

    # Получим примерное задание для twatch
    my $example = '';
    open my $exemple_crontab, '<', config->get('crontab');
    {
        $/ = '';
        $example = <$exemple_crontab>;
    }
    close $exemple_crontab;

    # Присоединим примерное задание к текущим
    $example = "\n" if $current;
    $current .= $example;

    # Установим новый файл с заданиями
    open my $new_crontab, '|-', 'crontab -';
    print $new_crontab $current;
    close $new_crontab;

    $self->{window}->destroy;
    return TRUE;
}

sub on_button_no_pressed
{
    my ($self, $window) = @_;
    $self->{window}->destroy;
    return TRUE;
}

1;