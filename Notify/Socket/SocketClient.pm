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


package Notify::Socket::SocketClient;

use strict;
use warnings;
use Notify::Config;
use IO::Socket::UNIX;
use IO::Socket::INET;
use Regexp::Common qw(net);
use parent qw(Notify::Socket);

sub new {
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);
    
    set_sockets($self);

    return $self;
}
    
sub set_sockets() {
    my $self = shift;

    $self->{_unix_socket} = IO::Socket::UNIX->new(
        Peer => $self->{_options}->{socket},
        Type => SOCK_STREAM,
    ) or die 'Could not contact client socket at ' 
      . $self->{_options}->{socket} . "\n$!\n"; 

    foreach my $host (@{$self->{_options}->{hosts}}) {
        my ($address, $port) = split(':', $host);

        # Validate the address.
        if(not $address =~ /$RE{net}{IPv4}/) {
            print 'Could not contact host at address '
                . $host . ', invalid address.'
                . "\n"; 
            next;
        }

        # Validate the port.
        if(not $port =~  m/^[0-9]{1,5}$/) {
            print 'Could not contact host at address '
                . $host . ', invalid port number.'
                . "\n"; 
            next;
        }

        $self->{_inet_socket} = IO::Socket::INET->new(
                PeerAddr => $address,
                PeerPort => $port,
                Proto    => 'tcp',
                Type     => SOCK_STREAM,
        ) or print 'Could not contact host at address '
            . $host . ', no response.'
            . "\n"; 

        if(defined $self->{_inet_socket}) {
            print 'Connected to host at ' . $host ."\n";
            last;
        }
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
        print "Sent message to socket.\n";
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
    
    die 'Could not recieve message from server.\n'
        if(!defined $response);


    # Validate the response:
    # Response will only have this command if from invalid
    #   server, not a response citing an invalid key from
    #   the client.
    $response->{_body} = 'Recieved reply from untrusted server.'
        if $response->{_command} eq Notify::Message->CMD_AUTH_FAILURE;

    return $response;
}
 
sub close_connection {
    my $self = shift;

    $self->{_inet_socket}->close
        if(defined $self->{_inet_socket});
    $self->{_unix_socket}->close;
}

1;
