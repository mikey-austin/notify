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


package Notify::Server;

use strict;
use warnings;
use Notify::Config;
use Notify::Message;
use Notify::Queue;
use Notify::Logger;
use Notify::Sender;
use Notify::Suspend;
use IO::Socket::UNIX;
use IO::Select;
use IO::Handle;
use POSIX ();

use constant {
    DEFAULTS => [
        '/etc/notify/notify.conf',
        '/etc/notify/notify.yaml',
        ]
};

sub new {
    my ($class, $options) = @_;
    my $self = {
        _queue       => Notify::Queue->new,
        _sender_pid  => undef,
        _suspend_pid => undef,
        _pid         => undef,
        _options     => {},
    };

    # Load the configuration.
    Notify::Config->new($options->{config}, $class->DEFAULTS);

    # Print the configuration file being used.
    Notify::Logger->info('Loading configuration from '
        . Notify::Config->new->{_file});

    $self->{_options}->{socket} =
        $options->{socket} || Notify::Config->get('socket_path');
    Notify::Config->set('socket_path', $self->{_options}->{socket});

    $self->{_options}->{pidfile} =
        $options->{pidfile} || Notify::Config->get('pidfile');
    Notify::Config->set('pidfile', $self->{_options}->{pidfile});

    # Set remaining options.
    $self->{_options}->{$_} = $options->{$_} for qw|daemonize user group config|;

    bless $self, $class;
}

sub start {
    my $self = shift;
    my $select = IO::Select->new();

    # If socket already exists, exit.
    die Notify::Logger->err('Socket exists, exiting...')
        if -e Notify::Config->get('socket_path');

    die Notify::Logger->err('PID file exists, exiting...')
        if -e Notify::Config->get('pidfile');

    if($self->{_options}->{daemonize}) {
        $self->daemonize;
    }

    $self->save_pid;

    # Start the sender process.
    $self->start_sender;

    # Set the various signal handlers after the sender has been forked.
    $self->register_signals;

    my $listen = new IO::Socket::UNIX(
        Listen => 5,
        Type   => SOCK_STREAM,
        Local  => Notify::Config->get('socket_path')
    );
    $select->add($listen);

    Notify::Logger->write("Started notify, listening at "
                          . Notify::Config->get('socket_path'));

    # Start monitoring file descriptors.
    do {
        while(my @ready = $select->can_read) {
            foreach my $handle (@ready) {
                if($handle == $listen) {
                    # There is a connection waiting to be accepted.
                    my $new = $listen->accept;

                    # Now add the accepted file handle to the monitored list.
                    $select->add($new);
                } else {
                    #
                    # This is a connection ready for reading.
                    #
                    my $response;
                    if(my $message = Notify::Message->from_handle($handle)) {
                        if($message->command eq $message->CMD_NOTIF) {
                            $self->{_queue}->enqueue($message->body);

                            $response = $self->new_message(
                                $message->CMD_RESPONSE,
                                'OK: ' . $self->{_queue}->get_size . ' queued');

                            Notify::Logger->write('Queued notification');
                        } elsif($message->command eq $message->CMD_READY) {
                            $response = $self->new_message(
                                $message->CMD_DISPATCH);
                        } elsif($message->command eq $message->CMD_EMPTY_QUEUE) {
                            Notify::Logger->write('Queue Emptied');
                            $self->{_queue}->empty;

                            $response = $self->new_message(
                                $message->CMD_RESPONSE, 'OK: queue emptied');
                        } elsif($message->command eq $message->CMD_ENABLE_NOTIF) {
                            Notify::Logger->write('Notifications Enabled');
                            Notify::Config->set('enabled', 1);

                            $response = $self->new_message(
                                $message->CMD_RESPONSE,
                                'OK: notifications enabled');

                            $self->stop_suspend;
                        } elsif($message->command eq $message->CMD_SUSPEND) {
                            if(defined $self->{_suspend_pid}) {
                                $response = $self->new_message($message->CMD_RESPONSE,
                                                               'ERR: Already suspended');
                                $response->{_error} = 1;
                            } elsif($message->body =~ /^[1-9](\d{1,2})?$/) {
                                Notify::Logger->write('Notifications Suspended');
                                Notify::Config->set('enabled', 0);
                                $response = $self->new_message(
                                    $message->CMD_RESPONSE,
                                    'OK: notifications suspended for ' . $message->body . ' minutes');

                                # Start the suspend process.
                                $self->start_suspend($message->body);
                            } else {
                                $response = $self->new_message($message->CMD_RESPONSE,
                                                               'ERR: Invalid suspend time');
                                $response->{_error} = 1;
                            }
                        } elsif($message->command eq $message->CMD_DISABLE_NOTIF) {
                            Notify::Logger->write('Notifications Disabled');
                            Notify::Config->set('enabled', 0);

                            $response = $self->new_message(
                                $message->CMD_RESPONSE,
                                'OK: notifications disabled');
                        } elsif($message->command eq $message->CMD_STATUS) {
                            $response = $self->new_message(
                                $message->CMD_RESPONSE, $self->server_status);
                        } else {
                            Notify::Logger->err("Could not understand message");
                            $response = $self->new_message(
                                $message->CMD_RESPONSE, 'ERR: invalid message');
                            $response->{_error} = 1;
                        }

                        print $handle $response->encode;
                    }

                    $select->remove($handle);
                    $handle->close;
                }
            }
        }
    } while(1); # Never return.
}

sub new_message {
    my ($self, $command, $response) = @_;
    my $message = Notify::Message->new($command);

    if($command eq $message->CMD_DISPATCH) {
        #
        # Dispatch notifications to sender if notifications
        # are enabled.
        #
        $message->{_body} = (Notify::Config->get('enabled') == 1
                             ? $self->{_queue}->dequeue : []);
    } elsif($command eq $message->CMD_RESPONSE) {
        $message->{_body} = $response;
    }

    return $message;
}

sub server_status {
    my $self = shift;
    my $status = {
        queued          => $self->{_queue}->get_size,
        enabled         => Notify::Config->get('enabled'),
        interval        => Notify::Config->get('sending_interval'),
        sms_providers   => join(', ', @{Notify::Config->get('active_sms_providers')}),
        email_providers => join(', ', @{Notify::Config->get('active_email_providers')}),
    };

    if(defined $self->{_suspend_pid}) {
        $status->{suspended} = 1;
    }

    return $status;
}

sub daemonize {
    my $self = shift;

    # Log to syslog.
    Notify::Config->set('logging_facility', 'syslog');

    # Drop privileges.
    if(defined $self->{_options}->{user}) {
        my $uid = getpwnam($self->{_options}->{user});
        POSIX::setuid($uid)
            or die Notify::Logger->err("Could not setuid to $uid, exiting...", 'err');
    }

    if(defined $self->{_options}->{group}) {
        my $gid = getgrnam($self->{_options}->{group});
        POSIX::setgid($gid)
            or die Notify::Logger->err("Could not setgid to $gid, exiting...", 'err');
    }

    # Become session leader.
    POSIX::setsid or die Notify::Logger->err("Could not setsid: $!");

    # Fork a child process.
    my $pid = fork();
    if($pid < 0) {
        die Notify::Logger->err("Could not fork: $!");
    } elsif($pid) {
        exit;
    }

    # Change root directory and clear file creation mask.
    chdir('/');
    umask(0);

    # Clear all file descriptors.
    foreach(0 .. (POSIX::sysconf(&POSIX::_SC_OPEN_MAX) || 1024))
    {
        POSIX::close($_);
    }

    open(STDIN, "</dev/null");
    open(STDOUT, ">/dev/null");
    open(STDERR, ">&STDOUT");

    # Store the PID.
    $self->{_pid} = POSIX::getpid;

    Notify::Logger->write('Daemonized with pid ' . $self->{_pid});
}

sub save_pid {
    my $self = shift;

    open(PID, '>' . Notify::Config->get('pidfile'))
        or $self->shutdown and die Notify::Logger->err('Could not open pidfile for writing');
    print PID $$;
    close PID;
}

sub start_sender {
    my $self = shift;
    my $pid;

    if(!($pid = fork())) {
        # In child.
        my $sender_proc = Notify::Sender->new;

        # Start the sleep loop for the sender process.
        $sender_proc->start;
    } elsif($pid < 0) {
        die Notify::Logger->err('Could not fork sender process, exiting...');
    } else {
        $self->{_sender_pid} = $pid;
    }
}

sub start_suspend {
    my ($self, $minutes) = @_;
    my $pid;

    if(!($pid = fork())) {
        # In child.
        my $suspend_proc = Notify::Suspend->new($minutes);

        # Start the suspend process.
        $suspend_proc->start;
    } elsif($pid < 0) {
        die Notify::Logger->err('Could not fork suspend process, exiting...');
    } else {
        $self->{_suspend_pid} = $pid;
    }
}

sub stop_sender {
    my ($self, $sig) = @_;

    # Default to SIGTERM.
    $sig ||= 'TERM';

    Notify::Logger->write(
        'Stopping sender process'
        . (defined $self->{_sender_pid} ? ' ' . $self->{_sender_pid} . '...' : ''));

    kill($sig, $self->{_sender_pid}) if $self->{_sender_pid};
}

sub stop_suspend {
    my $self = shift;

    return if not defined $self->{_suspend_pid};

    Notify::Logger->write(
        'Stopping suspend process ' .  $self->{_suspend_pid} . '...');

    kill('TERM', $self->{_suspend_pid});
}

sub register_signals {
    my $self = shift;

    $SIG{'INT'} = $SIG{'TERM'} = sub {
        $self->shutdown;
        exit;
    };

    #
    # Reload the sender process on HUP.
    #
    $SIG{'HUP'} = sub {
        Notify::Logger->write('Received HUP, reloading configuration...');
        Notify::Config->reload($self->{_options}->{config}, $self->DEFAULTS);

        # Override any options set via command line.
        Notify::Config->set('socket_path', $self->{_options}->{socket});
        Notify::Config->set('pidfile', $self->{_options}->{pidfile});

        # The sender will automatically restart.
        $self->stop_sender('HUP');
    };

    #
    # Handle the deaths of the known child processes.
    #
    $SIG{'CHLD'} = sub {
        my ($child, $exit_status);

        do {
            $child = waitpid(-1, POSIX::WNOHANG);
            $exit_status = POSIX::WEXITSTATUS($?);

            if(defined $self->{_suspend_pid} && $child == $self->{_suspend_pid}) {
                Notify::Logger->write('Suspend process completed, re-enabling notifications...');
                Notify::Config->set('enabled', 1);

                # Unset the pid here as we know it has died for sure.
                $self->{_suspend_pid} = undef;                
            } elsif($child == $self->{_sender_pid}) {
                if($exit_status != 0) {
                    Notify::Logger->err('Sender process died, exiting...');
                    $self->shutdown;
                    exit(1);
                } else {
                    Notify::Logger->err('Sender process restarting...');
                    $self->start_sender;
                }
            }
        } while($child > 0);
    };
}

sub shutdown {
    my $self = shift;

    Notify::Logger->write("Shutting down notify $$...");
    $self->stop_sender;
    $self->stop_suspend;

    # Clean up socket and pidfile.
    unlink(Notify::Config->get('socket_path')) if -e Notify::Config->get('socket_path');
    unlink(Notify::Config->get('pidfile')) if -e Notify::Config->get('pidfile');
}

1;
