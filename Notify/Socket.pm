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


package Notify::Socket;

use strict;
use warnings;
use Notify::Config;
use Notify::Message;
use IO::Socket::UNIX;
use IO::Socket::INET;
use Notify::Logger;

use constant {
    CLIENT  => 'CLIENT',
    SERVER  => 'SERVER',
    INET    => 'INET',
    UNIX    => 'UNIX',
};

sub new {
    my ($class, $options) = @_;
    # self/options includes _mode and _options. 
    my $self = $options; 
    $self->{_handle} = undef;
    bless $self, $class;

    $self->set_handle();

    return $self;
}

sub set_handle {
    my ($self) = shift;

    if($self->{_mode} eq CLIENT
        and $self->{_options}->{socket_type} eq UNIX) {

            $self->{_handle} = IO::Socket::UNIX->new(
                Peer => $self->{_options}->{socket_path},
                Type => SOCK_STREAM,
            ) or die 'Could not contact client UNIX socket at ' 
                . $self->{_options}->{socket_path} . "\n"; 
    }
    if($self->{_mode} eq CLIENT
        and $self->{_options}->{socket_type} eq INET) {

            $self->{_handle} = IO::Socket::INET->new(
                PeerAddr => Notify::Config->get('local_addr'),
                PeerPort => Notify::Config->get('local_port'),
                Proto    => 'tcp',
            ) or die 'Could not contact client INET socket at local test'; 
    }
    if($self->{_mode} eq SERVER
        and $self->{_options}->{socket_type} eq UNIX) {

            $self->{_handle} = IO::Socket::UNIX->new(
                Local => $self->{_options}->{socket_path},
                Type => SOCK_STREAM,
                Listen => 5,
            ) or die 'Could not contact server UNIX socket at ' 
                . $self->{_options}->{socket_path} . "\n"; 
    }
    if($self->{_mode} eq SERVER
        and $self->{_options}->{socket_type} eq INET) {

            $self->{_handle} = IO::Socket::INET->new(
                LocalAddr => Notify::Config->get('local_addr'),
                LocalPort => Notify::Config->get('local_port'),
                Proto    => 'tcp',
                Listen => 5,
            ) or die 'Could not contact server INET socket at local test';
    } 
    die 'Mode or socket type not recognized in socket creation'
        if not defined $self->{_handle};
}

sub get_handle {
    my $self = shift;

    return $self->{_handle};
}

1;


