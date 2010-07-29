package TWatch::Watch::Reg;

use warnings;
use strict;
use utf8;

use TWatch::Config;

=head1 NAME

TWatch::Watch::Reg - Модуль работы с регулярниками пользователя

=head1 SYNOPSIS

  use TWatch::Watch::Reg;

=head1 DESCRIPTION

=cut

use constant DEFAULT_REG_TORRENT =>
    q{<a[^>]*href=["']?[^>'"]*/([^>'"]*\.torrent)["']?};
use constant DEFAULT_REG_LINK    =>
    q{<a[^>]*href=["']?([^>'"]*\.torrent)["']?};



=head1 CONSTRUCTOR

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    $self->param('torrent', DEFAULT_REG_TORRENT) unless $self->param('torrent');
    $self->param('link',    DEFAULT_REG_LINK)    unless $self->param('link');

    return $self;
}

=head1 METHODS

=cut

=head2 param $name, $value

Get or set new parameter value

=cut

sub param
{
    my ($self, $name, $value) = @_;

    $self->{$name} = $value if defined $value;
    return $self->{$name};
}

=head2 match $content

Parse content by regexp and return matches.

=cut

sub match
{
    my ($self, $content, $type) = @_;

    my %result;
    for my $name ( keys %{ $self } )
    {
        # Get regexp and clean it
        my $reg = $self->{$name};
        s/^\s+//, s/\s+$// for $reg;
        # Use regexp on content. If tree set only first value
        my @value = ($type eq 'tree')
            ? $content =~ m/$reg/si
            : $content =~ m/$reg/sgi;
        # All digits to decimal.
        # (Many sites start write digits from zero)
        (m/^\d+$/)  ?$_ = int($_)   :next   for @value;
        # Add values to result
        push @{ $result{$name} }, @value;
    }

    # Fix filenames unless it`s not *.torrent
    for my $torrent (@{ $result{torrent} })
    {
        # Skip if canonical
        next if $torrent =~ m~^[^\/]\.torrent$~i;
        # Remove special sybmols
        s~^[\/*?]~~, s~[\/*?]$~~, s~[\/*?]~_~g for $torrent;
        # Add file extension
        $torrent .= '.torrent' unless $torrent =~ m~\.torrent$~i;
    }

    # Transform to easy use form
    my @result;
    while (@{ $result{link} })
    {
        my %res;
        $res{$_} = shift @{$result{$_}} for keys %result;
        # Clean from tags
        ($res{$_}) ?() :next,
        $res{$_} =~ s/<\/?\s*br>/\n/g,
        $res{$_} =~ s/<.*?>//g for keys %res;

        push @result, \%res;
    }

    return @result if wantarray;
    return \@result;
}

1;