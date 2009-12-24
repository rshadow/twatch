package TWatch::Message;

=head1 TWatch::Message

Модуль отправки сообщений

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

################################################################################
# Переменные
################################################################################
my $log;

################################################################################
# Функции работы с сообщениями
################################################################################

=head1 MESSAGE METHODS

=head2 log

Добавить сообщение

=cut
sub add_message
{
    my (%opts) = @_;

    $log = [] unless $log;

    push @$log, \%opts;
    return 1;
}

=head2 get_messages

Получение всех сообщений

=cut
sub get_messages
{
    return (wantarray) ?@$log :$log;
}

=head2 has_messages

Проверка наличия сообщений

=cut
sub has_messages
{
    return 0 unless defined $log;
    return scalar @$log;
}

################################################################################
# Функции работы с почтой
################################################################################

=head1 EMAIL METHODS

=head2 send_messages

Отсылка списка сообщений

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
        );

        die Encode::decode(utf8 => $msg->body_as_string);

        $msg->send;
    }
}

1;