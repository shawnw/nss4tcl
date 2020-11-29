package require Tcl 8.6
package require critcl
package require generator

critcl::tcl 8.6
critcl::license {Shawn Wagner} {MIT license}
critcl::summary {Tcl bindings to NSS databases}
critcl::description {Access /etc/passwd, /etc/services, etc.}

if {![critcl::compiling]} {
    error "This extension cannot be compiled without critcl enabled."
}

critcl::ccode {
    #include <sys/types.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <pwd.h>
    #include <grp.h>
}

namespace eval nss {
    variable version 0.1
    namespace export {[a-z]*}
}

critcl::ccode {
    static int make_string_list(Tcl_Interp *interp, Tcl_Obj **res, char **elems) {
        *res = Tcl_NewListObj(0, NULL);
        Tcl_IncrRefCount(*res);
        for (int i = 0; elems[i]; i +=1 ) {
            if (Tcl_ListObjAppendElement(interp, *res,
                                         Tcl_NewStringObj(elems[i], -1)) != TCL_OK) {
               Tcl_DecrRefCount(*res);
               return TCL_ERROR;
            }
        }
        return TCL_OK;
    }

    static int make_servent_dict(Tcl_Interp *interp, Tcl_Obj **dict,
                                 struct servent *ent) {
        *dict = Tcl_NewDictObj();
        Tcl_IncrRefCount(*dict);

        if (!ent) {
            return TCL_OK;
        }

        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("name", -1),
                               Tcl_NewStringObj(ent->s_name, -1)) != TCL_OK) {
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            Tcl_Obj *aliases;
            if (make_string_list(interp, &aliases, ent->s_aliases) != TCL_OK) {
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("aliases", -1),
                               aliases) != TCL_OK) {
                Tcl_DecrRefCount(aliases);
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("port", -1),
                               Tcl_NewIntObj(ntohs(ent->s_port))) != TCL_OK) {
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("protocol", -1),
                               Tcl_NewStringObj(ent->s_proto, -1)) != TCL_OK) {
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            return TCL_OK;
        }


        static int make_protoent_dict(Tcl_Interp *interp, Tcl_Obj **dict,
                                 struct protoent *ent) {
        *dict = Tcl_NewDictObj();
        Tcl_IncrRefCount(*dict);

        if (!ent) {
            return TCL_OK;
        }

        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("name", -1),
                               Tcl_NewStringObj(ent->p_name, -1)) != TCL_OK) {
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            Tcl_Obj *aliases;
            if (make_string_list(interp, &aliases, ent->p_aliases) != TCL_OK) {
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("aliases", -1),
                               aliases) != TCL_OK) {
                Tcl_DecrRefCount(aliases);
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
            if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("proto", -1),
                               Tcl_NewIntObj(ent->p_proto)) != TCL_OK) {
                Tcl_DecrRefCount(*dict);
                return TCL_ERROR;
            }
        return TCL_OK;
    }

}

namespace eval nss {
    critcl::cproc sethostent {int stayopen} void
    critcl::cproc endhostent {} void

    critcl::ccommand gethostent {cdata interp objc objv} {
        if (objc != 1) {
            Tcl_WrongNumArgs(interp, 1, objv, "");
            return TCL_ERROR;
        }
        Tcl_Obj *dict = Tcl_NewDictObj();
        Tcl_IncrRefCount(dict);

        struct hostent *ent = gethostent();
        if (ent) {
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("name", -1),
                               Tcl_NewStringObj(ent->h_name, -1)) != TCL_OK) {
                Tcl_DecrRefCount(dict);
                return TCL_ERROR;
            }
            Tcl_Obj *aliases;
            if (make_string_list(interp, &aliases, ent->h_aliases) != TCL_OK) {
                Tcl_DecrRefCount(dict);
                return TCL_ERROR;
            }
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("aliases", -1),
                               aliases) != TCL_OK) {
                Tcl_DecrRefCount(aliases);
                Tcl_DecrRefCount(dict);
                return TCL_ERROR;
            }
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("addrtype", -1),
                               Tcl_NewIntObj(ent->h_addrtype)) != TCL_OK) {
                Tcl_DecrRefCount(dict);
                return TCL_ERROR;
            }
            Tcl_Obj *addrs = Tcl_NewListObj(0, NULL);
            Tcl_IncrRefCount(addrs);
            for (int i = 0; ent->h_addr_list[i]; i += 1) {
                char addrstr[INET6_ADDRSTRLEN + 1];
                if (!inet_ntop(ent->h_addrtype, ent->h_addr_list[i], addrstr,
                               sizeof addrstr)) {
                    Tcl_SetResult(interp, (char *)Tcl_PosixError(interp), TCL_VOLATILE);
                    Tcl_DecrRefCount(addrs);
                    Tcl_DecrRefCount(dict);
                    return TCL_ERROR;
                }
                if (Tcl_ListObjAppendElement(interp, addrs,
                                             Tcl_NewStringObj(addrstr, -1)) != TCL_OK) {
                    Tcl_DecrRefCount(addrs);
                    Tcl_DecrRefCount(dict);
                    return TCL_ERROR;
                }
            }
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("addresses", -1),
                               addrs) != TCL_OK) {
                Tcl_DecrRefCount(addrs);
                Tcl_DecrRefCount(dict);
                return TCL_ERROR;
            }
        }
        Tcl_SetObjResult(interp, dict);
        Tcl_DecrRefCount(dict);
        return TCL_OK;
    }

    generator define hosts {} {
        generator finally ::nss::endhostent
        ::nss::sethostent 1
        while {[dict size [set host [::nss::gethostent]]] > 0} {
            generator yield $host
        }
    }

    critcl::cproc setservent {int stayopen} void
    critcl::cproc endservent {} void

    critcl::ccommand getservent {cdata interp objc objv} {
        if (objc != 1) {
            Tcl_WrongNumArgs(interp, 1, objv, "");
            return TCL_ERROR;
        }

        struct servent *ent = getservent();
        Tcl_Obj *res;
        if (make_servent_dict(interp, &res, ent) != TCL_OK) {
            return TCL_ERROR;
        }
        Tcl_SetObjResult(interp, res);
        return TCL_OK;
    }

    critcl::cproc getservbyname {Tcl_Interp* interp char* name char* {proto NULL}} Tcl_Obj* {
        struct servent *ent = getservbyname(name, proto);
        Tcl_Obj *res;
        if (make_servent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getservbyport {Tcl_Interp* interp int port char* {proto NULL}} Tcl_Obj* {
        struct servent *ent = getservbyport(port, proto);
        Tcl_Obj *res;
        if (make_servent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    generator define services {} {
        generator finally ::nss::endservent
        ::nss::setservent 1
        while {[dict size [set service [::nss::getservent]]] > 0} {
            generator yield $service
        }
    }

    critcl::cproc setprotoent {int stayopen} void
    critcl::cproc endprotoent {} void

    critcl::ccommand getprotent {cdata interp objc objv} {
        if (objc != 1) {
            Tcl_WrongNumArgs(interp, 1, objv, "");
            return TCL_ERROR;
        }

        struct protoent *ent = getprotoent();
        Tcl_Obj *res;
        if (make_protoent_dict(interp, &res, ent) != TCL_OK) {
            return TCL_ERROR;
        }
        Tcl_SetObjResult(interp, res);
        return TCL_OK;
    }

    critcl::cproc getprotobyname {Tcl_Interp* interp char* name} Tcl_Obj* {
        struct protoent *ent = getprotobyname(name);
        Tcl_Obj *res;
        if (make_protoent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getprotobynumber {Tcl_Interp* interp int proto} Tcl_Obj* {
        struct protoent *ent = getprotobynumber(proto);
        Tcl_Obj *res;
        if (make_protoent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    generator define protocols {} {
        generator finally ::nss::endprotoent
        ::nss::setprotoent 1
        while {[dict size [set proto [::nss::getprotoent]]] > 0} {
            generator yield $proto
        }
    }


    critcl::cproc setnetent {int stayopen} void
    critcl::cproc endnetent {} void

    critcl::cproc setpwent {} void
    critcl::cproc endpwent {} void

    critcl::cproc setgrent {} void
    critcl::cproc endgrent {} void
}

proc nss::test {} {
    critcl::load
    puts "Hosts:"
    generator foreach host [nss::hosts] {
        puts "{$host}"
    }

    set http [nss::getservbyname http]
    puts "http is on port [dict get $http port]"

    set udp [nss::getprotobyname udp]
    puts "[dict get $udp name] is protocol [dict get $udp proto]"
}

if {[info exists argv0] &&
    ([file tail [info script]] eq [file tail $argv0])} {
    nss::test
}
