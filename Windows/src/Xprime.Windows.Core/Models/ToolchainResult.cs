namespace Xprime.Windows.Core.Models;

public sealed record ToolchainResult(
    string Executable,
    IReadOnlyList<string> Arguments,
    string WorkingDirectory,
    int ExitCode,
    string StandardOutput,
    string StandardError)
{
    public bool Succeeded => ExitCode == 0;

    public string CombinedOutput =>
        string.Join(
            Environment.NewLine,
            new[] { StandardOutput, StandardError }.Where(static value => !string.IsNullOrWhiteSpace(value)));
}
