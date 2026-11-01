param([int]$ProcessId, [string]$Text = "exit")
# Types a line into another process's console window (clean server shutdown with "exit").
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class ConsoleSend {
    [StructLayout(LayoutKind.Explicit, CharSet = CharSet.Unicode)]
    public struct KEY_EVENT_RECORD {
        [FieldOffset(0)] public int bKeyDown; [FieldOffset(4)] public short wRepeatCount;
        [FieldOffset(6)] public short wVirtualKeyCode; [FieldOffset(8)] public short wVirtualScanCode;
        [FieldOffset(10)] public char UnicodeChar; [FieldOffset(12)] public int dwControlKeyState; }
    [StructLayout(LayoutKind.Explicit)]
    public struct INPUT_RECORD { [FieldOffset(0)] public short EventType; [FieldOffset(4)] public KEY_EVENT_RECORD KeyEvent; }
    [DllImport("kernel32.dll", SetLastError = true)] public static extern bool FreeConsole();
    [DllImport("kernel32.dll", SetLastError = true)] public static extern bool AttachConsole(int pid);
    [DllImport("kernel32.dll", SetLastError = true)] public static extern IntPtr CreateFile(string name, uint access, uint share, IntPtr sa, uint disp, uint flags, IntPtr tmpl);
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)] public static extern bool WriteConsoleInput(IntPtr h, INPUT_RECORD[] rec, int len, out int written);
    public static string Send(int pid, string text) {
        FreeConsole();
        if (!AttachConsole(pid)) return "attach failed " + Marshal.GetLastWin32Error();
        IntPtr h = CreateFile("CONIN$", 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero);
        string s = text + "\r";
        var recs = new INPUT_RECORD[s.Length * 2];
        for (int i = 0; i < s.Length; i++) {
            for (int d = 0; d < 2; d++) {
                var r = new INPUT_RECORD(); r.EventType = 1;
                r.KeyEvent.bKeyDown = d == 0 ? 1 : 0; r.KeyEvent.wRepeatCount = 1; r.KeyEvent.UnicodeChar = s[i];
                r.KeyEvent.wVirtualKeyCode = (short)(s[i] == '\r' ? 0x0D : 0);
                recs[i * 2 + d] = r; } }
        int written; bool ok = WriteConsoleInput(h, recs, recs.Length, out written);
        FreeConsole();
        return ok ? "sent " + written : "write failed " + Marshal.GetLastWin32Error();
    }
}
"@
[ConsoleSend]::Send($ProcessId, $Text)
