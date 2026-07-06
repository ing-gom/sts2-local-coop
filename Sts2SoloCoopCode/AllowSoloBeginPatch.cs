using System;
using System.Linq;
using HarmonyLib;
using MegaCrit.Sts2.Core.Multiplayer.Game.Lobby;   // StartRunLobby

namespace Sts2SoloCoop;

/// <summary>
/// SPIKE: let a SOLO host BEGIN a multiplayer-type run. Normally
/// <see cref="StartRunLobby.IsAboutToBeginGame"/> returns false when the net type is multiplayer and
/// there is only one player (<c>NetService.Type.IsMultiplayer() &amp;&amp; Players.Count == 1</c>), so a host
/// can't start until a second client joins. We WANT a <c>Type=Host</c> session with the co-op UI active
/// but no real peer — then <c>sc_addplayer</c> injects a 2nd local player the co-op UI will actually
/// render (a singleplayer-type run leaves the co-op UI dormant → only one character shows).
///
/// This postfix forces "ready to begin" once the single host player is ready and nobody is mid-handshake.
/// It reuses the game's whole lobby→run flow (init, room generation, scene transition), so it's far
/// lower-risk than constructing a run from scratch via SetUpTest.
/// </summary>
[HarmonyPatch(typeof(StartRunLobby), nameof(StartRunLobby.IsAboutToBeginGame))]
internal static class AllowSoloBeginPatch
{
    private static void Postfix(StartRunLobby __instance, ref bool __result)
    {
        if (__result) return;   // already allowed
        try
        {
            if (__instance._connectingPlayers.Count == 0
                && __instance.Players.Count >= 1
                && __instance.Players.All(p => p.isReady))
            {
                __result = true;
                MainFile.Logger.Info($"[{MainFile.ModId}] AllowSoloBegin: forcing begin for solo host ({__instance.Players.Count} player).");
            }
        }
        catch (Exception e)
        {
            MainFile.Logger.Warn($"[{MainFile.ModId}] AllowSoloBegin postfix failed: {e.Message}");
        }
    }
}
