using System.Text.Json.Serialization;

namespace Xprime.Windows.Core.Models;

public sealed record ThemeDefinition
{
    [JsonPropertyName("name")]
    public string Name { get; init; } = string.Empty;

    [JsonPropertyName("type")]
    public string Type { get; init; } = "dark";

    [JsonPropertyName("colors")]
    public Dictionary<string, string> Colors { get; init; } = [];

    [JsonPropertyName("lineNumberRuler")]
    public Dictionary<string, string> LineNumberRuler { get; init; } = [];

    [JsonIgnore]
    public string SourcePath { get; init; } = string.Empty;

    public string? Color(string key)
        => Colors.TryGetValue(key, out var value) ? value : null;

    public string? LineNumberColor(string key)
        => LineNumberRuler.TryGetValue(key, out var value) ? value : null;
}
