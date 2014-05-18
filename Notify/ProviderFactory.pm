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


package Notify::ProviderFactory;

use strict;
use warnings;
use Notify::Config;
use Module::Load;

use constant {
    SMS_NAMESPACE   => 'Notify::SMS::',
    EMAIL_NAMESPACE => 'Notify::Email::',
};

sub get_providers {
    my ($class, $namespace, $active) = @_;
    my $providers = Notify::Config->get('providers');
    my $active_providers = [];
    my $provider;

    foreach my $active_provider (@{$active}) {
        #
        # Try to automatically construct the class name if
        # not explicitly specified, then load it.
        #
        my $classname = (defined $providers->{$active_provider}->{class} ?
            $providers->{$active_provider}->{class} :
            $namespace . $active_provider);
        load $classname;

        eval {
            $provider = $classname->new($providers->{$active_provider});
        };

        push @{$active_providers}, $provider if defined $provider;
    }

    return $active_providers;
}

sub get_sms_providers {
    shift->get_providers(
        SMS_NAMESPACE,
        Notify::Config->get('active_sms_providers'));
}

sub get_email_providers {
    shift->get_providers(
        EMAIL_NAMESPACE,
        Notify::Config->get('active_email_providers'));
}

1;
