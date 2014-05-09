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


package Notify::Client;

use strict;
use warnings;
use Notify::Config;
use Notify::Message;
use IO::Socket::UNIX;
use Notify::Logger;
use Notify::RecipientFactory;

use constant {
    DEFAULTS => [
        'notify.conf',
        'notify.yaml',
        $ENV{'HOME'} . '/.notify.conf',
        $ENV{'HOME'} . '/.notify.yaml',
        '/etc/notify/notify.conf',
        '/etc/notify/notify.yaml',
        ]
};

sub new {
    my ($class, $options, $console) = @_;

    # By default, assume we are on a console and print to stdout.
    $console ||= 1;

    my $self = {
        _options => {},
        _console => $console,
    };

    bless $self, $class;
    $self->set_options($options);

    return $self;
}

sub set_options {
    my ($self, $options) = @_;

    # Initialise configuration.
    Notify::Config->reload($options->{config}, $self->DEFAULTS);

    # Set a default socket if not specified.
    $self->{_options}->{socket} =
        $options->{socket} || Notify::Config->get('socket_path');

    $self->{_options}->{$_} = $options->{$_}
        for qw(label body subject minutes);
}

#
# Execute the specified command.
#
sub execute {
    my ($self, $command) = @_;
    my $res = undef;

    die "No command given\n" if not defined $command;

    for($command) {
        /queue/     and do { $res = $self->queue; last; };
        /stat(us)?/ and do { $res = $self->get_status; last; };
        /enabled?/  and do { $res = $self->enable_notifications; last; };
        /disabled?/ and do { $res = $self->disable_notifications; last; };
        /empty/     and do { $res = $self->empty_queue; last; };
        /suspend/   and do { $res = $self->suspend_notifications; last; };

        die "Unknown command $_\n";
    }

    return $self->output($res);
}

sub queue {
    my $self = shift;

    my $label   = $self->{_options}->{label};
    my $body    = $self->{_options}->{body};
    my $subject = $self->{_options}->{subject};

    die "A recipient label must be specified with the --label option\n"
        if not defined $label;
    die "A notification body must be specified with the --body option\n"
        if not defined $body;
    die "A subject must be specified with the --subject option\n"
        if not defined $subject;

    my $recipient = Notify::RecipientFactory::create($label);
    my $notification = Notify::Notification->new(
        $recipient, $body, $subject);

    my $message = Notify::Message->new(Notify::Message->CMD_NOTIF);
    $message->{_body} = $notification;

    return $self->send($message);
}

sub empty_queue {
    my $self = shift;
    my $message = Notify::Message->new(Notify::Message->CMD_EMPTY_QUEUE);

    return $self->send($message);
}

sub enable_notifications {
    my $self = shift;
    $self->disable_notifications(1);
}

sub disable_notifications {
    my ($self, $enable) = @_;

    my $message = Notify::Message->new(
        (defined $enable ? Notify::Message->CMD_ENABLE_NOTIF
         : Notify::Message->CMD_DISABLE_NOTIF)
        );

    return $self->send($message);
}

sub suspend_notifications {
    my $self = shift;

    die "Suspend requires the --minutes options\n"
        if not defined $self->{_options}->{minutes};
    die "The --minutes option must be a non-zero integer\n"
        if $self->{_options}->{minutes} !~ /^[1-9](\d{1,2})?$/;

    my $message = Notify::Message->new(
        Notify::Message->CMD_SUSPEND);
    $message->{_body} = $self->{_options}->{minutes};

    return $self->send($message);
}

sub get_status {
    my $self = shift;
    my $message = Notify::Message->new(Notify::Message->CMD_STATUS);

    return $self->send($message);
}

#
# Send off a message to the server, and return the response
# message.
#
sub send {
    my ($self, $message) = @_;
    my $server = IO::Socket::UNIX->new(
        Peer => $self->{_options}->{socket},
        Type => SOCK_STREAM)
        or die 'Could not contact server on ' . $self->{_options}->{socket} . "\n";

    # Send message off.
    print $server $message->encode;

    # Every message gets a response.
    my $response = Notify::Message->from_handle($server);
    $server->close;

    return $response;
}

#
# Output a response based on the context of this client.
#
sub output {
    my ($self, $response) = @_;

    if($self->{_console}) {
        if(ref $response->body eq 'HASH') {
            # Response should be key/value pairs.
            foreach my $key (keys %{$response->body}) {
                print "$key: " . $response->body->{$key} . "\n";
            }
        } else {
            print $response->body, "\n";
        }
    } else {
        # Just pass through the response object.
        return $response;
    }
}

1;
