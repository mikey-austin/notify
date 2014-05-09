#!/usr/bin/perl
#
# notify 0.1.1
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


package Notify::Sender;

use strict;
use warnings;
use Notify::Config;
use Notify::Message;
use IO::Socket::UNIX;
use Notify::Logger;

sub new {
    my $class = shift;
    my $self = {
        _queue   => [],   # Queue of messages to be sent immediately.
        _to_send => 0,
    };
    bless $self, $class;
}

sub start {
    my $self = shift;
    my $select = IO::Select->new;

    Notify::Logger->write('Sender process started, sending every '
        . Notify::Config->get('sending_interval') . ' seconds');

    #
    # These signals are considered abnormal, so return an exit code
    # greater than 0 so the parent knows something went wrong.
    #
    $SIG{'HUP'} = $SIG{'INT'} = $SIG{'TERM'} = sub { exit(1); };

    #
    # We use the following signal to indicate an expected reload.
    #
    $SIG{'USR1'} = sub { exit(0); };

    do {
        my $parent = IO::Socket::UNIX->new(
            Peer => Notify::Config->get('socket_path'),
            Type => SOCK_STREAM)
            or die "Could not contact server via socket " . Notify::Config->get('socket_path');

        # Let the parent know we are ready to send.
        my $message = Notify::Message->new(Notify::Message->CMD_READY);
        print $parent $message->encode;

        # Wait for response.
        if(my $message = Notify::Message->from_handle($parent)) {
            if($message->command eq $message->CMD_DISPATCH)
            {
                foreach my $n (@{$message->body}) {
                    push @{$self->{_queue}}, $n;
                }
            }
        }

        # Close connection to parent.
        $parent->close;

        if(@{$self->{_queue}} > 0) {
            #
            # Send any queued messages before sleeping.
            #
            while(my $notification = pop @{$self->{_queue}}) {
                eval {
                    $notification->send;
                };

                if($@) {
                    Notify::Logger->err($@);
                }
            }

            # Empty the queue.
            $self->{_queue} = [];
        }

        #
        # Sleep for the configured time if there are no expected
        # notifications.
        #
        sleep(Notify::Config->get('sending_interval'));

    } while(1); # Never return.
}

1;
