"""Autonomous event runs (owner 2026-10-13: run forced Darkness Falls, relic rallies/relic takes and the 3 epic dungeons
until they finish autonomously; fix and repeat until told to stop).

    python run.py start                       start runtime\\server\\CoreServer.exe in its own console (bots ramp in over 15 min)
    python run.py stop                        clean "exit" to the server console
    python run.py force <event> <realm>       start a forced event through realm-events.request.json and wait for the reply
                                               events: darkness-albion|-midgard|-hibernia, epic-albion|-midgard|-hibernia,
                                               rvr-keep-<KeepID>; realm: albion|midgard|hibernia (the attacking realm)
    python run.py stopevent <event>           stop a forced PvE expedition
    python run.py resetcd <event>             clear an event's cooldown (the boss must really be alive)
    python run.py status [minutes]            raid / relic progress in the server log since the run started (or the last N minutes)
    python run.py watch <minutes>             wait up to N minutes; returns early when a raid or relic event ends,
                                               a relic is captured, or the server stops"""
import datetime, json, os, re, subprocess, sys, time, uuid

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".."))  # found from this script, no fixed PC path
SERVER = os.path.join(ROOT, r"runtime\server")
LOG = os.path.join(SERVER, r"logs\server.log")
STATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "run_state.json")
REALMS = {"albion": 1, "midgard": 2, "hibernia": 3}
SEND = os.path.join(os.path.dirname(os.path.abspath(__file__)), "console_send.ps1")
END = re.compile(r"REALM_RAID_ENDED|RVR_EVENT_ENDED|RVR_KEEP_TAKEN|RAID_RELIC_PICKUP|RELIC_(CAPTURED|TAKEN|CLAIMED|PLACED)")
PROGRESS = re.compile(r"REALM_RAID_(ENDED|STARTED|HUB_DEPARTURE|START_UNAVAILABLE)|REALM_EXPEDITION_(TARGET_DEFEATED|TARGET_CALLED|FRONT|HOLD|STRANDED)|"
                      r"RVR_(SIEGE_STARTED|EVENT_ENDED|EVENT_STARTED|RETAKE_STARTED|SIEGE_MARCH)|RAID_RELIC_PICKUP|RELIC_[A-Z_]+|KEEP_(CAPTURED|TAKEN)")


def server_pid():
    out = subprocess.run(["tasklist", "/fi", "imagename eq CoreServer.exe", "/fo", "csv", "/nh"], capture_output=True, text=True).stdout
    m = re.search(r'"CoreServer.exe","(\d+)"', out)
    return int(m.group(1)) if m else None


def state():
    return json.load(open(STATE)) if os.path.exists(STATE) else {}


def save(**kw):
    s = state(); s.update(kw); json.dump(s, open(STATE, "w"), indent=1)


def log_lines(since=None):
    # server.log rolls over at 100 MB (server.YYYY-MM-DD.N.log); read the rolled files written since the cut-off too.
    import glob
    files = sorted(glob.glob(os.path.join(os.path.dirname(LOG), "server.*.log")), key=os.path.getmtime) + [LOG]
    cutoff = time.time() - 36 * 3600
    lines = []
    for f in files:
        if os.path.exists(f) and os.path.getmtime(f) >= cutoff:
            lines += open(f, encoding="utf-8", errors="replace").read().splitlines()
    if since:
        lines = [l for l in lines if l[:14] >= since]
    return lines


def stamp(dt):
    return dt.strftime("%m/%d %H:%M:%S")


def start(true165=False):
    """true165: start the True 1.65 Mode database (config/serverconfig-165.xml) instead of the normal one."""
    if server_pid():
        sys.exit("CoreServer already running; not starting another.")
    if subprocess.run(["tasklist"], capture_output=True, text=True).stdout.lower().count("offlinedaoc.exe"):
        sys.exit("The launcher is running (owner session?); not starting.")
    # Test goals (owner 2026-10-13: "change the bot goals"): runs	est-bot-goals.json overrides the launcher's
    # bot-goals.json for this run only (OFFLINE_DAOC_BOT_GOALS); the owner's saved setting is never edited.
    goals = os.path.join(os.path.dirname(os.path.abspath(__file__)), "test-bot-goals.json")
    env = dict(os.environ)
    if os.path.exists(goals):
        env["OFFLINE_DAOC_BOT_GOALS"] = goals
        print("bot goals override:", goals)
    args = " -ArgumentList '--start','-config=./config/serverconfig-165.xml'" if true165 else ""
    if true165:
        print("True 1.65 Mode: config/serverconfig-165.xml")
    subprocess.run(["powershell", "-NoProfile", "-Command",
                    f"Start-Process -FilePath '{os.path.join(SERVER, 'CoreServer.exe')}'{args} -WorkingDirectory '{SERVER}' -WindowStyle Minimized"], env=env)
    for _ in range(60):
        time.sleep(2)
        if server_pid():
            break
    save(started=stamp(datetime.datetime.now()), pid=server_pid())
    print("started", state())


def stop():
    pid = server_pid()
    if not pid:
        print("not running"); return
    for _ in range(3):
        subprocess.run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", SEND, "-ProcessId", str(pid), "-Text", "exit"],
                       capture_output=True, text=True)
        for _ in range(90):
            time.sleep(2)
            if not server_pid():
                print("stopped"); return
    print("server did not stop after 3 exits")


def force(event, realm, action="start"):
    req = dict(Id=str(uuid.uuid4()), Action=action, TargetId=event, Realm=REALMS.get(realm, 0),
               CreatedUtc=datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"), Confirmed=True)
    path = os.path.join(SERVER, "realm-events.request.json")
    open(path + ".tmp", "w").write(json.dumps(req))
    os.replace(path + ".tmp", path)
    result_path = os.path.join(SERVER, "realm-events.result.json")
    for _ in range(60):
        time.sleep(2)
        if os.path.exists(result_path):
            try:
                r = json.load(open(result_path))
            except (json.JSONDecodeError, OSError):
                continue
            if r.get("Id") == req["Id"]:
                print(("ACCEPTED " if r.get("Success") else "REFUSED ") + f"{event} {realm}: {r.get('Message')}")
                return r.get("Success")
    print(f"no reply for {event} {realm}")
    return False


def status(minutes=None):
    since = stamp(datetime.datetime.now() - datetime.timedelta(minutes=float(minutes))) if minutes else state().get("started")
    lines = [l for l in log_lines(since) if PROGRESS.search(l)]
    for l in lines[-60:]:
        print(l[:230])
    print(f"({len(lines)} progress lines since {since}; server pid {server_pid()})")


def watch(minutes):
    begin = stamp(datetime.datetime.now())
    deadline = time.time() + float(minutes) * 60
    while time.time() < deadline:
        time.sleep(30)
        if not server_pid():
            print("SERVER STOPPED"); break
        hits = [l for l in log_lines(begin) if END.search(l)]
        if hits:
            for l in hits:
                print(l[:260])
            break
    status(float(minutes) + 1)


if __name__ == "__main__":
    a = sys.argv[1:]
    {"start": lambda: start(len(a) > 1 and a[1] == "165"), "stop": lambda: stop(), "force": lambda: force(a[1], a[2]),
     "stopevent": lambda: force(a[1], "", "stop"), "resetcd": lambda: force(a[1], "", "reset-cooldown"), "status": lambda: status(a[1] if len(a) > 1 else None),
     "watch": lambda: watch(a[1])}[a[0]]()
