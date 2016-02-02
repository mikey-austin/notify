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


package Notify::Socket::SocketServer;

use strict;
use warnings;
use IO::Socket::UNIX;
use IO::Socket::INET;
use parent qw(Notify::Socket);

sub new {
    my ($class, $args) = @_;

    my $self = $class->SUPER::new($args);
    
    set_sockets($self);

    notify_status($self);

    return $self;
}
    
sub set_sockets() {
    my $self = shift;

    $self->{_unix_socket} = IO::Socket::UNIX->new(
        Local  => $self->{_options}->{socket},
        Type   => SOCK_STREAM,
        Listen => 5,
    ) or die 'Could not initialize socket at ' 
      . $self->{_options}->{socket} . "\n$!\n"; 

    if (defined $self->{_options}->{bind_address}
        and defined $self->{_options}->{port})
    {
        $self->{_inet_socket} = IO::Socket::INET->new(
            LocalAddr => $self->{_options}->{bind_address},
            LocalPort => $self->{_options}->{port},
            Proto     => 'tcp',
            ReuseAddr => 1,
            Type      => SOCK_STREAM,
        ) or die 'Could not bind at address '
            . $self->{_options}->{bind_address}
            . ':' . $self->{_options}->{port} . "\n$!\n"; 

        $self->{_inet_socket}->listen(5);
    }
}

sub notify_status {
    my $self = shift;

    if(defined $self->{_unix_socket}) {
        Notify::Logger->write('Listening at socket '
            . $self->{_options}->{socket} 
        );
    }

    if(defined $self->{_inet_socket}) {
        Notify::Logger->write('Listening at address '
            . $self->{_options}->{bind_address} 
            . ':' . $self->{_options}->{port}
        );
    }
    else {
        Notify::Logger->write('No options for network connection.');
    }
}

1;
