using System.Text.Json.Serialization;
using System.Text.RegularExpressions;

namespace Xprime.Windows.Core.Models;

public sealed record SnippetDefinition
{
    [JsonPropertyName("title")]
    public string Title { get; init; } = string.Empty;

    [JsonPropertyName("body")]
    public List<string> Body { get; init; } = [];

    [JsonPropertyName("description")]
    public string Description { get; init; } = string.Empty;

    [JsonIgnore]
    public string SourcePath { get; init; } = string.Empty;

    [JsonIgnore]
    public string InsertText
    {
        get
        {
            var joined = string.Join(Environment.NewLine, Body).Replace("$0", string.Empty, StringComparison.Ordinal);
            return Regex.Replace(joined, @"\$\{\d+:?([^}]*)\}", "$1");
        }
    }
}
