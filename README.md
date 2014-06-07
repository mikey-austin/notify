notify - notification throttling daemon
=======================================

Have you ever wanted to:
------------------------

* Rate-limit the sending of SMSes and/or emails from monitoring
  systems (eg nagios)?

* Have the ability to specify multiple SMS gateway providers
  and/or outgoing mail servers for redundancy?

* Have a clean & flexible interface to allow various administration
  functions related to notification sending such as:
  - disable/enable notification sending
  - the emptying of queued notifications
  - the suspending of notifications for a specified number of minutes
    (ie automatically re-enabling notification sending after 30 minutes)
  - obtaining the notification server status

If so, notify aims to provide all of the above. It consists of a server part
and a client part, with communication occuring over a UNIX-domain socket.

Overview
--------

On server startup, a dedicated "sender" process is forked with the sole purpose of:

1.  Requesting notifications from the server to dispatch (to unique recipients)
    via the configured providers.
2.  Sleeping for a configured number of seconds after sending any notifications.

Meanwhile, the server (notify) polls the socket, listening for any new messages to queue,
control commands to service, and requested messages to dispatch (popped off the queue).

In a nutshell, the client program (notifyctl) may queue as many notifications as the server
can accept, while the server periodically sends the notifications, say every minute,
essentially rate-limiting the sending.

The original motivation for this was driven by our two nagios boxes each dumping 30 SMSes
to 3 sysadmins in one swoop (worst case of course), with no quick way to clear/stop dispatched
messages. This situation starts to cost $$, and really freaks you out at 3am.

Usage
-----

The server can be started as below (when not run from an init script):

    $ notify --config sample.conf --socket /tmp/test.sock --pidfile /tmp/test.pid

and similarly for the client:

    $ notifyctl enable --socket /tmp/test.sock
    OK: notifications enabled
  
    $ notifyctl queue --socket /tmp/test.sock --recipient 61411221234 --subject "alert!" --body "alert alert"
    OK: 1 queued

Implementation Details
----------------------

Communication over the socket happens via JSON-encoded "messages", encapsulated in the Notify::Message
class.

The configuration file syntax is in YAML, see the example configuration file for details.

Dependencies
------------

To run notify you will need to install the following CPAN modules:

- YAML::XS
- JSON
- Module::Load

SMS Gateway Providers
---------------------

Currently there are two reference provider implementations for email and SMS dispatch. The SMS gateway
implemented is that of Esendex (no affiliation). To implement another SMS provider, you can:

1.  Implement a package extending the Notify::Provider class, in the Notify::SMS namespace (eg Notify::SMS::NewProvider)
2.  Implement the *send* method according to the provider's specifics
3.  Add the configuration to notify's configuration file
4.  Finally add the provider name to the list of active SMS providers to use