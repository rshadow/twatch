package TWatch;

=head1 NAME

TWatch - осуществляет слежение за ссылками на сайте и скачку файлов по ссылкам.

=head1 VERSION

0.0.1

=cut
our $VERSION = '0.0.1';

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../lib);

use Encode qw(decode encode is_utf8);
use POSIX (qw(strftime));
use WWW::Mechanize;
use Sys::Hostname;
use MIME::Lite;
use MIME::Base64;
use MIME::Words ':all';
use XML::Simple;
use Safe;

use TWatch::Config;
use TWatch::Project;
use TWatch::Watch;

=head1 CONSTRUCTOR AND MAIN

=head2 new

Конструктор объекта закачкм

=cut
sub new
{
    my ($class, %opts) = @_;

    my %obj = %opts;
    my $self = bless \%obj ,$class;

    $self->load_proj;

    return $self;
}

=head2 run

Скрипт выполнения закачек соответсвенно параметрам проекта.

=cut
sub run
{
    my ($self) = @_;

    my @projects = $self->get_projects;

    notify(sprintf 'Total projects: %s', scalar @projects);

    for my $project (@projects)
    {
        notify(sprintf
            'Start project: %s (%s), last update %s',
            $project->name,
            $project->url,
            $project->update);
        notify(sprintf 'Watches: %d', $project->watches_count);

        $project->run
            or warn sprintf 'Project aborted!';

#
#        # Сохраним список готовых заданий
#        $self->save_complete($proj->{name});

        notify('Project complete');
    }
}

################################################################################
# Функции работы с проектами
################################################################################

=head1 PROJECT METHODS

=head2 load_proj

Функция загрузки проектов

=cut
sub load_proj
{
    my ($self) = @_;

    # Загрузим конфиги
    my @projects = glob(config->get('Project'));
    return unless @projects;

    $_ = TWatch::Project->new(file => $_) for @projects;

    $self->{project}{$_->name} = $_ for @projects;

    return scalar @projects;
}

=head2 get_projects

Получние проектов

=cut
sub get_projects
{
    my ($self, $name) = @_;

    return sort {$a->{order} <=> $b->{order}} values %{$self->{project}}
        if ! defined $name and wantarray;
    return $self->{project} if ! defined $name;
    return $self->{project}{$name};
}

=head2 get_watch

Получние заданий

=cut
sub get_watch
{
    my ($self, $proj, $name) = @_;

    $proj = $self->get_projects($proj);

    return sort {$a->{order} <=> $b->{order}} values %{$proj->{watches}}
        if wantarray;
    return $proj->{watches} if !$name;
    return $proj->{watches}{$name};
}

=head2 save_complete

Сохранение готовых заданий

=cut
sub save_complete
{
    my ($self, $name) = @_;

    # Получим проект
    my $proj    = $self->get_projects($name);
    my $watch   = $self->get_watch($name);
    $watch->{$_} = {
        name        => $_,
        ($watch->{$_}{complete})
            ?(complete => { result => $watch->{$_}{complete} })
            :(),
    } for keys %$watch;

    # Составим данные о сохранении
    my $save = {
        name    => $proj->{name},
        update  => POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time)),
        watches => { watch => [ values %$watch ] },
    };

    # Составим имя файла для сохранения из пути поиска данных по завершенным
    # закачкам, плюс имя файла проекта
    my $file = $proj->{cfile};
    $file = (config->get('Complete') =~ m/^(.*)\/.*?$/)[0] .
            ($proj->{file} =~ m/^.*(\/.*?\.xml)$/)[0]
        unless $file;

    # Сохраним конфиг
    my $xs = XML::Simple->new(
        AttrIndent  => 1,
        KeepRoot    => 1,
        RootName    => 'project',
        NoAttr      => 1,
        NoEscape    => 1,
        NoSort      => 1,
        ForceArray  => ['watch', 'result'],
        XMLDecl     => 1,
        OutputFile  => $file,
    );
    my $xml = $xs->XMLout($save);

    return 1;
}

=head2 delete_proj

Удаление проекта с заданным именем.

=cut
sub delete_proj
{
    my ($self, $name) = @_;

    # Получим проект
    my $proj = $self->get_projects($name);
    warn 'Can`t delete project: Project does not exists.',
    return
        unless $proj;

    # Удалим файл проекта
    my $deleted = unlink $proj->{file};
    return unless $deleted;

    # Удалим проект
    undef $self->{project}{$name};

    return $deleted;
}

=head2 add_proj

Добавление нового проекта в список текущих

=cut
sub add_proj
{
    my ($self, $proj) = @_;

    if( $self->get_projects( $proj->{name} ) )
    {
        warn sprintf('Can`t add project "%s". This project already exists.',
            $proj->{name});
        return;
    }

    $self->{project}{ $proj->{name} } = $proj;
}

=head2 save_proj

Сохранение файла проекта

=cut
sub save_proj
{
    my ($self, $name) = @_;

    # Получим проект
    my $proj    = $self->get_projects($name);
    my $watch   = $self->get_watch($name);

    $watch->{$_} = {
        name        => $_,
        ($watch->{$_}{complete})
            ?(complete => { result => $watch->{$_}{complete} })
            :(),
    } for keys %$watch;
}


################################################################################
# Функции работы с почтой
################################################################################

=head1 EMAIL METHODS

=head2 send_mail

Отсылка списка сообщений

=cut
sub send_mail
{
    my ($self) = @_;

    # Пропустим если сообщений нет
    return 0 unless $self->has_messages;
    # Пропустим если не задан почтовый адрес
    return 0 if grep {$_ eq 'none'} @{ config->get('EmailLevel') };
    # Пропустим если не задан почтовый адрес
    return 0 unless config->get('Email');

    my @messages = $self->get_messages;
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

################################################################################
# Функции работы с сообщениями
################################################################################

=head1 MESSAGE METHODS

=head2 log

Добавить сообщение

=cut
sub add_message
{
    my ($self, %opts) = @_;

    $self->{log} = [] unless $self->{log};

    push @{ $self->{log} }, \%opts;
    return 1;
}

=head2 get_messages

Получение всех сообщений

=cut
sub get_messages
{
    my ($self) = @_;
    return (wantarray) ?@{ $self->{log} } :$self->{log};
}

=head2 has_messages

Проверка наличия сообщений

=cut
sub has_messages
{
    my ($self) = @_;
    return 0 unless exists $self->{log};
    return scalar @{ shift->{log} };
}

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=cut
1;