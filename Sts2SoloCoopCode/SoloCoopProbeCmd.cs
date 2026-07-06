using System.Linq;
using System.Text;
using MegaCrit.Sts2.Core.Context;                    // LocalContext
using MegaCrit.Sts2.Core.DevConsole;                 // CmdResult
using MegaCrit.Sts2.Core.DevConsole.ConsoleCommands; // AbstractConsoleCmd
using MegaCrit.Sts2.Core.Entities.Players;           // Player
using MegaCrit.Sts2.Core.Runs;                       // RunManager

namespace Sts2SoloCoop;

/// <summary>
/// <c>sc_probe</c> — dump the current net-session structure: the net service type + local NetId, every
/// player with its NetId and whether it's "me" (LocalContext), and whether combat-state sync is disabled.
/// Run it in a live co-op session to read the shape (e.g. to find a player's NetId for <c>sc_swap</c>).
/// </summary>
public sealed class SoloCoopProbeCmd : AbstractConsoleCmd
{
    public override string CmdName => "sc_probe";
    public override string Args => "";
    public override string Description => "Log the current co-op session structure (net type, players, NetIds).";
    public override bool IsNetworked => false;
    public override bool DebugOnly => false;

    public override CmdResult Process(Player? issuingPlayer, string[] args)
    {
        var rm = RunManager.Instance;
        var sb = new StringBuilder();
        sb.Append($"NetService.Type={rm?.NetService?.Type} localNetId={rm?.NetService?.NetId} ")
          .Append($"IsSPorFakeMP={rm?.IsSingleplayerOrFakeMultiplayer} ")
          .Append($"LocalContext.NetId={LocalContext.NetId} ")
          .Append($"CombatSync.IsDisabled={rm?.CombatStateSynchronizer?.IsDisabled}\n");

        var players = rm?.State?.Players;
        if (players != null)
            foreach (var p in players)
                sb.Append($"  player NetId={p.NetId} isMe={LocalContext.IsMe(p)}\n");
        else
            sb.Append("  (no run in progress)\n");

        MainFile.Logger.Info($"[{MainFile.ModId}] sc_probe\n{sb}");
        return new CmdResult(success: true,
            $"probe: type={rm?.NetService?.Type} players={players?.Count ?? 0} localNetId={rm?.NetService?.NetId} (full dump in log)");
    }
}

/// <summary>
/// <c>sc_swap &lt;netid&gt;</c> — set <see cref="LocalContext.NetId"/> to another player's id (the "who am I"
/// perspective). A diagnostic for testing how the co-op UI/logic reacts to the local player changing.
/// Guarded: a NetId with no matching player is refused (setting one makes LocalContext.GetMe throw every
/// frame and freezes the UI). Run <c>sc_probe</c> first to list valid NetIds.
/// </summary>
public sealed class SoloCoopSwapCmd : AbstractConsoleCmd
{
    public override string CmdName => "sc_swap";
    public override string Args => "<netid>";
    public override string Description => "Set LocalContext.NetId to another player (perspective diagnostic).";
    public override bool IsNetworked => false;
    public override bool DebugOnly => false;

    public override CmdResult Process(Player? issuingPlayer, string[] args)
    {
        var players = RunManager.Instance?.State?.Players;
        string valid = players != null ? string.Join(", ", players.Select(p => p.NetId)) : "(no run)";

        if (args.Length < 1 || !ulong.TryParse(args[0], out ulong id))
            return new CmdResult(success: false, $"Usage: sc_swap <netid>. Valid NetIds in this run: {valid}");

        // Guard: swapping to a NetId with no matching player makes LocalContext.GetMe throw every frame
        // (UI freezes). Only allow ids that actually exist in the current run.
        if (players != null && players.All(p => p.NetId != id))
            return new CmdResult(success: false, $"NetId {id} is not in this run. Valid NetIds: {valid}");

        ulong? old = LocalContext.NetId;
        LocalContext.NetId = id;
        MainFile.Logger.Info($"[{MainFile.ModId}] sc_swap LocalContext.NetId {old} -> {id}");
        return new CmdResult(success: true, $"LocalContext.NetId {old} -> {id} — sc_swap {old} to restore.");
    }
}
