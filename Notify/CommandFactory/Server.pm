#!/usr/bin/perl
#
# Copyright (C) 2016  Mikey Austin <mikey@jackiemclean.net>
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


package Notify::CommandFactory::Server;

use strict;
use warnings;
use parent qw(Notify::CommandFactory);

use Module::Load qw(load);

sub new {
    my ($class, $server) = @_;
    my $self = $class->SUPER::new;

    $self->{_server} = $server,

    return $self;
}

sub create {
    my ($self, $type) = @_;

    my $namespace = 'Notify::Command::Server::';
    my $class;
    if($type eq Notify::Message->CMD_AUTH_FAILURE) {
        $class = 'AuthFailure';
    }
    elsif($type eq Notify::Message->CMD_READY) {
        $class = 'Ready';
    }
    elsif($type eq Notify::Message->CMD_NOTIF) {
        $class = 'Enqueue';
    }
    elsif($type eq Notify::Message->CMD_EMPTY_QUEUE) {
        $class = 'EmptyQueue';
    }
    elsif($type eq Notify::Message->CMD_STATUS) {
        $class = 'Status';
    }
    elsif($type eq Notify::Message->CMD_DISABLE_NOTIF) {
        $class = 'DisableNotifications';
    }
    elsif($type eq Notify::Message->CMD_ENABLE_NOTIF) {
        $class = 'EnableNotifications';
    }
    elsif($type eq Notify::Message->CMD_SUSPEND) {
        $class = 'Suspend';
    }
    elsif($type eq Notify::Message->CMD_LIST) {
        $class = 'ListQueued';
    }
    elsif($type eq Notify::Message->CMD_REMOVE) {
        $class = 'Remove';
    }
    else {
        return $self->SUPER::create($type);
    }

    my $abs_class = "${namespace}${class}";
    load($abs_class);

    return $abs_class->new($type, $self->{_server});
}

1;
