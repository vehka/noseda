# Debugging and Testing on a norns

How an agent can run, inspect and test norns code itself: on a norns on the
local network over ssh, and on a desktop norns build if one is installed.
Prefer the desktop for quick functional checks; use real hardware for anything
about timing, CPU, audio dropouts, grid/MIDI hardware or feel.

## 1. Find out what's available

Check before assuming. Ask the user for anything missing.

```bash
# desktop norns (a local build of the norns desktop port)
command -v norns-desktop                           # launcher script, if installed
pgrep -af 'ws-wrapper ws://0.0.0.0:5555'           # is norns already running?
ls ~/dust/code                                     # desktop dust tree

# norns hardware on the network (user: we)
getent hosts norns.local                           # may return only an IPv6 link-local address
timeout 5 bash -c '</dev/tcp/<ip>/22' && echo reachable
ssh -o ConnectTimeout=10 -o BatchMode=yes we@<ip> 'cat ~/version.txt; systemctl list-units --no-pager "norns*"'
```

- Ask the user for the device's IP address. `norns.local` often resolves only
  to an IPv6 link-local address (`fe80::…`) that doesn't answer, so use the IPv4
  address for ssh, the REPL and maiden (`http://<ip>/maiden/`). "maiden won't
  open" is usually this name-resolution problem, not maiden itself.
- ssh as `we`. The default password is `sleep`, and sudo often works without
  one (`sudo -n true` to check).
- `~/version.txt` gives the norns version. On 2026 "converged" norns, matron and
  crone run in one process (`norns-main.service`). Older images have separate
  `norns-matron` and `norns-crone` services.

## 2. Talk to matron: the REPL over websocket

matron's REPL is a websocket on port **5555** (sclang's is on 5556), with the
subprotocol `bus.sp.nanomsg.org`. Send Lua text ending in a newline. `print()`
output comes back on the socket. This is what maiden uses, so it works whether
or not the maiden web page opens.

`scripts/nrepl.py` in this skill's directory is a small client (needs `pip install websocket-client`):

```bash
python3 <skill-dir>/scripts/nrepl.py --host <ip> --wait 25 'norns.script.load("code/<script>/<script>.lua")'
python3 <skill-dir>/scripts/nrepl.py --host <ip> 'print(params:get("clock_tempo"))'
python3 <skill-dir>/scripts/nrepl.py --host localhost "dofile('/abs/path/test.lua')"   # desktop
```

- Loading a script takes a while; use `--wait 20` or more on hardware.
- Long tests: start them inside matron with `clock.run(...)`, have them write
  results to a file (`norns.state.data .. "result.txt"`), and fetch the file
  afterwards. The test keeps running if the connection drops.
- `maiden-repl` (built with norns) is interactive (curses) and doesn't work
  from a non-interactive agent shell; use the websocket.

## 3. Get code onto the device

```bash
# a git branch, updatable later with git pull on the device
ssh we@<ip> 'cd ~/dust/code && rm -rf <name> && git clone -q -b <branch> https://github.com/<user>/<repo> <name>'

# an unpushed revision from a local repo
git archive --prefix=<name>/ <rev> | gzip > /tmp/<name>.tgz
scp /tmp/<name>.tgz we@<ip>:/home/we/
ssh we@<ip> 'cd ~/dust/code && rm -rf <name> && tar xzf ~/<name>.tgz'
```

- Look at what's in `~/dust/code/<name>` before replacing it. It may be the
  user's own copy.
- **Mods**: install the same way into `~/dust/code/<mod>`. To enable, the user
  goes to SYSTEM > MODS, turns it on with E3, and restarts. The enabled list is
  in `~/dust/data/system.mods`.
- **SuperCollider engines** (`*.sc`) are compiled when sclang starts. A new or
  changed engine file needs a restart:
  `sudo systemctl restart norns-sclang norns-main` (converged norns). Lua-only
  changes just need the script reloaded (`norns.script.load`). If a changed
  revision has an identical `.sc` file, `git diff --quiet A B -- path/Engine.sc`
  shows you can skip the restart.
- Restarting services and replacing installed code change the user's device:
  confirm with the user first unless they asked for it.

## 4. Logs and system state on hardware

```bash
journalctl -u norns-main -n 100 --no-pager     # matron/crone output (older: norns-matron)
journalctl -u norns-sclang -n 100 --no-pager   # SuperCollider, engine compile errors
journalctl -u norns-jack --since '10 min ago' | grep -i xrun   # audio dropouts, names the late client
cat ~/dust/data/system.mods                    # enabled mods
amidi -l                                       # MIDI devices connected
```

## 5. Flaky wifi

Norns wifi drops often. Assume any ssh or REPL call can fail:

- Retry every remote step (a small `retry N cmd…` bash function).
- Make runs resumable: skip steps whose result file already exists, and
  restart a run if its result never appears.
- Record which revision is deployed on the device (e.g. a `~/deployed` marker
  holding a checksum), so a re-run doesn't redeploy or restart for nothing.
- Keep results on the device and copy them back afterwards, rather than
  streaming output over a long-lived connection.

## 6. Desktop norns

A desktop norns port (x86-64 Linux, a fork of norns) may be installed, with a
`norns-desktop` launcher. It starts maiden (:5000), sclang (REPL :5556), then
norns (REPL :5555), and puts the screen in an SDL window. Logs:
`~/norns.log`, `~/sclang.log`, `~/maiden.log`. `~/dust` is the dust tree.

```bash
ln -sfn /path/to/worktree ~/dust/code/<name>   # test a git worktree directly
norns-desktop                                  # run in the background; wait for "starting norns"
until grep -q 'starting norns' <launcher output>; do sleep 1; done; sleep 15
```

- **Engines:** link the script into `~/dust/code` *before* starting, so sclang
  compiles its engine. The log lists `available engines`, so check that yours
  is there.
- **Output:** besides the websocket, script output lands in `~/norns.log`.
  Remember the line count before a command (`L=$(wc -l < ~/norns.log)`) and read
  only what comes after.
- **Keys and encoders** in the SDL window: hold Alt, then Alt+1/2/3 are the
  keys and Alt+q/w, a/s, z/x the encoders. The window needs focus.
- **Mods are active here too.** For example nb_fluid makes MIDI vport 1 a
  fluidsynth port. Check `midi.vports[i].name` before trusting MIDI results.
- **Restarting:** stop the launcher and start it again. Do that between test
  runs whenever earlier runs could leave state behind.
- It is much faster than a Pi. Use it for correctness, not for performance numbers.

## 7. Testing a script from the outside

A test file run with `dofile()` inside matron can reach a script's `local`
state through the upvalues of any global function that uses it (`init`,
`redraw`, `clock.transport.start`, a global `clocked_seq`…):

```lua
local function upv(f, name)
  for i = 1, 300 do
    local n, v = debug.getupvalue(f, i)
    if not n then return nil end
    if n == name then return v, i end
  end
end
local data = upv(clocked_seq, "data")        -- the script's local table
local seqrun, idx = upv(clocked_seq, "seqrun")
debug.setupvalue(clocked_seq, idx, wrapper)  -- swap a local function (restore after!)
```

- This lets one test harness run unchanged on many revisions of a script, for
  before/after comparisons, without adding test code to the script.
- Capture MIDI output by replacing methods on the vport table, and **save and
  put back the originals**. The vport methods are fields on each
  `midi.vports[i]` table, not class methods, so setting one to `nil` deletes it
  until norns restarts:
  `local orig = vp.note_on; vp.note_on = function(self, n) log[#log+1] = n end`
  … `vp.note_on = orig`. (For `params.set` the opposite holds: it is a class
  method, so `params.set = nil` removes an instance override.)
- `engine` is read-only; you can't wrap engine commands this way.
- **Globals survive script reloads.** A test that stores "the original
  function" in a global will later call a dead script instance's function.
  Only reuse a stored original if your own wrapper is currently installed.
- Call the step function directly in a loop (`for c = 1, 512 do seqrun(c) end`)
  for deterministic tests that don't need the clock.
- Syntax check without a norns: `luac5.3 -p file.lua` (norns uses Lua 5.3).
- Plain `lua5.3` can load norns libraries for offline tests:
  `package.path = "<norns>/lua/lib/?.lua;" .. package.path; util = require "util"`,
  then `require "musicutil"` and so on.
