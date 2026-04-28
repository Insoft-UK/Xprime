using System.Text.Json.Serialization;

namespace Xprime.Windows.Core.Models;

public sealed record HelpTopic
{
    [JsonPropertyName("title")]
    public string Title { get; init; } = string.Empty;

    [JsonPropertyName("originalPath")]
    public string OriginalPath { get; init; } = string.Empty;

    [JsonPropertyName("originalFileName")]
    public string OriginalFileName { get; init; } = string.Empty;

    [JsonPropertyName("safeFileName")]
    public string SafeFileName { get; init; } = string.Empty;

    [JsonPropertyName("wasWindowsUnsafe")]
    public bool WasWindowsUnsafe { get; init; }
}
