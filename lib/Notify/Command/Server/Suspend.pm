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

package Notify::Command::Server::Suspend;

use strict;
use warnings;
use parent qw(Notify::Command::Server);

sub execute {
    my $self = shift;

    my $response;
    if($self->server->is_suspended) {
        $response = $self->server->new_message(
            Notify::Message->CMD_RESPONSE,
            'ERR: Already suspended');
        $response->error(1);
    }
    elsif($self->message->body =~ /^[1-9](\d{1,2})?$/) {
        Notify::Logger->write('Notifications Suspended');
        Notify::Config->set('enabled', 0);

        my $min = $self->message->body;
        $response = $self->server->new_message(
            Notify::Message->CMD_RESPONSE,
            "OK: notifications suspended for $min minutes");

        # Start the suspend process.
        $self->server->start_suspend($min);
    }
    else {
        $response = $self->server->new_message(
            Notify::Message->CMD_RESPONSE,
            'ERR: Invalid suspend time');
        $response->error(1);
    }

    return $response;
}

1;
