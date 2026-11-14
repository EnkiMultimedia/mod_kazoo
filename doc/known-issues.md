# Known issues

Problems found by reading the mod_kazoo sources that are not fixed yet on this branch. Each entry says where it is, what can go wrong and the intended fix. Fixed issues are in the git history of the `opencore` branch.

## Concurrent writes on the node socket

`ei_link()` (`kazoo_ei_utils.c`) writes a link request on the node socket with a raw `write()` from worker threads, while `handle_node()` sends on the same socket with `ei_send()`. Frames can interleave, and short writes are ignored, which can break the distribution connection.

Fix: queue link requests on `send_msgs` so only `handle_node()` writes, or guard every write with a per-node mutex and loop on short writes.

## Configuration reload while events are flowing

`kazoo_globals.ei_nodes` is walked without `ei_nodes_lock` (`kazoo_event_stream.c`, `kazoo_ei_utils.c`). A reload frees event profiles that running event handlers still point to.

Fix: take the read lock while walking, and reference count or swap the configuration.

## Command ordering

Each node has several worker threads (`node-worker-threads`, default 10) that process its messages concurrently, so two casts for the same call can run out of order.

Fix: use one worker thread per node, or route messages for the same call UUID to the same worker.

## CUSTOM event unbind

`remove_event_binding()` for a CUSTOM event falls back to any CUSTOM binding when the subclass does not match, so it can remove the wrong subscription.

Fix: for CUSTOM events, require the subclass to match.

## kz_att_xfer can spin

When `kz_att_thread_run()` returns early, `att->running` stays set and the application loops until hangup.

Fix: clear `att->running` on every return path.

## Socket cleanup

Node sockets are closed with `close()` instead of `ei_close_connection()`, which leaks ei's per-socket state, and fd 0 is treated as invalid.

Fix: call `ei_close_connection()` and test `fd >= 0`.

## Fetch timeout

The fetch agent waits a fixed 3 seconds; the profile's `fetch_timeout` is only sent to Kazoo as a header.

Fix: wait for `profile->fetch_timeout`.

## Leaks on error paths

Some error paths return without freeing what they decoded or created: the decoded value in `build_event()`, the event in `sendmsg`/`command`/`commands` when `build_event()` fails, the stream in `api` on early return, `xml_str` when the fetch reply UUID cannot be decoded.

## Cookie shown by `erlang status`

`erlang status` prints the distribution cookie. The API is reachable over the event socket and xml_rpc.

Fix: mask the cookie.

## Unhandled control messages

`ERL_SEND_TT`, `REG_SEND_TT` and `EXIT_TT` (sent while seq_trace is active) are dropped, and `ERL_EXIT2` is ignored.
