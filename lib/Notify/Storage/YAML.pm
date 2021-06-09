
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


package Notify::Storage::YAML;

use strict;
use warnings;

use Notify::Config;
use YAML qw/DumpFile LoadFile/;
use parent qw/Notify::Storage/;

sub new {
    my ($class, $type, $options) = @_;
    my $self = $class->SUPER::new($type, $options);

    # Validate the base option, which should exist.
    die 'No base directory for YAML storage specified'
        if not defined $options->{base};

    die "$options->{base} does not exist"
        if not -d $options->{base};

    return $self;
}

sub store {
    my ($self, $to_store) = @_;
    DumpFile($self->_get_path, $to_store);
}

sub retrieve {
    my $self = shift;
    my $loaded = undef;

    eval {
        $loaded = LoadFile($self->_get_path);
    };

    if(not $loaded) {
        Notify::Logger->err(
            "Could not load YAML @{[$self->_get_path]}");
    }

    return $loaded;
}

sub _get_path {
    my $self = shift;
    $self->{_options}->{base} =~ s|/$||g;
    return "$self->{_options}->{base}/$self->{_type}.yaml";
}

1;
