#!/usr/bin/perl
#
# Copyright (C) 2014  Mikey Austin <mikey@jackiemclean.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.


package Notify::Socket::Client;

use strict;
use warnings;
use Notify::Config;
use IO::Socket::UNIX;
use IO::Socket::INET;
use parent qw(Notify::Socket);

sub new {
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);
    $self->set_sockets;

    return $self;
}

sub set_sockets {
    my $self = shift;

    if(defined $self->{_options}->{host} and defined $self->{_options}->{port}) {
        $self->{_inet_socket} = IO::Socket::INET->new(
            PeerAddr => $self->{_options}->{host},
            PeerPort => $self->{_options}->{port},
            Proto    => 'tcp',
            Type     => SOCK_STREAM,
        )
        or warn "Could not connect to $self->{_options}->{host}:$self->{_options}->{port}; $!\n";
    }
    else {
        $self->{_unix_socket} = IO::Socket::UNIX->new(
            Peer => $self->{_options}->{socket},
            Type => SOCK_STREAM
        )
        or die "Could not create unix socket: $!";
    }
}

#
# Send a message to the server.
#
sub send_message {
    my ($self, $message) = @_;

    if(defined $self->{_inet_socket}) {
        print {$self->{_inet_socket}} $message->encode;
    }
    else {
        print {$self->{_unix_socket}} $message->encode
            or die "Could not send message to socket.\n";
    }
}

#
# Get a response from the server.
#
sub get_response {
    my $self = shift;
    my $response = undef;

    # Try the INET socket first,
    if(defined $self->{_inet_socket}) {
        $response = Notify::Message->from_handle(
            $self->{_inet_socket});
    }
    else {
        $response = Notify::Message->from_handle(
            $self->{_unix_socket});
    }

    die 'could not recieve message from server'
        if not defined $response;

    $response->body('client packet authentication failure')
        if $response->type eq Notify::Message->CMD_AUTH_FAILURE;

    return $response;
}

sub close_connection {
    my $self = shift;

    $self->{_inet_socket}->close
        if defined $self->{_inet_socket};
    $self->{_unix_socket}->close
        if defined $self->{_unix_socket};
}

1;
