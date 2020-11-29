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
