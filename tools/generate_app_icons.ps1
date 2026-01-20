param(
  [string]$SvgPath = "ic_resource_management.svg",
  [string]$AssetsDir = "assets/icon",
  [string]$WindowsIcoPath = "windows/runner/resources/app_icon.ico"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName PresentationCore, PresentationFramework
Add-Type -AssemblyName System.Drawing

if (-not (Test-Path $SvgPath)) {
  throw "SVG not found: $SvgPath"
}

[xml]$svg = Get-Content $SvgPath
$paths = $svg.SelectNodes("//*[local-name()='path']") | ForEach-Object { $_.d }
if (-not $paths -or $paths.Count -eq 0) {
  throw "No path data found in $SvgPath"
}

$bgBrush = New-Object System.Windows.Media.LinearGradientBrush
$bgBrush.StartPoint = [System.Windows.Point]::new(0, 0)
$bgBrush.EndPoint = [System.Windows.Point]::new(1, 1)
$bgBrush.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromRgb(0x1e, 0x5a, 0xa8), 0))
$bgBrush.GradientStops.Add([System.Windows.Media.GradientStop]::new([System.Windows.Media.Color]::FromRgb(0x18, 0xa4, 0x9f), 1))

$iconBrush = [System.Windows.Media.Brushes]::White

function Render-Png {
  param(
    [int]$Size,
    [string]$OutPath
  )

  $visual = New-Object System.Windows.Media.DrawingVisual
  $dc = $visual.RenderOpen()

  $radius = [Math]::Round($Size * 0.195)
  $dc.DrawRoundedRectangle(
    $bgBrush,
    $null,
    [System.Windows.Rect]::new(0, 0, $Size, $Size),
    $radius,
    $radius
  )

  # Apply a uniform inset to keep the glyph away from edges.
  $scale = ($Size / 1024.0) * 0.82
  $transform = New-Object System.Windows.Media.TransformGroup
  $transform.Children.Add([System.Windows.Media.TranslateTransform]::new(-512, -512))
  $transform.Children.Add([System.Windows.Media.ScaleTransform]::new($scale, $scale))
  $transform.Children.Add([System.Windows.Media.TranslateTransform]::new($Size / 2.0, $Size / 2.0))

  $dc.PushTransform($transform)
  foreach ($d in $paths) {
    $geom = [System.Windows.Media.Geometry]::Parse($d)
    $dc.DrawGeometry($iconBrush, $null, $geom)
  }
  $dc.Pop()
  $dc.Close()

  $rtb = New-Object System.Windows.Media.Imaging.RenderTargetBitmap($Size, $Size, 96, 96, [System.Windows.Media.PixelFormats]::Pbgra32)
  $rtb.Render($visual)

  $encoder = New-Object System.Windows.Media.Imaging.PngBitmapEncoder
  $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($rtb))

  $outDir = Split-Path -Parent $OutPath
  if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
  }
  $stream = [System.IO.File]::Open($OutPath, [System.IO.FileMode]::Create)
  $encoder.Save($stream)
  $stream.Close()
}

if (-not (Test-Path $AssetsDir)) {
  New-Item -ItemType Directory -Path $AssetsDir | Out-Null
}

$sourcePng = Join-Path $AssetsDir "app_icon.png"
Render-Png -Size 1024 -OutPath $sourcePng

$androidSizes = @{
  "mipmap-mdpi" = 48
  "mipmap-hdpi" = 72
  "mipmap-xhdpi" = 96
  "mipmap-xxhdpi" = 144
  "mipmap-xxxhdpi" = 192
}

foreach ($kvp in $androidSizes.GetEnumerator()) {
  $outPath = Join-Path "android/app/src/main/res" (Join-Path $kvp.Key "ic_launcher.png")
  Render-Png -Size $kvp.Value -OutPath $outPath
}

$windowsPng = Join-Path $AssetsDir "app_icon_256.png"
Render-Png -Size 256 -OutPath $windowsPng

$bmp = New-Object System.Drawing.Bitmap $windowsPng
$icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$fs = New-Object System.IO.FileStream($WindowsIcoPath, [System.IO.FileMode]::Create)
$icon.Save($fs)
$fs.Close()
$icon.Dispose()
$bmp.Dispose()

Write-Host "Generated icon assets:"
Write-Host " - $sourcePng"
Write-Host " - android/app/src/main/res/mipmap-*/ic_launcher.png"
Write-Host " - $WindowsIcoPath"
