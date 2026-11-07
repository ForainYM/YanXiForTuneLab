using System.Text;
using YanXiForTuneLab.Native;

namespace YanXiForTuneLab.Assets;

/// <summary>一个可用的 MUTA 音源：目录下的 .voice/.inf/.bnk/.chr 四件套。</summary>
public sealed record MutaVoice(
    string Id,
    string Directory,
    string VoiceFile,
    string InfFile,
    string BankFile,
    string DisplayName,
    long BankBytes)
{
    /// <summary>声音体的字节数，用于在日志/描述里给出可核对的规模。</summary>
    public double BankMegabytes => BankBytes / (1024.0 * 1024.0);

    /// <summary>A bank makes the sampled path possible; without one there is no voice.</summary>
    public bool HasBank => !string.IsNullOrEmpty(BankFile) && File.Exists(BankFile);
}

/// <summary>
/// 音源发现。嫣汐的声音体**随插件包分发**（包内 <c>voices/yanxi/</c>），装完即用，
/// 不需要另外安装 MUTA；用户也可以在扩展设置里追加别的 MUTA 音源目录。
/// 这里只做路径与文件名检查，不读大文件——打开 .bnk 是会话阶段的事。
/// </summary>
public static class VoiceLibrary
{
    /// <summary>包内自带的音源根目录：<c>&lt;插件包&gt;/voices</c>。</summary>
    public static string BundledRoot => Path.Combine(NativeLibraries.PackageDirectory, "voices");

    /// <summary>
    /// 从若干根目录扫描音源。根目录既可以是"装着多个音源文件夹的父目录"，
    /// 也可以直接是一个音源文件夹（用户很可能直接选到 ...\song\yanxi）。
    /// 同 id 先到先得。
    /// </summary>
    public static IReadOnlyList<MutaVoice> Scan(IEnumerable<string> roots)
    {
        var found = new List<MutaVoice>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var root in roots)
        {
            if (string.IsNullOrWhiteSpace(root) || !Directory.Exists(root))
                continue;

            if (TryLoad(root) is { } self && seen.Add(self.Id))
                found.Add(self);

            string[] children;
            try
            {
                children = Directory.GetDirectories(root);
            }
            catch (Exception)
            {
                continue;
            }

            Array.Sort(children, StringComparer.OrdinalIgnoreCase);
            foreach (var child in children)
            {
                if (TryLoad(child) is { } voice && seen.Add(voice.Id))
                    found.Add(voice);
            }
        }

        return found;
    }

    /// <summary>若 <paramref name="directory"/> 本身是一个音源文件夹，返回它；否则 null。</summary>
    public static MutaVoice? TryLoad(string directory)
    {
        if (!Directory.Exists(directory))
            return null;

        var id = Path.GetFileName(Path.TrimEndingDirectorySeparator(directory));
        if (string.IsNullOrWhiteSpace(id))
            return null;

        var voiceFile = FindOne(directory, id, ".voice") ?? FindOne(directory, id, ".htsvoice");
        var infFile = FindOne(directory, id, ".inf");
        var bankFile = FindOne(directory, id, ".bnk");
        // 一个可用的音源必须有模型、上下文索引与采样体；缺一即视为不是音源文件夹。
        if (voiceFile is null || infFile is null || bankFile is null)
            return null;

        long bankBytes = 0;
        try
        {
            bankBytes = new FileInfo(bankFile).Length;
        }
        catch (Exception)
        {
        }

        return new MutaVoice(
            id.ToLowerInvariant(),
            directory,
            voiceFile,
            infFile,
            bankFile,
            ReadDisplayName(directory, id),
            bankBytes);
    }

    /// <summary>优先 &lt;id&gt;.&lt;ext&gt;，否则取目录里唯一的那个扩展名匹配项。</summary>
    static string? FindOne(string directory, string id, string extension)
    {
        var preferred = Path.Combine(directory, id + extension);
        if (File.Exists(preferred))
            return preferred;

        string[] candidates;
        try
        {
            candidates = Directory.GetFiles(directory, "*" + extension);
        }
        catch (Exception)
        {
            return null;
        }

        return candidates.Length == 1 ? candidates[0] : null;
    }

    /// <summary>.chr 的内容是 <c>name=&lt;GBK&gt;</c>；解不出来就退回目录名。</summary>
    static string ReadDisplayName(string directory, string fallbackId)
    {
        try
        {
            var chr = Path.Combine(directory, fallbackId + ".chr");
            if (!File.Exists(chr))
            {
                var any = Directory.GetFiles(directory, "*.chr");
                if (any.Length == 1)
                    chr = any[0];
            }

            if (!File.Exists(chr))
                return fallbackId;

            const string prefix = "name=";
            var text = Gbk.TryDecode(File.ReadAllBytes(chr));
            if (text is null)
                return fallbackId;

            var value = text.StartsWith(prefix, StringComparison.Ordinal)
                ? text[prefix.Length..].Trim()
                : text.Trim();
            return string.IsNullOrWhiteSpace(value) ? fallbackId : value;
        }
        catch (Exception)
        {
            return fallbackId;
        }
    }
}
