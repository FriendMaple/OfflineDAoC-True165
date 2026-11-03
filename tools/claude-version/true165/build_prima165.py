"""True 1.65: the Prima guides' fixes (owner 2026-11-02: "fix 1-4 and do the difficulty changes too. the primas are
authoritative"). Writes the True 1.65 content files; never touches a database.

python -I build_prima165.py <refreshed world db (read only)>

Reads the Prima audit (development-source/research/period-data/prima-tools: out/*.json, reports/*.json) and the world
as it is now, and writes, in BOTH copies (tools/claude-version/true165 and runtime/true165):
  1+2 item fixes   broken weapon damage, and item values where the 2002 guide and the late-2003 period page agree and
                   ours differs: base items -> true165-rules.json updates ("True 1.65 Prima item"), items from an add-file
                   -> that add-file's row
  3+4 drops        Atlas drops for monsters that drop nothing / miss an item we already have, spawned in the Atlas zone
                   -> drops165.json (per-item chance from the Atlas roll: 'pick' of n items = chance / n)
  difficulty       monster level / aggression / speed from the guides, only for spawns in the zones (Atlas appendix,
                   SI pages) or realm (Revised table) the guide row covers -> updates (base spawns) or add-file rows
Every decision goes to prima165_report.json. Running it again gives the same files (old Prima rows are replaced).
"""
import json, os, re, sqlite3, sys, statistics
from collections import defaultdict, Counter

HERE = os.path.dirname(os.path.abspath(__file__))
CV = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
RUNTIME = os.path.join(CV, 'runtime', 'true165')
PT = os.path.join(CV, 'development-source', 'research', 'period-data', 'prima-tools')
ITEM_TAG, MOB_TAG = 'True 1.65 Prima item', 'True 1.65 Prima monster'
DROPS_TAG = ' + Prima Atlas loot (2026-11-02)'

def n(s):
    return re.sub(r'[^a-z]', '', (s or '').lower())

def jload(p):
    return json.load(open(p, encoding='utf-8'))

# ---- owner 2026-11-02: "dont change any boss or epic dungeon mobs some are nerfed or mechanics changed intentionally"
PLAIN_CLASSES = {None, '', 'DOL.GS.GameNPC', 'DOL.GS.NightSpawn', 'DOL.GS.DaySpawn'}
PLAIN_BRAINS = {None, '', 'DOL.AI.Brain.NightSpawnBrain', 'DOL.AI.Brain.DaySpawnBrain'}
EPIC_DUNGEON_REGIONS = {60, 160, 191}          # Caer Sidi, Tuscaran Glacier, Galladoria
DARKNESS_FALLS = 249

def scripted_boss_names():
    """Names used by the named-monster scripts (scripts/namedmobs): bosses even when a spawn row is a plain GameNPC."""
    root = os.path.join(CV, 'development-source', 'server', 'GameServer', 'scripts', 'namedmobs')
    out = set()
    for dp, _, files in os.walk(root):
        for f in files:
            if f.endswith('.cs'):
                txt = open(os.path.join(dp, f), encoding='utf-8', errors='replace').read()
                out.update(n(x) for x in re.findall(r'\bName\s*=\s*"([^"]+)"', txt))
                out.update(n(x) for x in re.findall(r'class\s+(\w+)\s*:', txt))
                out.add(n(os.path.splitext(f)[0]))
    return {x for x in out if len(x) > 3}

def protected_spawn(name, ctype, brain, region):
    """A boss, a boss's add, a scripted mechanic or an epic dungeon monster: never changed by the Prima pass."""
    if ctype not in PLAIN_CLASSES or brain not in PLAIN_BRAINS or region in EPIC_DUNGEON_REGIONS:
        return True
    if n(name) in BOSS_NAMES:
        return True
    return region == DARKNESS_FALLS and name[:1].isupper()

BOSS_NAMES = set()

def sql_val(v):
    return str(int(v)) if isinstance(v, (int, float)) and float(v).is_integer() else (
        str(v) if isinstance(v, (int, float)) else "'" + str(v).replace("'", "''") + "'")

def lv_range(text):
    nums = [int(x) for x in re.findall(r'\d+', text or '')]
    return (min(nums), max(nums)) if nums else (None, None)

class AddFiles:
    """The add-*.json files: which row of which table comes from which file (edits go to the file's row)."""
    def __init__(self, folder, previous_originals=None):
        self.folder, self.docs, self.index = folder, {}, {}
        for f in sorted(os.listdir(folder)):
            if f.startswith('add-') and f.endswith('.json'):
                d = jload(os.path.join(folder, f))
                self.docs[f] = d
                for i, row in enumerate(d['rows']):
                    self.index[(d['table'], str(row.get(d['key'])))] = (f, i)
        self.changed = set()
        self.originals = {}            # "file|key" -> {field: value before any Prima edit}
        # a rerun starts from the rows as they were before the Prima pass (its earlier edits are put back first)
        for fk, fields in (previous_originals or {}).items():
            f, key = fk.split('|', 1)
            d = self.docs.get(f)
            if not d:
                continue
            hit = self.index.get((d['table'], key))
            if hit:
                self.docs[f]['rows'][hit[1]].update(fields)
                self.changed.add(f)
                self.originals[fk] = dict(fields)

    def row(self, table, key):
        hit = self.index.get((table, str(key)))
        return (self.docs[hit[0]]['rows'][hit[1]], hit[0]) if hit else (None, None)

    def set(self, table, key, values):
        row, f = self.row(table, key)
        if row is None:
            return False
        orig = self.originals.setdefault(f'{f}|{key}', {})
        for k, v in values.items():
            if row.get(k) != v:
                orig.setdefault(k, row.get(k))
                row[k] = v
                self.changed.add(f)
        return True

    def save(self):
        for f in sorted(self.changed):
            for folder in (self.folder, RUNTIME):
                with open(os.path.join(folder, f), 'w', encoding='utf-8') as out:
                    json.dump(self.docs[f], out, ensure_ascii=False, indent=1)
                    out.write('\n')

# ------------------------------------------------------------------ 1 + 2: items
def item_fixes(c, adds, report):
    cols = [r[1] for r in c.execute('pragma table_info(ItemTemplate)')]
    rows = {}
    by_name = defaultdict(list)
    for r in c.execute('select * from ItemTemplate'):
        d = dict(zip(cols, r))
        rows[d['Id_nb']] = d
        by_name[n(d['Name'])].append(d)
    findings = jload(os.path.join(PT, 'reports', 'item_findings.json'))['findings']
    updates, done = [], Counter()
    for f in findings:
        high = [d for d in f['differences'] if d['verdict'].startswith('high')]
        if not high:
            continue
        base = rows.get(f['ours'])
        if base is None:
            continue
        # the same wrong value on another copy of the item (same name and type) is the same mistake
        copies = [d for d in by_name[n(base['Name'])] if d['Object_Type'] == base['Object_Type']]
        for item in copies:
            sets = {}
            bonus_slots = {i: (item.get(f'Bonus{i}Type') or 0, item.get(f'Bonus{i}') or 0) for i in range(1, 11)}
            for d in high:
                fld, ours, want = d['field'], d['ours'], d['guide_2002']
                if 'zero' in d['verdict'] and want is None:
                    want = d['period_page']
                if want is None and not fld.startswith('extra bonus '):   # a bonus neither source lists has no value
                    continue
                def same(col, cur):            # this copy has the wrong value the finding saw
                    return item.get(col) == cur
                if fld == 'level' and same('Level', ours):
                    sets['Level'] = int(want)
                elif fld == 'quality' and same('Quality', ours):
                    sets['Quality'] = int(want)
                elif fld == 'hit/defense %' and same('Bonus', ours):
                    sets['Bonus'] = int(want)
                elif fld == 'dps' and abs((item['DPS_AF'] or 0) / 10 - (ours or 0)) < 0.051:
                    sets['DPS_AF'] = int(round(float(want) * 10))
                elif fld == 'speed' and abs((item['SPD_ABS'] or 0) / 10 - (ours or 0)) < 0.051:
                    sets['SPD_ABS'] = int(round(float(want) * 10))
                elif fld == 'af' and same('DPS_AF', ours):
                    sets['DPS_AF'] = int(want)
                elif fld.startswith('bonus ') and (item.get('ExtraBonusType') or 0) == int(fld.split(' ')[1]):
                    sets['ExtraBonus'] = int(want)            # the bonus lives in the item's extra-bonus field
                elif fld.startswith('bonus '):
                    pid = int(fld.split(' ')[1])
                    slots = [i for i, (t, v) in bonus_slots.items() if t == pid]
                    if slots:
                        bonus_slots[slots[0]] = (pid, int(want))
                        for i in slots[1:]:
                            bonus_slots[i] = (0, 0)
                    else:
                        free = [i for i, (t, v) in bonus_slots.items() if t == 0]
                        if free:
                            bonus_slots[free[0]] = (pid, int(want))
                elif fld.startswith('extra bonus '):
                    pid = int(fld.split(' ')[2])
                    for i, (t, v) in list(bonus_slots.items()):
                        if t == pid:
                            bonus_slots[i] = (0, 0)
                    if (item.get('ExtraBonusType') or 0) == pid:   # both sources lack it: the extra-bonus field too
                        sets['ExtraBonusType'], sets['ExtraBonus'] = 0, 0
            for i, (t, v) in bonus_slots.items():
                if (item.get(f'Bonus{i}Type') or 0) != t or (item.get(f'Bonus{i}') or 0) != v:
                    sets[f'Bonus{i}Type'], sets[f'Bonus{i}'] = t, v
            if not sets:
                continue
            if adds.set('ItemTemplate', item['Id_nb'], sets):
                done['item rows in add-files'] += 1
                how = 'add-file'
            else:
                updates.append({'sql': f"UPDATE ItemTemplate SET {', '.join(f'{k} = {sql_val(v)}' for k, v in sets.items())} "
                                       f"WHERE Id_nb = {sql_val(item['Id_nb'])}",
                                'reason': f"{ITEM_TAG}: {item['Name']} (2002 guide and late-2003 period page agree)"})
                done['item updates'] += 1
                how = 'update'
            report['items'].append({'item': item['Id_nb'], 'name': item['Name'], 'set': sets, 'via': how,
                                    'evidence': [(d['field'], d['ours'], d['guide_2002'], d['period_page']) for d in high]})
    return updates, done

# ------------------------------------------------------------------ 3 + 4: drops
def roll_chance(roll):
    """Atlas roll -> our per-item chance: the band chances' median; a 'pick' of n items is one roll, so n items share it."""
    ch = roll.get('chances') or []
    if not ch:
        fl = roll.get('flags') or []
        return 100 if any('read as always' in x for x in fl) else None
    p = statistics.median(ch)
    if roll.get('mode') == 'pick' and roll.get('pick_size', 1) > 1:
        p = p / roll['pick_size']
    return max(1, min(100, int(round(p))))

def drop_fixes(c, report):
    findings = jload(os.path.join(PT, 'reports', 'loot_findings.json'))['findings']
    zone_realm = {}
    for zname, realm in c.execute('select Name, Realm from Zones'):
        zone_realm[zname] = realm
    items = defaultdict(list)
    used = {r[0] for r in c.execute('select distinct ItemTemplateID from LootTemplate')}
    for idn, name, realm in c.execute('select Id_nb, Name, Realm from ItemTemplate'):
        items[n(name)].append((idn, realm))
    def pick_item(name, realm):
        cands = items.get(n(name), [])
        if not cands:
            return None
        cands.sort(key=lambda x: (x[1] not in (realm, 0), x[0] not in used, x[1] != realm, x[0]))
        return cands[0][0]
    protected = set()                                # names with any boss / epic dungeon / scripted spawn
    for name, ctype, brain, region in c.execute('select Name, ClassType, Brain, Region from Mob'):
        if protected_spawn(name or '', ctype, brain, region):
            protected.add((name or '').lower())
    wanted = defaultdict(dict)                       # mob name -> {item id: chance}
    for f in findings:
        if f.get('severity') != 'high':
            continue
        if f['monster'].lower() in protected:
            report['held'].append({'monster': f['monster'], 'field': 'drops', 'why': 'boss / epic dungeon / scripted monster'})
            continue
        realm = zone_realm.get(f['zone'], 0)
        if f['type'] == 'no loot on our side':
            for roll in f.get('atlas_rolls', []):
                ch = roll_chance(roll)
                iid = pick_item(roll['item'], realm) if ch else None
                if iid:
                    wanted[f['monster']][iid] = max(ch, wanted[f['monster']].get(iid, 0))
        elif f['type'] == 'missing item' and f.get('item_exists'):
            ch = roll_chance(dict(f.get('roll') or {}, flags=f.get('flags')))
            iid = pick_item(f['item'], realm) if ch else None
            if iid:
                wanted[f['monster']][iid] = max(ch, wanted[f['monster']].get(iid, 0))
    return wanted

def write_drops(c, wanted, report):
    path = os.path.join(HERE, 'drops165.json')
    d = jload(path)
    mons = d['monsters']
    # remove the previous run's Prima additions (kept in the report of that run) so a rerun is exact
    prev = os.path.join(HERE, 'prima165_report.json')
    if os.path.exists(prev):
        for row in jload(prev).get('drops', []):
            m = mons.get(row['monster_key'])
            if m:
                m['items'] = [x for x in m['items'] if x[0] not in row['added']]
                if row.get('created') and not m['items']:
                    mons.pop(row['monster_key'], None)
                elif 'old_drop_count' in row:
                    m['drop_count'] = row['old_drop_count']
    keys = {k.lower(): k for k in mons}
    base_random = Counter()
    for tpl, ch in c.execute('select lower(l.TemplateName), l.Chance from LootTemplate l'):
        if ch is not None and 0 < ch < 100:
            base_random[tpl] += 1
    for mob, its in sorted(wanted.items()):
        key = keys.get(mob.lower())
        created = key is None
        if created:
            key = mob
            mons[key] = {'drop_count': 1, 'items': []}
        have = {x[0] for x in mons[key]['items']}
        added = []
        for iid, ch in sorted(its.items()):
            if iid not in have:
                mons[key]['items'].append([iid, ch])
                added.append(iid)
        if not added:
            if created:
                mons.pop(key)
            continue
        old = mons[key]['drop_count']
        # every random item rolls on its own; the cap must let them all through or the Atlas chances get cut
        need = base_random[mob.lower()] + sum(1 for iid in added if its[iid] < 100)
        mons[key]['drop_count'] = max(old, min(need, 12))
        report['drops'].append({'monster_key': key, 'added': added, 'created': created, 'old_drop_count': old,
                                'chances': {i: its[i] for i in added}})
    if DROPS_TAG not in d['source']:
        d['source'] += DROPS_TAG
    for folder in (HERE, RUNTIME):
        with open(os.path.join(folder, 'drops165.json'), 'w', encoding='utf-8') as out:
            json.dump(d, out, ensure_ascii=False, indent=1)
            out.write('\n')

# ------------------------------------------------------------------ difficulty: levels, aggression, speed
def monster_fixes(c, adds, report):
    sys.path.insert(0, PT)
    import guide_tables
    zones = []
    exp = {rid: e for rid, e in c.execute('select RegionID, Expansion from Regions')}
    for zid, rid, zname, ox, oy, w, h, realm in c.execute(
            'select ZoneID, RegionID, Name, OffsetX, OffsetY, Width, Height, Realm from Zones'):
        # Zones.Realm is 0 everywhere: the realm comes from the region number (1-99 Albion, 100-179 Midgard,
        # 180-299 Hibernia; the Shrouded Isles regions 51 / 151 / 181 and their dungeons follow the same split)
        realm = 1 if rid < 100 else 2 if rid < 180 else 3 if rid < 300 else 0
        zones.append({'id': zid, 'region': rid, 'name': zname, 'box': (ox * 8192, oy * 8192, (ox + w) * 8192, (oy + h) * 8192),
                      'realm': realm, 'expansion': exp.get(rid, 0)})
    def zone_of(region, x, y):
        for z in zones:
            if z['region'] == region and z['box'][0] <= x < z['box'][2] and z['box'][1] <= y < z['box'][3]:
                return z
        return None

    def abbreviates(part, word):
        if not word.startswith(part[0]):
            return False
        it = iter(word)
        return all(ch in it for ch in part)
    def zone_by_code(code):
        """Atlas appendix zone codes (SvE, LoD, FCG = frontier Cruachan Gorge, DKC = dungeon Koalinth Caverns)."""
        code = code.strip('.')
        tries = [code] + ([code[1:]] if code[:1] in 'FD' and len(code) > 2 else [])
        best = []
        for t in tries:
            parts = [p.lower() for p in re.findall(r'[A-Z][a-z]*', t)]
            for z in zones:
                if z['expansion'] != 0:
                    continue
                words = [w.lower() for w in re.findall(r"[A-Za-z']+", z['name']) if w.lower() not in ('of', 'the')]
                i, score = 0, 0
                for p in parts:
                    while i < len(words) and not abbreviates(p, words[i]):
                        i += 1
                    if i == len(words):
                        break
                    score += words[i].startswith(p)
                    i += 1
                else:
                    best.append((score, len(words) == len(parts), z))
            if best:
                break
        if not best:
            return None
        best.sort(key=lambda b: (-b[0], not b[1]))
        top = [b for b in best if b[:2] == best[0][:2]]
        return top[0][2] if len({b[2]['id'] for b in top}) == 1 else None
    def zone_by_name(name):
        k = n(name)
        hits = [z for z in zones if n(z['name']) == k]
        return hits[0] if hits else None

    # spawns: Mob rows (base or add-file) with zone; level-0 spawns use their NpcTemplate's level range
    tpl = {}
    for tid, tlv, tagg, tspd in c.execute('select TemplateId, Level, AggroLevel, MaxSpeed from NpcTemplate'):
        tpl[tid] = (tlv, tagg, tspd)
    # only monsters: never a merchant, smith, trainer, healer, stable master, guard, rift or any realm NPC (a guide
    # row "svartalf merchant, aggressive 80%" is a hostile monster, not a vendor of the same name)
    service = re.compile(r'(?i)merchant|smith|stable|trainer|healer|guard|vault|rift|teleport|emblem|enchanter|'
                         r'recharger|bank|crier|mage|lord|captain|innkeeper|courier|master')
    spawns = defaultdict(list)
    raid_classes = Counter()
    report['raid_monsters_not_changed'] = raid_classes
    for mid, name, region, x, y, lv, agg, spd, tid, realm_, ctype, brain in c.execute(
            'select Mob_ID, Name, Region, X, Y, Level, AggroLevel, Speed, NPCTemplateID, Realm, ClassType, Brain from Mob'):
        if (realm_ or 0) != 0 or (ctype and ctype != 'DOL.GS.GameNPC' and service.search(ctype.rsplit('.', 1)[-1])):
            continue
        # bosses, their adds, scripted mechanics and epic-dungeon monsters: listed, never changed (owner 2026-11-02)
        if protected_spawn(name or '', ctype, brain, region):
            raid_classes[ctype or name] += 1
            continue
        spawns[n(name)].append({'id': mid, 'region': region, 'zone': zone_of(region, x, y), 'level': lv,
                                'aggro': agg, 'speed': spd, 'tpl': tid})
    tpl_users = Counter(s['tpl'] for ss in spawns.values() for s in ss if s['tpl'])

    names = jload(os.path.join(PT, 'out', 'name_map.json'))
    rev = jload(os.path.join(PT, 'out', 'revised_tables.json'))
    ext = jload(os.path.join(PT, 'out', 'atlas_extra.json'))
    si = jload(os.path.join(PT, 'out', 'si_tables.json'))
    six = jload(os.path.join(PT, 'out', 'si_extra.json'))
    # the Revised guide's monster table is per realm chapter (Albion, Hibernia, Midgard, in book order)
    rtext = guide_tables.norm_text(open(os.path.join(CV, 'development-source', 'research', 'period-data', 'archive', 'prima',
                                    'Dark_Age_of_Camelot_Revised_and_Expanded_Prima_Official_eGuide.txt'),
                                    encoding='utf-8', errors='replace').read())
    marks = [m.start() for m in re.finditer(r'Monsters For more complete descriptions', rtext)]
    chapters, appendix = marks[:3], (marks[3] if len(marks) > 3 else len(rtext))
    def revised_realm(at):
        if at >= appendix:                           # the appendix table mixes the realms: not used for scope
            return None
        realm = None
        for r, pos in zip((1, 3, 2), chapters):      # 1 Albion, 3 Hibernia, 2 Midgard (book order)
            if at >= pos:
                realm = r
        return realm

    rows = []        # (priority, source, name, levels, aggro, speed, scope test)
    for r in ext['monster_stats']:
        zs = [zone_by_code(code) for code in re.split(r'[.,]', r['zones']) if code.strip()]
        zs = [z for z in zs if z]
        if zs:
            ids = {z['id'] for z in zs}
            rows.append((0, 'atlas appendix', r['name'], r['levels'], r.get('aggro_pct'), r.get('speed'),
                         lambda s, ids=ids: s['zone'] is not None and s['zone']['id'] in ids))
    for r in si['si_zone_monsters']:
        z = zone_by_name(r['zone'] or '')
        if z and r.get('levels'):
            rows.append((0, 'si zone', r['name'], r['levels'], None, None,
                         lambda s, zid=z['id']: s['zone'] is not None and s['zone']['id'] == zid))
    for r in six['dungeon_monsters']:
        if r.get('check'):
            continue
        regs = {z['region'] for z in zones if n(r['dungeon']) in n(z['name'])}
        if regs:
            rows.append((0, 'si dungeon', r['name'], r['levels'], None, None, lambda s, regs=regs: s['region'] in regs))
    for r in rev['monsters']:
        realm = revised_realm(r['at'])
        if realm:
            rows.append((1, 'revised', r['name'], r['levels'], r.get('aggro_pct'), r.get('speed'),
                         lambda s, realm=realm: s['zone'] is not None and s['zone']['realm'] == realm and s['zone']['expansion'] == 0))
    # second source: the period Allakhazam monster pages (levels, speed, habitats), realm-matched
    period = defaultdict(list)
    for p in jload(os.path.join(CV, 'development-source', 'research', 'period-data', 'TRUE 1.65 SPAWN AND DROP AUDIT 2026-10-31',
                                'data', 'period_mobs_parsed.json')):
        realm = {'Albion': 1, 'Midgard': 2, 'Hibernia': 3}.get(p.get('realm'))
        sp = p.get('speed')
        period[n(p.get('name'))].append({'realm': realm, 'min': p.get('min_level'), 'max': p.get('max_level'),
                                         'speed': int(sp) if str(sp or '').isdigit() else None})
    # the Prima books against each other: a name whose rows disagree is a generic name (Demon, Spider): held
    by_name = defaultdict(list)
    for prio, src, gname, glv, gagg, gspd, _ in rows:
        by_name[n((names.get(gname) or {}).get('db') or gname)].append((src, lv_range(glv), gagg, gspd))
    def prima_conflict(key, field):
        vals = {r[field] for r in by_name[key] if r[0] in ('revised', 'atlas appendix') and r[field] not in (None, (None, None))}
        return len(vals) > 1
    def second_prima_agrees(key, src, rng):
        return any(r[0] != src and r[1] == rng for r in by_name[key])
    def held(gname, s, field, why, extra=None):
        report['held'].append(dict({'monster': gname, 'spawn': s['id'], 'zone': s['zone']['name'] if s['zone'] else None,
                                    'field': field, 'why': why}, **(extra or {})))

    handled_level, handled_aggro, handled_speed = set(), set(), set()
    mob_sets, tpl_sets = defaultdict(dict), defaultdict(dict)
    for prio, src, gname, glv, gagg, gspd, in_scope in sorted(rows, key=lambda r: r[0]):
        db_name = (names.get(gname) or {}).get('db') or gname
        key = n(db_name)
        lo, hi = lv_range(glv)
        scope = [s for s in spawns.get(key, []) if in_scope(s)]
        level_conflict, aggro_conflict, speed_conflict = (prima_conflict(key, i) for i in (1, 2, 3))
        for s in scope:
            realm = s['zone']['realm'] if s['zone'] else 0
            pages = [p for p in period.get(key, []) if p['realm'] in (realm, None)]
            if lo is not None and s['id'] not in handled_level:
                handled_level.add(s['id'])
                cur = s['level']
                if cur == 0 and s['tpl'] in tpl:
                    tlo, thi = lv_range(tpl[s['tpl']][0])
                    if tlo is not None and (tlo < lo - 1 or thi > hi + 1):
                        if level_conflict:
                            held(gname, s, 'template level', 'the Prima books disagree on this name')
                        elif any(p['min'] is not None and p['min'] - 1 <= tlo and thi <= (p['max'] or 0) + 1 for p in pages):
                            held(gname, s, 'template level', 'kept: the period monster page covers it')
                        # the template only when every spawn using it is in this guide row's scope
                        elif all(in_scope(x) for x in spawns.get(key, []) if x['tpl'] == s['tpl']) and \
                                tpl_users[s['tpl']] == sum(1 for x in scope if x['tpl'] == s['tpl']):
                            tpl_sets[s['tpl']]['Level'] = f'{lo}-{hi}' if hi != lo else str(lo)
                        else:
                            held(gname, s, 'template level', 'shared NPC template', {'template': s['tpl']})
                elif cur and (cur < lo or cur > hi + (1 if hi > 5 else 0)):
                    new = max(lo, min(hi, cur))
                    if level_conflict:
                        held(gname, s, 'level', 'the Prima books disagree on this name', {'ours': cur, 'guide': glv})
                    elif any(p['min'] is not None and p['min'] - 1 <= cur <= (p['max'] or 0) + 1 for p in pages):
                        held(gname, s, 'level', 'kept: the period monster page covers this level', {'ours': cur, 'guide': glv})
                    elif pages or abs(new - cur) <= 5 or second_prima_agrees(key, src, (lo, hi)):
                        mob_sets[s['id']]['Level'] = new
                    else:
                        held(gname, s, 'level', 'big move, one source only', {'ours': cur, 'guide': glv})
            if gagg is not None and s['id'] not in handled_aggro:
                handled_aggro.add(s['id'])
                eff = tpl[s['tpl']][1] if s['aggro'] == 200 and s['tpl'] in tpl else s['aggro']
                if eff is None or eff == 200 or abs(eff - gagg) > 25:
                    if aggro_conflict:
                        held(gname, s, 'aggression', 'the Prima books disagree on this name', {'ours': eff, 'guide': gagg})
                    else:
                        mob_sets[s['id']]['AggroLevel'] = int(gagg)
            if gspd and s['id'] not in handled_speed:
                handled_speed.add(s['id'])
                if s['speed'] and abs(s['speed'] - gspd) > 40:
                    if speed_conflict:
                        held(gname, s, 'speed', 'the Prima books disagree on this name', {'ours': s['speed'], 'guide': gspd})
                    elif any(p['speed'] and abs(p['speed'] - s['speed']) <= 10 for p in pages):
                        held(gname, s, 'speed', 'kept: the period monster page has our speed', {'ours': s['speed'], 'guide': gspd})
                    else:
                        mob_sets[s['id']]['Speed'] = int(gspd)
        if scope and any(s['id'] in mob_sets for s in scope):
            report['monsters'].append({'monster': gname, 'source': src, 'guide': {'levels': glv, 'aggro': gagg, 'speed': gspd},
                                       'spawns_changed': sum(1 for s in scope if s['id'] in mob_sets)})
    updates, done = [], Counter()
    grouped = defaultdict(list)
    for mid, sets in mob_sets.items():
        if adds.set('Mob', mid, sets):
            done['spawn rows in add-files'] += 1
        else:
            grouped[tuple(sorted(sets.items()))].append(mid)
    for sets, ids in sorted(grouped.items()):
        for i in range(0, len(ids), 400):
            chunk = ids[i:i + 400]
            updates.append({'sql': f"UPDATE Mob SET {', '.join(f'{k} = {sql_val(v)}' for k, v in sets)} "
                                   f"WHERE Mob_ID IN ({','.join(sql_val(x) for x in chunk)})",
                            'reason': f"{MOB_TAG}: {', '.join(f'{k} {v}' for k, v in sets)} ({len(chunk)} spawns)"})
            done['spawn updates'] += len(chunk)
    for tid, sets in sorted(tpl_sets.items()):
        if adds.set('NpcTemplate', tid, sets):
            done['template rows in add-files'] += 1
        else:
            updates.append({'sql': f"UPDATE NpcTemplate SET {', '.join(f'{k} = {sql_val(v)}' for k, v in sets.items())} "
                                   f"WHERE TemplateId = {sql_val(tid)}",
                            'reason': f'{MOB_TAG} template level: {tid}'})
            done['template updates'] += 1
    return updates, done

def main(db):
    c = sqlite3.connect(f'file:{db}?mode=ro', uri=True)
    report = {'items': [], 'drops': [], 'monsters': [], 'held': []}
    BOSS_NAMES.update(scripted_boss_names())
    prev_path = os.path.join(HERE, 'prima165_report.json')
    prev = jload(prev_path).get('add_file_originals', {}) if os.path.exists(prev_path) else {}
    adds = AddFiles(HERE, prev)
    item_updates, item_done = item_fixes(c, adds, report)
    wanted = drop_fixes(c, report)
    mob_updates, mob_done = monster_fixes(c, adds, report)
    write_drops(c, wanted, report)
    adds.save()
    rules_path = os.path.join(HERE, 'true165-rules.json')
    rules = jload(rules_path)
    rules['updates'] = [u for u in rules['updates'] if not u['reason'].startswith((ITEM_TAG, MOB_TAG))]
    rules['updates'] += item_updates + mob_updates
    for folder in (HERE, RUNTIME):
        with open(os.path.join(folder, 'true165-rules.json'), 'w', encoding='utf-8') as out:
            json.dump(rules, out, ensure_ascii=False, indent=1)
            out.write('\n')
    # only rows still different from their pre-Prima values are remembered
    report['add_file_originals'] = {}
    for fk, fields in adds.originals.items():
        f, key = fk.split('|', 1)
        row = adds.docs[f]['rows'][adds.index[(adds.docs[f]['table'], key)][1]]
        diff = {k: v for k, v in fields.items() if row.get(k) != v}
        if diff:
            report['add_file_originals'][fk] = diff
    report['summary'] = {**item_done, **mob_done, 'drop monsters': len(report['drops']),
                         'drop items added': sum(len(r['added']) for r in report['drops']),
                         'monsters with new drops (created)': sum(1 for r in report['drops'] if r['created'])}
    with open(os.path.join(HERE, 'prima165_report.json'), 'w', encoding='utf-8') as out:
        json.dump(report, out, ensure_ascii=False, indent=1)
    print(json.dumps(report['summary'], indent=1))

if __name__ == '__main__':
    main(sys.argv[1])
