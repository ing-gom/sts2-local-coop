using MegaCrit.Sts2.Core.Modding;
using Sts2.ModKit.Bootstrap;

namespace Sts2SoloCoop;

/// <summary>
/// Sts2SoloCoop — an in-game CO-OP TEST KIT. Pairs with a two-instance local co-op setup (see
/// tools/README.md) so one operator can drive both windows; this DLL provides the in-game diagnostics.
///
/// Console commands (see SoloCoopProbeCmd): <c>sc_probe</c> (dump net type / players / NetIds),
/// <c>sc_swap &lt;netid&gt;</c> (change the local-player perspective). Plus <see cref="AllowSoloBeginPatch"/>,
/// which lets a solo host begin a multiplayer-type run for solo smoke-testing of the co-op flow.
///
/// History: this began as a spike toward a single-window "hotseat" (control both players in one
/// process). That proved impractical — STS2 co-op is a networked lockstep whose ~10 per-choice
/// synchronizers (Event/Map/Reward/Combat/Act/RestSite/...) each snapshot the player set and wait for
/// every player's networked vote, with no disable flags. So the project pivoted to the two-instance
/// approach (both are real peers → all synchronizers satisfied) plus these test utilities.
/// </summary>
[ModInitializer(nameof(Initialize))]
public class MainFile
{
    public const string ModId = "Sts2SoloCoop";

    public static readonly MegaCrit.Sts2.Core.Logging.Logger Logger
        = ModBootstrap.CreateLogger(ModId);

    public static void Initialize() =>
        ModBootstrap.Run(ModId, Logger, typeof(MainFile).Assembly, body: () =>
        {
            Logger.Info($"[{ModId}] co-op test kit active — console: sc_probe, sc_swap <netid>; solo-host begin enabled.");
        });
}
