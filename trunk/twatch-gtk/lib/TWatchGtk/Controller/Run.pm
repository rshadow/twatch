#!/usr/bin/perl
package TWatchGtk::Controller::Run;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;
use lib qw(../../);

use Glib qw(:constants);
use Gtk2;
use POSIX qw(strftime);
use Encode qw(encode is_utf8);
#use IPC::Open3;
#use POSIX ":sys_wait_h";
#
use Config;

use IPC::Run qw( start pump finish timeout );
#use IPC::Run qw( run new_chunker timeout );


use TWatchGtk::Config;

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

#    run
#        [config->get('twatch'), '--verbose'],
#        new_chunker,
#        sub {
#            my ( $out ) = shift;
#            return unless $out;
#
#            $buffer->insert($buffer->get_end_iter, $out);
##                (is_utf8 $out) ?$out :encode( utf8 => $out ));
#            return $out;
#        };

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

    my ($in, $out);
    my $twatch = start [config->get('twatch'), '--verbose'], \$in, \$out;

    pump $twatch until ! $out;
    until( ! $out )
    {
        pump $twatch;
        $buffer->insert(
            $buffer->get_end_iter,
            (is_utf8 $out) ?$_ :encode( utf8 => $out )
        );
    }

    finish $twatch or die "$twatch returned $?";

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


    return TRUE;
}

sub on_button_cancel_pressed
{
    my ($self, $window) = @_;
#    threads->exit();
    $self->{window}->destroy;
    return TRUE;
}

1;