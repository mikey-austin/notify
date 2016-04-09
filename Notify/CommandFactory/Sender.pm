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


package Notify::CommandFactory::Sender;

use strict;
use warnings;
use parent qw(Notify::CommandFactory);

use Module::Load qw(load);

sub new {
    my ($class, $sender) = @_;
    my $self = $class->SUPER::new;

    $self->{_sender} = $sender,

    return $self;
}

sub create {
    my ($self, $type) = @_;

    my $namespace = 'Notify::Command::Sender::';
    my $class;
    if($type eq Notify::Message->CMD_DISPATCH) {
        $class = 'Dispatch';
    }

    my $abs_class = "${namespace}${class}";
    load($abs_class);

    return $abs_class->new($type, $self->{_sender});
}

1;
