namespace OfflineDaoc.Launcher;

internal sealed partial class MainForm
{
    private DateTime? _keepRelicResetUtc;

    private Control BuildActiveRvrHeader()
    {
        var header = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, RowCount = 1, Margin = Padding.Empty, BackColor = DaocTheme.Panel, Font = Font };
        header.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        header.ColumnStyles.Add(new ColumnStyle(SizeType.AutoSize));
        header.Controls.Add(new Label { Text = "ACTIVE RVR — roaming bots and warbands · keeps and relics are in Realm Events", Dock = DockStyle.Fill,
            ForeColor = DaocTheme.GoldLight, TextAlign = ContentAlignment.MiddleLeft, AutoEllipsis = true }, 0, 0);
        // Reset Keeps & Relics is not a player option (owner 2026-10-31); releases still reset the slate (KeepRelicReset).
        return header;
    }
}
