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


use Test::Simple tests => 8;
use Notify::ClientSocket;
use Notify::ServerSocket;
use Notify::Socket;
use IO::Select;
use Data::Dumper;

$options = {
    socket        => "/tmp/test.sock",
    bind_address  => "localhost",
    port          => 9000,
};
    
    
my $serversock = Notify::ServerSocket->new($options);
ok($serversock->{_options}->{socket} eq '/tmp/test.sock'); 
ok($serversock->{_options}->{bind_address} eq 'localhost'); 
ok($serversock->{_options}->{port} eq 9000);

my $select = IO::Select->new();
ok($serversock->add_handles($select));

$serversock->add_handles($select);
ok($select->count() == 2);

ok(defined $serversock->match($serversock->{_unix_socket}));
ok(defined $serversock->match($serversock->{_inet_socket}));
ok(!defined $serversock->match(1234));
