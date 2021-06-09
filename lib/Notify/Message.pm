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

# Hold key instance in memory.
my $message_key = undef;

sub new {
    my ($class, $type, $factory) = @_;
    my $self = {
        _type    => $type,
        _command => $factory ? $factory->create($type) : undef,
        _error   => 0,
        _body    => undef,
    };
    bless $self, $class;

    if(defined $self->{_command}) {
        $self->{_command}->message($self);
    }

    # Set some getter/setters directly in symbol table.
    foreach my $var (qw/type command error body/) {
        no strict 'refs';
        *{"$class::$var"} = sub {
            my ($self, $arg) = @_;
            $self->{"_$var"} = $arg if defined $arg;
            return $self->{"_$var"};
        } if not defined *{"$class::$var"}{CODE};
    }

    return $self;
}

sub get_key {
    my $self = shift;

    if(not defined $message_key) {
        my $key_data = undef;
        my $key_handle = IO::File->new(
            Notify::Config->get('key_path'), 'r');

        if(defined $key_handle) {
            $key_data = <$key_handle>;
        }
        else {
            die 'no key found at specified path';
        }

        $message_key = sha1_hex($key_data, 'sha256');
    }

    return $message_key;
}

sub generate_hmac {
    my ($self, $message) = @_;

    my $hmac = Digest::HMAC->new($self->get_key, 'Digest::SHA');
    $hmac->add($message);

    return $hmac->hexdigest;
}

sub encode {
    my $self = shift;
    my $json = JSON->new->convert_blessed(1)->encode($self);

    return $json . "|" . $self->generate_hmac($json) . "\n";
}

sub from_handle {
    my ($class, $handle, $factory) = @_;
    my $message = undef;

    if(defined (my $buf = <$handle>)) {
        chomp $buf;
        eval {
            $message = $class->parse($buf, $factory);
        };

        Notify::Logger->err($@) if $@;
    }

    return $message;
}

#
# Class subroutine to parse a JSON-encoded string and
# return a Message object.
#
sub parse {
    my ($class, $encoded, $factory) = @_;

    # Remove carriage returns.
    $encoded =~ s/\r//g;
    my ($json, $received_hmac) = split(/\|/, $encoded, 2);

    my $digest = $class->generate_hmac($json);
    if(not defined $received_hmac or $digest ne $received_hmac) {
        return $class->new($class->CMD_AUTH_FAILURE, $factory);
    }

    my $decoded = JSON->new->decode($json);
    my $message = $class->new($decoded->{command}, $factory);
    $message->error($decoded->{error});

    if($message->{_type} eq $class->CMD_NOTIF) {
        $message->{_body} =
            Notify::Notification->create_from_decoded_json(
                $decoded->{body});
    }
    elsif($message->{_type} eq $class->CMD_DISPATCH) {
        $message->{_body} = [];
        foreach my $decoded_notification (@{$decoded->{body}}) {
            push @{$message->{_body}},
            Notify::Notification->create_from_decoded_json(
                $decoded_notification);
        }
    }
    else {
        $message->body($decoded->{body});
    }

    return $message;
}

sub TO_JSON {
    my $self = shift;
    my $output = {
        command => $self->type,
        error   => $self->error,
        body    => $self->body,
    };

    return $output;
}

1;
