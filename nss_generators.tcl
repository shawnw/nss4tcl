# The MIT License (MIT)
# Copyright © 2020 Shawn Wagner

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# “Software”), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

package require generator

namespace eval nss {
    variable version 0.9
    namespace export {[a-z]*}
}

generator define ::nss::hosts {} {
    generator finally ::nss::endhostent
    ::nss::sethostent 1
    while {[dict size [set host [::nss::gethostent]]] > 0} {
        generator yield $host
    }
}

generator define ::nss::services {} {
    generator finally ::nss::endservent
    ::nss::setservent 1
    while {[dict size [set service [::nss::getservent]]] > 0} {
        generator yield $service
    }
}

generator define ::nss::protocols {} {
    generator finally ::nss::endprotoent
    ::nss::setprotoent 1
    while {[dict size [set proto [::nss::getprotoent]]] > 0} {
        generator yield $proto
    }
}

generator define ::nss::networks {} {
    generator finally ::nss::endnetent
    ::nss::setnetent 1
    while {[dict size [set net [::nss::getnetent]]] > 0} {
        generator yield $net
    }
}

generator define ::nss::users {} {
    generator finally ::nss::endpwent
    ::nss::setpwent
    while {[dict size [set pw [::nss::getpwent]]] > 0} {
        generator yield $pw
    }
}

generator define ::nss::groups {} {
    generator finally ::nss::endgrent
    ::nss::setgrent
    while {[dict size [set group [::nss::getgrent]]] > 0} {
        generator yield $group
    }
}

# Conversion routines inspired by TclX

namespace eval nss::convert {
    namespace export {[a-z]*}
    namespace ensemble create
}

proc nss::convert::userid {uid} {
    try {
        set user [nss::getpwbyuid $uid]
        return [dict get $user name]
    } on error {_} {
        error "unknown user id: $uid"
    }
}

proc nss::convert::user {name} {
    try {
        set user [nss::getpwbyname $name]
        return [dict get $user uid]
    } on error {_} {
        error "unknown user name: $name"
    }
}

proc nss::convert::groupid {gid} {
    try {
        set group [nss::getgrbygid $gid]
        return [dict get $group name]
    } on error {_} {
        error "unknown group id: $gid"
    }
}

proc nss::convert::group {name} {
    try {
        set group [nss::getgrbyname $name]
        return [dict get $group gid]
    } on error {_} {
        error "unknown group name: $name"
    }
}

proc nss::convert::service args {
    set len [llength $args]
    if {$len == 0 || $len > 2} {
        error "Wrong number of arguments to nss::convert service"
    }
    try {
        set service [nss::getservbyname {*}$args]
        return [dict get $service port]
    } on error {_} {
        error "unknown service name: [lindex $args 0]"
    }
}

proc nss::convert::port args {
    set len [llength $args]
    if {$len == 0 || $len > 2} {
        error "Wrong number of arguments to nss::convert port"
    }
    try {
        set service [nss::getservbyport {*}$args]
        return [dict get $service name]
    } on error {_} {
        error "unknown service port: [lindex $args 0]"
    }
}
