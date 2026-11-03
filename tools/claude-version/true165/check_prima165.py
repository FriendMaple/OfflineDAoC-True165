"""Checks a refreshed world against build_prima165.py's report (read only).

python -I check_prima165.py <refreshed world db> <the same world before the refresh>
"""
import json, os, re, sqlite3, sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_prima165 as B

def main(after, before):
    a = sqlite3.connect(f'file:{after}?mode=ro', uri=True)
    b = sqlite3.connect(f'file:{before}?mode=ro', uri=True)
    rep = B.jload(os.path.join(HERE, 'prima165_report.json'))
    rules = B.jload(os.path.join(HERE, 'true165-rules.json'))
    out = Counter()
    # copies identical
    for f in ('true165-rules.json', 'drops165.json'):
        out['copies identical' if open(os.path.join(HERE, f), 'rb').read() == open(os.path.join(B.RUNTIME, f), 'rb').read()
            else 'COPIES DIFFER ' + f] += 1
    # 1+2 items
    cols = [r[1] for r in a.execute('pragma table_info(ItemTemplate)')]
    for it in rep['items']:
        row = a.execute('select * from ItemTemplate where Id_nb=?', (it['item'],)).fetchone()
        if row is None:
            out['item missing in this world'] += 1
            continue
        d = dict(zip(cols, row))
        out['item ok' if all(d.get(k) == v for k, v in it['set'].items()) else 'ITEM WRONG'] += 1
    # 3+4 drops
    for dr in rep['drops']:
        for iid in dr['added']:
            r = a.execute('select Chance from LootTemplate where lower(TemplateName)=lower(?) and ItemTemplateID=?',
                          (dr['monster_key'], iid)).fetchone()
            out['drop ok' if r and r[0] == dr['chances'][iid] else ('drop present, other chance' if r else 'DROP MISSING')] += 1
        cap = a.execute('select max(DropCount) from MobXLootTemplate where lower(MobName)=lower(?)', (dr['monster_key'],)).fetchone()[0]
        out['drop cap ok' if cap is not None and cap >= 1 else 'DROP CAP MISSING'] += 1
    # difficulty: every Prima monster update and every add-file spawn row the pass edited
    for u in rules['updates']:
        if not u['reason'].startswith(B.MOB_TAG) or 'IN (' not in u['sql']:
            continue
        sets = dict((k, int(v)) for k, v in re.findall(r'(\w+) = (-?\d+)', u['sql'].split(' WHERE ')[0]))
        ids = re.findall(r"'([^']+)'", u['sql'].split('IN (')[1])
        for i in range(0, len(ids), 900):
            ch = ids[i:i + 900]
            got = a.execute(f"select {','.join(sets)} from Mob where Mob_ID in ({','.join('?' * len(ch))})", ch).fetchall()
            out['spawn rows not in this world'] += len(ch) - len(got)
            for row in got:
                out['spawn ok' if list(row) == list(sets.values()) else 'SPAWN WRONG'] += 1
    adds = B.AddFiles(HERE)
    for (table, key), (f, i) in adds.index.items():
        if table != 'Mob':
            continue
        row = adds.docs[f]['rows'][i]
        got = a.execute('select Level, AggroLevel, Speed from Mob where Mob_ID=?', (key,)).fetchone()
        if got and list(got) != [row.get('Level'), row.get('AggroLevel'), row.get('Speed')]:
            out['ADD-FILE SPAWN DIFFERS FROM ITS FILE'] += 1
    # protected spawns: same level / aggression / speed as before the refresh
    changed = 0
    for mid, name, ct, br, reg, lv, ag, sp in b.execute(
            'select Mob_ID, Name, ClassType, Brain, Region, Level, AggroLevel, Speed from Mob'):
        if not B.protected_spawn(name or '', ct, br, reg):
            continue
        now = a.execute('select Level, AggroLevel, Speed from Mob where Mob_ID=?', (mid,)).fetchone()
        if now and list(now) != [lv, ag, sp]:
            changed += 1
    out['protected spawns changed (must be 0)'] = changed
    out['quick_check'] = a.execute('pragma quick_check').fetchone()[0]
    for k, v in sorted(out.items()):
        print(f'{k:45s} {v}')

if __name__ == '__main__':
    B.BOSS_NAMES.update(B.scripted_boss_names())
    main(sys.argv[1], sys.argv[2])
