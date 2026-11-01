using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading;
using DOL.Events;
using DOL.GS.Quests;
using DOL.Logging;

namespace DOL.GS
{
    /// <summary>
    /// Map markers and quest icons for the two True 1.65 courier quests turned in at the traveler's inn (owner
    /// 2026-10-31: nothing showed where to go until you were nearby): "The Traveler's Inn" at the realm's innkeeper and
    /// "The Horn of Rallying" at its Horn Handler. While the quest is active the player's map shows a marker on that NPC
    /// (the relic-marker packet, like bounty and classic quest markers) and the NPC shows the turn-in quest icon.
    /// </summary>
    public static class InnQuestMarkers165
    {
        // A range of its own: bounty / reputation / Sluaghbinder use 0xFFFE0001-3, classic quests 0xFFFE0004 and up,
        // bot markers ordinary database ids under the high bit.
        public const uint InnMarkerId = 0xFFFD0001;
        public const uint HornMarkerId = 0xFFFD0002;
        private const int RefreshMilliseconds = 12000;

        private static readonly Logger Log = LoggerManager.Create(typeof(InnQuestMarkers165));
        private static readonly ConcurrentDictionary<eRealm, GameNPC> Innkeepers = new();
        private static readonly ConcurrentDictionary<eRealm, GameNPC> HornHandlers = new();
        private static readonly ConcurrentDictionary<GamePlayer, (bool Inn, bool Horn)> Shown = new();
        private static Timer _timer;

        public static void Register(GameNPC npc)
        {
            if (npc is Innkeeper165) Innkeepers[npc.Realm] = npc;
            else if (npc is HornHandler165) HornHandlers[npc.Realm] = npc;
        }

        public static void Unregister(GameNPC npc)
        {
            if (npc is Innkeeper165) Innkeepers.TryRemove(new KeyValuePair<eRealm, GameNPC>(npc.Realm, npc));
            else if (npc is HornHandler165) HornHandlers.TryRemove(new KeyValuePair<eRealm, GameNPC>(npc.Realm, npc));
        }

        /// <summary>The NPC turns in this player's courier quest now (shows the turn-in icon).</summary>
        public static bool TurnsInFor(GameNPC npc, GamePlayer player) =>
            Classic165Mode.IsOn && player != null && npc != null && npc.Realm == player.Realm &&
            (npc is Innkeeper165 && player.IsDoingQuest(typeof(RoadsideInn165)) is { Step: 1 } ||
             npc is HornHandler165 && player.IsDoingQuest(typeof(HornOfRallying165)) != null);

        /// <summary>Right after a turn-in: the icon and the marker go at once.</summary>
        public static void TurnedIn(GameNPC npc, GamePlayer player)
        {
            if (npc == null || player == null) return;
            player.Out.SendNPCsQuestEffect(npc, npc.GetQuestIndicator(player));
            Update(player);
        }

        [GameServerStartedEvent]
        public static void OnServerStarted(DOLEvent e, object sender, EventArgs args)
        {
            _timer?.Dispose();
            if (Classic165Mode.IsOn)
                _timer = new Timer(Refresh, null, RefreshMilliseconds, RefreshMilliseconds);
        }

        [GameServerStoppedEvent]
        public static void OnServerStopped(DOLEvent e, object sender, EventArgs args)
        {
            _timer?.Dispose();
            _timer = null;
            Shown.Clear();
        }

        private static void Refresh(object state)
        {
            try
            {
                foreach (GamePlayer player in ClientService.Instance.GetPlayers())
                    Update(player);
                foreach (GamePlayer gone in Shown.Keys)
                    if (gone.ObjectState != GameObject.eObjectState.Active)
                        Shown.TryRemove(gone, out _);
            }
            catch (Exception ex)
            {
                Log.Error("Inn quest markers: refresh failed", ex);
            }
        }

        private static void Update(GamePlayer player)
        {
            if (player?.ObjectState != GameObject.eObjectState.Active || player.Out == null)
                return;
            bool inn = player.IsDoingQuest(typeof(RoadsideInn165)) is { Step: 1 };
            bool horn = player.IsDoingQuest(typeof(HornOfRallying165)) != null;
            Shown.TryGetValue(player, out var before);
            Show(player, InnMarkerId, inn, before.Inn, Innkeepers);
            Show(player, HornMarkerId, horn, before.Horn, HornHandlers);
            if (inn || horn) Shown[player] = (inn, horn);
            else Shown.TryRemove(player, out _);
        }

        private static void Show(GamePlayer player, uint id, bool active, bool wasShown, ConcurrentDictionary<eRealm, GameNPC> npcs)
        {
            npcs.TryGetValue(player.Realm, out GameNPC npc);
            if (!active || npc?.ObjectState != GameObject.eObjectState.Active)
            {
                if (wasShown) player.Out.SendMinotaurRelicMapRemove(id);
                return;
            }
            player.Out.SendMinotaurRelicMapUpdate(id, npc.CurrentRegionID, npc.X, npc.Y, npc.Z);
            // the quest icon over the NPC, for a player already in sight of it when the quest began
            if (npc.CurrentRegion == player.CurrentRegion && npc.IsWithinRadius(player, WorldMgr.VISIBILITY_DISTANCE))
                player.Out.SendNPCsQuestEffect(npc, npc.GetQuestIndicator(player));
        }
    }
}
