using Xprime.Windows.Core.Models;

namespace Xprime.Windows.Core.Services;

public sealed class WindowsHpPrimePathService
{
    public IEnumerable<string> CalculatorRoots()
    {
        var profile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        var documents = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);

        var candidates = new[]
        {
            Path.Combine(documents, "HP Connectivity Kit", "Calculators"),
            Path.Combine(profile, "OneDrive", "Documents", "HP Connectivity Kit", "Calculators"),
            Path.Combine(profile, "Documents", "HP Connectivity Kit", "Calculators"),
            Path.Combine(documents, "HP Prime", "Calculators"),
            Path.Combine(profile, "Documents", "HP Prime", "Calculators")
        };

        return candidates.Where(Directory.Exists).Distinct(StringComparer.OrdinalIgnoreCase);
    }

    public IReadOnlyList<string> CalculatorNames()
    {
        return CalculatorRoots()
            .SelectMany(root => Directory.EnumerateDirectories(root))
            .Select(Path.GetFileName)
            .Where(static name => !string.IsNullOrWhiteSpace(name))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .OrderBy(static name => name, StringComparer.OrdinalIgnoreCase)
            .ToArray()!;
    }

    public string ResolveCalculatorDirectory(string calculator)
    {
        foreach (var root in CalculatorRoots())
        {
            var candidate = Path.Combine(root, calculator);
            if (Directory.Exists(candidate))
            {
                return candidate;
            }
        }

        var preferredRoot = CalculatorRoots().FirstOrDefault()
            ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "HP Connectivity Kit", "Calculators");

        return Path.Combine(preferredRoot, calculator);
    }

    public InstallPlan PlanInstall(string sourcePath, string calculator, bool dryRun)
    {
        var destination = Path.Combine(ResolveCalculatorDirectory(calculator), Path.GetFileName(sourcePath));
        return new InstallPlan(sourcePath, destination, File.Exists(destination) || Directory.Exists(destination), dryRun, Completed: false);
    }
}
