using System.Text.Json;
using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class ThemeService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public IReadOnlyList<ThemeDefinition> LoadThemes(string themeDirectory)
    {
        if (!Directory.Exists(themeDirectory))
        {
            return [];
        }

        return Directory.EnumerateFiles(themeDirectory, "*.xpcolortheme", SearchOption.TopDirectoryOnly)
            .Select(LoadTheme)
            .Where(static theme => theme is not null)
            .Cast<ThemeDefinition>()
            .OrderBy(static theme => theme.Name, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private static ThemeDefinition? LoadTheme(string path)
    {
        try
        {
            var theme = JsonSerializer.Deserialize<ThemeDefinition>(File.ReadAllText(path), JsonOptions);
            return theme is null ? null : theme with { SourcePath = path };
        }
        catch
        {
            return null;
        }
    }
}
