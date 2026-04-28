using System.IO.Compression;
using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class HpAppBuildService
{
    private readonly ToolchainRunner _toolchainRunner;
    private readonly XprimeProjectService _projectService;
    private readonly WindowsHpPrimePathService _pathService;

    public HpAppBuildService(
        ToolchainRunner toolchainRunner,
        XprimeProjectService projectService,
        WindowsHpPrimePathService pathService)
    {
        _toolchainRunner = toolchainRunner;
        _projectService = projectService;
        _pathService = pathService;
    }

    public async Task<ToolchainResult> BuildProgramAsync(string projectFile, XprimeProject project, CancellationToken cancellationToken = default)
    {
        var projectDirectory = Path.GetDirectoryName(projectFile) ?? Environment.CurrentDirectory;
        var projectName = _projectService.GetProjectName(projectFile);
        var source = _projectService.FindMainSource(projectDirectory)
            ?? throw new FileNotFoundException("Unable to find a main.hpppl, main.hppplplus, main.pas, main.prgm, main.prgm+, main.ppl, or main.ppl+ source file.");

        var destination = Path.Combine(projectDirectory, $"{projectName}.hpprgm");
        return await RunPreprocessorAsync(source, destination, project, projectDirectory, cancellationToken).ConfigureAwait(false);
    }

    public async Task<IReadOnlyList<ToolchainResult>> BuildApplicationAsync(
        string projectFile,
        XprimeProject project,
        string baseApplicationName,
        CancellationToken cancellationToken = default)
    {
        var projectDirectory = Path.GetDirectoryName(projectFile) ?? Environment.CurrentDirectory;
        var projectName = _projectService.GetProjectName(projectFile);
        var source = _projectService.FindMainSource(projectDirectory)
            ?? throw new FileNotFoundException("Unable to find the project main source file.");

        var appDirectory = EnsureHpAppDirectory(projectDirectory, projectName, baseApplicationName);
        var results = new List<ToolchainResult>();

        var noteResult = await ConvertProjectNoteAsync(projectDirectory, projectName, project, cancellationToken).ConfigureAwait(false);
        if (noteResult is not null)
        {
            results.Add(noteResult);
        }

        var appProgramPath = Path.Combine(appDirectory, $"{projectName}.hpappprgm");
        results.Add(await RunPreprocessorAsync(source, appProgramPath, project, projectDirectory, cancellationToken).ConfigureAwait(false));
        return results;
    }

    public string ArchiveApplication(string projectFile, XprimeProject project)
    {
        var projectDirectory = Path.GetDirectoryName(projectFile) ?? Environment.CurrentDirectory;
        var projectName = _projectService.GetProjectName(projectFile);
        var appDirectory = Path.Combine(projectDirectory, $"{projectName}.hpappdir");

        if (!Directory.Exists(appDirectory))
        {
            throw new DirectoryNotFoundException($"Application directory not found: {appDirectory}");
        }

        var archivePath = Path.Combine(projectDirectory, $"{projectName}.hpappdir.zip");
        if (File.Exists(archivePath))
        {
            File.Delete(archivePath);
        }

        ZipFile.CreateFromDirectory(appDirectory, archivePath, CompressionLevel.Optimal, includeBaseDirectory: true);
        return archivePath;
    }

    public InstallPlan Install(string sourcePath, string calculator, bool dryRun)
    {
        var plan = _pathService.PlanInstall(sourcePath, calculator, dryRun);

        if (dryRun)
        {
            return plan;
        }

        Directory.CreateDirectory(Path.GetDirectoryName(plan.DestinationPath)!);

        if (Directory.Exists(plan.SourcePath))
        {
            if (Directory.Exists(plan.DestinationPath))
            {
                Directory.Delete(plan.DestinationPath, recursive: true);
            }

            PathUtilities.CopyDirectory(plan.SourcePath, plan.DestinationPath, overwrite: true);
        }
        else
        {
            File.Copy(plan.SourcePath, plan.DestinationPath, overwrite: true);
        }

        return plan with { Completed = true };
    }

    private async Task<ToolchainResult> RunPreprocessorAsync(
        string source,
        string destination,
        XprimeProject project,
        string workingDirectory,
        CancellationToken cancellationToken)
    {
        if (File.Exists(destination))
        {
            File.Delete(destination);
        }

        var arguments = new List<string> { source, "-o", destination };

        if (project.Compression)
        {
            arguments.Add("--compress");
        }

        var includePath = ResolveSdkPath(project.Include);
        if (!string.IsNullOrWhiteSpace(includePath))
        {
            arguments.Add($"-I{includePath}");
        }

        var libPath = ResolveSdkPath(project.Lib);
        if (!string.IsNullOrWhiteSpace(libPath))
        {
            arguments.Add($"-L{libPath}");
        }

        return await _toolchainRunner.RunAsync("hppplplus", arguments, workingDirectory, cancellationToken).ConfigureAwait(false);
    }

    private async Task<ToolchainResult?> ConvertProjectNoteAsync(
        string projectDirectory,
        string projectName,
        XprimeProject project,
        CancellationToken cancellationToken)
    {
        var source = new[] { "info.note", "info.ntf", "info.md" }
            .Select(name => Path.Combine(projectDirectory, name))
            .FirstOrDefault(File.Exists);

        if (source is null)
        {
            return null;
        }

        var destination = Path.Combine(projectDirectory, $"{projectName}.hpappdir", $"{projectName}.hpappnote");
        var arguments = new List<string> { source, "-o", destination };

        if (project.PlainFallbackText)
        {
            arguments.Add("--plain-fallback");
        }

        return await _toolchainRunner.RunAsync("hpnote", arguments, projectDirectory, cancellationToken).ConfigureAwait(false);
    }

    private string EnsureHpAppDirectory(string projectDirectory, string appName, string baseApplicationName)
    {
        var safeName = PathUtilities.FileSafeName(appName);
        var appDirectory = Path.Combine(projectDirectory, $"{safeName}.hpappdir");
        Directory.CreateDirectory(appDirectory);

        var baseDirectory = Path.Combine(_toolchainRunner.AppRoot, "Resources", "Developer", "Library", "Xprime", "Templates", "Base Applications", $"{baseApplicationName}.hpappdir");
        if (!Directory.Exists(baseDirectory))
        {
            baseDirectory = Path.Combine(_toolchainRunner.AppRoot, "Resources", "Developer", "Library", "Xprime", "Templates", "Base Applications", "None.hpappdir");
        }

        if (Directory.Exists(baseDirectory))
        {
            var baseHpApp = Path.Combine(baseDirectory, $"{baseApplicationName}.hpapp");
            if (!File.Exists(baseHpApp))
            {
                baseHpApp = Directory.EnumerateFiles(baseDirectory, "*.hpapp", SearchOption.TopDirectoryOnly).FirstOrDefault() ?? baseHpApp;
            }

            CopyIfMissing(baseHpApp, Path.Combine(appDirectory, $"{safeName}.hpapp"));
            CopyIfMissing(Path.Combine(baseDirectory, $"{baseApplicationName}.png"), Path.Combine(appDirectory, "icon.png"));
            CopyIfMissing(Path.Combine(baseDirectory, "None.png"), Path.Combine(appDirectory, "icon.png"));
        }

        var notePath = Path.Combine(appDirectory, $"{safeName}.hpappnote");
        if (!File.Exists(notePath))
        {
            File.WriteAllBytes(notePath, [0x00, 0x00]);
        }

        return appDirectory;
    }

    private string ResolveSdkPath(string value)
    {
        return value
            .Replace("$(APPROOT)", _toolchainRunner.AppRoot, StringComparison.OrdinalIgnoreCase)
            .Replace("$(SDKROOT)", Path.Combine(_toolchainRunner.AppRoot, "Resources", "Developer", "usr"), StringComparison.OrdinalIgnoreCase)
            .Replace('/', Path.DirectorySeparatorChar);
    }

    private static void CopyIfMissing(string source, string destination)
    {
        if (!File.Exists(source) || File.Exists(destination))
        {
            return;
        }

        Directory.CreateDirectory(Path.GetDirectoryName(destination)!);
        File.Copy(source, destination);
    }
}
