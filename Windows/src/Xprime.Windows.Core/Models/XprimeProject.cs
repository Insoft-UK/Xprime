using System.Text.Json.Serialization;

namespace Xprime.Windows.Core.Models;

public sealed record XprimeProject
{
    [JsonPropertyName("compression")]
    public bool Compression { get; init; }

    [JsonPropertyName("include")]
    public string Include { get; init; } = "$(SDKROOT)/include";

    [JsonPropertyName("lib")]
    public string Lib { get; init; } = "$(SDKROOT)/lib";

    [JsonPropertyName("calculator")]
    public string Calculator { get; init; } = "Prime";

    [JsonPropertyName("bin")]
    public string Bin { get; init; } = "$(APPROOT)/tools/bin";

    [JsonPropertyName("language")]
    public string Language { get; init; } = "hppplplus";

    [JsonPropertyName("archiveProjectAppOnly")]
    public bool ArchiveProjectAppOnly { get; init; } = true;

    [JsonPropertyName("plainFallbackText")]
    public bool PlainFallbackText { get; init; } = true;
}
