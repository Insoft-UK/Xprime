namespace Xprime.Windows.Core.Services;

internal static class PathUtilities
{
    public static void CopyDirectory(string sourceDirectory, string destinationDirectory, bool overwrite)
    {
        Directory.CreateDirectory(destinationDirectory);

        foreach (var file in Directory.EnumerateFiles(sourceDirectory))
        {
            var destination = Path.Combine(destinationDirectory, Path.GetFileName(file));
            File.Copy(file, destination, overwrite);
        }

        foreach (var directory in Directory.EnumerateDirectories(sourceDirectory))
        {
            var destination = Path.Combine(destinationDirectory, Path.GetFileName(directory));
            CopyDirectory(directory, destination, overwrite);
        }
    }

    public static string FileSafeName(string name)
    {
        var invalid = Path.GetInvalidFileNameChars().Concat(new[] { '/', '\\', ':', '?', '%', '*', '|', '"', '<', '>' }).ToHashSet();
        var safe = new string(name.Where(ch => !invalid.Contains(ch)).ToArray()).Trim();

        if (string.IsNullOrWhiteSpace(safe))
        {
            throw new ArgumentException("The project or application name does not contain a Windows-safe file name.", nameof(name));
        }

        return safe;
    }
}
