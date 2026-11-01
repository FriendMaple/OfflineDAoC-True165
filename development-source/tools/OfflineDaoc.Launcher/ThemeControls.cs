using System.Drawing.Drawing2D;
using System.ComponentModel;
using System.Reflection;

namespace OfflineDaoc.Launcher;

internal static class DaocTheme
{
    /// <summary>
    /// True 1.65 Mode's night theme (owner 2026-10-30): the dark blue night, standing stones and moon of the 1.64
    /// client's character screen. Every warm brown and gold of the normal theme turns night blue and moonlight
    /// silver; the realm colours and the red and green buttons stay. Set before any colour below (field order).
    /// OFFLINEDAOC_THEME=night|day overrides it for previews.
    /// </summary>
    internal static readonly bool Night = ReadNight();

    private static bool ReadNight()
    {
        string? forced = Environment.GetEnvironmentVariable("OFFLINEDAOC_THEME");
        if (string.Equals(forced, "night", StringComparison.OrdinalIgnoreCase)) return true;
        if (string.Equals(forced, "day", StringComparison.OrdinalIgnoreCase)) return false;
        try { return TrueMode.Read(AppContext.BaseDirectory.TrimEnd(Path.DirectorySeparatorChar)).Is165; }
        catch (Exception) { return false; }
    }

    /// <summary>A theme colour: as given in the normal theme, moved to the night palette in True 1.65 Mode.</summary>
    internal static Color Tint(int r, int g, int b) => Tint(255, r, g, b);

    internal static Color Tint(int a, int r, int g, int b)
    {
        Color c = Color.FromArgb(a, Math.Clamp(r, 0, 255), Math.Clamp(g, 0, 255), Math.Clamp(b, 0, 255));
        return Night ? ToNight(c) : c;
    }

    private static Color ToNight(Color c)
    {
        float hue = c.GetHue(), sat = c.GetSaturation(), light = c.GetBrightness();
        if (sat > 0.12f && (hue < 12f || hue > 60f))
            return c;                                   // realm colours, red / green buttons, blues: unchanged
        float s, l;
        if (light > 0.42f && sat > 0.25f)
        {
            s = 0.16f;                                  // gold accents and parchment: moonlight silver
            l = Math.Min(0.86f, light + 0.18f);
        }
        else if (light > 0.55f)
        {
            s = 0.18f;                                  // pale text: blue-grey
            l = light;
        }
        else
        {
            s = Math.Min(0.5f, 0.30f + sat * 0.3f);     // stone and panels: night blue
            l = light * 0.95f;
        }
        return FromHsl(c.A, 214f, s, l);
    }

    private static Color FromHsl(int a, float h, float s, float l)
    {
        float q = l < 0.5f ? l * (1 + s) : l + s - l * s, p = 2 * l - q;
        float Channel(float t)
        {
            t = t < 0 ? t + 1 : t > 1 ? t - 1 : t;
            return t < 1f / 6 ? p + (q - p) * 6 * t : t < 0.5f ? q : t < 2f / 3 ? p + (q - p) * (2f / 3 - t) * 6 : p;
        }
        float k = h / 360f;
        return Color.FromArgb(a, (int)Math.Round(Channel(k + 1f / 3) * 255), (int)Math.Round(Channel(k) * 255),
            (int)Math.Round(Channel(k - 1f / 3) * 255));
    }

    internal static readonly Color Void = Tint(18, 15, 12);
    internal static readonly Color Stone = Tint(47, 43, 36);
    internal static readonly Color StoneDark = Tint(25, 24, 21);
    internal static readonly Color StoneLight = Tint(79, 71, 56);
    internal static readonly Color Iron = Tint(102, 100, 90);
    internal static readonly Color Gold = Tint(194, 157, 77);
    internal static readonly Color GoldLight = Tint(232, 205, 135);
    internal static readonly Color Parchment = Tint(215, 199, 157);
    internal static readonly Color Ink = Tint(43, 32, 22);
    internal static readonly Color Panel = Tint(35, 31, 26);
    internal static readonly Color PanelAlt = Tint(42, 37, 30);
    internal static readonly Color Text = Tint(224, 215, 190);
    internal static readonly Color Muted = Tint(166, 154, 128);
    internal static readonly Color Success = Tint(139, 191, 104);
    internal static readonly Color Danger = Tint(232, 95, 83);
    internal static readonly Color Albion = Tint(171, 64, 58);
    internal static readonly Color Midgard = Tint(62, 94, 144);
    internal static readonly Color Hibernia = Tint(57, 117, 66);
}

internal sealed class StoneSurface : Panel
{
    public StoneSurface()
    {
        DoubleBuffered = true;
        ResizeRedraw = true;
        Padding = new Padding(14);
    }

    protected override void OnPaintBackground(PaintEventArgs e)
    {
        using var background = new LinearGradientBrush(ClientRectangle, DaocTheme.Tint(54, 50, 42), DaocTheme.Tint(25, 23, 20), 90f);
        e.Graphics.FillRectangle(background, ClientRectangle);

        // Subtle deterministic banding gives the surface the compressed stone texture
        // common to small fan launchers without shipping a large modern art asset.
        for (var y = 5; y < Height; y += 7)
        {
            var shade = 33 + ((y * 17) % 13);
            using var texture = new Pen(DaocTheme.Tint(65, shade + 12, shade + 8, shade));
            e.Graphics.DrawLine(texture, 2, y, Width - 3, y);
        }

        using var outer = new Pen(DaocTheme.Tint(12, 10, 8), 2f);
        using var middle = new Pen(DaocTheme.StoneLight);
        using var inner = new Pen(DaocTheme.Tint(112, 91, 61));
        e.Graphics.DrawRectangle(outer, 1, 1, Math.Max(0, Width - 3), Math.Max(0, Height - 3));
        e.Graphics.DrawRectangle(middle, 3, 3, Math.Max(0, Width - 7), Math.Max(0, Height - 7));
        e.Graphics.DrawRectangle(inner, 6, 6, Math.Max(0, Width - 13), Math.Max(0, Height - 13));
    }
}

internal sealed class InsetPanel : Panel
{
    [Browsable(false)]
    [DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
    public Color Accent { get; init; } = DaocTheme.Gold;

    public InsetPanel()
    {
        DoubleBuffered = true;
        ResizeRedraw = true;
        BackColor = DaocTheme.Panel;
        Padding = new Padding(2);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        base.OnPaint(e);
        using var shadow = new Pen(DaocTheme.Tint(10, 9, 7), 2f);
        using var edge = new Pen(DaocTheme.StoneLight);
        using var accent = new Pen(Accent);
        e.Graphics.DrawRectangle(shadow, 1, 1, Math.Max(0, Width - 3), Math.Max(0, Height - 3));
        e.Graphics.DrawLine(edge, 3, 3, Width - 4, 3);
        e.Graphics.DrawLine(accent, 3, Height - 4, Width - 4, Height - 4);
    }
}

internal sealed class RuneButton : Button
{
    [Browsable(false)]
    [DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
    public bool ShowOrnaments { get; set; } = true;
    private bool _hovered;
    private bool _pressed;
    [Browsable(false)]
    [DesignerSerializationVisibility(DesignerSerializationVisibility.Hidden)]
    public Color Accent { get; init; } = DaocTheme.Gold;

    public RuneButton()
    {
        DoubleBuffered = true;
        FlatStyle = FlatStyle.Flat;
        FlatAppearance.BorderSize = 0;
        Cursor = Cursors.Hand;
        Font = new Font("Georgia", 8.25f, FontStyle.Bold);
        ForeColor = DaocTheme.GoldLight;
        Width = 104;
        Height = 31;
        Margin = new Padding(4, 0, 0, 0);
    }

    protected override void OnMouseEnter(EventArgs e) { _hovered = true; Invalidate(); base.OnMouseEnter(e); }
    protected override void OnMouseLeave(EventArgs e) { _hovered = false; _pressed = false; Invalidate(); base.OnMouseLeave(e); }
    protected override void OnMouseDown(MouseEventArgs e) { _pressed = true; Invalidate(); base.OnMouseDown(e); }
    protected override void OnMouseUp(MouseEventArgs e) { _pressed = false; Invalidate(); base.OnMouseUp(e); }
    protected override void OnEnabledChanged(EventArgs e) { Invalidate(); base.OnEnabledChanged(e); }

    protected override void OnPaint(PaintEventArgs e)
    {
        var bounds = new Rectangle(0, 0, Width - 1, Height - 1);
        var top = _pressed ? DaocTheme.Tint(30, 27, 23) : _hovered ? DaocTheme.Tint(77, 68, 52) : DaocTheme.Tint(58, 52, 42);
        var bottom = _pressed ? DaocTheme.Tint(51, 45, 36) : DaocTheme.Tint(27, 25, 22);
        using var fill = new LinearGradientBrush(bounds, top, bottom, 90f);
        e.Graphics.FillRectangle(fill, bounds);
        using var outer = new Pen(DaocTheme.Tint(12, 10, 8));
        using var inner = new Pen(Enabled ? Accent : DaocTheme.Tint(86, 82, 72));
        using var shine = new Pen(DaocTheme.Tint(112, 102, 81));
        e.Graphics.DrawRectangle(outer, bounds);
        e.Graphics.DrawRectangle(inner, 2, 2, Width - 5, Height - 5);
        e.Graphics.DrawLine(shine, 3, 3, Width - 4, 3);

        using var ornament = new SolidBrush(Enabled ? Accent : DaocTheme.Tint(86, 82, 72));
        Point[] leftDiamond = [new(8, Height / 2), new(11, Height / 2 - 3), new(14, Height / 2), new(11, Height / 2 + 3)];
        Point[] rightDiamond = [new(Width - 9, Height / 2), new(Width - 12, Height / 2 - 3), new(Width - 15, Height / 2), new(Width - 12, Height / 2 + 3)];
        if (ShowOrnaments)
        {
            e.Graphics.FillPolygon(ornament, leftDiamond);
            e.Graphics.FillPolygon(ornament, rightDiamond);
        }

        var offset = _pressed ? 1 : 0;
        TextRenderer.DrawText(e.Graphics, Text, Font, new Rectangle(offset, offset, Width, Height),
            Enabled ? ForeColor : DaocTheme.Tint(111, 106, 94), TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
    }
}

internal sealed class FantasyBanner : Panel
{
    private static readonly Lazy<Image?> Artwork = new(() =>
    {
        using Stream? stream = Assembly.GetExecutingAssembly()
            .GetManifestResourceStream("OfflineDaoc.Launcher.Assets.offline-daoc-header.png");
        if (stream == null)
            return null;
        using var loaded = new Bitmap(stream);
        return new Bitmap(loaded);
    });

    public FantasyBanner()
    {
        DoubleBuffered = true;
        ResizeRedraw = true;
        Padding = new Padding(4);
    }

    /// <summary>The full moon of the 1.64 character screen, left of the header buttons, with a soft halo.</summary>
    private void DrawMoon(Graphics g)
    {
        float r = Math.Clamp(Height * 0.27f, 10f, 24f);
        float cx = Width - 316 - 26 - r, cy = Math.Max(r + 8, Height * 0.36f);
        if (cx - r < Width * 0.45f)
            return;                                     // too narrow: no room beside the title
        g.SmoothingMode = SmoothingMode.AntiAlias;
        using (var halo = new GraphicsPath())
        {
            halo.AddEllipse(cx - r * 3, cy - r * 3, r * 6, r * 6);
            using var glow = new PathGradientBrush(halo)
            {
                CenterColor = Color.FromArgb(70, 170, 190, 225),
                SurroundColors = [Color.FromArgb(0, 20, 35, 70)],
            };
            g.FillPath(glow, halo);
        }
        var disc = new RectangleF(cx - r, cy - r, r * 2, r * 2);
        using (var face = new LinearGradientBrush(disc, Color.FromArgb(236, 238, 232), Color.FromArgb(150, 156, 160), 60f))
            g.FillEllipse(face, disc);
        using (var mare = new SolidBrush(Color.FromArgb(55, 70, 76, 86)))
        {
            g.FillEllipse(mare, cx - r * 0.55f, cy - r * 0.45f, r * 0.55f, r * 0.42f);
            g.FillEllipse(mare, cx + r * 0.05f, cy - r * 0.10f, r * 0.50f, r * 0.55f);
            g.FillEllipse(mare, cx - r * 0.35f, cy + r * 0.25f, r * 0.35f, r * 0.28f);
        }
        g.SmoothingMode = SmoothingMode.Default;
    }

    protected override void OnPaintBackground(PaintEventArgs e)
    {
        e.Graphics.Clear(DaocTheme.Tint(18, 19, 18));
        Image? artwork = Artwork.Value;
        if (artwork != null && Width > 0 && Height > 0)
        {
            float scale = Math.Max(Width / (float)artwork.Width, Height / (float)artwork.Height);
            float sourceWidth = Width / scale;
            float sourceHeight = Height / scale;
            float sourceX = Math.Max(0, (artwork.Width - sourceWidth) / 2f);
            float sourceY = Math.Max(0, (artwork.Height - sourceHeight) / 2f);
            e.Graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            if (DaocTheme.Night)
            {
                // Moonlit: the artwork's brightness carried in night blue (the 1.64 standing-stones sky).
                float[] R = [0.45f, 0.60f, 0.95f];
                var matrix = new System.Drawing.Imaging.ColorMatrix(
                [
                    [0.30f * R[0], 0.30f * R[1], 0.30f * R[2], 0, 0],
                    [0.59f * R[0], 0.59f * R[1], 0.59f * R[2], 0, 0],
                    [0.11f * R[0], 0.11f * R[1], 0.11f * R[2], 0, 0],
                    [0, 0, 0, 1, 0],
                    [0.01f, 0.02f, 0.05f, 0, 1],
                ]);
                using var night = new System.Drawing.Imaging.ImageAttributes();
                night.SetColorMatrix(matrix);
                e.Graphics.DrawImage(artwork, ClientRectangle, sourceX, sourceY, sourceWidth, sourceHeight, GraphicsUnit.Pixel, night);
            }
            else
                e.Graphics.DrawImage(artwork, ClientRectangle,
                    sourceX, sourceY, sourceWidth, sourceHeight, GraphicsUnit.Pixel);
        }

        using var shade = new LinearGradientBrush(ClientRectangle,
            DaocTheme.Tint(190, 10, 9, 8), DaocTheme.Tint(80, 10, 9, 8), 0f);
        e.Graphics.FillRectangle(shade, ClientRectangle);
        using var lowerShade = new LinearGradientBrush(ClientRectangle,
            DaocTheme.Tint(5, 0, 0, 0), DaocTheme.Tint(105, 0, 0, 0), 90f);
        e.Graphics.FillRectangle(lowerShade, ClientRectangle);
        if (DaocTheme.Night)
            DrawMoon(e.Graphics);

        using var outer = new Pen(DaocTheme.Tint(8, 7, 5), 2f);
        using var gold = new Pen(DaocTheme.Tint(113, 83, 43));
        e.Graphics.DrawRectangle(outer, 1, 1, Math.Max(0, Width - 3), Math.Max(0, Height - 3));
        e.Graphics.DrawRectangle(gold, 3, 3, Math.Max(0, Width - 7), Math.Max(0, Height - 7));
    }
}

// Inspired by the classic Camelot knot (the game client's effects/camknot.tga): the dragon
// in the triquetra with the Hibernia tree, Midgard hammer and Albion grail, in gold, red and
// the realm colours.
internal sealed class RealmShieldPicture : PictureBox
{
    private static readonly Lazy<Image?> Shield = new(() =>
    {
        using Stream? stream = Assembly.GetExecutingAssembly()
            .GetManifestResourceStream("OfflineDaoc.Launcher.Assets.offline-daoc-realm-emblem.png");
        if (stream == null)
            return null;
        using var loaded = new Bitmap(stream);
        return new Bitmap(loaded);
    });

    public RealmShieldPicture()
    {
        BackColor = Color.Transparent;
        Image = Shield.Value;
        SizeMode = PictureBoxSizeMode.Zoom;
        TabStop = false;
    }
}

internal sealed class DaocTabControl : TabControl
{
    public DaocTabControl()
    {
        DrawMode = TabDrawMode.OwnerDrawFixed;
        SizeMode = TabSizeMode.Fixed;
        ItemSize = new Size(172, 29);
        Padding = new Point(8, 3);
        Font = new Font("Georgia", 9f, FontStyle.Bold);
    }

    protected override void OnDrawItem(DrawItemEventArgs e)
    {
        var selected = e.Index == SelectedIndex;
        var rectangle = GetTabRect(e.Index);
        rectangle.Inflate(-1, 0);
        using var fill = new LinearGradientBrush(rectangle,
            selected ? DaocTheme.Tint(79, 65, 42) : DaocTheme.Tint(47, 43, 36),
            selected ? DaocTheme.Tint(39, 32, 23) : DaocTheme.Tint(25, 24, 21), 90f);
        e.Graphics.FillRectangle(fill, rectangle);
        using var border = new Pen(selected ? DaocTheme.Gold : DaocTheme.Iron);
        e.Graphics.DrawRectangle(border, rectangle.X, rectangle.Y, rectangle.Width - 1, rectangle.Height - 1);
        TextRenderer.DrawText(e.Graphics, TabPages[e.Index].Text.ToUpperInvariant(), Font, rectangle,
            selected ? DaocTheme.GoldLight : DaocTheme.Muted,
            TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
    }

    protected override void WndProc(ref Message message)
    {
        base.WndProc(ref message);
        if (message.Msg != 0x000F || !IsHandleCreated || TabCount == 0) return;

        using var graphics = Graphics.FromHwnd(Handle);
        var lastTab = GetTabRect(TabCount - 1);
        var headerHeight = Math.Max(lastTab.Bottom + 2, DisplayRectangle.Top);
        using var fill = new SolidBrush(DaocTheme.StoneDark);
        graphics.FillRectangle(fill, lastTab.Right, 0, Math.Max(0, Width - lastTab.Right), headerHeight);
        using var edge = new Pen(DaocTheme.Tint(116, 88, 48));
        graphics.DrawLine(edge, lastTab.Right, headerHeight - 1, Width, headerHeight - 1);
    }
}
