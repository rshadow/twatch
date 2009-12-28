package TWatch::Watch;

=head1 TWatch::Watch

Модуль загрузки торрента

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use POSIX (qw(strftime));
use WWW::Mechanize;
use Safe;

use TWatch::Config;
use TWatch::Message;

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    return $self;
}

sub name
{
    my ($self, $param) = @_;
    $self->{name} = $param if defined $param;
    return $self->{name};
}

sub url
{
    my ($self, $param) = @_;
    $self->{url} = $param if defined $param;
    return $self->{url};
}

sub urlreg
{
    my ($self, $param) = @_;
    $self->{urlreg} = $param if defined $param;
    return $self->{urlreg};
}

sub order
{
    my ($self, $param) = @_;
    $self->{order} = $param if defined $param;
    return $self->{order};
}

sub type
{
    my ($self, $param) = @_;
    $self->{type} = $param if defined $param;
    return $self->{type};
}

sub reg
{
    my ($self) = @_;
    return $self->{reg};
}

sub complete
{
    my ($self) = @_;
    return $self->{complete};
}

sub complete_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{complete} };
}

=head2 add_complete

Добавить результат выполнения

=cut

sub add_complete
{
    my ($self, $complete) = @_;

    # Работаем с массивом результатов
    $complete = [$complete] unless 'ARRAY' eq ref $complete;

    # Добавим законченные в задание
    $self->{complete}{ $_->{torrent} } = $_ for @$complete;
}


=head2 add_result

Добавить результат выполнения

=cut

sub add_result
{
    my ($self, $result) = @_;

    # Работаем с массивом результатов
    $result = [$result] unless 'ARRAY' eq ref $result;

    # Добавим законченные в задание
    $self->{result}{ $_->{torrent} } = $_ for @$result;
}

=head2 result

Получение хеща результатов

=cut

sub result
{
    my ($self) = @_;
    return $self->{result};
}

=head2 get_result $torrent

Get result by torrent name

=over

=item $torrent

Torrent file name

=back

=cut

sub get_result
{
    my ($self, $torrent) = @_;
    return $self->{result}{ $torrent };
}

=head2 is_result

Проверка есть такой торрент в результатах

=cut

sub is_result
{
    my ($self, $torrent) = @_;
    return ( exists $self->{result}{ $torrent } ) ?1 :0;
}

=head2 delete_result

Удаляет результат

=cut

sub delete_result
{
    my ($self, $torrent) = @_;

    warn 'No result for delete'
        unless $self->{result}{ $torrent };

    delete $self->{result}{ $torrent };
}

=head2 result_count

Возвращает количество скаченных страниц.
В коде надо быть осторожным. Это значение обычно уменьшается при
фильтрации готовых торрентов, фильтрации по выражениям и т.д.

=cut

sub result_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{result} };
}

sub filters
{
    my ($self) = @_;
    return $self->{filters};
}

sub filters_count
{
    my ($self) = @_;
    return scalar keys %{ $self->{filters} };
}

sub filter_method
{
    my ($self, $name) = @_;
    return $self->{filters}{$name}{method};
}

sub filter_value
{
    my ($self, $name) = @_;
    return $self->{filters}{$name}{value};
}

=head2 run $browser

Do job to get new torrent files

=over

=item $browser

WWW::Mechanize object.
It`s must be authtorized and prepared for unlimited usage.

=back

=cut

sub run
{
    my ($self, $browser) = @_;

    unless( $self->url )
    {
        notify 'Url not set. Skip watch.';
        return;
    }
    notify(sprintf 'Get links list from %s', $self->url );

    # Получим страницу с сылками на торренты
    eval{ $browser->get( $self->url ); };

    # Проверка что контент получен
    if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
    {
        warn sprintf 'Can`t get content (links list) by link: %s', $self->url;
        return;
    }

    # Получим контент сртраницы со списком торрентов
    my $content = $browser->content;

    # Получим ссылки на страницы описания торрентов и определим
    # структуру хранения торрентов на трекере
    my @links;
    if ($self->urlreg)
    {
        # Если на трекере описание каждого торрента находиться на
        # отдельной странице то считаем его древовидным.
        # Это основной тип тракеров. Например: torrents.ru
        $self->type('tree');

        # Получим ссылки на страницы с описаниями торрентов и ссылками
        # для скачки файлов торрента
        my $reg = $self->urlreg;
        @links = $content =~ m/$reg/sgi;
    }
    else
    {
        # Если на трекере есть список с описаниями торрентов и ссылками
        # на получение торрент файлов в этом списке то считаем его
        # линейным.
        # Как правило это трекеры с сериалами. Например: lostfilm.tv
        $self->type('linear');

        # Текущая страница и есть страница со ссылками
        @links = ($self->url);
    }

    notify(sprintf 'Watch type: %s', $self->type);
    notify(sprintf 'Links count: %d', scalar @links) if $self->type eq 'tree';

    for my $url ( @links )
    {
        # Получим страницу с описанием торрента/ов
        if( $self->type eq 'tree' )
        {
            notify(sprintf 'Get torrent page by tree from: %s.', $url);

            eval{ $browser->get( $url ); };
            # Проверка что контент получен
            if( !$browser->success or ($@ and $@ =~ m/Can't connect/) )
            {
                warn
                    sprintf 'Can`t get content (torrent page) by link: %s',$url;
                next;
            }

            # Получим контент сртраницы с торрентом
            $content = $browser->content;
        }

        # Сохраним абсолютный url к списку ссылок
        my $absoulete = $browser->uri->as_string();

        # Получим ссылки на торренты
        $self->parse( $content );
        notify('Nothing to download. Skip Watch.'),
        next
            unless $self->result_count;

        # Добавим текущую страницу в результаты
        $_->{page} = $absoulete for values %{ $self->result };

        # Загрузим торренты
        notify('NEW TORRENTS AVIABLE!');
        $self->download( $browser );

        notify('Has not dowloaded torrents') if $self->result_count;
    }

    return $self;
}

=head2 parse $content

Parse content for torrent data

=over

=item $content

content of html page for parsing

=back

=cut

sub parse
{
    my ($self, $content) = @_;

    # С помощью пользовательских регулярников вытащим нужные поля
    notify('Get data by user regexp');
    my %result;
    for( keys %{ $self->reg } )
    {
        # Получим регулярное выражение и очистим его от пробелов
        my $reg = $self->reg->{$_};
        s/^\s+//, s/\s+$// for $reg;
        # Используем регулярник на содержимом страницы
        my @value = $content =~ m/$reg/sgi;
        # Приведем к десятичным числам.
        # (Числа на сайте могут начиниться с нуля, а для перла это
        # восьмеричный формат)
        (m/^\d+$/)  ?$_ = int($_)   :next   for @value;
        # Добавим массив в результаты
        push @{ $result{$_} }, @value;
    }

    # Если ссылки не были найдены то обработку дальше не ведем
    notify(sprintf 'Links not found. Wrong regexp?: %s', $self->reg->{link}),
    return
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

        $self->add_result( \%res );
    }

    # Выбрасим уже загруженные торренты если таковые имеються
    notify('Drop completed torrents');
    if( $self->complete_count )
    {
        for( values %{ $self->complete } )
        {
            $self->delete_result( $_->{torrent} )
                if $self->is_result( $_->{torrent} );
        }
    }

    # Если все уже готово то перейдем к следующему заданию
    notify('All torrent already completed.'),
    return
        unless $self->result_count;
    {{
        # Выбрасим тоттенты не походящие по фильтрам
        notify('Filter torrents');

        # Пропустим если фильтры не заданы
        last unless $self->filters_count;

        # Создадим песочницу для вычисления фильтра
        my $sandbox = Safe->new;

        # Пройдемся по заданиям
        for my $key ( keys %{ $self->result } )
        {
            # Получим результат
            my $result = $self->get_result($key);

            # Флаг - признак что фильтры стработали
            my $flag = 1;

            # Проверим все фильтры для задния
            for my $name ( keys %{ $self->filters } )
            {
                # Удалим из закачки если в задании такое значение
                # не найдено
                $flag = 0, last unless $result->{$name};

                # Проверим фильтр
                my $left =      $result->{$name};
                my $right =     $self->filter_value($name);
                my $method =    $self->filter_method($name) || '=~';

                if($method eq '=~' or $method eq '!~')
                {
                    $flag &&= $sandbox->reval(qq{"$left" $method $right});
                }
                else
                {
                    $flag &&= $sandbox->reval("$left $method $right");
                }

                # Если пользователь что-то ввел не так то выведим
                # сообщение об ошибке
                warn sprintf(
                    'Can`t set filter %s: "%s %s %s", becouse %s',
                    $name, $left, $method, $right, $@),
                next
                    if $@;

                # Прекратим проверку если хоть один фильтр
                # не совпадает
                last unless $flag;
            }

            # Если не соответствует фильтрам то удалим задание
            $self->delete_result( $key ) unless $flag;
        }
    }}

    # Если фильтры все отсеяли то перейдем к следующему заданию
    notify('All links filtered'),
    return
        unless $self->result_count;

    return $self->result_count;
}

=head2 download $browser

Download torrents listed in watch results.

=over

=item $browser

WWW::Mechanize object.
It`s must be authtorized and prepared for unlimited usage.

=back

=cut

sub download
{
    my ($self, $browser) = @_;

    # Обработаем полученные данные о торрентах
    for my $key ( keys %{ $self->{result} } )
    {
        my $result = $self->get_result( $key );

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

            # Сохраним задание как выполненное
            $self->add_complete( $result );
            $self->delete_result( $key );

            notify( sprintf 'Download complete: %s', $result->{torrent} );

            # Добавим сообщение об удачной закачке
            add_message(
                level   => 'info',
                message => sprintf('Download complete: %s', $result->{torrent}),
                data    => $result);
        }
        else
        {
            notify( sprintf 'Can`t download from %s', $result->{link} );
            add_message(
                level   => 'error',
                message => sprintf('Can`t download from %s', $result->{link}),
                data    => $result);
        }
    }

    return $self->result_count;
}

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=cut

1;