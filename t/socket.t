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


use Test::Simple tests => 37;
use Notify::Socket::SocketClient;
use Notify::Socket::SocketServer;
use Notify::Socket;
use Notify::Message;
use IO::Select;
use Data::Dumper;

$options = {
    socket        => "/tmp/test.sock",
    bind_address  => "localhost",
    port          => 9000,
    hosts         => [
        '127.0.0.1:9000',
        '127.0.0.1:9001',
        '127.0.0.1:9002',
    ],
};
    
#
# Server socket testing:
#

# Method call notify_status in SocketServer 
# constructor must be commented out for testing.
$server_socket = Notify::Socket::SocketServer->new($options);
ok($server_socket->{_options}->{socket} eq '/tmp/test.sock'); 
ok($server_socket->{_options}->{bind_address} eq 'localhost'); 
ok($server_socket->{_options}->{port} eq 9000);
ok(defined $server_socket->{_unix_socket});
ok(defined $server_socket->{_inet_socket});

$select = IO::Select->new();
ok($server_socket->add_handles($select));
$server_socket->add_handles($select);
ok($select->count() == 2);

ok($server_socket->get_pending_handle($server_socket->{_unix_socket}));
ok($server_socket->get_pending_handle($server_socket->{_inet_socket}));
ok(not defined $server_socket->get_pending_handle(1234));

#
# Client socket testing:
#
$client_socket = Notify::Socket::SocketClient->new($options);
ok($client_socket->{_options}->{socket} eq '/tmp/test.sock'); 
ok($client_socket->{_options}->{bind_address} eq 'localhost'); 
ok($client_socket->{_options}->{port} eq 9000);
ok(defined $client_socket->{_unix_socket});
ok(defined $client_socket->{_inet_socket});

$select = IO::Select->new();
ok($client_socket->add_handles($select));
$client_socket->add_handles($select);
ok($select->count() == 2);

ok($client_socket->get_pending_handle($client_socket->{_unix_socket}));
ok($client_socket->get_pending_handle($client_socket->{_inet_socket}));
ok(not defined $client_socket->get_pending_handle(1234));

#
# Testing both with a mock message.
# NB Config defaults must be hard coded for the following tests.
#
$message = Notify::Message->new(
    _command => Notify::Message->CMD_NOTIF,
);
$message->body('foo');
ok($client_socket->send_message($message));

$select = IO::Select->new();
ok($server_socket->add_handles($select));

$inet_message = undef;
OUTERLOOP: while(my @ready = $select->can_read) {
    foreach my $handle (@ready) {
        my $listen = $server_socket->get_pending_handle($handle);
        if(defined $listen) {
            my $new = $listen->accept;

            $select->add($new);
            }
        else {
            $message = Notify::Message->from_handle($handle);

            if(ref $handle eq 'IO::Socket::INET') {
                $inet_message = $message;
                last OUTERLOOP;
            }
        }
    $select->remove($handle);
    $handle->close;
    }
}

ok($inet_message->body eq 'foo');

ok($server_socket->delete_socket);
ok($client_socket->close_connection);
ok(not -e '/tmp/test.sock');

# Now to test the UNIX socket - when no INEt socket options
# are specified.
$options = {
    socket        => "/tmp/test.sock",
};
    
$server_socket = Notify::Socket::SocketServer->new($options);
ok($server_socket->{_options}->{socket} eq '/tmp/test.sock');
ok(defined $server_socket->{_unix_socket});
ok(not defined $server_socket->{_inet_socket});


$client_socket = Notify::Socket::SocketClient->new($options);
ok($client_socket->{_options}->{socket} eq '/tmp/test.sock'); 
ok(defined $client_socket->{_unix_socket});
ok(not defined $client_socket->{_inet_socket});

$message = Notify::Message->new(
    _command => Notify::Message->CMD_NOTIF,
);
$message->body('foo');
ok($client_socket->send_message($message));

$select = IO::Select->new();
ok($server_socket->add_handles($select));

$unix_message = undef;
OUTERLOOP: while(my @ready = $select->can_read) {
    foreach my $handle (@ready) {
        my $listen = $server_socket->get_pending_handle($handle);
        if(defined $listen) {
            my $new = $listen->accept;

            $select->add($new);
            }
        else {
            $message = Notify::Message->from_handle($handle);

            if(ref $handle eq 'IO::Socket::UNIX') {
                $unix_message = $message;
                last OUTERLOOP;
            }
        }
    $select->remove($handle);
    $handle->close;
    }
}

ok($unix_message->body eq 'foo');

ok($server_socket->delete_socket);
ok($client_socket->close_connection);

