using System.Text.Json.Serialization;

namespace Xprime.Windows.Core.Models;

public sealed record WindowsSafeHelpManifest
{
    [JsonPropertyName("sourceRepository")]
    public string SourceRepository { get; init; } = string.Empty;

    [JsonPropertyName("treeish")]
    public string Treeish { get; init; } = "HEAD";

    [JsonPropertyName("exportedAtUtc")]
    public DateTimeOffset ExportedAtUtc { get; init; } = DateTimeOffset.UtcNow;

    [JsonPropertyName("topicCount")]
    public int TopicCount { get; init; }

    [JsonPropertyName("windowsUnsafeTopicCount")]
    public int WindowsUnsafeTopicCount { get; init; }

    [JsonPropertyName("topics")]
    public List<HelpTopic> Topics { get; init; } = [];
}
