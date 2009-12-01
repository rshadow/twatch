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

    my @proj = $self->get_proj;

    $self->notify(sprintf 'Total projects: %s', scalar @proj);
    for my $proj (@proj)
    {
        $self->notify(sprintf 'Start project: %s (%s)',
            $proj->{name}, $proj->{url});
        $self->notify(sprintf 'Total watches: %s',
            scalar @{[ $self->get_watch($proj->{name}) ]} );

        $self->notify(sprintf 'Authtorization...');

        # Получим объект браузера с пройденной авторизацией на трекере
        my $browser = $self->get_auth_browser( $proj );
        # Если авторизоваться не удалось пропустим проект
        unless ($browser)
        {
            warn sprintf 'Browser is wrong and skip project: %s',
                $proj->{name};
            next;
        }

        #Пройдемся по заданиям в проекте
        for my $watch( $self->get_watch($proj->{name}) )
        {
            $self->notify(sprintf 'Start watch: %s', $watch->{name});
            $self->notify(sprintf 'Get torrents list from %s', $watch->{url});

            # Получим страницу с сылками на торренты
            eval{ $browser->get( $watch->{url} ); };

            # Проверка что контент получен
            if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
            {
                warn sprintf 'Can`t get content in "%s" project, watch "%s".',
                    $proj->{name}, $watch->{name};
                next;
            }

            # Получим контент ср=траницы со списком торрентов
            my $content = $browser->content;

            # Получим ссылки на страницы описания торрентов и определим
            # структуру хранения торрентов на трекере
            my @links;
            if ($watch->{urlreg})
            {
                # Если на трекере описание каждого торрента находиться на
                # отдельной странице то считаем его древовидным.
                # Это основной тип тракеров. Например: torrents.ru
                $watch->{type} = 'tree';

                # Получим ссылки на страницы с описаниями торрентов и ссылками
                # для скачки файлов торрента
                my $reg = $watch->{urlreg};
                @links = $content =~ m/$reg/sgi;
            }
            else
            {
                # Если на трекере есть список с описаниями торрентов и ссылками
                # на получение торрент файлов в этом списке то считаем его
                # линейным.
                # Как правило это трекеры с сериалами. Например: lostfilm.tv
                $watch->{type} = 'linear';

                # Текущая страница и есть страница со ссылками
                @links = ($watch->{url});
            }

            $self->notify(sprintf 'Watch type: %s.', $watch->{type});

            for my $url ( @links )
            {
                # Получим страницу с описанием торрента/ов
                if( $watch->{type} eq 'tree' )
                {
                    $self->notify(sprintf 'Get info from: %s.', $url);

                    eval{ $browser->get( $url ); };
                    # Проверка что контент получен
                    if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
                    {
                        warn sprintf 'Can`t get content in "%s" project, watch "%s".',
                            $proj->{name}, $watch->{name};
                        next;
                    }

                    # Получим контент сртраницы с торрентом
                    $content = $browser->content;
                }

                my $absoulete = $browser->uri->as_string();

                $self->notify(sprintf 'Get fields by user regexp');

                # С помощью пользовательских регулярников вытащим нужные поля
                my %result;
                for( keys %{ $watch->{reg} } )
                {
                    # Получим регулярное выражение и очистим его от пробелов
                    my $reg = $watch->{reg}{$_};
                    s/^\s+//, s/\s+$// for $reg;
                    # Используем регулярник на содержимом страницы
                    @{ $result{$_} } = $content =~ m/$reg/sgi;
                }

                # Если ссылки не были найдены то обработку дальше не ведем
                $self->notify(sprintf 'Links not found'),
                next
                    unless @{ $result{link} };

                # Приведем к удобной форме хеша по ключу торренту
                while (@{ $result{link} })
                {
                    my %res;
                    $res{$_} = shift @{$result{$_}} for keys %result;
                    # Очистим от тегов
                    ($res{$_}) ?() :next,
                    $res{$_} =~ s/<\/?\s*br>/\n/g,
                    $res{$_} =~ s/<.*?>//g for keys %res;

                    $watch->{result}{$res{torrent}} = \%res;
                }

                $self->notify(sprintf 'Drop completed torrents');

                # Выбрасим уже загруженные торренты если таковые имеються
                if( $watch->{complete} and @{$watch->{complete}} )
                {
                    for( @{$watch->{complete}} )
                    {
                        delete $watch->{result}{$_->{torrent}}
                            if $watch->{result}{$_->{torrent}};
                    }
                }

                # Если все уже готово то перейдем к следующему заданию
                $self->notify(sprintf 'New links not found'),
                next
                    unless $watch->{result} and %{ $watch->{result} };

                $self->notify(sprintf 'Filter torrents');

                #Выбрасим тоттенты не походящие по фильтрам
                if( $watch->{filters} and %{$watch->{filters}} )
                {
                    # Создадим песочницу для вычисления фильтра
                    my $sandbox = Safe->new;

                    # Пройдемся по заданиям
                    for my $key ( keys %{$watch->{result}} )
                    {
                        # Флаг - признак что фильтры стработали
                        my $flag = 1;

                        # Проверим все фильтры для задния
                        for ( keys %{$watch->{filters}} )
                        {
                            # Удалим из закачки если в задании такое значение
                            # не найдено
                            $flag = 0, last unless $watch->{result}{$key}{$_};

                            # Проверим фильтр
                            $flag &&= $sandbox->reval(
                                "$watch->{result}{$key}{$_}".
                                " $watch->{filters}{$_}{method} ".
                                "$watch->{filters}{$_}{value}");

                            # Если пользователь что-то ввел не так то выведим
                            # сообщение об ошибке
                            die sprintf 'Can`t set filter in "%s" project,'.
                                ' watch "%s", filter "%s"',
                                $proj->{name}, $watch->{name}, $_ if $@;

                            # Прекратим проверку если хоть один фильтр
                            # не совпадает
                            last unless $flag;
                        }

                        # Если не соответствует фильтрам то удалим задание
                        delete $watch->{result}{$key} unless $flag;
                    }
                }

                # Если фильтры все отсеяли то перейдем к следующему заданию
                $self->notify(sprintf 'All links filtered'),
                next
                    unless $watch->{result} and %{ $watch->{result} };

                $self->notify(sprintf 'Download *.torrents');

                # Обработаем полученные данные о торрентах
                for( keys %{ $watch->{result} } )
                {
                    my $result = $watch->{result}{$_};
                    # Загрузим торрент файл
                    {{
                        # Соберем путь для сохранения
                        my $save = config->get('Save').'/'.$result->{torrent};
                        # Пропустим уже загруженный торрент
                        last if -f $save or -s _;
                        # Загрузим торрент с сайта
                        $browser->get( $result->{link}, ':content_file' => $save);
                    }}

                    # Если загрузка удачна, переместим торрент в готовые
                    if ($browser->success)
                    {
                        # Добавим дополнительные параметры для сохранения
                        $result->{datetime} = POSIX::strftime(
                            "%Y-%m-%d %H:%M:%S", localtime(time));
                        $result->{page} = $absoulete;

                        # Сохраним задание как выполненное
                        $watch->{complete} = []
                            unless exists $watch->{complete} or
                                   'ARRAY' eq ref $watch->{complete};
                        push @{ $watch->{complete} }, $result;
                        delete $watch->{result}{$_};

                        # Добавим сообщение об удачной закачке
                        $self->add_message(
                            level   => 'info',
                            message => sprintf('New *.torrent download complete.'),
                            data    => $result);
                    }
                    else
                    {
                        warn
                            sprintf
                                'Can`t get *.torrent in "%s" project,'.
                                ' watch "%s" from %s',
                                $proj->{name}, $watch->{name}, $result->{link};
                    }
                }
            }

            $self->notify(sprintf 'Watch complete');
        }

        # Сохраним список готовых заданий
        $self->save_complete($proj->{name});

        $self->notify(sprintf 'Project complete');
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

    # Единый объект для работы с XML
    my $xs = XML::Simple->new(
        NoAttr      => 1,
        ForceArray  => ['watch', 'result', 'filter'],
        GroupTags   => {
            'watches'   => 'watch',
            'complete'  => 'result',
            'filters'   => 'filter',
        }
    );

    # Загрузим конфиги
    my @proj = glob(config->get('Project'));
    return unless @proj;
    $_ = {%{$xs->XMLin($_)}, file => $_} for @proj;

    # Загрузим завершенные задания
    my @complete = glob(config->get('Complete'));
    $_ = {%{$xs->XMLin($_)}, cfile => $_} for @complete;

    # Очистим результаты от пустых хешей (Гнусный хак чистки за XML::Simple)
    for my $complete ( @complete )
    {
        for my $name ( keys %{ $complete->{watches} } )
        {
            for my $result ( @{ $complete->{watches}{$name}{complete} } )
            {
                for my $key ( keys %$result)
                {
                    $result->{$key} = ''
                        if 'HASH' eq ref $result->{$key} and !%{$result->{$key}};
                }
            }
        }
    }

    # Информацию по завершенным заданиям добавим в проекты
    for my $complete ( @complete )
    {
        # Найдем проект для данных завершенных заданий по его имени
        my ($proj) = grep {$_->{name} eq $complete->{name}} @proj;
        next unless $proj;

        # Сольем хеши вместе
        ( exists $complete->{watches}{$_})
            ?   $proj->{watches}{$_} = {
                    %{ $complete->{watches}{$_} },
                    %{ $proj->{watches}{$_} }
                }
            :   ()
        for keys %{$proj->{watches}};

        # Сохраним путь к файлу выполненных задач
        $proj->{cfile} = $complete->{cfile};
    }

    # Добавим имена к заданиям
    for my $proj (@proj)
    {
        $proj->{watches}{$_}{name} = $_ for keys %{$proj->{watches}};
    }


    # Завершим загрузку проектов преобразованием в хеш по имени проекта
    $self->{project} = { map {($_->{name} => $_)}  @proj };

#DieDumper( $self->{project} );
    # Возвратим количество загруженных проектов
    return scalar @proj;
}

=head2 get_proj

Получние проектов

=cut
sub get_proj
{
    my ($self, $name) = @_;

    return sort {$a->{order} <=> $b->{order}} values %{$self->{project}}
        if wantarray;
    return $self->{project} if !$name;
    return $self->{project}{$name};
}

=head2 get_watch

Получние заданий

=cut
sub get_watch
{
    my ($self, $proj, $name) = @_;

    $proj = $self->get_proj($proj);

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
    my $proj    = $self->get_proj($name);
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
    my $proj = $self->get_proj($name);
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

    if( $self->get_proj( $proj->{name} ) )
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
    my $proj    = $self->get_proj($name);
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

=head2 notify

Вывод сообщений в консоль

=cut
sub notify
{
    my ($self, $message) = @_;
    return unless $self->{verbose};
    return unless $message;
    print $message . "\n";
}
################################################################################
# Функции закачки
################################################################################

=head1 DOWNLOAD METHODS

=head2 get_auth_browser

Получение авторизававшегося объекта браузера

=cut
sub get_auth_browser
{
    my ($self, $proj) = @_;

    return undef unless $proj;

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
    eval{ $browser->get( $proj->{url} ); };

    if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
    {
        warn sprintf 'Can`t connect to link: %s.', $proj->{url};
        return undef;
    }

    # Если страница авторизации указана и отличается от главной то загрузим
    # ее для поиска формы авторизации
    if( exists $proj->{authtorization}{url} and
        $proj->{authtorization}{url} !~ m/^\s*$/ and
        $proj->{authtorization}{url} ne $proj->{url} )
    {
        eval{ $browser->get( $proj->{authtorization}{url} ); };
        if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
        {
            warn sprintf 'Can`t connect to link: %s.', $proj->{url};
            return undef;
        }
    }

    # Найдем форму авторизации (она так же станет текущей в браузере)
    my $form = $browser->form_with_fields(
        $proj->{authtorization}{login}{name},
        $proj->{authtorization}{password}{name}
    );
    # Если форма не найдена то продолжать не будем
    unless( $form )
    {
        warn sprintf 'Can`t find authtorization form in "%s" project.',
            $proj->{name};
        return undef;
    }

    # Заполним/дополним форму параметрами авторизации
    for (keys %{$proj->{authtorization}})
    {
        # Пропустим определенные параметры
        next if $_ eq 'url' or $_ eq 'method';
        # Пропустим если параметр задан неверно
        warn
            sprintf( 'Wrong authtorization param %s in project: %s.'.
                " Skipped.\n", $_, $proj->{name}),
            next
                if !exists $proj->{authtorization}{$_}{name} or
                   !exists $proj->{authtorization}{$_}{value} or
                   !$proj->{authtorization}{$_}{name};

        # Запишем значение
        $browser->field(
            $proj->{authtorization}{$_}{name},
            $proj->{authtorization}{$_}{value}
        );
    }

    # Потом авторизуемся с параметрами проекта
    eval{ $browser->click(); };

    # Проверка что авторизация прошла нормально
    if( !$browser->success or
        ($@ and $@ =~ m/Can't connect/) or
        !$browser->is_html() )
    {
        warn sprintf 'Can`t authtorize in "%s" project.', $proj->{name};
        return undef;
    }

    return $browser;
}

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=cut
1;