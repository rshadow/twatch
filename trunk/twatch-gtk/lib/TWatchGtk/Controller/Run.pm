#!/usr/bin/perl
package TWatchGtk::Controller::Run;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);
#use threads ('exit' => 'threads_only', 'stringify');
#use threads::shared;

use Glib qw(:constants);
use Gtk2;
use POSIX qw(strftime);
use Encode qw(encode is_utf8);
#use IPC::Open3;
#use POSIX ":sys_wait_h";
#
use Config;

#use IPC::Run qw( start pump finish timeout );
use IPC::Run qw( run new_chunker timeout );


use TWatchGtk::Config;

sub init
{
    my ($self) = @_;

#    $Config{useithreads}
#        or die 'Recompile Perl with threads to run this dialog.';
}


sub on_button_run_pressed
{
    my ($self, $window) = @_;

    # Отключим кнопку выполнить чтобы не нажимали 2 раза
    my $button_run  = $self->{builder}->get_object('button_run');
    $button_run->set_sensitive(FALSE);

    # Получим элементы управления
    my $textview    = $self->{builder}->get_object('textview');
    my $buffer      = $textview->get_buffer;
    my $iter        = $buffer->get_end_iter;

    # Начнем вывод с времени запуска
    $buffer->set_text(POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime)."\n");

    # Проверим наличие демона
    my $msg;
    if( -f config->get('twatch') )
    {
        $msg = sprintf "Find in %s\n", config->get('twatch');
    }
    else
    {
        $msg = sprintf "Can`t find twatch in %s\n", config->get('twatch');
    }
    $buffer->insert($buffer->get_end_iter, $msg);

    run
        [config->get('twatch'), '--verbose'],
        '>',
        new_chunker,
        sub {
            my ( $out ) = shift;
            return unless $out;

            $buffer->insert($buffer->get_end_iter, $out);
#                (is_utf8 $out) ?$out :encode( utf8 => $out ));
        };

#    run( [config->get('twatch'), '--verbose'],
#        undef,
#        sub {
#            DieDumper \@_;
#            my ( $in_ref, $out_ref ) = @_;
#
#            $buffer->insert(
#                $buffer->get_end_iter,
#                (is_utf8 $out) ?$_ :encode( utf8 => $out ));
#        },
#        sub {
#            DieDumper \@_;
#            my $out = shift;
#            $buffer->insert(
#                $buffer->get_end_iter,
#                (is_utf8 $out) ?$_ :encode( utf8 => $out ));
#        })
#        or die "cat: $?";

#    my ($in, $out);
#    my $twatch = start [config->get('twatch'), '--verbose'], \$in, \$out;

#    until( $out )
#    {
#        $buffer->insert(
#            $buffer->get_end_iter,
#            (is_utf8 $out) ?$_ :encode( utf8 => $out )
#        );
#
#        pump $twatch;
#    }

#    finish $twatch or die "$twatch returned $?";

    # Включим кнопку запуска
    $button_run->set_sensitive(TRUE);




#    my($wtr, $rdr, $err);
#    use Symbol 'gensym'; $err = gensym;
#    my $pid = open3($wtr, $rdr, $err, config->get('twatch'), '--verbose');
#
#    my $kid;
#    do {
#        $kid = waitpid(-1, WNOHANG);
#        warn Dumper [$kid, $wtr, $rdr, $err];
##        sleep 1;
#    } while $kid > 0;
##
##    waitpid( $pid, 0 );
#    my $child_exit_status = $? >> 8;

#    DieDumper [$wtr, $rdr, $err];

#    $self->execute();

    # Создадим поток для выполнения закачки
#    my $thr = threads->create(\&execute, $self)
#        or die 'Can`t execute downloading thread';
#    threads->detach();
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
#
#sub execute
#{
#    my ($self) = @_;
#
#    # Пускай он выполняется в фоне
##    threads->detach();
#
##    Gtk2::Gdk::Threads->enter;
#
#    # Отключим кнопку выполнить чтобы не нажимали 2 раза
#    my $button_run  = $self->{builder}->get_object('button_run');
#    $button_run->set_sensitive(FALSE);
#
#    # Получим элементы управления
#    my $textview    = $self->{builder}->get_object('textview');
#    my $buffer      = $textview->get_buffer;
#    my $iter        = $buffer->get_end_iter;
#
#    # Начнем вывод с времени запуска
#    $buffer->set_text(POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime)."\n");
#
#    # Проверим наличие демона
#    $buffer->insert(
#        $buffer->get_end_iter,
#        sprintf "Can`t find twatch in %s\n", config->get('twatch'))#,
#            unless -f config->get('twatch');
##    $textview->scroll_to_iter($iter, 0, 0, 0, 0);
#
#    # Выполним демона скачки
#    open my $tw, '-|', config->get('twatch'), '--verbose'
#        or die sprintf 'Can`t execute %s', config->get('twatch');
#    # Все что он выдает будем писать в свое текстовое поле
#    # пока он не завершиться
#    while( <$tw> )
#    {
#        {
#            $|=1;
#
#            $buffer->insert(
#                $buffer->get_end_iter,
#                (is_utf8 $_) ?$_ :encode( utf8 => $_ )
#            );
#        }
##    $textview->scroll_to_iter($iter, 0, 0, 0, 0)
#
#    }
#
#    close $tw;
#
#    # Включим кнопку запуска
#    $button_run->set_sensitive(TRUE);
#
#    threads->exit() if threads->can('exit');
#    exit;
#
##    Gtk2::Gdk::Threads->leave;
##    return;
#}

1;