package TWatchGtk::Controller::Cron;
use base qw(TWatchGtk::Controller);

use strict;
use warnings;
use utf8;

use Glib qw(:constants);
use Gtk2;
use IPC::Cmd qw(can_run run);

use TWatchGtk::Config;


sub on_button_yes_pressed
{
    my ($self, $window) = @_;

    # Получим путь к программе
    my $cpath = can_run('crontab');
    warn 'crontab is not installed',
    return TRUE
        unless $cpath;

    # Получим текущие задания для пользователя
    my ($ok, $err, $full_buf, $stdout_buff, $stderr_buff) =
        run( command => [$cpath, '-l'], verbose => 0, timeout => 10 );
    my $current = join '', @$stdout_buff;

    # Получим примерное задание для twatch
    my $example = '';
    open my $exemple_crontab, '<', config->get('crontab');
    warn 'Can`t read example crontab',
    return TRUE
        unless $exemple_crontab;
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
    warn 'Can`t set new crontab',
    return TRUE
        unless $new_crontab;
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

=head2 verify`

Check for current crontab job

=cut

sub verify
{
    # Получим путь к программе
    my $cpath = can_run('crontab');
    warn 'crontab is not installed',
    return
        unless $cpath;

    # Проверим установлен ли twatch в заданиях cron
    my ($ok, $err, $full_buf, $stdout_buff, $stderr_buff) =
        run( command => [$cpath, '-l'], verbose => 0, timeout => 10 );

    # Преобразуем весь буфер в строку
    $stdout_buff = join '', @$stdout_buff;

    # Прервемся если не найдем путь к twatch
    my $regexp = sprintf '\s%s(\s|$)', config->get('twatch');
    return 1 if $stdout_buff =~ m/$regexp/;
    return 0;
}
1;