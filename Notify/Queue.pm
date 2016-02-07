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

# Runs a subroutine over the notifications in the queue.
sub walk_queue {
    my ($self, $sub) = @_;

    map { $sub->($_) } @{$self->{_notifications}->{$_}}
        for keys %{$self->{_notifications}};
}

# Deletes notifications satisfying the passed subroutine ie subroutine returns true.
sub delete {
    my ($self, $sub) = @_;
    my $counter = 0;
    
    foreach my $id (keys %{$self->{_notifications}}) {
        my @indices;

        for my $i (0 .. $#{$self->{_notifications}->{$id}}) { 
            if($sub->(@{$self->{_notifications}->{$id}}[$i])) { 
                push @indices, $i;
            }
        }
        splice @{$self->{_notifications}->{$id}}, $_, 1
            for @indices;

        $counter += @indices;
    }

    return $counter;
}

sub empty {
    my $self = shift;
    $self->{_notifications} = {};
}

1;
