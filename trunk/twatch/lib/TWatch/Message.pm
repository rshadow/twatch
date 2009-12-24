package TWatch::Message;

=head1 NAME

TWatch::Message - collect and send messges to user

=head1 SYNOPSIS

    use TWatch::Message;

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use base qw(Exporter);
our @EXPORT=qw(add_message get_messages has_messages send_messages);

use MIME::Lite;
use MIME::Base64;
use MIME::Words ':all';
use Sys::Hostname;
use Encode qw(decode encode is_utf8);

use TWatch::Config;

# Message collector
my @quie;

=head1 MESSAGE METHODS

=cut

=head2 log

Add message to collector

=cut

sub add_message
{
    my (%opts) = @_;

    push @quie, \%opts;
    return 1;
}

=head2 get_messages

Get messages from collector

=cut

sub get_messages
{
    return (wantarray) ?@quie :\@quie;
}

=head2 has_messages

How many messages in collector. Can be used as boolean flag.

=cut

sub has_messages
{
    return scalar @quie;
}

=head1 EMAIL METHODS

=cut

=head2 send_messages

Send collected messages on email

=cut

sub send_messages
{
    # Пропустим если сообщений нет
    return 0 unless has_messages;
    # Пропустим если не задан почтовый адрес
    return 0 if grep {$_ eq 'none'} @{ config->get('EmailLevel') };
    # Пропустим если не задан почтовый адрес
    return 0 unless config->get('Email');

    my @messages = get_messages;
    @messages = grep {$_->{level} ~~ @{ config->get('EmailLevel') }} @messages;
    # Преобразуем данные сообщения в текст для письма
    @messages = map {
        my $message = $_->{message};
        $message .= "\n";
        $message .= sprintf("%s: %s\n", $_, ) for keys %{ $_->{data} };
        join( "\n", values %{$message->{data}} );

    } @messages;

    # Отправим в рассылку
    {
        my $msg = new MIME::Lite(
            From        =>  sprintf( 'TWatch <twatch@%s>', hostname),
            To          =>  config->get('Email'),
            Subject     =>  sprintf( 'TWatch: %d messages', @messages),
            Type        =>  "text/plain; charset=utf-8",
            Data        =>
                encode( utf8 => join( (('#') x 50 ."\n"), @messages) ),
            'X-Service' => 'twatch',
        );

        eval { $msg->send; };
        warn sprintf 'Can`t send email to %s : $s', config->get('Email'), $@
            if $@;
    }
}

1;