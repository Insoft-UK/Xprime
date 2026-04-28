using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Xml;
using ICSharpCode.AvalonEdit.Highlighting;
using ICSharpCode.AvalonEdit.Highlighting.Xshd;
using Microsoft.Win32;
using Xprime.Windows.Core.Models;
using Xprime.Windows.Core.Services;

namespace Xprime.Windows;

public partial class MainWindow : Window
{
    private readonly XprimeProjectService _projectService = new();
    private readonly WindowsHpPrimePathService _pathService = new();
    private readonly HelpCatalogService _helpCatalogService = new();
    private readonly ThemeService _themeService = new();
    private readonly SnippetService _snippetService = new();

    private ToolchainRunner _toolchainRunner = null!;
    private HpAppBuildService _buildService = null!;
    private XprimeProject? _project;
    private string? _projectFile;
    private string? _currentSourceFile;
    private bool _currentDocumentReadOnly;
    private bool _loadingFileList;
    private bool _loadingUi;
    private IReadOnlyList<HelpTopic> _helpTopics = [];
    private IReadOnlyList<SnippetDefinition> _snippets = [];
    private IReadOnlyList<ThemeDefinition> _themes = [];

    public MainWindow()
    {
        InitializeComponent();
    }

    private void Window_Loaded(object sender, RoutedEventArgs e)
    {
        _toolchainRunner = new ToolchainRunner(AppContext.BaseDirectory);
        _buildService = new HpAppBuildService(_toolchainRunner, _projectService, _pathService);

        LoadHighlighting();
        LoadThemes();
        LoadSnippets();
        LoadHelpCatalog();
        RefreshBaseApplications();
        RefreshCalculators();
        Log("Xprime for Windows ready.");
        Log($"Toolchain bin: {_toolchainRunner.ToolBinDirectory}");
    }

    private void OpenProject_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFileDialog
        {
            Title = "Open Xprime Project",
            Filter = "Xprime project (*.xprimeproj)|*.xprimeproj|All files (*.*)|*.*"
        };

        if (dialog.ShowDialog(this) == true)
        {
            LoadProject(dialog.FileName);
        }
    }

    private void SaveSource_Click(object sender, RoutedEventArgs e)
    {
        if (_currentSourceFile is null)
        {
            Log("No source file is open.");
            return;
        }

        if (_currentDocumentReadOnly)
        {
            Log("This document was opened through a binary conversion view. Build from source to regenerate it.");
            return;
        }

        _projectService.WriteSource(_currentSourceFile, Editor.Text);
        Log($"Saved {Path.GetFileName(_currentSourceFile)}.");
    }

    private void SaveProjectSettings_Click(object sender, RoutedEventArgs e)
    {
        if (!TryGetProject(out var projectFile, out _))
        {
            return;
        }

        _project = ProjectFromUi();
        _projectService.Save(projectFile, _project);
        Log($"Saved {Path.GetFileName(projectFile)} settings.");
    }

    private async void BuildProgram_Click(object sender, RoutedEventArgs e)
    {
        if (!TryGetProject(out var projectFile, out var project))
        {
            return;
        }

        SaveOpenSourceIfNeeded();
        Log("Building standalone program...");
        var result = await _buildService.BuildProgramAsync(projectFile, project).ConfigureAwait(true);
        LogResult(result);
        RefreshProjectFiles(Path.GetDirectoryName(projectFile)!);
    }

    private async void BuildApplication_Click(object sender, RoutedEventArgs e)
    {
        if (!TryGetProject(out var projectFile, out var project))
        {
            return;
        }

        SaveOpenSourceIfNeeded();
        Log("Building application directory...");
        var baseApplicationName = string.IsNullOrWhiteSpace(BaseApplicationBox.Text) ? "None" : BaseApplicationBox.Text.Trim();
        var results = await _buildService.BuildApplicationAsync(projectFile, project, baseApplicationName).ConfigureAwait(true);
        foreach (var result in results)
        {
            LogResult(result);
        }

        RefreshProjectFiles(Path.GetDirectoryName(projectFile)!);
    }

    private void ArchiveApplication_Click(object sender, RoutedEventArgs e)
    {
        if (!TryGetProject(out var projectFile, out var project))
        {
            return;
        }

        try
        {
            var archive = _buildService.ArchiveApplication(projectFile, project);
            Log($"Archived {archive}.");
            RefreshProjectFiles(Path.GetDirectoryName(projectFile)!);
        }
        catch (Exception ex)
        {
            Log($"Archive failed: {ex.Message}");
        }
    }

    private void InstallProgram_Click(object sender, RoutedEventArgs e)
    {
        if (!TryGetProject(out var projectFile, out var project))
        {
            return;
        }

        var projectName = _projectService.GetProjectName(projectFile);
        var program = Path.Combine(Path.GetDirectoryName(projectFile)!, $"{projectName}.hpprgm");
        InstallPath(program, project);
    }

    private void InstallApplication_Click(object sender, RoutedEventArgs e)
    {
        if (!TryGetProject(out var projectFile, out var project))
        {
            return;
        }

        var projectName = _projectService.GetProjectName(projectFile);
        var appDirectory = Path.Combine(Path.GetDirectoryName(projectFile)!, $"{projectName}.hpappdir");
        InstallPath(appDirectory, project);
    }

    private async void FileList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loadingFileList || FileList.SelectedItem is not string file || !File.Exists(file))
        {
            return;
        }

        await LoadSourceAsync(file).ConfigureAwait(true);
    }

    private void ThemeBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_loadingUi || ThemeBox.SelectedItem is not ThemeDefinition theme)
        {
            return;
        }

        ApplyTheme(theme);
    }

    private void HelpSearchBox_TextChanged(object sender, TextChangedEventArgs e)
    {
        RefreshHelpTopics(HelpSearchBox.Text);
    }

    private void HelpTopicList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (HelpTopicList.SelectedItem is not HelpTopic topic)
        {
            return;
        }

        var helpDirectory = Path.Combine(AppContext.BaseDirectory, "Resources", "HelpWindowsSafe");
        HelpViewer.Text = _helpCatalogService.ReadTopic(helpDirectory, topic);
    }

    private void SnippetList_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (SnippetList.SelectedItem is SnippetDefinition snippet)
        {
            SnippetDescription.Text = snippet.Description;
        }
    }

    private void InsertSnippet_Click(object sender, RoutedEventArgs e)
    {
        if (SnippetList.SelectedItem is not SnippetDefinition snippet)
        {
            Log("Select a snippet first.");
            return;
        }

        Editor.Document.Insert(Editor.CaretOffset, snippet.InsertText);
        Editor.Focus();
    }

    private void Exit_Click(object sender, RoutedEventArgs e)
    {
        Close();
    }

    private void LoadProject(string projectFile)
    {
        try
        {
            _projectFile = projectFile;
            _project = _projectService.Load(projectFile);
            ProjectPathBox.Text = projectFile;
            PopulateProjectSettings(_project);

            var projectDirectory = Path.GetDirectoryName(projectFile)!;
            RefreshProjectFiles(projectDirectory);

            var main = _projectService.FindMainSource(projectDirectory);
            if (main is not null)
            {
                _ = LoadSourceAsync(main);
            }

            Log($"Opened {Path.GetFileName(projectFile)}.");
        }
        catch (Exception ex)
        {
            Log($"Open failed: {ex.Message}");
        }
    }

    private async Task LoadSourceAsync(string sourceFile)
    {
        _currentSourceFile = sourceFile;
        _currentDocumentReadOnly = false;
        Editor.IsReadOnly = false;

        try
        {
            var extension = Path.GetExtension(sourceFile).ToLowerInvariant();
            if (extension is ".hpprgm" or ".hpappprgm")
            {
                var converted = await ConvertBinaryProgramAsync(sourceFile).ConfigureAwait(true);
                Editor.Text = converted;
                Editor.IsReadOnly = true;
                _currentDocumentReadOnly = true;
                Log($"Loaded converted view of {Path.GetFileName(sourceFile)}.");
                return;
            }

            if (extension is ".hpnote" or ".hpappnote")
            {
                var converted = await ConvertBinaryNoteAsync(sourceFile).ConfigureAwait(true);
                Editor.Text = converted;
                Editor.IsReadOnly = true;
                _currentDocumentReadOnly = true;
                Log($"Loaded converted note view of {Path.GetFileName(sourceFile)}.");
                return;
            }

            Editor.Text = _projectService.ReadSource(sourceFile);
            Log($"Loaded {Path.GetFileName(sourceFile)}.");
        }
        catch (Exception ex)
        {
            Log($"Load failed: {ex.Message}");
        }
    }

    private async Task<string> ConvertBinaryProgramAsync(string sourceFile)
    {
        var temp = ConvertedTempPath(sourceFile, ".hpppl");
        var result = await _toolchainRunner.RunAsync("hppplplus", [sourceFile, "-o", temp]).ConfigureAwait(true);
        if (result.ExitCode != 0 || !File.Exists(temp))
        {
            throw new InvalidOperationException(result.CombinedOutput);
        }

        return _projectService.ReadSource(temp);
    }

    private async Task<string> ConvertBinaryNoteAsync(string sourceFile)
    {
        var temp = ConvertedTempPath(sourceFile, ".ntf");
        var result = await _toolchainRunner.RunAsync("hpnote", [sourceFile, "-o", temp]).ConfigureAwait(true);
        if (result.ExitCode != 0 || !File.Exists(temp))
        {
            throw new InvalidOperationException(result.CombinedOutput);
        }

        return _projectService.ReadSource(temp);
    }

    private static string ConvertedTempPath(string sourceFile, string extension)
    {
        var directory = Path.Combine(Path.GetTempPath(), "Xprime.Windows", "converted");
        Directory.CreateDirectory(directory);
        return Path.Combine(directory, $"{Path.GetFileNameWithoutExtension(sourceFile)}.{Guid.NewGuid():N}{extension}");
    }

    private void RefreshProjectFiles(string projectDirectory)
    {
        _loadingFileList = true;
        try
        {
            FileList.Items.Clear();

            var allowed = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                ".hpppl", ".hppplplus", ".pas", ".prgm", ".ppl", ".ppl+",
                ".ntf", ".md", ".note", ".hpnote", ".hpappnote",
                ".hpprgm", ".hpappprgm", ".hpapp", ".xprimeproj",
                ".png", ".bmp", ".h", ".py"
            };

            foreach (var file in Directory.EnumerateFiles(projectDirectory, "*", SearchOption.AllDirectories)
                         .Where(path => allowed.Contains(Path.GetExtension(path)) || path.EndsWith(".prgm+", StringComparison.OrdinalIgnoreCase))
                         .OrderBy(path => Path.GetRelativePath(projectDirectory, path), StringComparer.OrdinalIgnoreCase))
            {
                FileList.Items.Add(file);
            }
        }
        finally
        {
            _loadingFileList = false;
        }
    }

    private void RefreshCalculators()
    {
        CalculatorBox.Items.Clear();

        foreach (var calculator in _pathService.CalculatorNames())
        {
            CalculatorBox.Items.Add(calculator);
        }

        CalculatorBox.Text = CalculatorBox.Items.Count > 0 ? CalculatorBox.Items[0]?.ToString() ?? "Prime" : "Prime";
    }

    private void RefreshBaseApplications()
    {
        BaseApplicationBox.Items.Clear();
        var baseApplicationsRoot = Path.Combine(AppContext.BaseDirectory, "Resources", "Developer", "Library", "Xprime", "Templates", "Base Applications");

        if (Directory.Exists(baseApplicationsRoot))
        {
            foreach (var directory in Directory.EnumerateDirectories(baseApplicationsRoot, "*.hpappdir").OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase))
            {
                BaseApplicationBox.Items.Add(Path.GetFileNameWithoutExtension(directory));
            }
        }

        if (BaseApplicationBox.Items.Contains("None"))
        {
            BaseApplicationBox.Text = "None";
        }
        else
        {
            BaseApplicationBox.Text = BaseApplicationBox.Items.Count > 0 ? BaseApplicationBox.Items[0]?.ToString() ?? "None" : "None";
        }
    }

    private bool TryGetProject(out string projectFile, out XprimeProject project)
    {
        projectFile = _projectFile ?? ProjectPathBox.Text.Trim();

        if (string.IsNullOrWhiteSpace(projectFile) || !File.Exists(projectFile))
        {
            Log("Open a .xprimeproj file first.");
            project = new XprimeProject();
            return false;
        }

        project = ProjectFromUi();
        _project = project;
        return true;
    }

    private XprimeProject ProjectFromUi()
    {
        var existing = _project ?? new XprimeProject();

        return existing with
        {
            Compression = CompressionBox.IsChecked == true,
            Include = string.IsNullOrWhiteSpace(IncludeBox.Text) ? existing.Include : IncludeBox.Text.Trim(),
            Lib = string.IsNullOrWhiteSpace(LibBox.Text) ? existing.Lib : LibBox.Text.Trim(),
            Bin = string.IsNullOrWhiteSpace(BinBox.Text) ? existing.Bin : BinBox.Text.Trim(),
            Calculator = string.IsNullOrWhiteSpace(CalculatorBox.Text) ? existing.Calculator : CalculatorBox.Text.Trim(),
            Language = ReadComboText(LanguageBox, existing.Language),
            ArchiveProjectAppOnly = ArchiveProjectAppOnlyBox.IsChecked == true,
            PlainFallbackText = existing.PlainFallbackText
        };
    }

    private void PopulateProjectSettings(XprimeProject project)
    {
        _loadingUi = true;
        try
        {
            CompressionBox.IsChecked = project.Compression;
            ArchiveProjectAppOnlyBox.IsChecked = project.ArchiveProjectAppOnly;
            IncludeBox.Text = project.Include;
            LibBox.Text = project.Lib;
            BinBox.Text = project.Bin;
            CalculatorBox.Text = string.IsNullOrWhiteSpace(project.Calculator) ? "Prime" : project.Calculator;
            LanguageBox.Text = string.IsNullOrWhiteSpace(project.Language) ? "hppplplus" : project.Language;
        }
        finally
        {
            _loadingUi = false;
        }
    }

    private static string ReadComboText(ComboBox comboBox, string fallback)
    {
        if (!string.IsNullOrWhiteSpace(comboBox.Text))
        {
            return comboBox.Text.Trim();
        }

        if (comboBox.SelectedItem is ComboBoxItem item && item.Content is not null)
        {
            return item.Content.ToString() ?? fallback;
        }

        return fallback;
    }

    private void SaveOpenSourceIfNeeded()
    {
        if (_currentSourceFile is not null && !_currentDocumentReadOnly)
        {
            _projectService.WriteSource(_currentSourceFile, Editor.Text);
        }
    }

    private void InstallPath(string sourcePath, XprimeProject project)
    {
        if (!File.Exists(sourcePath) && !Directory.Exists(sourcePath))
        {
            Log($"Install source does not exist yet: {sourcePath}");
            return;
        }

        var calculator = string.IsNullOrWhiteSpace(CalculatorBox.Text) ? project.Calculator : CalculatorBox.Text.Trim();
        var dryRun = PerformInstallBox.IsChecked != true;
        var plan = _buildService.Install(sourcePath, calculator, dryRun);
        var action = dryRun ? "Dry run" : "Installed";
        Log($"{action}: {plan.SourcePath} -> {plan.DestinationPath}");

        if (plan.DestinationExists && dryRun)
        {
            Log("Destination already exists. Check Perform install to overwrite it.");
        }
    }

    private void LogResult(ToolchainResult result)
    {
        Log($"{Path.GetFileName(result.Executable)} exited with {result.ExitCode}.");

        if (!string.IsNullOrWhiteSpace(result.CombinedOutput))
        {
            Log(result.CombinedOutput.TrimEnd());
        }
    }

    private void Log(string message)
    {
        OutputBox.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}{Environment.NewLine}");
        OutputBox.ScrollToEnd();
    }

    private void LoadThemes()
    {
        _themes = _themeService.LoadThemes(Path.Combine(AppContext.BaseDirectory, "Resources", "Themes"));
        ThemeBox.ItemsSource = _themes;

        var selected = _themes.FirstOrDefault(static theme => string.Equals(theme.Name, "Dark", StringComparison.OrdinalIgnoreCase))
                       ?? _themes.FirstOrDefault()
                       ?? new ThemeDefinition { Name = "Dark", Type = "dark" };

        ThemeBox.SelectedItem = selected;
        ApplyTheme(selected);
    }

    private void ApplyTheme(ThemeDefinition theme)
    {
        Editor.Background = BrushFrom(theme.Color("editor.background"), Color.FromRgb(13, 17, 23));
        Editor.Foreground = BrushFrom(theme.Color("editor.foreground"), Color.FromRgb(240, 243, 246));
        Editor.LineNumbersForeground = BrushFrom(theme.LineNumberColor("foreground"), Color.FromRgb(118, 131, 144));
    }

    private static SolidColorBrush BrushFrom(string? value, Color fallback)
    {
        if (!string.IsNullOrWhiteSpace(value))
        {
            try
            {
                return new SolidColorBrush((Color)ColorConverter.ConvertFromString(value));
            }
            catch
            {
                return new SolidColorBrush(fallback);
            }
        }

        return new SolidColorBrush(fallback);
    }

    private void LoadSnippets()
    {
        _snippets = _snippetService.LoadSnippets(Path.Combine(AppContext.BaseDirectory, "Resources", "Developer", "Library", "Xprime", "Snippets"));
        SnippetList.ItemsSource = _snippets;
        Log($"Loaded {_snippets.Count} snippets.");
    }

    private void LoadHelpCatalog()
    {
        var helpDirectory = Path.Combine(AppContext.BaseDirectory, "Resources", "HelpWindowsSafe");
        var manifest = _helpCatalogService.LoadManifest(helpDirectory);

        if (manifest is null)
        {
            Log("Converted help catalog is missing. Run Xprime.Windows.Tools convert-help.");
            return;
        }

        _helpTopics = manifest.Topics;
        RefreshHelpTopics(string.Empty);
        Log($"Loaded {manifest.TopicCount} help topics; {manifest.WindowsUnsafeTopicCount} came from Windows-unsafe filenames.");
    }

    private void RefreshHelpTopics(string? filter)
    {
        var query = filter?.Trim() ?? string.Empty;
        HelpTopicList.ItemsSource = _helpTopics
            .Where(topic => string.IsNullOrWhiteSpace(query)
                            || topic.Title.Contains(query, StringComparison.OrdinalIgnoreCase)
                            || topic.OriginalPath.Contains(query, StringComparison.OrdinalIgnoreCase))
            .Take(250)
            .ToArray();
    }

    private void LoadHighlighting()
    {
        const string resourceName = "Xprime.Windows.Resources.PplHighlighting.xshd";
        using var stream = typeof(MainWindow).Assembly.GetManifestResourceStream(resourceName);
        if (stream is null)
        {
            return;
        }

        using var reader = XmlReader.Create(stream);
        Editor.SyntaxHighlighting = HighlightingLoader.Load(reader, HighlightingManager.Instance);
    }
}
