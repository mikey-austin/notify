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


use Test::Simple tests => 8;
use Notify::Config;
use Notify::ProviderFactory;

# Use the test configuration.
Notify::Config->new('t/config/providers.yaml');

$active = Notify::ProviderFactory->get_email_providers;
ok(@{$active} == 2);
ok(ref $active->[0] eq 'Notify::Email::ProviderEmail');
ok(ref $active->[1] eq 'Notify::Email::ProviderEmail');
ok($active->[0]->{host} eq 'host1');
ok($active->[1]->{host} eq 'host3');

$active = Notify::ProviderFactory->get_sms_providers;
ok(@{$active} == 1);
ok($active->[0]->{host} eq 'host2');
ok(ref $active->[0] eq 'Notify::SMS::ProviderEsendex');
