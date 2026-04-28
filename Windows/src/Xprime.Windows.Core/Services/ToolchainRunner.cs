using System.Diagnostics;
using System.Text;
using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class ToolchainRunner
{
    public ToolchainRunner(string appRoot)
    {
        AppRoot = appRoot;
    }

    public string AppRoot { get; }

    public string ToolBinDirectory => Path.Combine(AppRoot, "tools", "bin");

    public async Task<ToolchainResult> RunAsync(
        string executableName,
        IEnumerable<string> arguments,
        string? workingDirectory = null,
        CancellationToken cancellationToken = default)
    {
        var resolvedExecutable = ResolveExecutable(executableName);
        var argumentList = arguments.ToArray();
        var cwd = workingDirectory ?? Environment.CurrentDirectory;

        if (resolvedExecutable is null)
        {
            return new ToolchainResult(
                executableName,
                argumentList,
                cwd,
                -1,
                string.Empty,
                $"Tool not found: {executableName}. Build the Windows toolchain and copy it to {ToolBinDirectory}.");
        }

        var startInfo = new ProcessStartInfo
        {
            FileName = resolvedExecutable,
            WorkingDirectory = cwd,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8
        };

        foreach (var argument in argumentList)
        {
            startInfo.ArgumentList.Add(argument);
        }

        using var process = new Process { StartInfo = startInfo };
        process.Start();

        var stdoutTask = process.StandardOutput.ReadToEndAsync(cancellationToken);
        var stderrTask = process.StandardError.ReadToEndAsync(cancellationToken);

        await process.WaitForExitAsync(cancellationToken).ConfigureAwait(false);

        return new ToolchainResult(
            resolvedExecutable,
            argumentList,
            cwd,
            process.ExitCode,
            await stdoutTask.ConfigureAwait(false),
            await stderrTask.ConfigureAwait(false));
    }

    private string? ResolveExecutable(string executableName)
    {
        var candidates = new List<string>();

        if (Path.IsPathRooted(executableName) || executableName.Contains(Path.DirectorySeparatorChar) || executableName.Contains(Path.AltDirectorySeparatorChar))
        {
            candidates.Add(executableName);
        }
        else
        {
            candidates.Add(Path.Combine(ToolBinDirectory, executableName));
            candidates.Add(Path.Combine(ToolBinDirectory, $"{executableName}.exe"));

            foreach (var path in (Environment.GetEnvironmentVariable("PATH") ?? string.Empty).Split(Path.PathSeparator))
            {
                if (!string.IsNullOrWhiteSpace(path))
                {
                    candidates.Add(Path.Combine(path, executableName));
                    candidates.Add(Path.Combine(path, $"{executableName}.exe"));
                }
            }
        }

        return candidates.FirstOrDefault(File.Exists);
    }
}
