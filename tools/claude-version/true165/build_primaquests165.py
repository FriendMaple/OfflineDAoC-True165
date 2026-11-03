"""True 1.65: the classic quests the Prima guides list that the server lacked (owner 2026-11-02: "add these into the
fixes ... any new quests are 100% completable and up to the standards of the current ones"). Writes content and the
server's quest config; never touches a database.

python -I build_primaquests165.py

In: the sandbox run of the classic quest pipeline on the new specs (research/period-data/prima-tools/questbuild:
resolve_specs -> plan_spawns -> gen_dataquests against the True 1.65 world; specs in prima-tools/questbuild_specs).
Out (both copies of the content files):
  add-primaquests165.json      DataQuest rows (ids after the last classic quest id)
  add-primaquestitems165.json  the quest items and the reward items (reward stats: Prima Revised 2002 + the period
                               Allakhazam item pages, levels by the period pages' "Level to Attain" like the others)
  true165-rules.json updates   "True 1.65 Prima quest": Rhian's Dyes back to its 1.65 self, Tyree's Dyes (Tyree, Howth)
  runtime/server/classic-quests.json        markers and quest monsters of the new quests; Tyree's turn-in marker
  runtime/server/classic-quest-guides.json  a short guide per quest, written from the specs (not copied page text)
"""
import datetime, json, os, re, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
CV = os.path.normpath(os.path.join(HERE, '..', '..', '..'))
RUNTIME = os.path.join(CV, 'runtime', 'true165')
SERVER = os.path.join(CV, 'runtime', 'server')
PT = os.path.join(CV, 'development-source', 'research', 'period-data', 'prima-tools')
QB = os.path.join(PT, 'questbuild')
TAG = 'True 1.65 Prima quest'
NOW = '2026-11-02 21:00:00'

def jload(p):
    return json.load(open(p, encoding='utf-8'))

def jsave(obj, p, indent=1):
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=indent)
        f.write('\n')

def save_server_json(obj, p, indent, ascii_only):
    """The server's quest files keep their own format (CRLF, no final newline) so a change shows as only its lines."""
    text = json.dumps(obj, ensure_ascii=ascii_only, indent=indent).replace('\n', '\r\n')
    with open(p, 'wb') as f:
        f.write(text.encode('utf-8'))

# period numbers that override the generator's automatic values (the spec rule: a recorded number wins)
XP_OVERRIDE = {'Missing Bard': 10000000}      # Allakhazam (Wayback 2004-10): "around 10 million exp" at level 43

def base_item(iid, name, level, item_type, realm, model, weight, bonus, quality, props, quest, **extra):
    row = dict(Id_nb=iid, Name=name, Level=level, Durability=50000, MaxDurability=50000, Condition=50000,
               MaxCondition=50000, Quality=quality, DPS_AF=0, SPD_ABS=0, Hand=0, Type_Damage=0, Object_Type=41,
               Item_Type=item_type, Weight=weight, Bonus=bonus, BonusLevel=0, Realm=realm, AllowedClasses='0',
               IsPickable=1, IsDropable=1, CanDropAsLoot=0, IsTradable=0, Price=0, MaxCount=1, PackSize=1, Color=0,
               Extension=0, Model=model, PackageID='ClassicQuest', Description=f'Classic quest reward ({quest})')
    for i, (pid, val) in enumerate(props, 1):
        row[f'Bonus{i}Type'], row[f'Bonus{i}'] = pid, val
    row.update(extra)
    return row

# Reward items. eProperty: 1 Str, 6 Pie, 9 Power, 10 Hits, 75 Large Weaponry. Weight is in tenths of a pound.
REWARDS = [
    # Prima: Str +4; HP +6, PL 12, Q 100. Period page 2003-09: neck, level to attain 11, default bonus 1%, 2.40 lbs.
    base_item('cq_mid_berserker_strength_necklace', 'Berserker Strength Necklace', 11, 29, 2, 101, 24, 1, 100,
              [(1, 4), (10, 6)], "Rasczel's Bane"),
    # Prima: Pie +6; Power +4; HP +9, PL 38, Q 100 (no period item page; weight and bonus % not recorded).
    base_item('cq_mid_luminescent_choker', 'Luminescent Choker', 38, 29, 2, 101, 3, 0, 100,
              [(6, 6), (9, 4), (10, 9)], 'Big Paw'),
    # Prima: HP +6, PL 6, Q 100. Period page 2003-09: waist, level to attain 3, default bonus 0%, 0.30 lbs.
    base_item('cq_mid_ghoul_hair_belt', 'Ghoul Hair Belt', 3, 32, 2, 597, 3, 0, 100, [(10, 6)], 'Ghoul Hair Belt'),
    # Prima: +20%; Large Weaponry +5; Str +9, PL 39, O8, Q 100, 4.3 speed, 55 damage, 12.9 DPS, slash, two-handed.
    base_item('cq_hib_imbedded_greatsword', 'Imbedded Greatsword', 39, 12, 3, 448, 55, 20, 100,
              [(75, 5), (1, 9)], 'Missing Bard', Object_Type=22, Hand=1, Type_Damage=2, DPS_AF=129, SPD_ABS=43),
]

TIPS = 'Tips from period players:'

GUIDES = {
    "Rasczel's Bane": ("Midgard", 11, "Warcry quest 100 (2001-12, 2004-11); Prima Revised (2002)", [
        "The level 11 quest of the Berserker trainer in Jordheim (Skalds get the same errand as Rasczel's Nose). You must have finished Traveler's Way.",
        "A hobyah bit the nose off the trainer's dog. Find the hobyah leader Rasczel west of Fort Veldon in the Vale of Mularn; the hobyahs come out at night.",
        "Rasczel does not always drop his nose; keep hunting the hobyahs there until you have Rasczel's Nose.",
        "Bring the nose back to your trainer for the Berserker Strength Necklace.",
        " ", TIPS,
        "- Rasczel is immediately west of Fort Veldon, just down the hill, around loc 39222, 10362 (Warcry, 2004).",
        "- He conned yellow to a level 12 (Warcry, 2004): bring a friend if you are just 11."]),
    "Bear Skins": ("Midgard", 1, "Warcry quest 187 (2001-12, 2004-10); Prima Revised (2002)", [
        "Helen in Haggerfel wants the hide of a mauler cub.",
        "Kill a black mauler cub outside Haggerfel and take its small mauler skin.",
        "Return the skin to Helen for a silver piece and a little experience."]),
    "Big Paw": ("Midgard", 38, "Prima Revised (2002); Warcry quest 354 (2001-12)", [
        "Finna in Fort Atla (Gotar) tells of Big Paw, a great bear who rules Skona Ravine.",
        "Big Paw roams west of Varulvhamn in Skona Ravine. Slay him to finish the quest.",
        "Reward: the Luminescent Choker."]),
    "Trapper's Joy": ("Midgard", 3, "Warcry quest 798 (2004-07); Prima Revised (2002)", [
        "For Seers and Vikings at level 3, after Trapper's Pride. Your trainer in Galplen sends you back to the trapper Wariel.",
        "Wariel gives you a treated pelt to sell.",
        "Take the pelt to Kaiti, next to the dye merchants in Galplen, for three silver and some experience."]),
    "Ghoul Hair Belt": ("Midgard", 5, "Allakhazam quest 22 (archived 2004-10); Prima Revised (2002)", [
        "Lefur in Audliten can make a magical belt from ghoul hair.",
        "Wayward ghouls walk north of Audliten at night. Kill one for a patch of decayed hair.",
        "Give the hair to Lefur for the Ghoul Hair Belt.",
        " ", TIPS,
        "- Not every ghoul drops hair: players reported about one in two or three (2001).",
        "- Ghouls that con grey to you never drop it, so do this at level 5 or 6 (2001).",
        "- Besides the hill north of Audliten, players found many wayward ghouls on the hill northwest of the Galplen stable (2001-12).",
        "- Lefur makes one belt per character (2001-11)."]),
    "Missing Bard": ("Hibernia", 43, "Allakhazam quest 2044 (archived 2004-10); Prima Revised (2002)", [
        "Illaliel in Ardagh is worried about the bard O'Rourke. Ask Maire on the north shore by the Connla bridge.",
        "Find O'Rourke in the ollipheist valley of Shannon Estuary (around 21k, 58k).",
        "He lost his flute to Arracht, a named ollipheist that wanders that valley. Slay Arracht and take the flute.",
        "Give the flute to Maire in Connla, then return to Illaliel in Ardagh and tell her O'Rourke is fine.",
        "Champions receive the Imbedded Greatsword.",
        " ", TIPS,
        "- Illaliel offers it from level 43: players of 39 to 42 were turned away, a 43 got it (2004)."]),
    "Tyree's Dyes": ("Hibernia", 11, "Allakhazam quest 74 (updated 2003-06, archived 2004-10); Warcry quest 140 (2004-07); Prima Revised (2002)", [
        "Tyree in Howth is running low on dyes and needs three components.",
        "A badger scent gland and the hair of a wild lucradan: both along the road south of Mag Mell.",
        "The eyes of a large eirebug: south of Howth across the stepping stones along the shore.",
        "Bring the components back to Tyree in Howth.",
        " ", TIPS,
        "- The stepping stones: follow the river in front of the Howth gates south until you see about eight stones in the water; that is the 'bridge' (Warcry, 2004).",
        "- Tyree offers the quest when you speak with him or sell him loot (Warcry, 2004)."]),
    "Growler Mace": ("Albion", 13, "Allakhazam quest 135 player notes (2001-11 to 2003-12, archived 2004-09), Allakhazam quest 2580; Prima Revised (2002)", [
        "For Fighters and Clerics of level 13 who finished The Growling Ghost by slaying Growler instead of helping him. Not offered if you took Growler's Necklace: the two paths both end with the same mace, The Growler.",
        "1. Sergeant Alain, south of the Camelot Hills bridge, wants the shipment of etched rods. Kill the bandit Cyfwlch Difwych at his camp on the road to Castle Sauvage (around 50043, 12549) for it.",
        "2. Take the rods to Beria, apprentice smith, in West Downs (Salisbury Plains). Mind her full name: she is listed as 'Beria, apprentice smith'.",
        "3. Beria sends her work on to Contyth, Apprentice Smith, in Humberton (Black Mountains South).",
        "4. Contyth sends you to his father Mathien at Snowdonia Station (Black Mountains North). Mathien stands by the bind stone, at the side of the building.",
        "5. Mathien needs metal first: accept Mathien's Metal from him and finish it (slay Erick Redbeard, then speak to Mathien).",
        "6. Then he wants a hunk of ore to finish the mace. The ghost miners walk the hill northwest of Snowdonia Station, below Swanton Keep; not every miner has ore.",
        "7. Bring the ore to Mathien.",
        "8. Mathien sends you to the Guards' Armorer in Swanton Keep, north of Snowdonia Station.",
        "9. Return to Mathien for the Growler mace.",
        " ", TIPS,
        "- 'Killing Growler gets you a tedious 11 step quest' (2002-01): set aside an evening.",
        "- Cyfwlch has look-alike brothers at the other bandit camps on that road (Cefwlch, Dlyfwlch...). Only the exact name counts (2002).",
        "- Cyfwlch conned blue at level 13 and brought two friends, a bandit thaumaturge and a bandit (later walkthrough).",
        "- In the period the ghost miners came out only at night; here they stand on that hill all day.",
        "- A level 13 player earned about three to four bubbles of experience over the whole quest (later walkthrough)."]),
    "Mathien's Metal": ("Albion", 13, "Allakhazam quest 135 player notes (2001-11, 2001-12, 2002-01, archived 2004-09); Prima Revised (2002)", [
        "Mathien at Snowdonia Station offers this while you do Growler Mace, after The Growling Ghost.",
        "1. The trader Erick Redbeard stands with a camp of red dwarf matrons in the vale due west of Snowdonia Station, around 27041, 40323. Slay him.",
        "2. Return to Mathien at Snowdonia Station. Growler Mace then continues with him.",
        " ", TIPS,
        "- Way there: due west of Snowdonia Station there is a rise with a ridge running west, a deep vale on the left and a wide shallow hollow on the right. Erick is in the vale on the left; you can usually see him from the ridge (2001-12).",
        "- A red dwarf matron is linked to Erick, and both conned yellow at level 13: pull carefully (later walkthrough).",
        "- In the period Erick and the matrons spawned only at night (6 PM game time, 2002-01); here they are there all day."]),
}

# The Growling Ghost and Growler's Necklace keep their period walkthrough (archived Allakhazam text); these lines
# say how the two branches work on this server. Lines starting with BRANCH are replaced on every run.
BRANCH = 'On this server:'
BRANCH_NOTES = {
    "albion|the growling ghost": [
        " ", BRANCH,
        "- Speak with Growler first: killing him before you have spoken with him does not count.",
        "- Help him (Growler's Necklace, offered by Growler while you do this quest) and he rewards you with The Growler. Or simply slay him and return his skull for experience; Sergeant Alain then offers Growler Mace, the long way to the same weapon.",
        "- Either way his skull goes back to Sergeant Alain to finish this quest."],
    "albion|growler's necklace": [
        " ", BRANCH,
        "- Growler offers this only while you are doing The Growling Ghost. It rewards The Growler; the skull from his bones still goes to Sergeant Alain.",
        "- Taking it closes the other path (Growler Mace)."],
}

BRANCHES = {   # classic-quests.json branch rules (ClassicQuests.QuestInfo.OnlyDuring / ExcludedBy)
    "Growler's Necklace": {'OnlyDuring': ['The Growling Ghost']},
    'Growler Mace': {'ExcludedBy': ["Growler's Necklace"]},
    "Mathien's Metal": {'OnlyDuring': ['Growler Mace']},
}
BASE_ROWS = {20213, 20216}          # base-world quests regenerated in place: rules updates, not add rows
KEEP_XP = {20213: (88000, [0.0, 0.0, 0.11]), 20216: (88000, [0.0, 0.0, 0.11])}   # their XP as before

def sql_value(v):
    if v is None:
        return 'NULL'
    if isinstance(v, (int, float)):
        return str(v)
    return "'" + str(v).replace("'", "''") + "'"

def main():
    preview = jload(os.path.join(QB, 'dataquest_preview.json'))
    config_new = jload(os.path.join(QB, 'classic-quests.preview.json'))
    rows, base_rows = [], []
    for r in preview['rows']:
        row = {k: v for k, v in r.items() if not k.startswith('_') and k not in ('src', 'realm')}
        if row['Name'] in XP_OVERRIDE:
            xp = row['RewardXP'].split('|')
            xp[-1] = str(XP_OVERRIDE[row['Name']])
            row['RewardXP'] = '|'.join(xp)
        if row['ID'] in KEEP_XP:
            xp = row['RewardXP'].split('|')
            xp[-1] = str(KEEP_XP[row['ID']][0])
            row['RewardXP'] = '|'.join(xp)
        row['LastTimeRowUpdated'] = NOW
        (base_rows if row['ID'] in BASE_ROWS else rows).append(row)
    assert {r['ID'] for r in base_rows} == BASE_ROWS, 'the Growler quests must keep their ids'
    quest_doc = {'table': 'DataQuest', 'key': 'ID',
                 'reason': 'True 1.65 Prima quests: classic quests the Prima guides list that the server lacked (2026-11-02)',
                 'rows': rows}
    # already on the server: Rasczel's Nose, and the items of The Growling Ghost
    existing_items = {'cq_rasczel_s_nose', 'cq_growler_s_necklace', 'cq_growler_s_skull'}
    items = [{k: v for k, v in r.items() if k != 'donor'} for r in preview['item_rows'] if r['Id_nb'] not in existing_items]
    for r in items:
        r['Description'] = 'Classic quest item'
    item_doc = {'table': 'ItemTemplate', 'key': 'Id_nb',
                'reason': 'True 1.65 Prima quests: quest items and rewards (Prima Revised 2002 + period item pages)',
                'rows': items + REWARDS}
    for folder in (HERE, RUNTIME):
        jsave(quest_doc, os.path.join(folder, 'add-primaquests165.json'))
        jsave(item_doc, os.path.join(folder, 'add-primaquestitems165.json'))

    # Tyree's Dyes: the 1.65 quest (renamed Rhian's Dyes later, moved to Tir na mBeo); keeps id 20304
    rules = jload(os.path.join(HERE, 'true165-rules.json'))
    rules['updates'] = [u for u in rules['updates'] if not u['reason'].startswith(TAG)]
    rules['updates'].append({
        'sql': "UPDATE DataQuest SET Name = 'Tyree''s Dyes', StartName = 'Tyree', StartRegionID = 200, "
               "StepText = 'Get a badger scent gland along the road south from Mag Mell.|Get hair from a wild lucradan.|"
               "Get the third component from a large eirebug.|Return to Tyree in Howth.', "
               "TargetName = 'badger;200|wild lucradan;200|large eirebug;200|Tyree;200' WHERE ID = 20304",
        'reason': f"{TAG}: Tyree's Dyes is the 1.65 name and giver (Tyree in Howth; Allakhazam 2003-06, Warcry 2004-07, "
                  f"Prima 2002); Rhian's Dyes in Tir na mBeo is a later change"})
    # The Growling Ghost branches (owner 2026-11-03 "do this one"): help Growler (Growler's Necklace, The Growler) or
    # slay him (experience, then Growler Mace and Mathien's Metal for the same weapon). First move anyone midway
    # through the old five-step Growling Ghost onto the matching new step (only while the row is still the old one,
    # so a second content refresh changes nothing): Cyfwlch / necklace / slay Growler -> slay Growler; skull -> skull.
    rules['updates'].append({
        'sql': "UPDATE CharacterXDataQuest SET Step = CASE WHEN Step IN (2, 3, 4) THEN 2 WHEN Step >= 5 THEN 3 ELSE Step END "
               "WHERE DataQuestID = 20216 AND Step > 1 AND (SELECT StepType FROM DataQuest WHERE ID = 20216) = '4|0|2|0|3'",
        'reason': f"{TAG}: players midway through the old five-step Growling Ghost keep their place in the new three steps"})
    for row in sorted(base_rows, key=lambda r: r['ID']):
        sets = ', '.join(f'{k} = {sql_value(v)}' for k, v in row.items() if k != 'ID')
        rules['updates'].append({
            'sql': f"UPDATE DataQuest SET {sets} WHERE ID = {row['ID']}",
            'reason': f"{TAG}: {row['Name']}, the help-or-slay branches of Growler (Warcry quest 65 2001-12: Reward "
                      f"Experience, Subquest Reward The Growler; Allakhazam 135 notes 2001-11 to 2002-04; Prima 2002)"})
    for folder in (HERE, RUNTIME):
        jsave(rules, os.path.join(folder, 'true165-rules.json'))

    # the server's quest config: back up, then merge (rerunnable: the Prima quest ids are replaced)
    stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
    cq_path = os.path.join(SERVER, 'classic-quests.json')
    shutil.copy2(cq_path, os.path.join(SERVER, f'classic-quests.before-prima-quests-{stamp}.json'))
    cq = jload(cq_path)
    new_ids = {str(r['ID']) for r in rows}
    for qid in new_ids | {str(i) for i in BASE_ROWS}:
        cq['Quests'][qid] = config_new['Quests'][qid]
    for i, (_, shares) in KEEP_XP.items():
        cq['Quests'][str(i)]['XpShares'] = shares
    for r in rows + base_rows:
        for k, v in BRANCHES.get(r['Name'], {}).items():
            cq['Quests'][str(r['ID'])][k] = v
    mons = set(cq['QuestMonsterIds']) | set(config_new.get('QuestMonsterIds', []))
    cq['QuestMonsterIds'] = sorted(mons)
    tyree = cq['Quests']['20304']['Steps']
    tyree[-1] = {'Marker': {'Region': 200, 'X': 342704, 'Y': 591651, 'Z': 5456}}       # Tyree's spawn in Howth
    save_server_json(cq, cq_path, 1, True)

    g_path = os.path.join(SERVER, 'classic-quest-guides.json')
    shutil.copy2(g_path, os.path.join(SERVER, f'classic-quest-guides.before-prima-quests-{stamp}.json'))
    g = jload(g_path)
    g['Guides'].pop("hibernia|rhian's dyes", None)
    for name, (realm, level, source, lines) in GUIDES.items():
        g['Guides'][f'{realm.lower()}|{name.lower()}'] = {
            'Name': name, 'Realm': realm, 'Source': f'Written from the period sources: {source}',
            'Updated': '2026-11-03' if name in ('Growler Mace', "Mathien's Metal") or TIPS in lines else '2026-11-02',
            'Level': level, 'Lines': lines}
    for key, notes in BRANCH_NOTES.items():
        lines = g['Guides'][key]['Lines']
        if BRANCH in lines:
            del lines[lines.index(BRANCH) - 1:]
        lines.extend(notes)
    save_server_json(g, g_path, 0, False)
    print(f'quests {len(rows)} (ids {min(map(int, new_ids))}-{max(map(int, new_ids))}) + {len(base_rows)} regenerated in '
          f'place, items {len(items)} + rewards {len(REWARDS)}, config quests {len(cq["Quests"])}, guides {len(g["Guides"])}')

if __name__ == '__main__':
    main()
