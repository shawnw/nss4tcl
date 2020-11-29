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

### nss::sethostent stayopen

Opens or rewinds the connection. See `sethostent(3)`.

### nss::endhostent

See `endhostent(3)`

### nss::gethostent

Returns the next host, or an empty dictionary if there are no
more. See `gethostent(3)`.

### nss::hosts

Returns a generator that enumerates all hosts as returned by
`gethostent`.

Services
--------

An interface to the services database (`/etc/services`).

Commands that return values return a dict with the following fields:

* name - The official service name.
* aliases - List of alias names.
* port - The port number of the service.
* protocol - The protocol used for the service.

### nss::setservent stayopen

See `setservent(3)`.

### nss::endservent

See `endservent(3)`

### nss::getservent

Returns the next service, or an empty dictionary if there are no
more. See `getservent(3)`.

### nss::getservbyname name ?proto?

See `getservbyname(3)`

### nss::getservbyport port ?proto?

See `getservbyport(3)`

### nss::services

Returns a generator that enumerates all services as returned by
`nss::getservent`.

Protocols
---------

An interface to the protocol database (`/etc/protocols`).

Commands that return values return a dict with the following fields:

* name - The official protocol name.
* aliases - List of alias names.
* proto - The protocol number

### nss::setprotoent stayopen

See `setprotoent(3)`

### nss::endprotoent

See `endprotoent(3)`

### nss::getprotoent

See `getprotoent(3)`

### nss::getprotobyname name

See `getprotobyname(3)`

### nss::getprotobynumber

See `getprotobynumer(3)`

### nss:protocols

Returns a generator that enumerates all protocols as returned by
`nss::getprotoent`.

Networks
--------

An interface to the network database (`/etc/networks`).

Commands that return values return a dict with the following fields:

* name - The official protocol name.
* aliases - List of alias names.
* addrtype - (Integer) address type
* net - (Integer) network number

### nss::setnetent stayopen

See `setnetent(3)`

### nss::endnetent

See `endnetent(3)`

### nss::getnetent

See `getnetent(3)`

### nss::getnetbyname name

See `getnetbyname(3)`

### nss:networks

Returns a generator that enumerates all protocols as returned by
`nss::getnetent`.

Users
-----

An interface to the users database (`/etc/passwd`).

Commands that return values return a dict with the following fields:

* name - Username
* password - Password
* uid - (Integer) user ID
* gid - (Grouop) group ID
* gecos - User information
* dir - Home directory
* shell - User's shell

### setpwent

See `setpwent(3)`

### endpwent

See `endpwent(3)`

### getpwent

See `getpwent(3)`

### getpwbyname username

Look up a user by name. See `getpwnam(3)`

### getpwbyuid uid

Look up a user by uid. See `getpwuid(3)`

### users

Returns a generator that enumerates all users as returned by
`nss::getpwent`.
