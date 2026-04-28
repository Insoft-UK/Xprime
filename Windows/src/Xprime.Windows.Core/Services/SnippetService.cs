using System.Text.Json;
using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class SnippetService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public IReadOnlyList<SnippetDefinition> LoadSnippets(string snippetDirectory)
    {
        if (!Directory.Exists(snippetDirectory))
        {
            return [];
        }

        return Directory.EnumerateFiles(snippetDirectory, "*.xpsnippet", SearchOption.AllDirectories)
            .Select(LoadSnippet)
            .Where(static snippet => snippet is not null)
            .Cast<SnippetDefinition>()
            .OrderBy(static snippet => snippet.Title, StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private static SnippetDefinition? LoadSnippet(string path)
    {
        try
        {
            var snippet = JsonSerializer.Deserialize<SnippetDefinition>(File.ReadAllText(path), JsonOptions);
            return snippet is null ? null : snippet with { SourcePath = path };
        }
        catch
        {
            return null;
        }
    }
}
