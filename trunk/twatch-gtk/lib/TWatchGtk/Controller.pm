#!/usr/bin/perl
package TWatchGtk::Controller;

use strict;
use warnings;
use utf8;
use lib qw(..);

use Glib qw(:constants);
use Gtk2;

use TWatchGtk::Config;

=head2 new

Конструктор окна "О программе"

=cut
sub new
{
    my ($class, %opts) = @_;
    my $self = bless \%opts, $class;

    # Получим имя файла с интерфейсом
    my ($glade) = $class =~ m/::(\w+?)$/;
    $glade = lc $glade;

    # Загрузим Glade
    my $builder = Gtk2::Builder->new;
    $builder->add_from_file(config->get('Glade') . $glade . '.glade' );

    # Подсоединим сигналы
    $builder->connect_signals (undef, $self );

    # Сохраним окно
    $self->{builder} = $builder;
    $self->{window} = $builder->get_object($glade);

    # Вызов хука инициализации
    $self->init();

    return $self;
}

sub init {}

# Стандартные функции ##########################################################
=head2

Выход из приложения

=cut
sub gtk_main_quit
{
    Gtk2->main_quit;
    return TRUE;
}

#sub gtk_widget_show
#{
#    my ($self, $item, $window) = @_;
#    $window->reshow_with_initial_size;
#    return TRUE;
#}
#
#sub gtk_widget_hide
#{
#    my ($self, $item, $window) = @_;
#    $window->hide;
#    return TRUE;
#}
#
#sub gtk_widget_destroy
#{
#    my ($self, $item, $window) = @_;
##    $window->gtk_widget_hide_on_delete;
#    $window->destroy;
#    return TRUE;
#}

1;