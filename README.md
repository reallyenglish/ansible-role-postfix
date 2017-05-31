# ansible-role-postfix

Configures postfix.

## Notes about `aliases(5)`

Please make sure your platform and its version is supported in `meta/main.yml`.
The role is designed to be version-agnostic, but, to keep compatibility with
default installation, it maintains a list of aliases in default `aliases(5)`
(see `var/*.yml`). If you do not care of the system default `aliases(5)`, you
may change this behaviour (see `postfix_aliases_default_is_empty`).

## Notes about validating configurations

The role checks all the configurations right before `postfix reload`. However,
as `postfix check` requires all configurations, including `main.cf`,
`master.cf`, and various tables, and postfix daemons read configuration files
and table periodically, it is not possible to validate them without affecting
running postfix. If the validation fails, the ansible play will stop. But do
not assume that your changes have not been deployed.

## Notes for FreeBSD users

Always set `alias_database` to the *real* path to `aliases(5)` in `main.cf(5)`.
Do not rely on symlinks. The role assume the path is `/etc/mail/aliases` by
default.

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `postfix_user` | user name of postfix | `{{ __postfix_user }}` |
| `postfix_group` | group name of postfix | `{{ __postfix_group }}` |
| `postfix_service` | service name | `postfix` |
| `postfix_conf_dir` | path to configuration directory | `{{ __postfix_conf_dir }}` |
| `postfix_aliases_file` | path to `aliases(5)` | `{{ __postfix_aliases_file }}` |
| `postfix_db_dir` | path to the directory where table files reside | `{{ postfix_conf_dir }}/db` |
| `postfix_master_cf_path` | path to `master.cf` | `{{ __postfix_conf_dir }}/master.cf` |
| `postfix_main_cf_path` | path to `main.cf` | `{{ __postfix_conf_dir }}/main.cf` |
| `postfix_flags` | NOT implemented | `""` |
| `postfix_package` | package name of postfix | `{{ __postfix_package }}` |
| `postfix_extra_packages` | list of extra packages to install, such as `postfix-cdb`. you may install any packages using the variable, but the role does nothing more than installing them. | `[]` |
| `postfix_master_cf` | array of lines of `master.cf` | See below |
| `postfix_main_cf_default` | dict of defaults in `main.cf` | `{"soft_bounce"=>"yes"}` |
| `postfix_main_cf` | dict of `main.cf` | `{}` |
| `postfix_tables` | See below | `[]` |
| `postfix_aliases` | dict of additional aliases | `{}` |
| `postfix_aliases_default` | dict of default aliases | `{{ __postfix_aliases_default }}` |
| `postfix_aliases_default_is_empty` | set `true` value if you do not use system's default `aliases(5)`, and create one from scratch. `postfix_aliases_default` will be ignored | `false` |

## `postfix_master_cf`

```yaml
postfix_master_cf:
  - "# service type  private unpriv  chroot  wakeup  maxproc command + args"
  - smtp      inet  n       -       n       -       -       smtpd
  - pickup    unix  n       -       n       60      1       pickup
  - cleanup   unix  n       -       n       -       0       cleanup
  - qmgr      unix  n       -       n       300     1       qmgr
  - tlsmgr    unix  -       -       n       1000?   1       tlsmgr
  - rewrite   unix  -       -       n       -       -       trivial-rewrite
  - bounce    unix  -       -       n       -       0       bounce
  - defer     unix  -       -       n       -       0       bounce
  - trace     unix  -       -       n       -       0       bounce
  - verify    unix  -       -       n       -       1       verify
  - flush     unix  n       -       n       1000?   0       flush
  - proxymap  unix  -       -       n       -       -       proxymap
  - proxywrite unix -       -       n       -       1       proxymap
  - smtp      unix  -       -       n       -       -       smtp
  - relay     unix  -       -       n       -       -       smtp
  - showq     unix  n       -       n       -       -       showq
  - error     unix  -       -       n       -       -       error
  - retry     unix  -       -       n       -       -       error
  - discard   unix  -       -       n       -       -       discard
  - local     unix  -       n       n       -       -       local
  - virtual   unix  -       n       n       -       -       virtual
  - lmtp      unix  -       -       n       -       -       lmtp
  - anvil     unix  -       -       n       -       1       anvil
  - scache    unix  -       -       n       -       1       scache
```
## `postfix_tables`

`postfix_tables` holds a list of lookup tables. An element of the list is a
dict, whose keys and values are described below.

| key | description |
|-----|-------------|
| `type` | lookup table type, such as `hash`, `cidr`, or `pcre` |
| `name` | the file name, which must be in the form of `$NAME.$type`. |
| `table` | the table |

Tables defined in `postfix_tables` are created in `postfix_db_dir`, and
automatically `postmap(1)`ed. When any of the tables is updated, `postfix` is
reloaded by a handler.

```yaml
postfix_tables:
  - name: mynetworks.cidr
    type: cidr
    table:
      127.0.0.1:
      192.168.100.0/24:
      192.168.101.0/24:
  - name: hello_access.hash
    type: hash
    table:
      localhost: reject
      localhost.localdomain: reject
```

## Debian

| Variable | Default |
|----------|---------|
| `__postfix_user` | `postfix` |
| `__postfix_group` | `postfix` |
| `__postfix_conf_dir` | `/etc/postfix` |
| `__postfix_package` | `postfix` |
| `__postfix_aliases_file` | `/etc/aliases` |
| `__postfix_aliases_default` | see below |

### `__postfix_aliases_default`

```yaml
__postfix_aliases_default:
  "14.04":
    postmaster: root
  "16.04":
    postmaster: root
```

## FreeBSD

| Variable | Default |
|----------|---------|
| `__postfix_user` | `postfix` |
| `__postfix_group` | `postfix` |
| `__postfix_conf_dir` | `/usr/local/etc/postfix` |
| `__postfix_package` | `mail/postfix` |
| `__postfix_aliases_file` | `/etc/mail/aliases` |
| `__postfix_aliases_default` | see below |

### `__postfix_aliases_default`

```yaml
__postfix_aliases_default:
  "10.3":
    MAILER-DAEMON: postmaster
    postmaster: root
    _dhcp: root
    _pflogd: root
    auditdistd: root
    bin: root
    bind: root
    daemon: root
    games: root
    hast: root
    kmem: root
    mailnull: postmaster
    man: root
    news: root
    nobody: root
    operator: root
    pop: root
    proxy: root
    smmsp: postmaster
    sshd: root
    system: root
    toor: root
    tty: root
    usenet: news
    uucp: root
    abuse: root
    security: root
    ftp: root
    ftp-bugs: ftp
```
## OpenBSD

| Variable | Default |
|----------|---------|
| `__postfix_user` | `_postfix` |
| `__postfix_group` | `_postfix` |
| `__postfix_conf_dir` | `/etc/postfix` |
| `__postfix_package` | `postfix-3.1.1p0` |
| `__postfix_aliases_file` | `/etc/mail/aliases` |
| `__postfix_aliases_default` | see below |

### `__postfix_aliases_default`

```yaml
__postfix_aliases_default:
  "6.0":
    MAILER-DAEMON: postmaster
    postmaster: root
    daemon: root
    ftp-bugs: root
    operator: root
    uucp: root
    www: root
    _bgpd: /dev/null
    _dhcp: /dev/null
    _dpb: /dev/null
    _dvmrpd: /dev/null
    _eigrpd: /dev/null
    _file: /dev/null
    _fingerd: /dev/null
    _ftp: /dev/null
    _hostapd: /dev/null
    _identd: /dev/null
    _iked: /dev/null
    _isakmpd: /dev/null
    _iscsid: /dev/null
    _ldapd: /dev/null
    _ldpd: /dev/null
    _mopd: /dev/null
    _nsd: /dev/null
    _ntp: /dev/null
    _ospfd: /dev/null
    _ospf6d: /dev/null
    _pbuild: /dev/null
    _pfetch: /dev/null
    _pflogd: /dev/null
    _pkgfetch: /dev/null
    _pkguntar: /dev/null
    _portmap: /dev/null
    _ppp: /dev/null
    _radiusd: /dev/null
    _rbootd: /dev/null
    _relayd: /dev/null
    _rebound: /dev/null
    _ripd: /dev/null
    _rstatd: /dev/null
    _rtadvd: /dev/null
    _rusersd: /dev/null
    _rwalld: /dev/null
    _smtpd: /dev/null
    _smtpq: /dev/null
    _sndio: /dev/null
    _snmpd: /dev/null
    _spamd: /dev/null
    _syslogd: /dev/null
    _tcpdump: /dev/null
    _tftpd: /dev/null
    _unbound: /dev/null
    _vmd: /dev/null
    _x11: /dev/null
    _ypldap: /dev/null
    bin: /dev/null
    nobody: /dev/null
    proxy: /dev/null
    _tftp_proxy: /dev/null
    _ftp_proxy: /dev/null
    _sndiop: /dev/null
    sshd: /dev/null
    abuse: root
    security: root
```

## RedHat

| Variable | Default |
|----------|---------|
| `__postfix_user` | `postfix` |
| `__postfix_group` | `postfix` |
| `__postfix_conf_dir` | `/etc/postfix` |
| `__postfix_package` | `postfix` |
| `__postfix_aliases_file` | `/etc/aliases` |
| `__postfix_aliases_default` | see below |

### `__postfix_aliases_default`

```yaml
__postfix_aliases_default:
  "7":
    mailer-daemon: postmaster
    postmaster: root
    bin: root
    daemon: root
    adm: root
    lp: root
    sync: root
    shutdown: root
    halt: root
    mail: root
    news: root
    uucp: root
    operator: root
    games: root
    gopher: root
    ftp: root
    nobody: root
    radiusd: root
    nut: root
    dbus: root
    vcsa: root
    canna: root
    wnn: root
    rpm: root
    nscd: root
    pcap: root
    apache: root
    webalizer: root
    dovecot: root
    fax: root
    quagga: root
    radvd: root
    pvm: root
    amandabackup: root
    privoxy: root
    ident: root
    named: root
    xfs: root
    gdm: root
    mailnull: root
    postgres: root
    sshd: root
    smmsp: root
    postfix: root
    netdump: root
    ldap: root
    squid: root
    ntp: root
    mysql: root
    desktop: root
    rpcuser: root
    rpc: root
    nfsnobody: root
    ingres: root
    system: root
    toor: root
    manager: root
    dumper: root
    abuse: root
    newsadm: news
    newsadmin: news
    usenet: news
    ftpadm: ftp
    ftpadmin: ftp
    ftp-adm: ftp
    ftp-admin: ftp
    www: webmaster
    webmaster: root
    noc: root
    security: root
    hostmaster: root
    info: postmaster
    marketing: postmaster
    sales: postmaster
    support: postmaster
    decode: root
```

# Dependencies

None

# Example Playbook

```yaml
- hosts: localhost
  roles:
    - ansible-role-postfix
  vars:
    postfix_aliases:
      dave.null: root
    postfix_tables:
      - name: mynetworks.cidr
        type: cidr
        table:
          127.0.0.1:
          192.168.100.0/24:
          192.168.101.0/24:
      - name: hello_access.hash
        type: hash
        table:
          localhost: reject
          localhost.localdomain: reject
    postfix_main_cf: "{% if ansible_os_family == 'OpenBSD' %}{{ postfix_main_cf_openbsd }}{% elif ansible_os_family == 'FreeBSD' %}{{ postfix_main_cf_freebsd }}{% else %}{}{% endif %}"

    # for historical reasons, postfix's default of alias_database for FreeBSD
    # is `/etc/aliases'. however, it has been a symlink to /etc/mail/aliases.
    # this usually works because human does not care of exact path. the role
    # does. it is about time use the real path instead.
    postfix_main_cf_freebsd:
      alias_database: /etc/mail/aliases

    # unlike other distributions, the OpenBSD package does not modify
    # /etc/postfix/main.cf.default, but sets distribution defaults in
    # /etc/postfix/main.cf. An empty main.cf does not work.
    postfix_main_cf_openbsd:
      compatibility_level: 2
      smtputf8_enable: "no"
      queue_directory: /var/spool/postfix
      command_directory: /usr/local/sbin
      daemon_directory: /usr/local/libexec/postfix
      data_directory: /var/postfix
      mail_owner: "{{ postfix_user }}"
      inet_protocols: all
      unknown_local_recipient_reject_code: 550
      debug_peer_level: 2
      sendmail_path: /usr/local/sbin/sendmail
      newaliases_path: /usr/local/sbin/newaliases
      mailq_path: /usr/local/sbin/mailq
      setgid_group: _postdrop
      html_directory: /usr/local/share/doc/postfix/html
      manpage_directory: /usr/local/man
      sample_directory: /etc/postfix
      readme_directory: /usr/local/share/doc/postfix/readme
      meta_directory: /etc/postfix
      shlib_directory: "no"
    postfix_extra_packages: "{% if ansible_os_family == 'RedHat' %}[ 'postfix-perl-scripts' ]{% else %}[ 'pflogsumm' ]{% endif %}"
```

# License

```
Copyright (c) 2017 Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
```

# Author Information

Tomoyuki Sakurai <tomoyukis@reallyenglish.com>

This README was created by [qansible](https://github.com/trombik/qansible)
