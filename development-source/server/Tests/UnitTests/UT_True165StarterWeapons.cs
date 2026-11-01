using DOL.Database;
using DOL.GS;
using NUnit.Framework;

namespace DOL.UnitTests
{
    // True 1.65 (owner 2026-10-31): bots and hired companions carry only their class's starting weapon, in its own hand,
    // until they find an upgrade; never a generated ROG weapon, never a second copy in the off hand.
    [TestFixture]
    public class UT_True165StarterWeapons
    {
        [Test]
        public void StarterWeaponGoesInItsOwnHandOnly()
        {
            var staff = new DbItemTemplate { Item_Type = Slot.TWOHAND };
            var sword = new DbItemTemplate { Item_Type = Slot.RIGHTHAND };
            var dirk = new DbItemTemplate { Item_Type = Slot.LEFTHAND };
            var bow = new DbItemTemplate { Item_Type = Slot.RANGED };
            Assert.Multiple(() =>
            {
                Assert.That(GameBot.StarterFitsSlot165(staff, eInventorySlot.TwoHandWeapon), Is.True);
                Assert.That(GameBot.StarterFitsSlot165(staff, eInventorySlot.RightHandWeapon), Is.False);
                Assert.That(GameBot.StarterFitsSlot165(sword, eInventorySlot.RightHandWeapon), Is.True);
                Assert.That(GameBot.StarterFitsSlot165(sword, eInventorySlot.TwoHandWeapon), Is.False, "a polearm plan keeps the practice sword in its hand");
                Assert.That(GameBot.StarterFitsSlot165(dirk, eInventorySlot.RightHandWeapon), Is.True);
                Assert.That(GameBot.StarterFitsSlot165(dirk, eInventorySlot.LeftHandWeapon), Is.False, "no second starting dirk for the off hand");
                Assert.That(GameBot.StarterFitsSlot165(bow, eInventorySlot.RightHandWeapon), Is.False);
            });
        }
    }
}
