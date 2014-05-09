#!/usr/bin/perl
#
# notify 0.1.1
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

use strict;
use warnings;
use CGI;

use Notify::Client;

print $cgi->header,
    $cgi->start_html('notify'),
    $cgi->h1('Notifications');

print <<STYLE;
<style type="text/css">
    *        { font-size: 30px; }
.success { color: green; }
.error   { color: red; }
.warning { color: orange; }

select,
    input    { padding: 40px; margin-right: 5px; }

table    { width: 100%; }
tr, td   { padding: 20px; }
</style>
STYLE

my $res = undef;
my $options = { config => '/etc/notify/notify.conf' };
my $client = Notify::Client->new($options);
$client->{_console} = 0;

if($cgi->request_method eq 'POST') {
    print $cgi->h2('Executing command: ' . $cgi->param('command'));
    eval {
        if($cgi->param('minutes')) {
            $options->{minutes} = $cgi->param('minutes');
            $client->set_options($options);
        }

        $res = $client->execute($cgi->param('command'));
        print $res->body;
    };
}

eval {
    $res = $client->execute('status');
};

if($@) {
    print "$@";
} elsif($res) {
    print $cgi->h2(
        'current status: ' . ($res->body->{enabled} ? '<span class="success">ENABLED</span>' : '<span class="error">DISABLED</span>'));

    if($res->body->{suspended}) {
        print $cgi->h2({ -class => 'warning' }, 'Notifications Suspended');
    }

    print $cgi->table({ -border => 2 },
        $cgi->Tr(
            $cgi->th('Active Email Providers'),
            $cgi->td($res->body->{email_providers})
        ),
        $cgi->Tr(
            $cgi->th('Active SMS Providers'),
            $cgi->td($res->body->{sms_providers})
        ),
        $cgi->Tr(
            $cgi->th('Sending Interval'),
            $cgi->td($res->body->{interval})
        ),
        $cgi->Tr(
            $cgi->th('Notifications Queued'),
            $cgi->td($res->body->{queued})
        )
    );
}

print $cgi->h2('Notification Control:');
print <<FORM;
<form method="post">
    <input type="submit" name="command" value="enable" />
    <input type="submit" name="command" value="disable" />
    <input type="submit" name="command" value="empty" />

    <br /><br />
    <b>OR</b>
    <br /><br />

    <select name="minutes">
        <option value="10">10</option>
        <option value="20">20</option>
        <option value="30">30</option>
        <option value="60">60</option>
    </select>
    <input type="submit" name="command" value="suspend" />
</form>
FORM

print $cgi->end_html;
