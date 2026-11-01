Add-Type -AssemblyName System.Drawing

$out = $PSScriptRoot

function New-RoundedRect([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $p = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

$bmp = [System.Drawing.Bitmap]::new(1024, 1024, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$bgPath = New-RoundedRect 24 24 976 976 190
$bgBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.PointF]::new(24, 24),
    [System.Drawing.PointF]::new(1000, 1000),
    [System.Drawing.Color]::FromArgb(255, 26, 82, 174),
    [System.Drawing.Color]::FromArgb(255, 13, 178, 162))
$g.FillPath($bgBrush, $bgPath)

$light = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 233, 238, 243))

$handle = New-RoundedRect 452 268 120 56 26
$g.FillPath($light, $handle)

$lid = New-RoundedRect 300 308 424 64 30
$g.FillPath($light, $lid)

$bodyPts = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(324, 384),
    [System.Drawing.PointF]::new(700, 384),
    [System.Drawing.PointF]::new(672, 842),
    [System.Drawing.PointF]::new(352, 842))
$bodyPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$bodyPath.AddPolygon($bodyPts)
$bodyBrush = [System.Drawing.Drawing2D.LinearGradientBrush]::new(
    [System.Drawing.PointF]::new(512, 384),
    [System.Drawing.PointF]::new(512, 842),
    [System.Drawing.Color]::FromArgb(255, 244, 248, 251),
    [System.Drawing.Color]::FromArgb(255, 196, 209, 221))
$g.FillPath($bodyBrush, $bodyPath)

$g.SetClip($bodyPath)
$ridgeBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(170, 158, 175, 190))
foreach ($x in 404, 476, 548, 620) {
    $rp = New-RoundedRect ($x - 8) 420 16 380 8
    $g.FillPath($ridgeBrush, $rp)
    $rp.Dispose()
}
$g.ResetClip()

$cx = 512.0; $cy = 600.0; $R = 104.0; $pw = 36.0; $L = 52.0; $hw = 27.0
$greenCol = [System.Drawing.Color]::FromArgb(255, 33, 176, 92)
$pen = [System.Drawing.Pen]::new($greenCol, [float]$pw)
$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Flat
$greenBrush = [System.Drawing.SolidBrush]::new($greenCol)
$arcRect = [System.Drawing.RectangleF]::new([float]($cx - $R), [float]($cy - $R), [float]($R * 2), [float]($R * 2))
$rad = [math]::PI / 180.0
for ($i = 0; $i -lt 3; $i++) {
    $a0 = 90.0 + $i * 120.0
    $sweep = 84.0
    $g.DrawArc($pen, $arcRect, [float]$a0, [float]$sweep)
    $ae = $a0 + $sweep
    $px = $cx + $R * [math]::Cos($ae * $rad)
    $py = $cy + $R * [math]::Sin($ae * $rad)
    $tang = ($ae + 90.0) * $rad
    $ux = [math]::Cos($tang); $uy = [math]::Sin($tang)
    $nx = [math]::Cos($ae * $rad); $ny = [math]::Sin($ae * $rad)
    $bx = $px - $ux * 10.0; $by = $py - $uy * 10.0
    $tip = [System.Drawing.PointF]::new([float]($bx + $ux * $L), [float]($by + $uy * $L))
    $b1 = [System.Drawing.PointF]::new([float]($bx + $nx * $hw), [float]($by + $ny * $hw))
    $b2 = [System.Drawing.PointF]::new([float]($bx - $nx * $hw), [float]($by - $ny * $hw))
    $g.FillPolygon($greenBrush, [System.Drawing.PointF[]]@($tip, $b1, $b2))
}

$g.Dispose()
$bmp.Save((Join-Path $out 'icon_1024.png'), [System.Drawing.Imaging.ImageFormat]::Png)

$sizes = 16, 24, 32, 48, 64, 128, 256
$entries = @()
foreach ($s in $sizes) {
    $sb = [System.Drawing.Bitmap]::new($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $sg = [System.Drawing.Graphics]::FromImage($sb)
    $sg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $sg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $rect = [System.Drawing.Rectangle]::new(0, 0, $s, $s)
    $sg.DrawImage($bmp, $rect)
    $sg.Dispose()
    $ms = [System.IO.MemoryStream]::new()
    $sb.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $entries += [pscustomobject]@{ Size = $s; Data = $ms.ToArray() }
    $ms.Dispose()
    $sb.Dispose()
}

$icoPath = Join-Path $out 'app.ico'
$fs = [System.IO.File]::Create($icoPath)
$bw = [System.IO.BinaryWriter]::new($fs)
$bw.Write([uint16]0)
$bw.Write([uint16]1)
$bw.Write([uint16]$entries.Count)
$offset = 6 + 16 * $entries.Count
foreach ($e in $entries) {
    $dim = if ($e.Size -ge 256) { [byte]0 } else { [byte]$e.Size }
    $bw.Write($dim)
    $bw.Write($dim)
    $bw.Write([byte]0)
    $bw.Write([byte]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]32)
    $bw.Write([uint32]$e.Data.Length)
    $bw.Write([uint32]$offset)
    $offset += $e.Data.Length
}
foreach ($e in $entries) { $bw.Write($e.Data) }
$bw.Dispose()
$fs.Dispose()
Write-Output ("ICO OK: " + $entries.Count + " sizes, " + (Get-Item $icoPath).Length + " bytes")
