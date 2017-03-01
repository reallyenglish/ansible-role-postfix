# ansible-role-postfix

Configures postfix.

## Notes about validating configurations

The role checks all the configurations right before `postfix reload`. However,
as `postfix check` requires all configurations, including `main.cf`,
`master.cf`, and various tables, and postfix daemons read configuration files
and table periodically, it is not possible to validate them without affecting
running postfix. If the validation fails, the ansible play will stop. But do
not assume that your changes have not been deployed.

# Requirements

None

# Role Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `postfix_user` | user name of postfix | `{{ __postfix_user }}` |
| `postfix_group` | group name of postfix | `{{ __postfix_group }}` |
| `postfix_service` | service name | `postfix` |
| `postfix_conf_dir` | path to configuration directory | `{{ __postfix_conf_dir }}` |
| `postfix_db_dir` | path to the directory where table files reside | `{{ postfix_conf_dir }}/db` |
| `postfix_master_cf_path` | path to `master.cf` | `{{ __postfix_conf_dir }}/master.cf` |
| `postfix_main_cf_path` | path to `main.cf` | `{{ __postfix_conf_dir }}/main.cf` |
| `postfix_flags` | NOT implemented | `""` |
| `postfix_package` | package name of postfix | `{{ __postfix_package }}` |
| `postfix_master_cf` | array of lines of `master.cf` | See below |
| `postfix_main_cf_default` | dict of defaults in `main.cf` | `{"soft_bounce"=>"yes"}` |
| `postfix_main_cf` | dict of `main.cf` | `{}` |
| `postfix_tables` | See below | `[]` |

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

## FreeBSD

| Variable | Default |
|----------|---------|
| `__postfix_user` | `postfix` |
| `__postfix_group` | `postfix` |
| `__postfix_conf_dir` | `/usr/local/etc/postfix` |
| `__postfix_package` | `mail/postfix` |

## OpenBSD

| Variable | Default |
|----------|---------|
| `__postfix_user` | `_postfix` |
| `__postfix_group` | `_postfix` |
| `__postfix_conf_dir` | `/etc/postfix` |
| `__postfix_package` | `postfix-3.1.1p0` |

## RedHat

| Variable | Default |
|----------|---------|
| `__postfix_user` | `postfix` |
| `__postfix_group` | `postfix` |
| `__postfix_conf_dir` | `/etc/postfix` |
| `__postfix_package` | `postfix` |

# Dependencies

None

# Example Playbook

```yaml
- hosts: localhost
  roles:
    - ansible-role-postfix
  vars:
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
    postfix_main_cf: "{% if ansible_os_family == 'OpenBSD' %}{{ postfix_main_cf_openbsd }}{% else %}{}{% endif %}"

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
