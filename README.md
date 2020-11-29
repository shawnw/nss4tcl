TCL bindings to Unix NSS databases.
===================================

Interfaces to /etc/passwd, /etc/services, etc. or their alternatives.

Dependencies
------------

critcl, a POSIXish system.

Package
=======

    package require nss

None of these commands are re-enttrant. Using the same family in
multiple threads at once, or, say, `getpwbyname` when a password
generator is active, will cause unpredictable results.

Hosts
-----

An interface to the host database.

Commands that return values return a dict with the following fields:

* name - official name of the host.
* aliases - List of alias names.
* addrtype - Integer - host address type.
* addresses - List of addresses.

#### nss::sethostent stayopen

Opens or rewinds the connection. See `sethostent(3)`.

#### nss::endhostent

See `endhostent(3)`

#### nss::gethostent

Returns the next host, or an empty dictionary if there are no
more. See `gethostent(3)`.

#### nss::hosts

A generator that returns all hosts returned by `gethostent`.

Services
--------

An interface to the services database (`/etc/services`).

Commands that return values return a dict with the following fields:

* name - The official service name.
* aliases - List of alias names.
* port - The port number of the service.
* protocol - The protocol used for the service.
