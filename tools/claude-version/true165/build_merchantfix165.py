"""True 1.65: merchant items stuck in another realm at a 30 copper placeholder price (player report 2026-11-03: "TNN
merchant sells animist staffs ... all staffs are 30 copper and when attempting to equip them it says not of this realm").

The base world data has copies of realm equipment ("..3" Id_nb: Hibernian staffs, blades, blunts, shields) carrying
Realm 2 (Midgard) and Price 30 instead of their realm and price; Hibernian merchants (Ewen in Tir na Nog, the staff
merchants of region 181...) sell them, so they cost 30 copper and can't be worn. Each copy has a correct twin: same
name, object type and level, of the merchant's realm, with a real price. The copy is set to the twin's realm, price,
DPS/AF and speed/absorb (the shield copies also had speed 0). Bonuses are the same set (only their order differs).

python -I build_merchantfix165.py      (rerunnable: reads the pre-Prima 1.65 world, which still has the bad rows)
Out (both copies): true165-rules.json updates tagged "True 1.65 merchant item"; merchantfix165_report.json.
"""
import collections, json, os, sqlite3

HERE = os.path.dirname(os.path.abspath(__file__))
CV = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
RUNTIME = os.path.join(CV, 'runtime', 'true165')
BASE = os.path.join(CV, 'development-source', 'research', 'period-data', 'prima-tools', 'work', 'world_before_prima.db')
TAG = 'True 1.65 merchant item'
GEAR = set(range(1, 29)) | set(range(31, 39)) | {41, 42, 45}

def q(v):
    return "'" + str(v).replace("'", "''") + "'"

def main():
    c = sqlite3.connect(f'file:{BASE}?mode=ro', uri=True)
    sold = collections.defaultdict(set)
    for realm, iid in c.execute("select m.Realm, mi.ItemTemplateID from Mob m join MerchantItem mi on mi.ItemListID = "
                                "m.ItemsListTemplateID where m.Realm in (1, 2, 3) and m.ItemsListTemplateID <> ''"):
        sold[iid].add(realm)
    updates, report, skipped = [], [], []
    for iid in sorted(sold):
        realms = sold[iid]
        t = c.execute('select Id_nb, Name, Level, Object_Type, Item_Type, Realm, Price, DPS_AF, SPD_ABS from ItemTemplate '
                      'where Id_nb = ?', (iid,)).fetchone()
        if not t or t[6] != 30 or t[5] == 0 or t[5] in realms or t[3] not in GEAR:
            continue
        if len(realms) != 1:
            skipped.append({'item': iid, 'why': f'sold in several realms {sorted(realms)}'})
            continue
        realm = next(iter(realms))
        twins = c.execute('select Id_nb, Price, DPS_AF, SPD_ABS from ItemTemplate where Name = ? and Object_Type = ? and '
                          'Level = ? and Realm = ? and Price > 30 and Id_nb <> ? order by (DPS_AF = ?) desc, length(Id_nb), Id_nb',
                          (t[1], t[3], t[2], realm, iid, t[7])).fetchall()
        if not twins:
            skipped.append({'item': iid, 'why': 'no twin of the merchant realm'})
            continue
        tw = twins[0]
        updates.append({'sql': f"UPDATE ItemTemplate SET Realm = {realm}, Price = {tw[1]}, DPS_AF = {tw[2]}, SPD_ABS = {tw[3]} "
                               f"WHERE Id_nb = {q(iid)} AND Realm = {t[5]} AND Price = 30",
                        'reason': f'{TAG}: {t[1]} ({iid}) sold by realm {realm} merchants had realm {t[5]} and 30 copper; '
                                  f'as its twin {tw[0]}'})
        report.append({'item': iid, 'name': t[1], 'from_realm': t[5], 'realm': realm, 'price': tw[1], 'twin': tw[0],
                       'dps_af': [t[7], tw[2]], 'spd_abs': [t[8], tw[3]]})
    for folder in (HERE, RUNTIME):
        p = os.path.join(folder, 'true165-rules.json')
        rules = json.load(open(p, encoding='utf-8'))
        rules['updates'] = [u for u in rules['updates'] if not u['reason'].startswith(TAG)] + updates
        with open(p, 'w', encoding='utf-8') as f:
            json.dump(rules, f, ensure_ascii=False, indent=1)
            f.write('\n')
    with open(os.path.join(HERE, 'merchantfix165_report.json'), 'w', encoding='utf-8') as f:
        json.dump({'fixed': report, 'skipped': skipped}, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(f'fixed {len(report)}, skipped {len(skipped)}: {[s["item"] for s in skipped]}')

if __name__ == '__main__':
    main()
