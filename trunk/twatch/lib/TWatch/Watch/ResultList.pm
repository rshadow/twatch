package TWatch::Watch::ResultList;

use warnings;
use strict;
use utf8;

=head1 NAME

TWatch::Watch::ResultList - Модуль работы с результатоми парсинга страницы

=head1 SYNOPSIS

  use TWatch::Watch::ResultList;

=head1 DESCRIPTION

=cut

=head1 CONSTRUCTOR

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    return $self;
}

=head1 METHODS

=cut

=head2 delete_result $torrent

Delete from result hash by $torrent.

=cut

sub delete
{
    my ($self, $torrent) = @_;

    warn 'No result for delete'
        unless $self->{result}{ $torrent };

    delete $self->{result}{ $torrent };
}

sub add
{
    my ($self, $param) = @_;

    if( 'HASH' eq ref $param )
    {
        $self->{result}{ $param->{torrent} } = $param;
        return $self->{result}{$param};
    }
    elsif( 'ARRAY' eq ref $param )
    {
        $self->{result}{ $_->{torrent} } = $_ for @$param;
        return scalar @$param;
    }
}

sub get
{
    my ($self, $torrent) = @_;
    return $self->{result}{$torrent};
}

sub exists
{
    my ($self, $torrent) = @_;
    return exists $self->{result}{$torrent};
}

sub count
{
    my ($self) = @_;
    return scalar keys %{ $self->{result} };
}

sub param
{
    my ($self, $torrent, $name, $value) = @_;

    if(defined $torrent)
    {
        die 'Result not set' unless exists $self->{result}{$torrent};

        $self->{result}{$torrent}{$name} = $value;
    }
    else
    {
        $self->{result}{$_}{$name} = $value for keys %{ $self->{result} };
    }
}

sub keys
{
    my ($self) = @_;
    return keys %{ $self->{result} };
}

1;