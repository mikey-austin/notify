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


use Test::Simple tests => 9;
use Notify::Config;

# Test the recursive loading with an included directory.
$c = Notify::Config->load_config('t/config/config1.yaml');

# This shouldn't change.
ok($c->{enabled} == 1);

# This is overridden in the included file.
ok($c->{sending_interval} eq "10");

# There should be 2 providers, with the provider in
# config1.yaml intact.
@keys = keys %{$c->{providers}};
ok(@keys == 2);

# Test the providers.
ok($c->{providers}->{TestProvider}->{username}
   eq 'test2@example.com');
ok($c->{providers}->{ProviderEsendex}->{username}
   eq 'test@example.com');

# Test explicitly including another file.
$c = Notify::Config->load_config('t/config/config2.yaml');

ok($c->{active_provider} eq 'TestProvider');

# Test the providers.
@keys = keys %{$c->{providers}};
ok(@keys == 2);

ok($c->{providers}->{TestProvider}->{username}
   eq 'test2@example.com');
ok($c->{providers}->{ProviderEsendex}->{username}
   eq 'test@example.com');
