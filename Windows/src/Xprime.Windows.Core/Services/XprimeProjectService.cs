using System.Text;
using System.Text.Json;
using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class XprimeProjectService
{
    private static readonly string[] MainFileNames =
    [
        "main.hpppl",
        "main.hppplplus",
        "main.pas",
        "main.prgm",
        "main.prgm+",
        "main.ppl",
        "main.ppl+"
    ];

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true
    };

    public XprimeProject Load(string projectFile)
    {
        var json = File.ReadAllText(projectFile, Encoding.UTF8);
        return JsonSerializer.Deserialize<XprimeProject>(json, JsonOptions) ?? new XprimeProject();
    }

    public void Save(string projectFile, XprimeProject project)
    {
        var json = JsonSerializer.Serialize(project, JsonOptions);
        File.WriteAllText(projectFile, json, Encoding.UTF8);
    }

    public string? FindProjectFile(string directory)
    {
        return Directory
            .EnumerateFiles(directory, "*.xprimeproj", SearchOption.TopDirectoryOnly)
            .OrderBy(static path => path, StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault();
    }

    public string GetProjectName(string projectFile)
    {
        return Path.GetFileNameWithoutExtension(projectFile);
    }

    public string? FindMainSource(string projectDirectory)
    {
        return MainFileNames
            .Select(name => Path.Combine(projectDirectory, name))
            .FirstOrDefault(File.Exists);
    }

    public string ReadSource(string sourceFile)
    {
        var bytes = File.ReadAllBytes(sourceFile);

        if (bytes.Length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE)
        {
            return Encoding.Unicode.GetString(bytes, 2, bytes.Length - 2);
        }

        if (bytes.Length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF)
        {
            return Encoding.BigEndianUnicode.GetString(bytes, 2, bytes.Length - 2);
        }

        return Encoding.UTF8.GetString(bytes);
    }

    public void WriteSource(string sourceFile, string content)
    {
        if (string.Equals(Path.GetExtension(sourceFile), ".prgm", StringComparison.OrdinalIgnoreCase))
        {
            using var stream = File.Create(sourceFile);
            stream.Write([0xFF, 0xFE]);
            stream.Write(Encoding.Unicode.GetBytes(content));
            return;
        }

        File.WriteAllText(sourceFile, content, new UTF8Encoding(encoderShouldEmitUTF8Identifier: false));
    }
}
