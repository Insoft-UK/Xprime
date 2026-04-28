namespace Xprime.Windows.Core.Models;

public sealed record InstallPlan(
    string SourcePath,
    string DestinationPath,
    bool DestinationExists,
    bool DryRun,
    bool Completed);
