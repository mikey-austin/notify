#!/usr/bin/perl
#
# notify 0.2.0
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


package Notify::Queue;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = {
        _notifications => {}
    };

    bless $self, $class;
}

sub get_size {
    my $self = shift;
    my $size = 0;

    foreach my $id (keys %{$self->{_notifications}}) {
        $size += @{$self->{_notifications}->{$id}};
    }

    return $size;
}

sub enqueue {
    my ($self, $notification) = @_;
    my $id = $notification->get_recipient->get_id;

    # A queue per recipient.
    push @{$self->{_notifications}->{$id}}, $notification;
}

# Return an array of popped notifications from each recipient queue.
sub dequeue {
    my $self = shift;
    my @popped;

    foreach my $id (keys %{$self->{_notifications}}) {
        my $n = pop @{$self->{_notifications}->{$id}};
        push @popped, $n if defined $n;
    }

    return \@popped;
}

sub empty {
    my $self = shift;
    $self->{_notifications} = {};
}

1;
