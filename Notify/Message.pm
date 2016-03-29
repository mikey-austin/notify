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


package Notify::Message;

use strict;
use warnings;
use IO::File;
use JSON;
use Digest::HMAC;
use Digest::SHA qw(sha1_hex);
use Notify::Notification;
use Notify::Config;

use constant {
    CMD_AUTH_FAILURE  => 'AUTHENTICATION_FAILURE',
    CMD_READY         => 'READY',
    CMD_NOTIF         => 'NOTIFICATION',
    CMD_EMPTY_QUEUE   => 'EMPTY_QUEUE',
    CMD_STATUS        => 'STATUS',
    CMD_DISABLE_NOTIF => 'DISABLE_NOTIFICATIONS',
    CMD_ENABLE_NOTIF  => 'ENABLE_NOTIFICATIONS',
    CMD_DISPATCH      => 'DISPATCH',
    CMD_RESPONSE      => 'RESPONSE',
    CMD_SUSPEND       => 'SUSPEND',
    CMD_LIST          => 'LIST',
    CMD_REMOVE        => 'REMOVE',
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
    my ($self, $command) = @_;

    if(defined $command) {
        $self->{_command} = $command;
    }
    else {
        return $self->{_command};
    }
}

sub body {
    my ($self, $body) = @_;

    if(defined $body) {
        $self->{_body} = $body;
    }
    else {
        return $self->{_body};
    }
}

sub generate_hmac {
    my ($self, $message) = @_;

    my $key_data = undef;
    my $key_handle = IO::File->new(Notify::Config->get('key_path'), 'r');
    if(defined $key_handle) {
        $key_data = <$key_handle>;
    }
    else {
        die 'no key found at specified path';
    }

    my $key = sha1_hex($key_data, 'sha256');
    my $hmac = Digest::HMAC->new($key, 'Digest::SHA');
    $hmac->add($message);

    return $hmac->digest;
}

sub encode {
    my $self = shift;
    my $json = JSON->new->convert_blessed(1)->encode($self);

    return $json . "\t" . $self->generate_hmac($json) . "\n";
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
    my ($class, $encoded) = @_;
    my ($json, $recieved_hmac) = split("\t", $encoded, 2);

    my $digest = $class->generate_hmac($json);
    if($digest ne $recieved_hmac) {
        return $class->new(CMD_AUTH_FAILURE);
    }

    my $decoded = JSON->new->decode($json);

    my $message = $class->new($decoded->{command});
    $message->{_error} = $decoded->{error};

    if($message->command eq $class->CMD_NOTIF) {
        $message->{_body} =
            Notify::Notification->create_from_decoded_json($decoded->{body});
    }
    elsif($message->command eq $class->CMD_DISPATCH) {
        $message->{_body} = [];
        foreach my $decoded_notification (@{$decoded->{body}}) {
            push @{$message->{_body}},
            Notify::Notification->create_from_decoded_json(
                $decoded_notification);
        }
    }
    else {
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
