using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace DOL.GS
{
    /// <summary>
    /// True 1.65 coin (owner 2026-10-31: "coin drops on every kill" was wrong). In 1.65 a monster either carried coin or
    /// it didn't: most animals, insects, reptiles and plants never did. Uthgard's measured kills show exactly that, so a
    /// monster Uthgard measured uses its own coin rate and any other monster its body type's average.
    /// Data: runtime\true165\coin165.json (tools\claude-version\true165\build_coin165.py). Amounts are unchanged.
    /// Without the file (or outside True 1.65) every kill drops coin, as before.
    /// </summary>
    public static class Coin165
    {
        private static readonly Logging.Logger Log = Logging.LoggerManager.Create(System.Reflection.MethodBase.GetCurrentMethod().DeclaringType);

        private static readonly string[] BodyNames =
            ["None", "Animal", "Demon", "Dragon", "Elemental", "Giant", "Humanoid", "Insect", "Magical", "Reptile", "Plant", "Undead"];

        private static readonly object Sync = new();
        private static Dictionary<string, int> _monsters;
        private static Dictionary<string, int> _bodyDefaults;

        public static string FilePath => Path.GetFullPath(Path.Combine(GameServer.Instance.Configuration.RootDirectory, "..", "true165", "coin165.json"));

        /// <summary>The chance in percent that this monster drops coin when killed (100 when no rule applies).</summary>
        public static int ChanceFor(GameNPC mob)
        {
            if (mob == null || !Classic165Mode.IsOn)
                return 100;
            EnsureLoaded();
            if (_monsters == null)
                return 100;
            if (_monsters.TryGetValue(mob.Name?.ToLowerInvariant() ?? string.Empty, out int measured))
                return Math.Clamp(measured, 0, 100);
            int body = mob.BodyType;
            string type = body >= 0 && body < BodyNames.Length ? BodyNames[body] : "None";
            return _bodyDefaults.TryGetValue(type, out int chance) ? Math.Clamp(chance, 0, 100) : 100;
        }

        public static bool DropsCoin(GameNPC mob) => Util.Chance(ChanceFor(mob));

        /// <summary>For tests: use this data instead of the file.</summary>
        public static void SetForTests(Dictionary<string, int> monsters, Dictionary<string, int> bodyDefaults)
        {
            lock (Sync)
            {
                _monsters = monsters == null ? null : new Dictionary<string, int>(monsters, StringComparer.OrdinalIgnoreCase);
                _bodyDefaults = new Dictionary<string, int>(bodyDefaults ?? [], StringComparer.OrdinalIgnoreCase);
            }
        }

        private static void EnsureLoaded()
        {
            if (_bodyDefaults != null)
                return;
            lock (Sync)
            {
                if (_bodyDefaults != null)
                    return;
                var monsters = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                var defaults = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
                bool loaded = false;
                try
                {
                    string path = FilePath;
                    if (File.Exists(path))
                    {
                        using JsonDocument doc = JsonDocument.Parse(File.ReadAllText(path));
                        foreach (JsonProperty p in doc.RootElement.GetProperty("monsters").EnumerateObject())
                            monsters[p.Name] = p.Value.GetInt32();
                        foreach (JsonProperty p in doc.RootElement.GetProperty("body_type_default").EnumerateObject())
                            defaults[p.Name] = p.Value.GetInt32();
                        loaded = true;
                        Log.Info($"True 1.65 coin: {monsters.Count} measured monsters, {defaults.Count} body type defaults.");
                    }
                }
                catch (Exception e)
                {
                    Log.Error("True 1.65 coin: coin165.json could not be read; every kill drops coin.", e);
                }
                _monsters = loaded ? monsters : null;
                _bodyDefaults = defaults;
            }
        }
    }
}
