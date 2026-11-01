using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using System.Runtime.CompilerServices;
using DOL.GS;
using DOL.GS.ServerProperties;
using NUnit.Framework;

namespace DOL.UnitTests
{
    // Owner 2026-10-31 audit fixes: True 1.65 coin comes per monster (most animals, insects, plants carried none), and a
    // day/night spawn saved while asleep must not store its asleep flags (night ghosts that could never be fought).
    [TestFixture]
    public class UT_True165CoinAndNightFlags
    {
        private bool _mode;

        private sealed class Mob : GameNPC
        {
            public override byte Level { get; set; }
            public override int X => 0;
            public override int Y => 0;
            public override int Z => 0;
        }

        private sealed class SleepingGhost : NightSpawn
        {
            public eFlags Saved => FlagsToSave;
        }

        [SetUp]
        public void Save()
        {
            _mode = Properties.CLASSIC165_MODE;
            Coin165.SetForTests(new Dictionary<string, int> { ["adder"] = 0, ["abominable snowman"] = 98, ["abysmal"] = 101 },
                new Dictionary<string, int> { ["Animal"] = 37, ["Humanoid"] = 81 });
        }

        [TearDown]
        public void Restore()
        {
            Properties.CLASSIC165_MODE = _mode;
            Coin165.SetForTests(null, null);
        }

        // Built without the constructor (it needs a running server), like the other loot tests.
        private static T Inert<T>() where T : GameNPC
        {
            T npc = (T)RuntimeHelpers.GetUninitializedObject(typeof(T));
            typeof(GameLiving).GetField("<TempProperties>k__BackingField", BindingFlags.Instance | BindingFlags.NonPublic)
                .SetValue(npc, new PropertyCollection());
            typeof(GameNPC).GetField("m_brains", BindingFlags.Instance | BindingFlags.NonPublic).SetValue(npc, new ArrayList());
            return npc;
        }

        private static Mob Make(string name, NpcTemplateMgr.eBodyType body)
        {
            Mob mob = Inert<Mob>();
            mob.Name = name;
            mob.BodyType = (ushort)body;
            return mob;
        }

        [Test]
        public void MeasuredMonstersUseTheirOwnRate()
        {
            Properties.CLASSIC165_MODE = true;
            Assert.Multiple(() =>
            {
                Assert.That(Coin165.ChanceFor(Make("adder", NpcTemplateMgr.eBodyType.Animal)), Is.EqualTo(0));
                Assert.That(Coin165.ChanceFor(Make("Abominable Snowman", NpcTemplateMgr.eBodyType.Giant)), Is.EqualTo(98));
                Assert.That(Coin165.ChanceFor(Make("abysmal", NpcTemplateMgr.eBodyType.Demon)), Is.EqualTo(100), "capped at 100");
            });
        }

        [Test]
        public void OtherMonstersUseTheirBodyTypeAverage()
        {
            Properties.CLASSIC165_MODE = true;
            Assert.Multiple(() =>
            {
                Assert.That(Coin165.ChanceFor(Make("forest wolf", NpcTemplateMgr.eBodyType.Animal)), Is.EqualTo(37));
                Assert.That(Coin165.ChanceFor(Make("bandit", NpcTemplateMgr.eBodyType.Humanoid)), Is.EqualTo(81));
                Assert.That(Coin165.ChanceFor(Make("odd thing", NpcTemplateMgr.eBodyType.Plant)), Is.EqualTo(100), "no average known: coin as before");
            });
        }

        [Test]
        public void NormalModeAndMissingDataKeepCoinOnEveryKill()
        {
            Properties.CLASSIC165_MODE = false;
            Assert.That(Coin165.ChanceFor(Make("adder", NpcTemplateMgr.eBodyType.Animal)), Is.EqualTo(100));
            Properties.CLASSIC165_MODE = true;
            Coin165.SetForTests(null, new Dictionary<string, int>());
            Assert.That(Coin165.ChanceFor(Make("adder", NpcTemplateMgr.eBodyType.Animal)), Is.EqualTo(100));
        }

        [Test]
        public void SleepingNightSpawnSavesItsOwnFlagsOnly()
        {
            SleepingGhost ghost = Inert<SleepingGhost>();   // no brain yet = asleep
            typeof(GameNPC).GetField("m_flags", BindingFlags.Instance | BindingFlags.NonPublic).SetValue(ghost, GameNPC.eFlags.GHOST);
            Assert.Multiple(() =>
            {
                Assert.That(ghost.Flags.HasFlag(GameNPC.eFlags.PEACE), Is.True, "asleep: shown peaceful");
                Assert.That(ghost.Flags.HasFlag(GameNPC.eFlags.CANTTARGET), Is.True);
                Assert.That(ghost.Saved, Is.EqualTo(GameNPC.eFlags.GHOST), "saved without the asleep flags");
            });
        }
    }
}
