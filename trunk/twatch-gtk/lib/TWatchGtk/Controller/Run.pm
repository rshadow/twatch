#!/usr/bin/perl
package TWatchGtk::Controller::Run;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);
#use threads ('yield', 'stack_size' => 64*4096, 'exit' => 'threads_only', 'stringify');
#use threads::shared;

use Glib qw(:constants);
use Gtk2;
use POSIX qw(strftime);
use Encode qw(encode);

use TWatchGtk::Config;

sub on_button_run_pressed
{
    my ($self, $window) = @_;

    $self->execute();

    # Создадим поток для выполнения закачки
#    my $thr = threads->create('execute', $self);
#    die 'Can`t execute downloading thread' unless $thr;
    # Пускай он выполняется в фоне
#    $thr->detach();
#    $thr->join();
#    sleep 1 if $thr->is_running();
#    threads->exit();

    return TRUE;
}

sub on_button_cancel_pressed
{
    my ($self, $window) = @_;
#    threads->exit();
    $self->{window}->destroy;
    return TRUE;
}

sub execute
{
    my ($self) = @_;

#    Gtk2::Gdk::Threads->enter;

    # Отключим кнопку выполнить чтобы не нажимали 2 раза
    my $button_run  = $self->{builder}->get_object('button_run');
    $button_run->set_sensitive(FALSE);

#    # Получим элементы управления
    my $textview    = $self->{builder}->get_object('textview');
    my $buffer      = $textview->get_buffer;
    my $iter        = $buffer->get_end_iter;
#
#    sleep 1;
#
    # Начнем вывод с времени запуска
    $buffer->set_text(POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime)."\n");
#    sleep 1;
##    $textview->scroll_to_iter($iter, 0, 0, 0, 0);
#
#    # Проверим наличие демона
    $buffer->set_text(
#        $iter,
        sprintf "Can`t find twatch in %s\n", config->get('twatch'))#,
#    sleep 1
            unless -f config->get('twatch');
##    $textview->scroll_to_iter($iter, 0, 0, 0, 0);
#
    # Выполним демона скачки
    open my $tw, '-|', sprintf( '%s %s', config->get('twatch'), '--verbose')
        or die sprintf 'Can`t execute %s', config->get('twatch');
    # Все что он выдает будем писать в свое текстовое поле
    # пока он не завершиться
    while( <$tw> )
    {
        {
            $|=1;

            $buffer->set_text(
    #           $iter,
                encode( utf8 => $_ ));
        }
#    $textview->scroll_to_iter($iter, 0, 0, 0, 0)
        sleep 1;
    }

    close $tw;

    # Включим кнопку запуска
    $button_run->set_sensitive(TRUE);

#    Gtk2::Gdk::Threads->leave;

#    threads->exit() if threads->can('exit');
#    exit;
    return;
}

1;