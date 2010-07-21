package TWatch::Watch::FilterList;

use warnings;
use strict;
use utf8;

=head1 NAME

TWatch::Watch::FilterList - Модуль работы с фильтрами

=head1 SYNOPSIS

  use TWatch::Watch::FilterList;

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

sub count
{
    my ($self) = @_;
    return scalar keys %{ $self->{filters} };
}

sub param
{
    my ($self, $filter, $name, $value) = @_;

    die 'Can`t find filter' unless exists $self->{filters}{$filter};

    return $self->{filters}{$filter} unless defined $name or defined $value;
    $self->{filters}{$filter}{$name} = $value if defined $value;
    return $self->{filters}{$filter}{$name};
}

sub keys
{
    my ($self) = @_;
    return keys %{ $self->{filters} };
}

1;