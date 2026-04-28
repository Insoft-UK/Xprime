using Xprime.Windows.Core.Models;
using Xprime.Windows.Core.Services;

namespace Xprime.Windows.Tools;

internal static class Program
{
    private static async Task<int> Main(string[] args)
    {
        if (args.Length == 0 || args[0] is "-h" or "--help")
        {
            PrintUsage();
            return 0;
        }

        try
        {
            return args[0] switch
            {
                "convert-help" => await ConvertHelpAsync(args[1..]).ConfigureAwait(false),
                "verify" => await VerifyAsync(args[1..]).ConfigureAwait(false),
                _ => UnknownCommand(args[0])
            };
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
    }

    private static async Task<int> ConvertHelpAsync(string[] args)
    {
        var options = Options.Parse(args);
        var repo = options.ValueOrDefault("--repo", string.Empty);
        if (string.IsNullOrWhiteSpace(repo))
        {
            repo = FindRepositoryRoot();
        }

        var output = options.Required("--out");
        var treeish = options.ValueOrDefault("--treeish", "HEAD");

        var exporter = new WindowsSafeHelpExporter();
        var manifest = await exporter.ExportAsync(repo, output, treeish).ConfigureAwait(false);

        Console.WriteLine($"Exported {manifest.TopicCount} help topics to {output}");
        Console.WriteLine($"{manifest.WindowsUnsafeTopicCount} original filenames required Windows-safe names.");
        return 0;
    }

    private static async Task<int> VerifyAsync(string[] args)
    {
        var options = Options.Parse(args);
        var repoValue = options.ValueOrDefault("--repo", string.Empty);
        if (string.IsNullOrWhiteSpace(repoValue))
        {
            repoValue = FindRepositoryRoot();
        }

        var repo = Path.GetFullPath(repoValue);
        var appRoot = Path.GetFullPath(options.Required("--app-root"));
        var smokeRoot = Path.GetFullPath(options.ValueOrDefault("--smoke", Path.Combine(repo, "Windows", "toolchain", "build", "smoke")));
        Directory.CreateDirectory(smokeRoot);

        var failures = new List<string>();
        var toolchain = new ToolchainRunner(appRoot);
        var projectService = new XprimeProjectService();
        var buildService = new HpAppBuildService(toolchain, projectService, new WindowsHpPrimePathService());

        CheckFile(Path.Combine(toolchain.ToolBinDirectory, "hppplplus.exe"), failures);
        CheckFile(Path.Combine(toolchain.ToolBinDirectory, "hpnote.exe"), failures);
        CheckFile(Path.Combine(toolchain.ToolBinDirectory, "font.exe"), failures);
        CheckFile(Path.Combine(toolchain.ToolBinDirectory, "grob.exe"), failures);

        var helpManifest = new HelpCatalogService().LoadManifest(Path.Combine(appRoot, "Resources", "HelpWindowsSafe"));
        if (helpManifest is null)
        {
            failures.Add("Converted help manifest is missing from app resources.");
        }
        else
        {
            Require(helpManifest.TopicCount >= 690, $"Help manifest topic count looks low: {helpManifest.TopicCount}", failures);
            Require(helpManifest.WindowsUnsafeTopicCount >= 7, $"Expected at least 7 Windows-unsafe help filenames, found {helpManifest.WindowsUnsafeTopicCount}.", failures);
            Console.WriteLine($"Help topics: {helpManifest.TopicCount}; Windows-unsafe originals: {helpManifest.WindowsUnsafeTopicCount}");
        }

        await CheckToolHelpAsync(toolchain, "hppplplus", failures).ConfigureAwait(false);
        await CheckToolHelpAsync(toolchain, "hpnote", failures).ConfigureAwait(false);
        await CheckToolHelpAsync(toolchain, "font", failures).ConfigureAwait(false);
        await CheckToolHelpAsync(toolchain, "grob", failures).ConfigureAwait(false);

        await VerifyProgramRoundTripAsync(repo, smokeRoot, toolchain, failures).ConfigureAwait(false);
        await VerifyNoteConversionsAsync(repo, smokeRoot, toolchain, failures).ConfigureAwait(false);
        await VerifyAppBuildAndArchiveAsync(repo, smokeRoot, buildService, projectService, failures).ConfigureAwait(false);

        if (failures.Count == 0)
        {
            Console.WriteLine("Windows replication verification passed.");
            return 0;
        }

        Console.Error.WriteLine("Windows replication verification failed:");
        foreach (var failure in failures)
        {
            Console.Error.WriteLine($"- {failure}");
        }

        return 1;
    }

    private static async Task VerifyProgramRoundTripAsync(
        string repo,
        string smokeRoot,
        ToolchainRunner toolchain,
        List<string> failures)
    {
        var output = Path.Combine(smokeRoot, "Graphics.hpprgm");
        var extracted = Path.Combine(smokeRoot, "Graphics.extracted.hpppl");
        TryDelete(output);
        TryDelete(extracted);

        var graphics = Path.Combine(repo, "Examples", "Graphics");
        var include = Path.Combine(repo, "Xcode", "Xprime", "Resources", "Developer", "usr", "include");
        var lib = Path.Combine(repo, "Xcode", "Xprime", "Resources", "Developer", "usr", "lib");
        var build = await toolchain.RunAsync(
            "hppplplus",
            [Path.Combine(graphics, "main.hppplplus"), "-o", output, $"-I{include}", $"-L{lib}"],
            graphics).ConfigureAwait(false);

        Require(build.ExitCode == 0 && File.Exists(output), $"Graphics .hpprgm build failed: {build.CombinedOutput}", failures);

        var extract = await toolchain.RunAsync("hppplplus", [output, "-o", extracted], smokeRoot).ConfigureAwait(false);
        Require(extract.ExitCode == 0 && File.Exists(extracted), $"Graphics .hpprgm extraction failed: {extract.CombinedOutput}", failures);
    }

    private static async Task VerifyNoteConversionsAsync(
        string repo,
        string smokeRoot,
        ToolchainRunner toolchain,
        List<string> failures)
    {
        var hpnote = Path.Combine(smokeRoot, "Graphics.hpnote");
        var ntf = Path.Combine(smokeRoot, "Colors.ntf");
        TryDelete(hpnote);
        TryDelete(ntf);

        var ntfToHpnote = await toolchain.RunAsync(
            "hpnote",
            [Path.Combine(repo, "Examples", "Graphics", "info.ntf"), "-o", hpnote, "--plain-fallback"],
            smokeRoot).ConfigureAwait(false);
        Require(ntfToHpnote.ExitCode == 0 && File.Exists(hpnote), $"info.ntf -> .hpnote failed: {ntfToHpnote.CombinedOutput}", failures);

        var appnoteToNtf = await toolchain.RunAsync(
            "hpnote",
            [Path.Combine(repo, "Examples", "Colors", "Colors.hpappdir", "Colors.hpappnote"), "-o", ntf],
            smokeRoot).ConfigureAwait(false);
        Require(appnoteToNtf.ExitCode == 0 && File.Exists(ntf), $".hpappnote -> .ntf failed: {appnoteToNtf.CombinedOutput}", failures);
    }

    private static async Task VerifyAppBuildAndArchiveAsync(
        string repo,
        string smokeRoot,
        HpAppBuildService buildService,
        XprimeProjectService projectService,
        List<string> failures)
    {
        var copiedProject = Path.Combine(smokeRoot, "ColorsProject");
        SafeRecreateDirectory(copiedProject, smokeRoot);
        CopyDirectory(Path.Combine(repo, "Examples", "Colors"), copiedProject);

        var projectFile = Path.Combine(copiedProject, "Colors.xprimeproj");
        var project = projectService.Load(projectFile) with
        {
            Include = "$(SDKROOT)/include",
            Lib = "$(SDKROOT)/lib"
        };

        var results = await buildService.BuildApplicationAsync(projectFile, project, "None").ConfigureAwait(false);
        Require(results.All(static result => result.ExitCode == 0), $"Colors app build failed: {string.Join(Environment.NewLine, results.Select(static result => result.CombinedOutput))}", failures);
        Require(File.Exists(Path.Combine(copiedProject, "Colors.hpappdir", "Colors.hpappprgm")), "Colors app program was not generated.", failures);
        Require(File.Exists(Path.Combine(copiedProject, "Colors.hpappdir", "Colors.hpappnote")), "Colors app note was not generated.", failures);

        var archive = buildService.ArchiveApplication(projectFile, project);
        Require(File.Exists(archive), "Colors app archive was not generated.", failures);
    }

    private static async Task CheckToolHelpAsync(ToolchainRunner toolchain, string executable, List<string> failures)
    {
        var result = await toolchain.RunAsync(executable, ["--help"]).ConfigureAwait(false);
        Require(result.ExitCode == 0, $"{executable} --help failed: {result.CombinedOutput}", failures);
    }

    private static void CheckFile(string path, List<string> failures)
        => Require(File.Exists(path), $"Missing required file: {path}", failures);

    private static void Require(bool condition, string message, List<string> failures)
    {
        if (!condition)
        {
            failures.Add(message);
        }
    }

    private static void SafeRecreateDirectory(string directory, string allowedRoot)
    {
        var fullDirectory = Path.GetFullPath(directory);
        var fullRoot = Path.GetFullPath(allowedRoot);

        if (!fullDirectory.StartsWith(fullRoot, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException($"Refusing to recreate directory outside smoke root: {fullDirectory}");
        }

        if (Directory.Exists(fullDirectory))
        {
            Directory.Delete(fullDirectory, recursive: true);
        }

        Directory.CreateDirectory(fullDirectory);
    }

    private static void CopyDirectory(string source, string destination)
    {
        Directory.CreateDirectory(destination);

        foreach (var file in Directory.EnumerateFiles(source))
        {
            File.Copy(file, Path.Combine(destination, Path.GetFileName(file)), overwrite: true);
        }

        foreach (var directory in Directory.EnumerateDirectories(source))
        {
            CopyDirectory(directory, Path.Combine(destination, Path.GetFileName(directory)));
        }
    }

    private static void TryDelete(string path)
    {
        if (File.Exists(path))
        {
            File.Delete(path);
        }
    }

    private static string FindRepositoryRoot()
    {
        var current = Directory.GetCurrentDirectory();
        while (!string.IsNullOrWhiteSpace(current))
        {
            if (Directory.Exists(Path.Combine(current, ".git")) && Directory.Exists(Path.Combine(current, "Xcode")))
            {
                return current;
            }

            current = Directory.GetParent(current)?.FullName ?? string.Empty;
        }

        throw new InvalidOperationException("Unable to find Xprime repository root. Pass --repo.");
    }

    private static int UnknownCommand(string command)
    {
        Console.Error.WriteLine($"Unknown command: {command}");
        PrintUsage();
        return 1;
    }

    private static void PrintUsage()
    {
        Console.WriteLine("Xprime.Windows.Tools");
        Console.WriteLine();
        Console.WriteLine("Commands:");
        Console.WriteLine("  convert-help --repo <repo> --out <dir> [--treeish HEAD]");
        Console.WriteLine("  verify --repo <repo> --app-root <built app root> [--smoke <dir>]");
    }

    private sealed class Options
    {
        private readonly Dictionary<string, string> _values;

        private Options(Dictionary<string, string> values)
        {
            _values = values;
        }

        public static Options Parse(string[] args)
        {
            var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

            for (var index = 0; index < args.Length; index++)
            {
                var key = args[index];
                if (!key.StartsWith("--", StringComparison.Ordinal))
                {
                    throw new ArgumentException($"Unexpected argument: {key}");
                }

                if (index + 1 >= args.Length)
                {
                    throw new ArgumentException($"Missing value for {key}");
                }

                values[key] = args[++index];
            }

            return new Options(values);
        }

        public string Required(string key)
            => _values.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value)
                ? value
                : throw new ArgumentException($"Missing required option {key}.");

        public string ValueOrDefault(string key, string fallback)
            => _values.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value) ? value : fallback;
    }
}
