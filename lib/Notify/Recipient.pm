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


package Notify::Recipient;

use strict;
use warnings;
use Digest::MD5 qw(md5);

sub new {
    my ($class, $label) = @_;
    my $self = {
        _label => $label
    };
    bless $self, $class;
}

sub get_id {
    my $self = shift;
    return md5($self->{_label});
}

sub get_label {
    my $self = shift;
    return $self->{_label};
}

sub send {
    my ($self, $body, $subject) = @_;
    my $sent = 0;

    #
    # Try each active provider in sequence until the
    # notification is successfully sent.
    #
    foreach my $provider (@{$self->get_providers}) {
        eval {
            $sent = $provider->send($self->{_label}, $body, $subject);
        };

        if($@ || !$sent) {
            $provider->err("sending failed, giving up on provider");
        }
        elsif($sent) {
            last;
        }
    }

    if(!$sent) {
        # All active providers have failed.
        Notify::Logger->err('Failed to send notification to '
                            . $self->{_label});
    }

    return $sent;
}

sub TO_JSON {
    my $self = shift;
    my $output = {
        label => $self->{_label}
    };

    return $output;
}

#
# To be implemented in the recipient sub-classes.
#
sub get_providers {
    return [];
}

1;
