$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$projectRoot = Split-Path -Parent $PSScriptRoot
$assetDir = Join-Path $projectRoot "report_assets"
$buildDir = Join-Path $projectRoot "report_docx"
$mediaDir = Join-Path $buildDir "word\media"
$relsDir = Join-Path $buildDir "word\_rels"
$rootRelsDir = Join-Path $buildDir "_rels"
$outputPath = Join-Path $projectRoot "Project_Report.docx"
$zipPath = Join-Path $projectRoot "Project_Report.zip"
$dataPath = Join-Path $projectRoot "report_data_zh.json"
$data = Get-Content -Raw $dataPath | ConvertFrom-Json

foreach ($dir in @($assetDir, $buildDir, $mediaDir, $relsDir, $rootRelsDir)) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

foreach ($path in @($outputPath, $zipPath)) {
  if (Test-Path $path) {
    Remove-Item $path -Force
  }
}

function New-Brush([string]$hex) {
  New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function New-Pen([string]$hex, [float]$width = 2) {
  New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml($hex)), $width
}

function Draw-RoundedBox {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.RectangleF]$Rect,
    [float]$Radius,
    [string]$FillColor,
    [string]$BorderColor
  )

  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $diameter = $Radius * 2
  $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
  $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
  $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
  $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()

  $fill = New-Brush $FillColor
  $pen = New-Pen $BorderColor 2
  $Graphics.FillPath($fill, $path)
  $Graphics.DrawPath($pen, $path)
  $fill.Dispose()
  $pen.Dispose()
  $path.Dispose()
}

function Draw-Arrow {
  param(
    [System.Drawing.Graphics]$Graphics,
    [float]$X1,
    [float]$Y1,
    [float]$X2,
    [float]$Y2,
    [string]$Color
  )

  $pen = New-Pen $Color 4
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::ArrowAnchor
  $Graphics.DrawLine($pen, $X1, $Y1, $X2, $Y2)
  $pen.Dispose()
}

function Save-Bitmap {
  param(
    [string]$Path,
    [int]$Width,
    [int]$Height,
    [scriptblock]$Painter
  )

  $bmp = New-Object System.Drawing.Bitmap $Width, $Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
  & $Painter $g
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

function Xml-Escape([string]$text) {
  if ($null -eq $text) { return "" }
  return [System.Security.SecurityElement]::Escape($text)
}

function New-ParagraphXml([string]$text) {
  return "<w:p><w:r><w:t>$(Xml-Escape $text)</w:t></w:r></w:p>"
}

function New-HeadingXml([string]$text) {
  return "<w:p><w:pPr><w:pStyle w:val=""Heading1""/></w:pPr><w:r><w:t>$(Xml-Escape $text)</w:t></w:r></w:p>"
}

$titleFont = New-Object System.Drawing.Font("Microsoft JhengHei UI", 28, [System.Drawing.FontStyle]::Bold)
$h2Font = New-Object System.Drawing.Font("Microsoft JhengHei UI", 18, [System.Drawing.FontStyle]::Bold)
$bodyFont = New-Object System.Drawing.Font("Microsoft JhengHei UI", 12, [System.Drawing.FontStyle]::Regular)
$smallFont = New-Object System.Drawing.Font("Microsoft JhengHei UI", 10, [System.Drawing.FontStyle]::Regular)

$ui = $data.images.ui
$uiImage = Join-Path $assetDir "ui_overview.png"
Save-Bitmap -Path $uiImage -Width 1280 -Height 720 -Painter {
  param($g)
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#f4efe3"))

  $ellipse1 = New-Brush "#dde8d9"
  $ellipse2 = New-Brush "#d6e6f2"
  $g.FillEllipse($ellipse1, -60, -80, 340, 260)
  $g.FillEllipse($ellipse2, 980, 480, 320, 220)
  $ellipse1.Dispose()
  $ellipse2.Dispose()

  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(70, 50, 1140, 620)) -Radius 36 -FillColor "#ffffff" -BorderColor "#d9d0bf"
  $darkBrush = New-Brush "#2f2a24"
  $mutedBrush = New-Brush "#6c655c"
  $accentBrush = New-Brush "#b9cfb3"
  $summaryBrush = New-Brush "#f0d69a"

  $g.DrawString($ui.title, $titleFont, $darkBrush, 100, 90)
  $g.DrawString($ui.subtitle, $bodyFont, $mutedBrush, 100, 145)

  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(95, 220, 340, 360)) -Radius 26 -FillColor "#faf8f2" -BorderColor "#d5ccba"
  $g.DrawString($ui.left_title, $h2Font, $darkBrush, 120, 250)
  $g.DrawString($ui.left_1, $bodyFont, $mutedBrush, 120, 300)
  $g.DrawString($ui.left_2, $bodyFont, $mutedBrush, 120, 340)
  $g.DrawString($ui.left_3, $bodyFont, $mutedBrush, 120, 380)
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(120, 450, 220, 60)) -Radius 18 -FillColor "#b9cfb3" -BorderColor "#98b28f"
  $g.DrawString($ui.left_button, $bodyFont, $darkBrush, 185, 467)

  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(470, 220, 320, 360)) -Radius 26 -FillColor "#faf8f2" -BorderColor "#d5ccba"
  $g.DrawString($ui.middle_title, $h2Font, $darkBrush, 495, 250)
  $g.DrawString($ui.middle_1, $bodyFont, $mutedBrush, 495, 300)
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(500, 360, 260, 150)) -Radius 22 -FillColor "#fff4d8" -BorderColor "#e3cc82"
  $g.DrawString($ui.middle_income, $bodyFont, $darkBrush, 530, 390)
  $g.DrawString($ui.middle_expense, $bodyFont, $darkBrush, 530, 430)
  $g.DrawString($ui.middle_balance, $bodyFont, $darkBrush, 530, 470)

  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(825, 220, 350, 360)) -Radius 26 -FillColor "#faf8f2" -BorderColor "#d5ccba"
  $g.DrawString($ui.right_title, $h2Font, $darkBrush, 850, 250)
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(850, 305, 300, 78)) -Radius 18 -FillColor "#f9fbfc" -BorderColor "#d1dbe2"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(850, 398, 300, 78)) -Radius 18 -FillColor "#f9fbfc" -BorderColor "#d1dbe2"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(850, 491, 300, 78)) -Radius 18 -FillColor "#f9fbfc" -BorderColor "#d1dbe2"
  $g.FillRectangle($accentBrush, 875, 330, 52, 24)
  $g.FillRectangle($summaryBrush, 875, 423, 52, 24)
  $g.FillRectangle($accentBrush, 875, 516, 52, 24)
  $g.DrawString($ui.right_1, $bodyFont, $darkBrush, 945, 325)
  $g.DrawString($ui.right_2, $bodyFont, $darkBrush, 945, 418)
  $g.DrawString($ui.right_3, $bodyFont, $darkBrush, 945, 511)
  $g.DrawString("NT$ 5,000", $smallFont, $mutedBrush, 1040, 330)
  $g.DrawString("NT$ 85", $smallFont, $mutedBrush, 1055, 423)
  $g.DrawString("NT$ 3,000", $smallFont, $mutedBrush, 1045, 516)

  foreach ($brush in @($darkBrush, $mutedBrush, $accentBrush, $summaryBrush)) {
    $brush.Dispose()
  }
}

$architecture = $data.images.architecture
$architectureImage = Join-Path $assetDir "architecture.png"
Save-Bitmap -Path $architectureImage -Width 1280 -Height 720 -Painter {
  param($g)
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#f7f3e9"))
  $titleBrush = New-Brush "#2c2926"
  $textBrush = New-Brush "#5f5a54"
  $g.DrawString($architecture.title, $titleFont, $titleBrush, 80, 50)
  $g.DrawString($architecture.subtitle, $bodyFont, $textBrush, 82, 105)

  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(110, 210, 240, 120)) -Radius 24 -FillColor "#fffdf8" -BorderColor "#d8cfbf"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(470, 120, 280, 120)) -Radius 24 -FillColor "#eef5fb" -BorderColor "#bfd3e6"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(470, 300, 280, 120)) -Radius 24 -FillColor "#edf5ea" -BorderColor "#bdd0b9"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(890, 210, 260, 120)) -Radius 24 -FillColor "#fff5e3" -BorderColor "#e3c98d"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(110, 470, 240, 120)) -Radius 24 -FillColor "#fffdf8" -BorderColor "#d8cfbf"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(470, 500, 280, 120)) -Radius 24 -FillColor "#f7eef2" -BorderColor "#d9b8c3"
  Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new(890, 470, 260, 120)) -Radius 24 -FillColor "#fffdf8" -BorderColor "#d8cfbf"

  $g.DrawString($architecture.browser, $h2Font, $titleBrush, 150, 245)
  $g.DrawString($architecture.browser_sub, $bodyFont, $textBrush, 135, 285)
  $g.DrawString("localStorage", $h2Font, $titleBrush, 530, 155)
  $g.DrawString($architecture.local, $bodyFont, $textBrush, 545, 195)
  $g.DrawString("Supabase", $h2Font, $titleBrush, 545, 335)
  $g.DrawString($architecture.supabase, $bodyFont, $textBrush, 530, 375)
  $g.DrawString("Vercel", $h2Font, $titleBrush, 965, 245)
  $g.DrawString($architecture.vercel, $bodyFont, $textBrush, 950, 285)
  $g.DrawString("GitHub", $h2Font, $titleBrush, 170, 505)
  $g.DrawString($architecture.github, $bodyFont, $textBrush, 175, 545)
  $g.DrawString("Build Script", $h2Font, $titleBrush, 510, 535)
  $g.DrawString($architecture.build, $bodyFont, $textBrush, 500, 575)
  $g.DrawString($architecture.site, $h2Font, $titleBrush, 915, 505)
  $g.DrawString($architecture.site, $bodyFont, $textBrush, 900, 545)

  Draw-Arrow -Graphics $g -X1 350 -Y1 270 -X2 470 -Y2 180 -Color "#7aa0c4"
  Draw-Arrow -Graphics $g -X1 350 -Y1 270 -X2 470 -Y2 360 -Color "#87aa7f"
  Draw-Arrow -Graphics $g -X1 750 -Y1 270 -X2 890 -Y2 270 -Color "#c59d42"
  Draw-Arrow -Graphics $g -X1 350 -Y1 530 -X2 470 -Y2 560 -Color "#c28aa1"
  Draw-Arrow -Graphics $g -X1 750 -Y1 560 -X2 890 -Y2 530 -Color "#c28aa1"
  Draw-Arrow -Graphics $g -X1 1010 -Y1 330 -X2 1010 -Y2 470 -Color "#c59d42"

  $titleBrush.Dispose()
  $textBrush.Dispose()
}

$flow = $data.images.flow
$flowImage = Join-Path $assetDir "build_flow.png"
Save-Bitmap -Path $flowImage -Width 1280 -Height 560 -Painter {
  param($g)
  $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#f5f1e7"))
  $titleBrush = New-Brush "#2c2926"
  $textBrush = New-Brush "#5f5a54"
  $g.DrawString($flow.title, $titleFont, $titleBrush, 80, 40)
  $g.DrawString($flow.subtitle, $bodyFont, $textBrush, 82, 95)

  $steps = @(
    @{ X = 90; Text = $flow.step1; Fill = "#fffdf8"; Border = "#d8cfbf" },
    @{ X = 290; Text = $flow.step2; Fill = "#eef5fb"; Border = "#bfd3e6" },
    @{ X = 490; Text = $flow.step3; Fill = "#edf5ea"; Border = "#bdd0b9" },
    @{ X = 690; Text = $flow.step4; Fill = "#fff5e3"; Border = "#e3c98d" },
    @{ X = 890; Text = $flow.step5; Fill = "#f7eef2"; Border = "#d9b8c3" },
    @{ X = 1090; Text = $flow.step6; Fill = "#fffdf8"; Border = "#d8cfbf" }
  )

  foreach ($step in $steps) {
    Draw-RoundedBox -Graphics $g -Rect ([System.Drawing.RectangleF]::new($step.X, 220, 140, 150)) -Radius 20 -FillColor $step.Fill -BorderColor $step.Border
    $g.DrawString($step.Text, $bodyFont, $titleBrush, $step.X + 14, 255)
  }

  Draw-Arrow -Graphics $g -X1 230 -Y1 295 -X2 290 -Y2 295 -Color "#b39a65"
  Draw-Arrow -Graphics $g -X1 430 -Y1 295 -X2 490 -Y2 295 -Color "#b39a65"
  Draw-Arrow -Graphics $g -X1 630 -Y1 295 -X2 690 -Y2 295 -Color "#b39a65"
  Draw-Arrow -Graphics $g -X1 830 -Y1 295 -X2 890 -Y2 295 -Color "#b39a65"
  Draw-Arrow -Graphics $g -X1 1030 -Y1 295 -X2 1090 -Y2 295 -Color "#b39a65"

  $titleBrush.Dispose()
  $textBrush.Dispose()
}

foreach ($font in @($titleFont, $h2Font, $bodyFont, $smallFont)) {
  $font.Dispose()
}

Copy-Item $uiImage (Join-Path $mediaDir "image1.png") -Force
Copy-Item $architectureImage (Join-Path $mediaDir "image2.png") -Force
Copy-Item $flowImage (Join-Path $mediaDir "image3.png") -Force

function New-ImageXml {
  param(
    [string]$Rid,
    [int]$DocId,
    [string]$Name,
    [int]$Cx,
    [int]$Cy
  )

  @"
<w:p>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0"
        xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">
        <wp:extent cx="$Cx" cy="$Cy"/>
        <wp:effectExtent l="0" t="0" r="0" b="0"/>
        <wp:docPr id="$DocId" name="$(Xml-Escape $Name)"/>
        <wp:cNvGraphicFramePr>
          <a:graphicFrameLocks noChangeAspect="1"
            xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"/>
        </wp:cNvGraphicFramePr>
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:nvPicPr>
                <pic:cNvPr id="0" name="$(Xml-Escape $Name)"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <a:blip r:embed="$Rid" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
                <a:stretch><a:fillRect/></a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm><a:off x="0" y="0"/><a:ext cx="$Cx" cy="$Cy"/></a:xfrm>
                <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
"@
}

$uiXml = New-ImageXml -Rid "rId2" -DocId 10 -Name "畫面總覽" -Cx 5842000 -Cy 3286125
$architectureXml = New-ImageXml -Rid "rId3" -DocId 11 -Name "系統架構" -Cx 5842000 -Cy 3286125
$flowXml = New-ImageXml -Rid "rId4" -DocId 12 -Name "建置流程" -Cx 5842000 -Cy 2555000

$bodyXml = New-Object System.Text.StringBuilder
[void]$bodyXml.AppendLine('<w:p><w:pPr><w:pStyle w:val="Title"/></w:pPr><w:r><w:t>' + (Xml-Escape $data.report.title) + '</w:t></w:r></w:p>')
[void]$bodyXml.AppendLine((New-ParagraphXml $data.report.topic))
[void]$bodyXml.AppendLine((New-ParagraphXml $data.report.date))
[void]$bodyXml.AppendLine((New-ParagraphXml $data.report.intro))
[void]$bodyXml.AppendLine($uiXml)

for ($sectionIndex = 0; $sectionIndex -lt $data.report.sections.Count; $sectionIndex++) {
  $section = $data.report.sections[$sectionIndex]
  [void]$bodyXml.AppendLine((New-HeadingXml $section.heading))
  foreach ($paragraph in $section.paragraphs) {
    [void]$bodyXml.AppendLine((New-ParagraphXml $paragraph))
  }

  if ($sectionIndex -eq 1) {
    [void]$bodyXml.AppendLine($architectureXml)
  }

  if ($sectionIndex -eq 2) {
    [void]$bodyXml.AppendLine($flowXml)
  }
}

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
  xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
  xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
  xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  mc:Ignorable="w14 wp14">
  <w:body>
    $bodyXml
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="708" w:footer="708" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$stylesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:qFormat/>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:eastAsia="Microsoft JhengHei UI" w:hAnsi="Calibri"/>
      <w:sz w:val="24"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Title">
    <w:name w:val="Title"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr>
      <w:spacing w:after="240"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:eastAsia="Microsoft JhengHei UI" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="36"/>
    </w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:pPr>
      <w:spacing w:before="240" w:after="120"/>
    </w:pPr>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:eastAsia="Microsoft JhengHei UI" w:hAnsi="Calibri"/>
      <w:b/>
      <w:sz w:val="28"/>
      <w:color w:val="2F2A24"/>
    </w:rPr>
  </w:style>
</w:styles>
"@

$rootRelsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
"@

$docRelsXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image1.png"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image2.png"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/image3.png"/>
</Relationships>
"@

$contentTypesXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
"@

[System.IO.File]::WriteAllText((Join-Path $buildDir "[Content_Types].xml"), $contentTypesXml, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $rootRelsDir ".rels"), $rootRelsXml, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $buildDir "word\document.xml"), $documentXml, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $relsDir "document.xml.rels"), $docRelsXml, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText((Join-Path $buildDir "word\styles.xml"), $stylesXml, [System.Text.Encoding]::UTF8)

Compress-Archive -Path (Join-Path $buildDir "*") -DestinationPath $zipPath -Force
Rename-Item -Path $zipPath -NewName "Project_Report.docx"

Write-Output "Generated: $outputPath"
