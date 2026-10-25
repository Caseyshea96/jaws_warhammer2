using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace JawsPilot {
    public class HotkeyArgs : EventArgs { public int Id; public HotkeyArgs(int id) { Id = id; } }
    public sealed class Hotkeys : NativeWindow, IDisposable {
        [DllImport("user32.dll")] private static extern bool RegisterHotKey(IntPtr h, int id, uint mods, uint key);
        [DllImport("user32.dll")] private static extern bool UnregisterHotKey(IntPtr h, int id);
        public event EventHandler<HotkeyArgs> Pressed;
        private readonly HotkeyPolicy policy;
        public Hotkeys() {
            CreateHandle(new CreateParams());
            policy = new HotkeyPolicy(
                (id,key) => RegisterHotKey(Handle,id,0x4003,(uint)key),
                id => UnregisterHotKey(Handle,id));
        }
        public void Configure(int id, int key) { policy.Add(id,key); }
        public int[] UpdateFocus(bool enabled) { return policy.SetActive(enabled && Pointer.GameFocused()); }
        protected override void WndProc(ref Message m) {
            if (m.Msg == 0x0312 && policy != null && Pointer.GameFocused() && policy.CanDispatch(m.WParam.ToInt32()) && Pressed != null) Pressed(this, new HotkeyArgs(m.WParam.ToInt32()));
            base.WndProc(ref m);
        }
        public void Dispose() { policy.Dispose(); DestroyHandle(); }
    }
    public static class Pointer {
        [StructLayout(LayoutKind.Sequential)] private struct Rect { public int L, T, R, B; }
        [StructLayout(LayoutKind.Sequential)] private struct Point { public int X, Y; }
        [DllImport("user32.dll")] private static extern IntPtr GetForegroundWindow();
        [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
        [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr h, out Rect r);
        [DllImport("user32.dll")] private static extern bool ClientToScreen(IntPtr h, ref Point p);
        [DllImport("user32.dll")] private static extern bool GetCursorPos(out Point p);
        [DllImport("user32.dll")] private static extern bool SetCursorPos(int x, int y);
        [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
        [DllImport("user32.dll")] private static extern void mouse_event(uint flags, uint x, uint y, uint data, UIntPtr extra);
        [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
        public static bool GameFocused() {
            uint pid; GetWindowThreadProcessId(GetForegroundWindow(), out pid);
            try { return Process.GetProcessById((int)pid).ProcessName.Equals("Warhammer2", StringComparison.OrdinalIgnoreCase); }
            catch { return false; }
        }
        public static bool ModifiersReleased() {
            return (GetAsyncKeyState(0x11) & 0x8000) == 0 && (GetAsyncKeyState(0x12) & 0x8000) == 0
                && (GetAsyncKeyState(0x10) & 0x8000) == 0;
        }
        public static string Move(int dx, int dy, bool center) {
            if (!GameFocused()) return "Bring Warhammer II to the foreground first.";
            IntPtr h = GetForegroundWindow(); Rect r; Point origin = new Point(); Point p;
            if (!GetClientRect(h, out r) || !ClientToScreen(h, ref origin) || !GetCursorPos(out p)) return "Cannot read game window coordinates.";
            int w = r.R - r.L, height = r.B - r.T;
            if (w < 2 || height < 2) return "Game window has no usable area.";
            int x = center ? w / 2 : Math.Max(0, Math.Min(w - 1, p.X - origin.X + dx));
            int y = center ? height / 2 : Math.Max(0, Math.Min(height - 1, p.Y - origin.Y + dy));
            if (!SetCursorPos(origin.X + x, origin.Y + y)) return "Could not move cursor.";
            return "Cursor " + (100 * x / w) + " percent from left, " + (100 * y / height) + " percent from top.";
        }
        public static string Click(bool right) {
            if (!GameFocused()) return "Bring Warhammer II to the foreground first.";
            Rect r; Point origin = new Point(), p; IntPtr h = GetForegroundWindow();
            if (!GetClientRect(h, out r) || !ClientToScreen(h, ref origin) || !GetCursorPos(out p)) return "Cannot read cursor position.";
            if (p.X < origin.X || p.Y < origin.Y || p.X >= origin.X + r.R || p.Y >= origin.Y + r.B) return "Cursor is outside the game window.";
            // Ordinary input: the game decides target validity, turn restrictions and unit control.
            mouse_event(right ? 0x0008u : 0x0002u, 0, 0, 0, UIntPtr.Zero);
            mouse_event(right ? 0x0010u : 0x0004u, 0, 0, 0, UIntPtr.Zero);
            return right ? "Right click sent at cursor. Verify the resulting order." : "Left click sent at cursor.";
        }
    }
}
