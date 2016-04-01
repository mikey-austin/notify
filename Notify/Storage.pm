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


package Notify::Storage;

use strict;
use warnings;
use Notify::Config;

sub new {
    my ($class, $type, $options) = @_;
    my $self = {
        _type    => $type || 'default',
        _options => $options || {}
    };

    bless $self, $class;

    # Set some getter/setters directly in symbol table.
    foreach my $var (qw/type options/) {
        no strict 'refs';
        *$var = sub {
            my ($self, $arg) = @_;
            $self->{"_$var"} = $arg if defined $arg;
            return $self->{"_$var"};
        };
    }

    return $self;
}

sub store {
    # Implemented in subclasses.
}

sub retrieve {
    # Implemented in subclasses.
}

1;
