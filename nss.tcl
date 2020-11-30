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

package require Tcl 8.6
package require critcl

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
    #include <errno.h>
}

namespace eval nss {}

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

    static int make_netent_dict(Tcl_Interp *interp, Tcl_Obj **dict,
                                  struct netent *ent) {
        *dict = Tcl_NewDictObj();
        Tcl_IncrRefCount(*dict);

        if (!ent) {
            return TCL_OK;
        }

        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("name", -1),
                               Tcl_NewStringObj(ent->n_name, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        Tcl_Obj *aliases;
        if (make_string_list(interp, &aliases, ent->n_aliases) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("aliases", -1),
                           aliases) != TCL_OK) {
            Tcl_DecrRefCount(aliases);
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("addrtype", -1),
                           Tcl_NewIntObj(ent->n_addrtype)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        char addrstr[INET6_ADDRSTRLEN + 1];
        uint32_t net = htonl(ent->n_net);
        if (!inet_ntop(ent->n_addrtype, &net, addrstr, sizeof addrstr)) {
            Tcl_AppendResult(interp, "inet_ntop: ", Tcl_PosixError(interp), NULL);
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("net", -1),
                           Tcl_NewStringObj(addrstr, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        return TCL_OK;
    }

    static int make_passwd_dict(Tcl_Interp *interp, Tcl_Obj **dict,
                                  struct passwd *ent) {
        *dict = Tcl_NewDictObj();
        Tcl_IncrRefCount(*dict);

        if (!ent) {
            return TCL_OK;
        }

        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("name", -1),
                               Tcl_NewStringObj(ent->pw_name, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("password", -1),
                               Tcl_NewStringObj(ent->pw_passwd, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("uid", -1),
                           Tcl_NewIntObj(ent->pw_uid)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("gid", -1),
                           Tcl_NewIntObj(ent->pw_gid)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("gecos", -1),
                               Tcl_NewStringObj(ent->pw_gecos, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("dir", -1),
                               Tcl_NewStringObj(ent->pw_dir, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("shell", -1),
                               Tcl_NewStringObj(ent->pw_shell, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        return TCL_OK;
    }

    static int make_group_dict(Tcl_Interp *interp, Tcl_Obj **dict,
                                  struct group *ent) {
        *dict = Tcl_NewDictObj();
        Tcl_IncrRefCount(*dict);

        if (!ent) {
            return TCL_OK;
        }

        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("name", -1),
                               Tcl_NewStringObj(ent->gr_name, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("password", -1),
                               Tcl_NewStringObj(ent->gr_passwd, -1)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("gid", -1),
                           Tcl_NewIntObj(ent->gr_gid)) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        Tcl_Obj *members;
        if (make_string_list(interp, &members, ent->gr_mem) != TCL_OK) {
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }
        if (Tcl_DictObjPut(interp, *dict, Tcl_NewStringObj("members", -1),
                           members) != TCL_OK) {
            Tcl_DecrRefCount(members);
            Tcl_DecrRefCount(*dict);
            return TCL_ERROR;
        }

        return TCL_OK;
    }
}

namespace eval nss {
    critcl::cproc sethostent {int stayopen} void
    critcl::cproc endhostent {} void

    critcl::cproc gethostent {Tcl_Interp* interp} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct hostent *ent = gethostent();
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "gethostent: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *dict = Tcl_NewDictObj();
        Tcl_IncrRefCount(dict);

        if (ent) {
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("name", -1),
                               Tcl_NewStringObj(ent->h_name, -1)) != TCL_OK) {
                Tcl_DecrRefCount(dict);
                return NULL;
            }
            Tcl_Obj *aliases;
            if (make_string_list(interp, &aliases, ent->h_aliases) != TCL_OK) {
                Tcl_DecrRefCount(dict);
                return NULL;
            }
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("aliases", -1),
                               aliases) != TCL_OK) {
                Tcl_DecrRefCount(aliases);
                Tcl_DecrRefCount(dict);
                return NULL;
            }
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("addrtype", -1),
                               Tcl_NewIntObj(ent->h_addrtype)) != TCL_OK) {
                Tcl_DecrRefCount(dict);
                return NULL;
            }
            Tcl_Obj *addrs = Tcl_NewListObj(0, NULL);
            Tcl_IncrRefCount(addrs);
            for (int i = 0; ent->h_addr_list[i]; i += 1) {
                char addrstr[INET6_ADDRSTRLEN + 1];
                if (!inet_ntop(ent->h_addrtype, ent->h_addr_list[i], addrstr,
                               sizeof addrstr)) {
                    Tcl_AppendResult(interp, "inet_ntop: ", Tcl_PosixError(interp), NULL);
                    Tcl_DecrRefCount(addrs);
                    Tcl_DecrRefCount(dict);
                    return NULL;
                }
                if (Tcl_ListObjAppendElement(interp, addrs,
                                             Tcl_NewStringObj(addrstr, -1)) != TCL_OK) {
                    Tcl_DecrRefCount(addrs);
                    Tcl_DecrRefCount(dict);
                    return NULL;
                }
            }
            if (Tcl_DictObjPut(interp, dict, Tcl_NewStringObj("addresses", -1),
                               addrs) != TCL_OK) {
                Tcl_DecrRefCount(addrs);
                Tcl_DecrRefCount(dict);
                return NULL;
            }
        }
        return dict;
    }

    critcl::cproc setservent {int stayopen} void
    critcl::cproc endservent {} void

    critcl::cproc getservent {Tcl_Interp* interp} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct servent *ent = getservent();
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getservent: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_servent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        }
        return res;
    }

    critcl::cproc getservbyname {Tcl_Interp* interp char* name char* {proto NULL}} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct servent *ent = getservbyname(name, proto);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getservbyname: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_servent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getservbyport {Tcl_Interp* interp int port char* {proto NULL}} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct servent *ent = getservbyport(port, proto);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getservbyport: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_servent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc setprotoent {int stayopen} void
    critcl::cproc endprotoent {} void

    critcl::cproc getprotoent {Tcl_Interp* interp} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct protoent *ent = getprotoent();
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getprotoent: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_protoent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getprotobyname {Tcl_Interp* interp char* name} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct protoent *ent = getprotobyname(name);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getprotobyname: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_protoent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getprotobynumber {Tcl_Interp* interp int proto} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct protoent *ent = getprotobynumber(proto);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getprotobynumber: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }
        Tcl_Obj *res;
        if (make_protoent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc setnetent {int stayopen} void
    critcl::cproc endnetent {} void

    critcl::cproc getnetent {Tcl_Interp* interp} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct netent *ent = getnetent();
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getnetent: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_netent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getnetbyname {Tcl_Interp* interp char* name} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct netent *ent = getnetbyname(name);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getnetbyname: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_netent_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc setpwent {} void
    critcl::cproc endpwent {} void

    critcl::cproc getpwent {Tcl_Interp* interp} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct passwd *ent = getpwent();
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getpwent: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }
        Tcl_Obj *res;
        if (make_passwd_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getpwbyname {Tcl_Interp* interp char* name} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct passwd *ent = getpwnam(name);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getpwnam: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }
        Tcl_Obj *res;
        if (make_passwd_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getpwbyuid {Tcl_Interp* interp int uid} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct passwd *ent = getpwuid(uid);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getpwuid: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }
        Tcl_Obj *res;
        if (make_passwd_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc setgrent {} void
    critcl::cproc endgrent {} void

    critcl::cproc getgrent {Tcl_Interp* interp} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct group *ent = getgrent();
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getgrent: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }
        Tcl_Obj *res;
        if (make_group_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getgrbyname {Tcl_Interp* interp char* name} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct group *ent = getgrnam(name);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getgrnam: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }
        Tcl_Obj *res;
        if (make_group_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }

    critcl::cproc getgrbygid {Tcl_Interp* interp int gid} Tcl_Obj* {
        Tcl_SetErrno(0);
        struct group *ent = getgrgid(gid);
        if (!ent && Tcl_GetErrno() != 0) {
            Tcl_AppendResult(interp, "getgrgid: ", Tcl_PosixError(interp), NULL);
            return NULL;
        }

        Tcl_Obj *res;
        if (make_group_dict(interp, &res, ent) != TCL_OK) {
            return NULL;
        } else {
            return res;
        }
    }
}

critcl::tsources nss_generators.tcl

proc nss::_test {} {
    critcl::load
    puts "Hosts:"
    generator foreach host [nss::hosts] {
        puts "{$host}"
    }

    puts "Services"
    set http [nss::getservbyname http]
    puts "http is on port [dict get $http port]"

    puts "Protocols"
    set udp [nss::getprotobyname udp]
    puts "[dict get $udp name] is protocol [dict get $udp proto]"

    puts "Networks"
    generator foreach net [nss::networks] {
        puts "{$net}"
    }

    puts "Users"
    set shells [dict create]
    generator foreach user [nss::users] {
        dict incr shells [dict get $user shell]
    }
    dict for {shell count} $shells {
        puts "Shell $shell has $count users using it."
    }

    try {
        set nosuchuser [nss::getpwbyname bob]
        puts "[dict get $nosuchuser name]'s home directory: [dict get $nosuchuser dir]"
    } on error {msg} {
        puts "Failure to look up user bob: $msg"
    }

    set rootuid [nss::convert user root]
    puts "root uid is $rootuid and uid $rootuid name is [nss::convert userid $rootuid]"

    puts "Groups"
    generator foreach group [nss::groups] {
        set members [dict get $group members]
        if {[llength $members] > 0} {
            puts "[dict get $group name] members: $members"
        }
    }
}

if {[info exists argv0] &&
    ([file tail [info script]] eq [file tail $argv0])} {
    nss::_test
}

package provide nss 0.9
