using System.Text;

namespace YanXiForTuneLab.Native;

/// <summary>
/// MUTA 的 .chr / .inf 里的名字是 GBK（代码页 936）。
///
/// 原来直接调 Windows 的 MultiByteToWideChar，省一个随包依赖；但插件现在也跑在
/// macOS / Linux 上（见 NativeLibraries.NativeFileName），这条路就断了。改为用
/// System.Text.Encoding.CodePages 的托管实现，三个平台同一套代码；取不到 936 时
/// 再退回 UTF-8。
/// </summary>
internal static class Gbk
{
    const int CP_GBK = 936;

    static readonly Encoding? GbkEncoding = CreateGbkEncoding();

    static Encoding? CreateGbkEncoding()
    {
        try
        {
            Encoding.RegisterProvider(CodePagesEncodingProvider.Instance);
            return Encoding.GetEncoding(CP_GBK);
        }
        catch (Exception)
        {
            return null;
        }
    }

    /// <summary>把 GBK 字节解成字符串；失败时回退 UTF-8，再失败返回 null。</summary>
    public static string? TryDecode(ReadOnlySpan<byte> bytes)
    {
        if (bytes.IsEmpty)
            return null;

        if (GbkEncoding is not null)
        {
            try
            {
                var text = GbkEncoding.GetString(bytes).Trim();
                if (!string.IsNullOrEmpty(text))
                    return text;
            }
            catch (Exception)
            {
            }
        }

        try
        {
            return Encoding.UTF8.GetString(bytes).Trim();
        }
        catch
        {
            return null;
        }
    }
}
