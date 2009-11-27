#!/usr/bin/perl
package TWatchGtk::Controller::Run;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);
use threads;
use threads::shared;

use Glib qw(:constants);
use Gtk2;
use POSIX qw(strftime);
use Encode qw(encode);

use TWatchGtk::Config;

use constant TWATCH_PATH => '/usr/bin/twatch';


sub on_button_run_pressed
{
    my ($self, $window) = @_;

    # При прирывании внутри потока завершается он а не программа
    threads->set_thread_exit_only(1);
    # Создадим поток для выполнения закачки
    my $thr = threads->create('execute', $self);
    die 'Can`t execute downloading thread' unless $thr;
    # Пускай он выполняется в фоне
    $thr->detach();

    return TRUE;
}

sub on_button_cancel_pressed
{
    my ($self, $window) = @_;
    threads->exit();
    $self->{window}->destroy;
    return TRUE;
}

sub execute
{
    my ($self) = @_;

    eval
    {

    # Получим элементы управления
    my $button_run  = $self->{builder}->get_object('button_run');
    my $textview    = $self->{builder}->get_object('textview');
    my $buffer      = $textview->get_buffer;
    my $iter        = $buffer->get_end_iter;

    # Отключим кнопку выполнить чтобы не нажимали 2 раза
    $button_run->set_sensitive(FALSE);

    # Добавим время запуска
    $buffer->insert(
        $iter,

        encode( utf8 => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime)."\n"));
    $textview->scroll_to_iter($iter, 0, 0, 0, 0);

    # Проверим наличие демона
    $buffer->insert(
        $iter,
        encode( utf8 => sprintf "Can`t find twatch in %s\n", TWATCH_PATH))
            unless -f TWATCH_PATH;
    $textview->scroll_to_iter($iter, 0, 0, 0, 0);

    # Выполним демона скачки
    open my $tw, '-|', sprintf( '%s %s', TWATCH_PATH, '--verbose')
        or die sprintf 'Can`t execute %s', TWATCH_PATH;
    # Все что он выдает будем писать в свое текстовое поле
    # пока он не завершиться
    $buffer->insert($iter, encode( utf8 => $_ )),
    $textview->scroll_to_iter($iter, 0, 0, 0, 0)
        while <$tw>;

    close $tw;

    # Включим кнопку запуска
    $button_run->set_sensitive(TRUE);
    };

    warn $@ if $@;
}

1;