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


package Notify::Message;

use strict;
use warnings;
use JSON;
use Notify::Notification;

use constant {
    CMD_READY         => 'READY',
    CMD_NOTIF         => 'NOTIFICATION',
    CMD_EMPTY_QUEUE   => 'EMPTY_QUEUE',
    CMD_STATUS        => 'STATUS',
    CMD_DISABLE_NOTIF => 'DISABLE_NOTIFICATIONS',
    CMD_ENABLE_NOTIF  => 'ENABLE_NOTIFICATIONS',
    CMD_DISPATCH      => 'DISPATCH',
    CMD_RESPONSE      => 'RESPONSE',
    CMD_SUSPEND       => 'SUSPEND',
};

sub new {
    my ($class, $command) = @_;
    my $self = {
        _command => $command,
        _error   => 0,
        _body    => undef,
    };

    bless $self, $class;
}

sub command {
    shift->{_command};
}

sub body {
    shift->{_body};
}

sub encode {
    my $self = shift;
    return JSON->new->convert_blessed(1)->encode($self) . "\n";
}

sub from_handle {
    my ($class, $handle) = @_;
    my $message = undef;

    if(defined (my $buf = <$handle>)) {
        chomp $buf;
        eval {
            $message = $class->parse($buf);
        };
    }

    return $message;
}

#
# Class subroutine to parse a JSON-encoded string and
# return a Message object.
#
sub parse {
    my ($class, $json) = @_;
    my $decoded = JSON->new->decode($json);

    my $message = $class->new($decoded->{command});
    $message->{_error} = $decoded->{error};

    if($message->command eq $class->CMD_NOTIF) {
        $message->{_body} =
            Notify::Notification->create_from_decoded_json($decoded->{body});
    } elsif($message->command eq $class->CMD_DISPATCH) {
        $message->{_body} = [];
        foreach my $decoded_notification (@{$decoded->{body}}) {
            push @{$message->{_body}},
            Notify::Notification->create_from_decoded_json(
                $decoded_notification);
        }
    } else {
        $message->{_body} = $decoded->{body};
    }

    return $message;
}

sub TO_JSON {
    my $self = shift;
    my $output = {
        command => $self->{_command},
        error   => $self->{_error},
        body    => $self->{_body},
    };

    return $output;
}

1;
