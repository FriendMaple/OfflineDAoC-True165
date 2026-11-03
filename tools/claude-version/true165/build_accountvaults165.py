"""True 1.65: account vault keepers, a quality-of-life exception to 1.65 (owner 2026-11-03: "it would be an exception to
1.65 for qol to trade items between alts for each realm (separate per realm) there were already account vault keepers
and their locations in old server").

The server's AccountVaultKeeper keeps one vault per account AND realm (owner id "<account>_<realm>"), so alts of one
realm share it and the realms stay apart. The old (normal-mode) server had 13 keepers; the ones in True 1.65 regions come
back at their old spots in the three capitals only (owner: "just do the 3 capital cities for each realm"): Virsha in
Camelot City, Janash in Jordheim, Giorny in Tir na Nog. The others (Castle Sauvage, Atlantis, New Frontiers, the event
zones, the tutorial) stay out.

python -I build_accountvaults165.py      (rerunnable)
In: the normal-mode world (normal-mode-archive/data/opendaoc.sqlite3.db).
Out (both copies): add-accountvaults165.json (the three keepers); true165-rules.json: the class-wide removal of account
vault keepers becomes a removal of the ones outside the capitals (a fresh 1.65 world keeps the three from the base).
"""
import json, os, sqlite3

HERE = os.path.dirname(os.path.abspath(__file__))
CV = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
RUNTIME = os.path.join(CV, 'runtime', 'true165')
NORMAL = os.path.join(CV, 'normal-mode-archive', 'data', 'opendaoc.sqlite3.db')
CLASS = 'DOL.GS.AccountVaultKeeper'
REGIONS = (10, 101, 201)             # Camelot City, Jordheim, Tir na Nog
REASON = 'True 1.65 account vault'

def main():
    c = sqlite3.connect(f'file:{NORMAL}?mode=ro', uri=True)
    c.row_factory = sqlite3.Row
    rows = [dict(r) for r in c.execute(f"select * from Mob where ClassType = ? and Region in ({','.join('?' * len(REGIONS))}) "
                                       "order by Region, Name", (CLASS, *REGIONS))]
    assert len(rows) == 3, f'expected 3 keepers, found {len(rows)}'
    doc = {'table': 'Mob', 'key': 'Mob_ID',
           'reason': f'{REASON}: account vault keepers at their old spots (quality-of-life exception, owner 2026-11-03)',
           'rows': rows}
    for folder in (HERE, RUNTIME):
        with open(os.path.join(folder, 'add-accountvaults165.json'), 'w', encoding='utf-8') as f:
            json.dump(doc, f, ensure_ascii=False, indent=1)
            f.write('\n')
        p = os.path.join(folder, 'true165-rules.json')
        rules = json.load(open(p, encoding='utf-8'))
        rules['remove']['mob_classes'].pop(CLASS, None)
        where = [w for w in rules['remove']['where'] if not w['reason'].startswith(REASON)]
        where.append({'table': 'Mob', 'key': 'Mob_ID',
                      'where': f"ClassType = '{CLASS}' AND Region NOT IN ({', '.join(map(str, REGIONS))})",
                      'reason': f'{REASON}: only the three capitals have one (owner 2026-11-03); the others (Castle Sauvage, '
                                f'Atlantis, New Frontiers, event zones, tutorial) stay out'})
        rules['remove']['where'] = where
        with open(p, 'w', encoding='utf-8') as f:
            json.dump(rules, f, ensure_ascii=False, indent=1)
            f.write('\n')
    print('keepers:', [(r['Name'], r['Region'], r['X'], r['Y']) for r in rows])

if __name__ == '__main__':
    main()
