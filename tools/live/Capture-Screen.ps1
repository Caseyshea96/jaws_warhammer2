# Save a screenshot of the primary screen (for visually confirming the main
# menu or Select Lord when no computer-use tool is available).
param([Parameter(Mandatory=$true)][string]$Path, [double]$Scale = 0.5)
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public static class Dpi { [DllImport("user32.dll")] public static extern bool SetProcessDPIAware(); }'
[void][Dpi]::SetProcessDPIAware()
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$full = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
$g = [System.Drawing.Graphics]::FromImage($full)
$g.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$small = New-Object System.Drawing.Bitmap $full, ([int]($bounds.Width * $Scale)), ([int]($bounds.Height * $Scale))
$small.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $full.Dispose(); $small.Dispose()
$Path
