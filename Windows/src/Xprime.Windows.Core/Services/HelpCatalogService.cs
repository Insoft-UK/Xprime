using System.Text;
using System.Text.Json;
using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class HelpCatalogService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public WindowsSafeHelpManifest? LoadManifest(string helpDirectory)
    {
        var manifestPath = Path.Combine(helpDirectory, "manifest.json");
        if (!File.Exists(manifestPath))
        {
            return null;
        }

        var json = File.ReadAllText(manifestPath, Encoding.UTF8);
        return JsonSerializer.Deserialize<WindowsSafeHelpManifest>(json, JsonOptions);
    }

    public string ReadTopic(string helpDirectory, HelpTopic topic)
    {
        var path = Path.Combine(helpDirectory, topic.SafeFileName);
        return File.Exists(path) ? File.ReadAllText(path, Encoding.UTF8) : string.Empty;
    }
}
