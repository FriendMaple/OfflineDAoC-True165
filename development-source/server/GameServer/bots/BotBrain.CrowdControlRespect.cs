using DOL.GS;

namespace DOL.AI.Brain
{
    /// <summary>
    /// Bots leave crowd-controlled monsters alone while there is something else to fight (owner 2026-10-29: in group
    /// fights with several adds, bots and pets broke the healers' mezzes early). A mesmerized monster, or one rooted by a
    /// root that damage breaks, is not chosen as a target, and a bot's pet is moved off one, while any monster in the
    /// fight is not controlled; when every one left is controlled, the bot breaks one to go on, as a player does.
    /// Single-target fights are unchanged. Area spells already refuse a blast that would reach a controlled monster.
    /// </summary>
    public partial class BotBrain
    {
        /// <summary>Mesmerized, or rooted by a root that damage ends (not the unbreakable kind).</summary>
        public static bool IsBreakablyControlled(GameLiving living)
        {
            if (living == null)
                return false;
            if (living.IsMezzed)
                return true;
            return EffectListService.GetEffectOnTarget(living, eEffect.MovementSpeedDebuff) is ECSGameSpellEffect root &&
                root.SpellHandler?.Spell is { Value: >= 99 } spell &&
                spell.SpellType is not eSpellType.UnbreakableSpeedDecrease and not eSpellType.PreventFlight;
        }

        /// <summary>
        /// A player's group leaves a mesmerized or rooted monster alone even when nothing else is left, as long as it is
        /// not fighting anyone (a rooted caster still nuking is a fight): the player held it, and the companions engage
        /// it the moment the hold ends or breaks early (owner 2026-11-03). A gamebot group still finishes held adds
        /// once the rest is dead.
        /// </summary>
        private bool LeavesHeldForPlayer(GameLiving living) =>
            BotBody?.IsPlayerLedGroup == true && IsBreakablyControlled(living) &&
            !(living.IsAttacking || living.IsCasting && living.castingComponent?.SpellHandler?.Spell?.IsHarmful == true);

        /// <summary>
        /// A held (mesmerized or rooted) monster on this bot's aggro list is still near, and so is its player: the fight
        /// is not over. A player who walks off ends the wait (the companions follow; the monster rejoins the fight by
        /// group defense when its hold ends).
        /// </summary>
        internal bool WaitsOnHeldEnemy()
        {
            GameBot bot = BotBody;
            if (bot == null || AggroList.IsEmpty || bot.PlayerGroupLeader is GamePlayer leader &&
                (!leader.IsAlive || leader.CurrentRegion != bot.CurrentRegion || !bot.IsWithinRadius(leader, 650)))
                return false;
            foreach (GameLiving living in AggroList.Keys)
            {
                if (living is { IsAlive: true } && IsBreakablyControlled(living) && !ShouldBeRemovedFromAggroList(living) &&
                    bot.IsWithinRadius(living, GROUP_DEFENSE_ASSIST_RADIUS))
                    return true;
            }
            return false;
        }

        /// <summary>Pure rule: a controlled target is passed over only while an uncontrolled one is in the fight.</summary>
        public static bool PassOverControlled(bool controlled, bool uncontrolledAvailable) => controlled && uncontrolledAvailable;

        /// <summary>The pet leaves a controlled monster for the bot's own (uncontrolled) target.</summary>
        private void RedirectPetFromControlledTarget(GameLiving botTarget)
        {
            GameNPC pet = Body.ControlledBrain?.Body;
            if (pet is not { IsAlive: true } || botTarget is not { IsAlive: true } || IsBreakablyControlled(botTarget) ||
                pet.TargetObject is not GameLiving petTarget || petTarget == botTarget || !IsBreakablyControlled(petTarget))
                return;
            CommandPetAttack(botTarget);
        }
    }
}
