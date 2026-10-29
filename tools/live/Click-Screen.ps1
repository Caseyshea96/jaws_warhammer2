# Left-click at physical screen pixels (Capture-Screen coordinates divided by
# its -Scale). Stands in for a user's manual mouse action during live tests;
# never use it on Start Campaign or anything irreversible.
param([Parameter(Mandatory=$true)][int]$X, [Parameter(Mandatory=$true)][int]$Y, [switch]$MoveOnly)
Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public static class Mouse {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, UIntPtr e);
}
'@
[void][Mouse]::SetProcessDPIAware()
[void][Mouse]::SetCursorPos($X, $Y)
if ($MoveOnly) { "MOVED $X,$Y"; return }  # e.g. park the cursor so no hover tooltip shows
Start-Sleep -Milliseconds 150
[Mouse]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)  # left down
Start-Sleep -Milliseconds 80
[Mouse]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)  # left up
"CLICKED $X,$Y"
