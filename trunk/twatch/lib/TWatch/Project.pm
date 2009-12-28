package TWatch::Project;

=head1 TWatch::Project

Модуль проекта. Работа с трекером.

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use XML::Simple;
use WWW::Mechanize;

use TWatch::Config;
use TWatch::Watch;
use TWatch::Complete;

###############################################################################
=head1 Конструктор

=head2 new

Создает проект.

=head3 Опции

=over

=item file

Путь к файлу проекта

=back

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    # Если передан путь к проекту то загрузим его
    $self->load if $self->file;

    return $self;
}

################################################################################
=head1 Методы атрибутов

=cut

sub name
{
    my ($self, $param) = @_;
    $self->{name} = $param if defined $param;
    return $self->{name};
}

sub file
{
    my ($self, $param) = @_;
    $self->{file} = $param if defined $param;
    return $self->{file};
}

sub cfile
{
    my ($self, $param) = @_;
    $self->{cfile} = $param if defined $param;
    return $self->{cfile};
}

sub update
{
    my ($self, $param) = @_;
    $self->{update} = $param if defined $param;
    return $self->{update} || '';
}

sub url
{
    my ($self, $param) = @_;
    $self->{url} = $param if defined $param;
    return $self->{url};
}

sub auth
{
    my ($self, %param) = @_;
    $self->{authtorization} = \%param if %param;
    return undef unless %{ $self->{authtorization} };
    return $self->{authtorization};
}

sub auth_url
{
    my ($self, $param) = @_;
    $self->{authtorization}{url} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{url};
}

sub auth_login_name
{
    my ($self, $param) = @_;
    $self->{authtorization}{login}{name} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{login}{name};
}

sub auth_password_name
{
    my ($self, $param) = @_;
    $self->{authtorization}{password}{name} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{password}{name};
}

sub auth_login_value
{
    my ($self, $param) = @_;
    $self->{authtorization}{login}{value} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{login}{value};
}

sub auth_password_value
{
    my ($self, $param) = @_;
    $self->{authtorization}{password}{value} = $param if defined $param;
    return undef unless $self->auth;
    return $self->auth->{password}{value};
}

sub watches
{
    my ($self) = @_;
    return $self->{watches};
}

sub set_watch
{
    my ($self, $watch) = @_;
    $self->{watches}->{ $watch->name } = $watch;
    return $watch;
}

sub watches_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{watches} };
}

=head2 get_watch $name

Get watch by name

=cut

sub get_watch
{
    my ($self, $name) = @_;
    return $self->{watches}{$name};
}

###############################################################################
=head1 Другие методы

=head2 load

Загрузка проекта из имени файла

=cut

sub load
{
    my ($self) = @_;

    # Загрузим проект ##########################################################
    my $xs = XML::Simple->new(
        NoAttr      => 1,
        ForceArray  => ['watch', 'result', 'filter'],
        GroupTags   => {
            'watches'   => 'watch',
            'complete'  => 'result',
            'filters'   => 'filter',
        }
    );
    my $project = $xs->XMLin( $self->file );

    # Добавим задания в проект #################################################
    for my $name ( keys %{ $project->{watches} }  )
    {
        # Добавим имя задания в буфер
        $project->{watches}{$name}{name} = $name;
        # Создадим объект задания
        my $watch = TWatch::Watch->new(%{ $project->{watches}{$name} });
        # Добавим его в проект
        $self->set_watch( $watch );
    }

    # Удалим задания из буфера, т.к. они уже все загружены
    delete $project->{watches};

    # Добавим остальные параметры в проект #####################################
    # Остальное, без изменений, станет параметрами проекта
    $self->{$_} = $project->{$_} for keys %$project;

    # Добавим выполненные задания в проект #####################################
    # Получим выполненные задания для данного проекта
    my $complete = complete->get( $self->name );
    # Если загруженных нет то стразу выйдем
    return $self unless $complete;
    # Сохраним в проекте путь к файлу завершенных заданий
    $self->cfile( $complete->{cfile} );
    # Сохраним в проекте время последней проверки
    $self->update( $complete->{update} );

    # Добавим выполненные в задания
    $_->add_complete( $complete->{watches}{ $_->name }{complete} )
        for values %{ $self->watches };

    return $self;
}

################################################################################
# Функции закачки
################################################################################

=head1 DOWNLOAD METHODS

=cut

=head2 run

Проверка проекта

=cut

sub run
{
    my ($self) = @_;

    unless( $self->watches_count )
    {
        notify(sprintf 'No watches. Skip project.');
        return;
    }

    # Получим объект браузера с пройденной авторизацией на трекере
    notify(sprintf 'Authtorization...');
    my $browser = $self->get_auth_browser;

    # Если авторизоваться не удалось пропустим проект
    unless ($browser)
    {
        warn sprintf 'Link break. Skip project.';
        return;
    }

    # Пройдемся по всем заданиям
    for my $name ( keys %{ $self->watches })
    {
        # Получим задание
        my $watch = $self->watches->{$name};

        notify(sprintf 'Start watch: %s', $watch->name );

        $watch->run( $browser )
            or warn sprintf 'Watch aborted!';

        notify('Watch complete');
    }

    # Установим последнее время апдейта
    $self->update( POSIX::strftime("%Y-%m-%d %H:%M:%S", localtime(time)) );
    notify(sprintf 'Complete at %s', $self->update);

    # Сохраним список готовых заданий
    notify('Save completed list');
    complete->save( $self );

    return $self;
}



=head2 get_auth_browser

Получение авторизававшегося объекта браузера

=cut

sub get_auth_browser
{
    my ($self) = @_;

    return undef unless $self->{url};

    # Объект браузера
    my $browser = WWW::Mechanize->new(
        agent       => 'Mozilla/5.0'.
            ' (Windows; U; Windows NT 6.0; en-US; rv:1.9.1.1)'.
            ' Gecko/20090715 Firefox/3.5.1',
        cookie_jar  => {},
        noproxy     => config->is_noproxy,
    );

    # Во многих сайтах есть защита от прихода извне, поэтому сначала зайдем
    # на сайт.
    eval{ $browser->get( $self->url ); };

    if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
    {
        warn sprintf 'Can`t connect to link: %s.', $self->url;
        return undef;
    }

    # Если страница авторизации указана и отличается от главной то загрузим
    # ее для поиска формы авторизации
    if( $self->auth_url                 and
        $self->auth_url !~ m/^\s*$/     and
        $self->auth_url ne $self->url   )
    {
        eval{ $browser->get( $self->auth_url ); };
        if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
        {
            warn sprintf 'Can`t connect to auth link: %s.', $self->auth_url;
            return undef;
        }
    }

    # Найдем форму авторизации (она так же станет текущей в браузере)
    my $form = $browser->form_with_fields(
        $self->auth_login_name,
        $self->auth_password_name
    );
    # Если форма не найдена то продолжать не будем
    unless( $form )
    {
        warn sprintf 'Can`t find authtorization form in "%s" project.',
            $self->name;
        return undef;
    }

    # Заполним/дополним форму параметрами авторизации
    $browser->field( $self->auth_login_name, $self->auth_login_value )
        if $self->auth_login_name and $self->auth_login_value;
    $browser->field( $self->auth_password_name, $self->auth_password_value )
        if $self->auth_password_name and $self->auth_password_value;

    # Потом авторизуемся с параметрами проекта
    eval{ $browser->click(); };

    # Проверка что авторизация прошла нормально
    if( !$browser->success or
        ($@ and $@ =~ m/Can't connect/) or
        !$browser->is_html() )
    {
        warn sprintf 'Can`t authtorize in "%s" project.', $self->name;
        return undef;
    }

    return $browser;
}

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=cut

1;