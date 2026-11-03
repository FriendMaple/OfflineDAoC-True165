"""Horse route legs put off a bridge deck by the floor passes (player report 2026-11-03: "Pathing from N TNN to Druim
Ligen the horse goes ... under the bridge").

On some bridges the period route's own straight leg already rode the deck, and build_routefloor165.py still replaced it:
its deck pass lifted points onto small surfaces far above (arch or tower tops at the bridge ends: Druim Ligen's deck is
at 4941, two points sat at 5385) and its tracker followed the bank down under the ramps (points 70-85 under the deck), so
the horse climbed onto a tower top or was drawn below the bridge. For such a leg the period straight leg is put back.

A period leg (its original points, kept in the world's archive) is restored only when ALL of these hold:
- at every sample along it that has more than one floor (a bridge), its line lies on a floor (16 under to 64 over it):
  so Prydwen Bridge, whose period line ran flat at 2072 between the deck (2373) and the river (1901), is never touched;
- it does not climb more than 40 over its start on such a spot (the clients' floor pick, refine_routefloor165.py);
- the route's current points between its two ends stray 150 or more from it.
Runs after build_routefloor165.py and refine_routefloor165.py, on add-routefloor165.json, and updates refine's rule that
drops route-floor points past each route's end. Rerunnable.

Usage: python -I fix_routebridges165.py <world db> [--write]   (read-only on the database)
"""
import json, math, os, sqlite3, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import groundz165 as g   # noqa: E402

SAMPLE = 40
MIN_LEG = 200
UNDER, OVER = 16, 64      # the line rides a floor between floor-16 and floor+64 (the clients pick the floor from +64)
RISE = 40
STRAY = 150               # only legs whose current points left the deck by this much (a tower top: +440); the smaller
                          # offsets of other bridges (into Camelot...) were tuned with the owner and stay
END_MATCH = 40            # a current point this close to a period leg's end is that end

db_path = sys.argv[1]
write = '--write' in sys.argv
db = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
SRC = os.path.join(HERE, 'add-routefloor165.json')
doc = json.load(open(SRC, encoding='utf-8'))

originals = {}
for (raw,) in db.execute("SELECT RowJson FROM offline_true165_removed WHERE SourceTable = 'PathPoints' AND "
                         "Reason LIKE 'True 1.65 horse routes follow the floor%'"):
    r = json.loads(raw)
    originals.setdefault(r['PathID'], []).append((r['Step'], r['X'], r['Y'], r['Z']))
for pid in originals:
    originals[pid].sort()


def region_of(x, y, z):
    row = db.execute("SELECT Region FROM Mob WHERE abs(X-?)<800 AND abs(Y-?)<800 AND abs(Z-?)<600 "
                     "ORDER BY (X-?)*(X-?)+(Y-?)*(Y-?) LIMIT 1", (x, y, z, x, x, y, y)).fetchone()
    return row[0] if row else None


def rides_deck(region, a, b):
    """Whether the straight leg a->b crosses a spot with several floors and lies on a floor at every such spot."""
    length = math.hypot(b[1] - a[1], b[2] - a[2])
    n = int(length // SAMPLE)
    multi = 0
    for i in range(1, n):
        t = i / n
        x, y, z = a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t
        fl = [h for h in g.floors(region, int(round(x)), int(round(y))) if z - 600 <= h <= z + 600]
        if len(fl) < 2:
            continue
        multi += 1
        if not any(-UNDER <= z - h <= OVER for h in fl):
            return False
        if z - a[3] > RISE:
            return False
    return multi > 0


def nearest(rows, x, y, start=0):
    best = None
    for i in range(start, len(rows)):
        d = math.hypot(rows[i]['X'] - x, rows[i]['Y'] - y)
        if d <= END_MATCH and (best is None or d < best[0]):
            best = (d, i)
    return best[1] if best else None


by_route = {}
for row in doc['rows']:
    by_route.setdefault(row['PathID'], []).append(row)
report = {}
for pid, rows in by_route.items():
    rows.sort(key=lambda r: r['Step'])
    orig = originals.get(pid)
    if not orig or len(orig) < 2:
        continue
    region = region_of(rows[0]['X'], rows[0]['Y'], rows[0]['Z'])
    if region is None:
        continue
    for a, b in zip(orig, orig[1:]):
        if math.hypot(b[1] - a[1], b[2] - a[2]) < MIN_LEG or not rides_deck(region, a, b):
            continue
        ia = nearest(rows, a[1], a[2])
        ib = nearest(rows, b[1], b[2], (ia or 0) + 1) if ia is not None else None
        if ia is None or ib is None or ib <= ia + 1:
            continue
        seg = math.hypot(b[1] - a[1], b[2] - a[2])
        def line_at(r):
            t = max(0, min(1, ((r['X'] - a[1]) * (b[1] - a[1]) + (r['Y'] - a[2]) * (b[2] - a[2])) / (seg * seg)))
            return a[3] + (b[3] - a[3]) * t
        interior = rows[ia + 1:ib]
        stray = max(abs(r['Z'] - line_at(r)) for r in interior)
        if stray <= STRAY:
            continue
        report.setdefault(pid, []).append((a[0], b[0], len(interior), round(stray)))
        rows[ia]['X'], rows[ia]['Y'], rows[ia]['Z'] = a[1], a[2], a[3]
        rows[ib]['X'], rows[ib]['Y'], rows[ib]['Z'] = b[1], b[2], b[3]
        del rows[ia + 1:ib]

# Second pass: single points (a run of at most SPIKE_RUN) lifted onto a tower or arch top where the period leg did not
# ride the deck the whole way (Innis Carthaig's bridge, deck ~4878: points at 5154-5431). A run is one that jumps up more
# than SPIKE from the point before it and drops more than SPIKE to the point after; each of its points has a floor within
# 30 of the line between those two neighbours (the deck the route was on) and is put on it. A real raised deck (Prydwen
# Bridge's, 2373 over a bank at ~2082) has no floor near that line under it and is left alone.
SPIKE, SPIKE_RUN, NEAR = 200, 5, 30
spikes = {}
for pid, rows in by_route.items():
    region = None
    i = 1
    while i < len(rows) - 1:
        if rows[i]['Z'] - rows[i - 1]['Z'] <= SPIKE:
            i += 1
            continue
        j = next((k for k in range(i, min(i + SPIKE_RUN, len(rows) - 1)) if rows[k]['Z'] - rows[k + 1]['Z'] > SPIKE), None)
        if j is None:
            i += 1
            continue
        lo, hi = rows[i - 1], rows[j + 1]
        if any(rows[k]['Z'] <= max(lo['Z'], hi['Z']) + SPIKE for k in range(i, j + 1)):
            i += 1
            continue
        region = region or region_of(rows[0]['X'], rows[0]['Y'], rows[0]['Z'])
        total = sum(math.hypot(rows[k + 1]['X'] - rows[k]['X'], rows[k + 1]['Y'] - rows[k]['Y']) for k in range(i - 1, j + 1)) or 1
        new, run = [], 0.0
        for k in range(i, j + 1):
            run += math.hypot(rows[k]['X'] - rows[k - 1]['X'], rows[k]['Y'] - rows[k - 1]['Y'])
            zi = lo['Z'] + (hi['Z'] - lo['Z']) * run / total
            fl = [h for h in g.floors(region, int(rows[k]['X']), int(rows[k]['Y'])) if abs(h + 8 - zi) <= NEAR] if region else []
            if not fl:
                new = None
                break
            new.append(int(round(min(fl, key=lambda h: abs(h + 8 - zi)) + 8)))
        if new:
            for k, z in zip(range(i, j + 1), new):
                spikes.setdefault(pid, []).append((rows[k]['Step'], rows[k]['Z'], z))
                rows[k]['Z'] = z
        i = j + 1

print('legs restored', sum(len(v) for v in report.values()), 'routes', len(report))
print('spike points lowered', sum(len(v) for v in spikes.values()), 'routes', len(spikes))
for pid, ch in sorted(spikes.items()):
    print(' ', pid, ch)
for pid, legs in sorted(report.items()):
    print(' ', pid, legs)
if write:
    new_rows = []
    for pid, rows in by_route.items():
        for i, r in enumerate(rows, 1):
            r = dict(r)
            r['Step'] = i
            r['PathPoints_ID'] = f'p165floor-{pid}-{i}'
            new_rows.append(r)
    doc['rows'] = new_rows
    counts = {}
    for r in new_rows:
        counts[r['PathID']] = max(counts.get(r['PathID'], 0), r['Step'])
    tag = 'True 1.65 horse routes: route-floor points past a refined route\'s end'
    for folder in (HERE, os.path.join(HERE, '..', '..', '..', 'runtime', 'true165')):
        json.dump(doc, open(os.path.join(folder, 'add-routefloor165.json'), 'w', encoding='utf-8', newline='\n'), indent=1)
        rp = os.path.join(folder, 'true165-rules.json')
        raw = open(rp, 'rb').read()
        rules = json.loads(raw.decode('utf-8'))
        old = [w for w in rules['remove']['where'] if w['reason'].startswith(tag)]
        rules['remove']['where'] = [w for w in rules['remove']['where'] if not w['reason'].startswith(tag)]
        keep = ','.join("'" + p.replace("'", "''") + "'" for p in sorted(counts))
        cond = ' OR '.join(f"(PathID = '{p.replace(chr(39), chr(39) * 2)}' AND Step > {n})" for p, n in sorted(counts.items()))
        rules['remove']['where'].append({'table': 'PathPoints', 'key': 'PathPoints_ID',
            'where': f"PathPoints_ID LIKE 'p165floor-%' AND (({cond}) OR PathID NOT IN ({keep}))",
            'reason': old[0]['reason'] if old else tag + ' (refine_routefloor165.py: the refined routes have fewer points)'})
        nl = b'\r\n' if b'\r\n' in raw else b'\n'
        open(rp, 'wb').write(json.dumps(rules, indent=1, ensure_ascii=False).encode('utf-8').replace(b'\n', nl) + (nl if raw.endswith(nl) else b''))
    print('written', len(new_rows), 'rows')
