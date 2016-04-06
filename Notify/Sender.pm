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


package Notify::Sender;

use strict;
use warnings;
use Notify::Config;
use Notify::Message;
use IO::Socket::UNIX;
use Notify::Logger;
use Notify::StorageFactory;

sub new {
    my $class = shift;
    my $self = {
        _queue   => [],   # Queue of messages to be sent immediately.
        _to_send => 0,
        _storage => Notify::StorageFactory->create('sender') || undef,
    };

    bless $self, $class;
}

sub start {
    my ($self, $options) = @_;

    my $select = IO::Select->new;

    Notify::Logger->write('Sender process started, sending every '
        . Notify::Config->get('sending_interval') . ' seconds');

    # Load any queued notifications.
    $self->_load;

    #
    # These signals are considered abnormal, so return an exit code
    # greater than 0 so the parent knows something went wrong.
    #
    $SIG{'INT'} = $SIG{'TERM'} = sub { exit(1); };

    #
    # We use the following signal to indicate an expected reload.
    #
    $SIG{'HUP'} = sub { exit(0); };

    #
    # Clear all queued notifications.
    #
    $SIG{'USR1'} = sub {
        $self->{_queue} = [];
        $self->_sync;
    };

    do {
        my $parent = IO::Socket::UNIX->new(
            Peer => Notify::Config->get('socket'),
            Type => SOCK_STREAM)
            or die "Could not contact server via socket "
                . Notify::Config->get('socket');

        # Let the parent know we are ready to send.
        my $message = Notify::Message->new(Notify::Message->CMD_READY);
        print $parent $message->encode;

        # Wait for response.
        if(my $message = Notify::Message->from_handle($parent)) {
            if($message->command eq $message->CMD_DISPATCH) {
                foreach my $n (@{$message->body}) {
                    push @{$self->{_queue}}, $n;
                }
            }
        }

        # Close connection to parent.
        $parent->close;
        $self->_sync;

        if(@{$self->{_queue}} > 0) {
            #
            # Send any queued messages before sleeping.
            #
            my @failed;
            my $status;
            while(my $notification = pop @{$self->{_queue}}) {
                eval {
                    $status = $notification->send;
                };

                if($@ || !$status) {
                    Notify::Logger->err($@);
                    push @failed, $notification;
                }
            }

            $self->{_queue} = \@failed;
            $self->_sync;
        }

        #
        # Sleep for the configured time if there are no expected
        # notifications.
        #
        sleep(Notify::Config->get('sending_interval'));

    } while(1); # Never return.
}

sub _sync {
    my $self = shift;
    return if not defined $self->{_storage};

    $self->{_storage}->store($self->{_queue});
}

sub _load {
    my $self = shift;
    return if not defined $self->{_storage};

    $self->{_queue} = $self->{_storage}->retrieve;
    if(!$self->{_queue} or ref($self->{_queue}) ne 'ARRAY') {
        $self->{_storage}->store([]);
        $self->{_queue} = [];
    }
}

1;
