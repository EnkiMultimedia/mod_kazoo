# Building mod_kazoo for FreeSWITCH 1.11

This page lists what changed between FreeSWITCH v1.10.11 (the last release with mod_kazoo in tree) and v1.11.3 that matters to mod_kazoo, and what changed in Erlang/OTP's erl_interface up to OTP 29. Read it when you build mod_kazoo against a 1.11 release or a recent OTP.

The analysis was made from the public FreeSWITCH sources (headers in `src/include`, `switch_xml.c`, `switch_event.c`, `switch_loadable_module.c`, cJSON) and the OTP 29 erl_interface headers.

## Build it

```sh
./check-build.sh            # FreeSWITCH v1.11.3 on erlang:29, in Docker
FS_VERSION=v1.11.2 ./check-build.sh
```

The script builds FreeSWITCH, sofia-sip and spandsp from upstream, builds mod_kazoo against it, and checks that the module does not ask for an executable stack.

## FreeSWITCH changes

No API used by mod_kazoo was removed or renamed. These changes still matter:

| Change | Effect on mod_kazoo | What to do |
|---|---|---|
| `SWITCH_EVENT_CERT_RELOAD` added before `SWITCH_EVENT_ALL` | A binary built against 1.10 headers binds the wrong event for "ALL" | Rebuild against the headers of the release you run |
| `interface-allowlist` in `switch.conf.xml` (1.11.2) | When present, interfaces not listed are skipped with a warning only: `erlang`, `kz_*`, `node.info` and the kazoo dialplan apps disappear | Leave the allowlist out, or list `mod_kazoo` and every module whose APIs Kazoo calls |
| cJSON built with a nesting limit of 64 | JSON nested deeper than 64 levels no longer parses (json_api, event filters) | Nothing for Kazoo payloads, which stay shallow |
| XML parser: `xml_disable_dtd`, entity depth 20, at most 10000 expansions | Fetch replies relying on DTD entities can be rejected | Kazoo replies do not use them |
| `${var:offset}` past the end now expands to an empty string | Only that edge case changes | None |
| `switch_sockaddr_info_get` skips DNS for IP literals | None for IP `listen-ip` values | None |
| PCRE replaced by PCRE2 | None: mod_kazoo uses no regex API | None |
| `switch_uuid_get` can produce UUIDv7 (`uuid-version`) | Still 36 characters | None |

`switch_xml_parse_str_dynamic(s, FALSE)` keeps its ownership rules: on success the XML owns `s`, on failure the caller keeps it. mod_kazoo's fetch agent relies on that.

## erl_interface (OTP 29, ei 5.8)

- `ei_init()` must run before any other ei call since OTP 21. mod_kazoo now always calls it.
- Since OTP 24 `gen:call/4` tags requests with `[alias | Ref]`. mod_kazoo now echoes the tag unchanged instead of decoding a reference, so `gen_server:call/3` and `net_adm:ping/1` work from OTP 24+ nodes.
- `ei_set_compat_rel()` no longer does anything, so the `compat-rel` setting has no effect.
- New pid, port and reference encodings (NEW_PID_EXT, NEWER_REFERENCE_EXT, 32-bit creation) are handled by ei. Build mod_kazoo against the same OTP release as the Kazoo nodes it talks to.
- Atoms must be Latin-1 to decode with `ei_decode_atom`; Kazoo only sends Latin-1 atoms.
- `WITH_KAZOO_ERL_SHUTDOWN` reaches into private ei structures that OTP 29 no longer exports. Do not enable it.

## Build notes

- `kazoo_definitions.S` now carries a `.note.GNU-stack` section. Without it the module is marked as needing an executable stack, and glibc 2.41 (Debian 13) refuses to load it.
- mod_kazoo links the static `libei.a` into a shared module, so the erl_interface library must be built with `-fPIC`. Debian's `erlang-dev` and the official `erlang` images are.
- `kazoo_commands.c` includes `<curl/curl.h>`; the curl development headers must be installed. configure does not check for them.
- `make install` installs `fs_epmd` next to the module, not into FreeSWITCH's `bin`. mod_kazoo starts `fs_epmd` from `PATH`; run `epmd -daemon` before FreeSWITCH instead.
