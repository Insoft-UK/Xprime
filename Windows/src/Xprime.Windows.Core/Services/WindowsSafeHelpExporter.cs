using System.Diagnostics;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class WindowsSafeHelpExporter
{
    private const string HelpTreePath = "Xcode/Xprime/Resources/Help";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true
    };

    public async Task<WindowsSafeHelpManifest> ExportAsync(
        string repositoryRoot,
        string outputDirectory,
        string treeish = "HEAD",
        CancellationToken cancellationToken = default)
    {
        repositoryRoot = Path.GetFullPath(repositoryRoot);
        outputDirectory = Path.GetFullPath(outputDirectory);

        Directory.CreateDirectory(outputDirectory);
        ClearGeneratedFiles(outputDirectory);

        var paths = (await RunGitTextAsync(repositoryRoot, ["ls-tree", "-r", "--name-only", treeish, "--", HelpTreePath], cancellationToken)
                .ConfigureAwait(false))
            .Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries)
            .Where(static path => path.EndsWith(".txt", StringComparison.OrdinalIgnoreCase))
            .OrderBy(static path => path, StringComparer.OrdinalIgnoreCase)
            .ToArray();

        var topics = new List<HelpTopic>();
        var index = 1;

        foreach (var originalPath in paths)
        {
            var originalFileName = originalPath[(originalPath.LastIndexOf('/') + 1)..];
            var title = Path.GetFileNameWithoutExtension(originalFileName);
            var safeFileName = $"{index:D4}_{ToSafeToken(title)}_{ShortHash(originalPath)}.txt";
            var destination = Path.Combine(outputDirectory, safeFileName);

            await ExportGitBlobAsync(repositoryRoot, $"{treeish}:{originalPath}", destination, cancellationToken)
                .ConfigureAwait(false);

            topics.Add(new HelpTopic
            {
                Title = title,
                OriginalPath = originalPath,
                OriginalFileName = originalFileName,
                SafeFileName = safeFileName,
                WasWindowsUnsafe = IsWindowsUnsafeFileName(originalFileName)
            });

            index++;
        }

        var manifest = new WindowsSafeHelpManifest
        {
            SourceRepository = repositoryRoot,
            Treeish = treeish,
            ExportedAtUtc = DateTimeOffset.UtcNow,
            TopicCount = topics.Count,
            WindowsUnsafeTopicCount = topics.Count(static topic => topic.WasWindowsUnsafe),
            Topics = topics
        };

        await File.WriteAllTextAsync(
            Path.Combine(outputDirectory, "manifest.json"),
            JsonSerializer.Serialize(manifest, JsonOptions),
            new UTF8Encoding(encoderShouldEmitUTF8Identifier: false),
            cancellationToken).ConfigureAwait(false);

        await File.WriteAllTextAsync(
            Path.Combine(outputDirectory, "README.md"),
            $"# Windows-safe Xprime Help Export{Environment.NewLine}{Environment.NewLine}" +
            $"Generated from `{treeish}` with {topics.Count} topics. " +
            $"{manifest.WindowsUnsafeTopicCount} original filenames were unsafe on Windows and are represented through `manifest.json`.{Environment.NewLine}",
            new UTF8Encoding(encoderShouldEmitUTF8Identifier: false),
            cancellationToken).ConfigureAwait(false);

        return manifest;
    }

    private static void ClearGeneratedFiles(string outputDirectory)
    {
        foreach (var file in Directory.EnumerateFiles(outputDirectory, "*.txt"))
        {
            File.Delete(file);
        }

        foreach (var file in new[] { "manifest.json", "README.md" })
        {
            var path = Path.Combine(outputDirectory, file);
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
    }

    private static bool IsWindowsUnsafeFileName(string fileName)
        => fileName.IndexOfAny(Path.GetInvalidFileNameChars()) >= 0
           || fileName.Contains('*', StringComparison.Ordinal)
           || fileName.Contains('<', StringComparison.Ordinal)
           || fileName.Contains('>', StringComparison.Ordinal);

    private static string ToSafeToken(string title)
    {
        var builder = new StringBuilder();

        foreach (var ch in title)
        {
            if (char.IsAsciiLetterOrDigit(ch) || ch is '_' or '-')
            {
                builder.Append(ch);
            }
            else
            {
                builder.Append("_u");
                builder.Append(((int)ch).ToString("X4"));
                builder.Append('_');
            }
        }

        var safe = builder.ToString().Trim('.', ' ', '_');
        if (string.IsNullOrWhiteSpace(safe))
        {
            safe = "operator";
        }

        var reserved = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "CON", "PRN", "AUX", "NUL",
            "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
            "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
        };

        return reserved.Contains(safe) ? $"_{safe}" : safe;
    }

    private static string ShortHash(string value)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(bytes, 0, 4).ToLowerInvariant();
    }

    private static async Task<string> RunGitTextAsync(string repositoryRoot, IReadOnlyList<string> arguments, CancellationToken cancellationToken)
    {
        var startInfo = CreateGitStartInfo(repositoryRoot, arguments);
        startInfo.StandardOutputEncoding = Encoding.UTF8;
        startInfo.StandardErrorEncoding = Encoding.UTF8;

        using var process = Process.Start(startInfo) ?? throw new InvalidOperationException("Unable to start git.");
        var outputTask = process.StandardOutput.ReadToEndAsync(cancellationToken);
        var errorTask = process.StandardError.ReadToEndAsync(cancellationToken);

        await process.WaitForExitAsync(cancellationToken).ConfigureAwait(false);

        var output = await outputTask.ConfigureAwait(false);
        var error = await errorTask.ConfigureAwait(false);

        if (process.ExitCode != 0)
        {
            throw new InvalidOperationException($"git {string.Join(' ', arguments)} failed with exit code {process.ExitCode}: {error}");
        }

        return output;
    }

    private static async Task ExportGitBlobAsync(string repositoryRoot, string blobSpec, string destination, CancellationToken cancellationToken)
    {
        var startInfo = CreateGitStartInfo(repositoryRoot, ["show", blobSpec]);

        using var process = Process.Start(startInfo) ?? throw new InvalidOperationException("Unable to start git.");
        await using var destinationStream = File.Create(destination);

        var copyTask = process.StandardOutput.BaseStream.CopyToAsync(destinationStream, cancellationToken);
        var errorTask = process.StandardError.ReadToEndAsync(cancellationToken);

        await process.WaitForExitAsync(cancellationToken).ConfigureAwait(false);
        await copyTask.ConfigureAwait(false);
        var error = await errorTask.ConfigureAwait(false);

        if (process.ExitCode != 0)
        {
            throw new InvalidOperationException($"git show {blobSpec} failed with exit code {process.ExitCode}: {error}");
        }
    }

    private static ProcessStartInfo CreateGitStartInfo(string repositoryRoot, IReadOnlyList<string> arguments)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = "git",
            WorkingDirectory = repositoryRoot,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false
        };

        startInfo.ArgumentList.Add("-C");
        startInfo.ArgumentList.Add(repositoryRoot);
        startInfo.ArgumentList.Add("-c");
        startInfo.ArgumentList.Add("core.quotepath=false");

        foreach (var argument in arguments)
        {
            startInfo.ArgumentList.Add(argument);
        }

        return startInfo;
    }
}
