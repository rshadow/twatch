package TWatch::Message;

=head1 NAME

TWatch::Message - collect and send messges to user

=head1 SYNOPSIS

    use TWatch::Message;

=cut

use strict;
use warnings;
use utf8;

use base qw(Exporter);
our @EXPORT=qw(message);

use MIME::Lite;
use MIME::Base64;
use MIME::Words ':all';
use Sys::Hostname;
use Encode qw(decode encode is_utf8);

use TWatch::Config;

=head1 MESSAGE METHODS

=cut

=head2 message

Return singleton message object

=cut

sub message
{
    # Object singleton
    our $object;
    return $object if $object;

    $object = TWatch::Message->new;
    return $object;
}

=head2 new

Create message object

=cut

sub new
{
    my ($class, %opts) = @_;

    my $self = bless \%opts ,$class;

    $self->{quie} = [];

    return $self;
}

=head2 add %opts

Add message %opts to collector.

Message consist from

=over

=item message

Message text.

=item level

Message level: info, error.

=back

=cut

sub add
{
    my ($self, %opts) = @_;

    push @{ $self->{quie} }, \%opts;
    return 1;
}

=head2 get

Get messages from collector

=cut

sub get
{
    my ($self) = @_;
    return @{ $self->{quie} } if wantarray;
    return $self->{quie};
}

=head2 has

How many messages in collector. Can be used as boolean flag.

=cut

sub count
{
    my ($self) = @_;
    return scalar @{ $self->{quie} };
}

=head1 EMAIL METHODS

=cut

=head2 send

Send collected messages on email

=cut

sub send
{
    my ($self) = @_;

    # Skip if no messages
    return 0 unless $self->count;
    # Skip if level = none
    return 0 if 'none' ~~ @{ config->get('EmailLevel') };
    # Skip if no destination address
    return 0 unless config->get('Email');

    my @messages = $self->get;
    @messages = grep {$_->{level} ~~ @{ config->get('EmailLevel') }} @messages;
    # Style messages for mail
    @messages = map {
        my $message = $_;
        my $str = $message->{message};
        $str .= "\n";
        $str .= sprintf("%-18s %s\n", $_.':', $message->{data}{$_} || '')
            for keys %{ $message->{data} };
        $str;
    } @messages;

    # Send mail
    {
        my $msg = new MIME::Lite(
            From        =>  sprintf( 'TWatch <twatch@%s>', hostname),
            To          =>  config->get('Email'),
            Subject     =>  sprintf( 'TWatch: %d messages', scalar @messages),
            Type        =>  "text/plain; charset=utf-8",
            Data        =>
                encode( utf8 => join( ("\n".('#') x 80 ."\n\n"), @messages) ),
            'X-Service' => 'twatch',
        );

        eval { $msg->send; };
        if( $@ )
        {
            warn sprintf 'Can`t send email to %s : $s', config->get('Email'), $@;
        }
        else
        {
            notify( sprintf 'Sended %d messages in mail', scalar @messages );
        }

        # Clean memory
        undef @messages, $msg;
    }
}

1;

=head1 REQUESTS & BUGS

Roman V. Nikolaev <rshadow@rambler.ru>

=head1 AUTHORS

Copyright (C) 2008 Roman V. Nikolaev <rshadow@rambler.ru>

=head1 LICENSE

This program is free software: you can redistribute  it  and/or  modify  it
under the terms of the GNU General Public License as published by the  Free
Software Foundation, either version 3 of the License, or (at  your  option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even  the  implied  warranty  of  MERCHANTABILITY  or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public  License  for
more details.

You should have received a copy of the GNU  General  Public  License  along
with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
