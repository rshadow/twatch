package TWatch::Complete;

=head1 TWatch::Complete

Модуль загрузки выполненных заданий

=cut

use strict;
use warnings;
use utf8;
use open qw(:utf8 :std);
use lib qw(../../lib);

use base qw(Exporter);
our @EXPORT=qw(complete);

use XML::Simple;

use TWatch::Config;

=head2 complete

Загружает выполненные задания и держит их в кеше

=cut

sub complete
{
    our $complete;

    $complete = TWatch::Complete->new() unless $complete;

    return $complete;
}

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    $self->load;

    return $self;
}


sub load
{
    my ($self) = @_;

    # Загрузим завершенные задания
    my @complete = glob(config->get('Complete'));
    return unless @complete;

    # Объект для работы с XML
    my $xs = XML::Simple->new(
        NoAttr      => 1,
        ForceArray  => ['watch', 'result', 'filter'],
        GroupTags   => {
            'watches'   => 'watch',
            'complete'  => 'result',
            'filters'   => 'filter',
        }
    );

    # Загрузим все выполненные задания
    $_ = { %{$xs->XMLin($_)}, cfile => $_ } for @complete;

    # Очистим результаты от пустых хешей (Гнусный хак чистки за XML::Simple)
    for my $complete ( @complete )
    {
        for my $name ( keys %{ $complete->{watches} } )
        {
            # Добавим пустой массив выполненных, даже если их нету
            $complete->{watches}{$name}{complete} = []
                unless %{ $complete->{watches}{$name} };

            # В завершенных почистим пустые хеши
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

    # Перестроим для быстрого доступа по имени проекта
    $self->{project} = {};
    $self->{project}{ $_->{name} } = $_ for @complete;
}

=head2 get

Получение результатов для проекта

=cut
sub get
{
    my ($self, $name) = @_;

    return unless exists $self->{project}{$name};
    return $self->{project}{$name};
}

1;