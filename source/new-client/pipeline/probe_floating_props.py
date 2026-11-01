"""Offline probe (owner 2026-10-31: "floating bags and a floating shield near the path ... in salisbury plains, use
offline/headless probes to figure out what props are floating"): every prop the True 1.65 server places in a zone
(its DB WorldObject rows) and every prop baked into the zone (fixtures with source world_object), checked against
   - the ground: the zone's height map, as the client's ground_at (heights.f32, bilinear), and
   - anything to stand on: every zone fixture's model bounds (glTF accessor min / max, its yaw and scale), widened by
     SUPPORT_PAD - a prop inside or on top of one is resting on it (a table, a wall, a tower roof).
A prop more than FLOAT_M above the ground and on nothing is reported, with what the client does with it: a server
prop within BAKED_M of a baked one is not drawn (the baked one is); the client only lifts a server prop that is UNDER
the ground (and only within 4 m), it never lowers one.
    python probe_floating_props.py [zone=1] [--db=<sqlite>] [--all]"""
import json, math, sqlite3, struct, sys
import paths as _paths
from pathlib import Path
from assets_pipeline import ROOT

FLOAT_M = 0.6
TREES = ('elm', 'pine', 'oak', 'tree', 'birch', 'willow', 'fir', 'spruce', 'ash', 'beech', 'bush', 'shrub')
SUPPORT_PAD = 0.6
BAKED_M = 2.0
M = 0.025
DB = _paths.WORLD_DB


def main():
    zone = int(next((a for a in sys.argv[1:] if a.isdigit()), 1))
    db = Path(next((a.split('=', 1)[1] for a in sys.argv if a.startswith('--db=')), DB))
    zd = ROOT / f'godot/content/zones/zone{zone:03d}'
    z = json.loads((zd / 'zone.json').read_text(encoding='utf-8'))
    idx = json.loads((ROOT / 'godot/content/zones/zones_index.json').read_text(encoding='utf-8'))[str(zone)]
    region, ox, oy = int(idx['region']), int(idx['x']) * 8192, int(idx['y']) * 8192
    w, h = int(idx['w']) * 8192, int(idx['h']) * 8192
    n, cell = int(z['heights_size']), float(z['cell_m'])
    hs = struct.unpack('<%df' % (n * n), (zd / z['heights']).read_bytes()[:4 * n * n])

    def ground(x, y):
        gx, gz = min(max(x / cell, 0), n - 1.001), min(max(y / cell, 0), n - 1.001)
        i, j = int(gx), int(gz)
        fx, fz = gx - i, gz - j
        a, b, c, d = hs[j * n + i], hs[j * n + i + 1], hs[(j + 1) * n + i], hs[(j + 1) * n + i + 1]
        return (a * (1 - fx) + b * fx) * (1 - fz) + (c * (1 - fx) + d * fx) * fz

    bounds = {}

    def model_bounds(mi):
        if mi not in bounds:
            m = z['models'][mi]
            lo, hi = [1e9] * 3, [-1e9] * 3
            try:
                g = json.loads((zd / m['file']).read_text(encoding='utf-8'))
                for a in g.get('accessors', []):
                    if 'min' in a and len(a['min']) == 3:
                        lo = [min(p, q) for p, q in zip(lo, a['min'])]
                        hi = [max(p, q) for p, q in zip(hi, a['max'])]
            except (OSError, ValueError):
                pass
            bounds[mi] = (lo, hi) if lo[0] < 1e8 else None
        return bounds[mi]

    fixtures = z['fixtures']

    def resting_on(px, py, pz, skip=None):
        for f in fixtures:
            if f is skip:
                continue
            b = model_bounds(f['m'])
            if b is None:
                continue
            mname = z['models'][f['m']]['name'].lower()
            if any(w in mname for w in TREES):              # (a tree's bounds are its canopy: nothing rests on it)
                continue
            lo, hi = b
            sc = float(f.get('scale', 1.0))
            fx, fy, fz = f['pos']
            # into the fixture's own space: undo its yaw (degrees about up), then its scale
            a = -math.radians(float(f.get('yaw', 0.0)))
            dx, dz = px - fx, pz - fz
            lx = (dx * math.cos(a) + dz * math.sin(a)) / sc
            lz = (-dx * math.sin(a) + dz * math.cos(a)) / sc
            ly = (py - fy) / sc
            pad = SUPPORT_PAD / sc
            if lo[0] - pad <= lx <= hi[0] + pad and lo[2] - pad <= lz <= hi[2] + pad and lo[1] - pad <= ly <= hi[1] + pad:
                return z['models'][f['m']]['name']
        return None

    found = []
    baked = [f for f in fixtures if f.get('source') == 'world_object']
    for f in baked:
        x, y, zz = f['pos']
        up = y - ground(x, zz)
        on = resting_on(x, y, zz, skip=f)
        if up > FLOAT_M and not on or '--all' in sys.argv:
            found.append(('baked', f.get('name'), x, zz, y, up, on, 'drawn (baked into the zone)'))
    con = sqlite3.connect(db.as_uri() + '?mode=ro', uri=True)
    rows = con.execute('select Name, Model, X, Y, Z, ClassType from WorldObject where Region = ?', (region,)).fetchall()
    for name, model, X, Y, Z, ct in rows:
        lx, ly = X - ox, Y - oy
        if not (0 <= lx < w and 0 <= ly < h):
            continue
        x, zz, y = lx * M, ly * M, Z * M
        g = ground(x, zz)
        up = y - g
        near_baked = any(math.hypot(b['pos'][0] - x, b['pos'][2] - zz) <= BAKED_M for b in baked)
        on = resting_on(x, y, zz)
        if (up > FLOAT_M and not on) or '--all' in sys.argv:
            fate = 'not drawn (the baked prop beside it is)' if near_baked else (
                'drawn in the air' if up > FLOAT_M else 'drawn on the ground')
            found.append(('server', f'{name} (model {model}, {ct.split(".")[-1]})', x, zz, y, up, on, fate))
    print(f'zone {zone} {z.get("name")}: {len(baked)} baked props, '
          f'{sum(1 for r in rows if 0 <= r[2] - ox < w and 0 <= r[3] - oy < h)} server props')
    for kind, name, x, zz, y, up, on, fate in sorted(found, key=lambda r: -r[5]):
        print(f'  {kind:6} {name:45} at {x:7.1f}, {zz:7.1f} m  {up:5.1f} m above ground  '
              f'{("on " + on) if on else "on nothing"}  -> {fate}')
    print(len(found), 'listed')


if __name__ == '__main__':
    main()
