# Original concepts by /u/NotNotWrongUsually, /u/punisher1005, and benoitpatra.com
# Cruelly abused and twisted by /u/twoscoopsofpig
# Use by typing: 
#	Draw-Image "http://url.to.image/image.ext"
#	Draw-Image .\some\path\imagename.ext
#
# Date: 2019-03-12 and 2019-03-13

Function Draw-Color
{
	# Original concepts by /u/NotNotWrongUsually
	param(
		[decimal]$r,
		[decimal]$g,
		[decimal]$b
	)

	$ansi_command = "$ansi_escape[48;2;{0};{1};{2}m" -f $r, $g, $b
	$text = " "
	$ansi_terminate = "$ansi_escape[0m"
	$out = $ansi_command + $text + $ansi_terminate
	Return $out
}

function Draw-Image
{
	# Original concepts by /u/punisher1005, and benoitpatra.com
	param(
		[String] $img = "https://upload.wikimedia.org/wikipedia/en/f/ff/SuccessKid.jpg"
	)

	Add-Type -AssemblyName "System.Web"
	Add-Type -AssemblyName "System.Drawing"
	if (test-path $img)
	{
		$image = get-item $img
		$imageTarget = $image.name
		$bitmap = [System.Drawing.Bitmap]::FromFile($image.fullname) 
	}
	else
	{
		$image = Invoke-WebRequest $img
		$imageTarget = ($img -split "/")[-1]
		$bitmap = [System.Drawing.Bitmap]::FromStream($image.RawContentStream)
	}
	$mimetype = [System.Web.MimeMapping]::GetMimeMapping($image)
	if ($mimetype -notmatch "image")
	{
		gc $img
		Return "`r`nTry using an image."
	}
	if (!(test-path .\PSworking))
	{
		md .\PSworking
	}
	$imageResizedTarget = "$($(get-item .\PSworking).fullname)\Resized_$imageTarget"
	$imageTarget = "$($(get-item .\PSworking).fullname)\$imageTarget"

	# Set up for resizing
	$myEncoder = [System.Drawing.Imaging.Encoder]::Quality
	$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
	$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($myEncoder, 100)
	$myImageCodecInfo = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | where {$_.MimeType -eq $mimetype}
	$bitmap.save($($imageTarget -replace "\\","\\\\"), $myImageCodecInfo, $encoderParams)
	$bitmap.dispose()
	$bitmap = [System.Drawing.Bitmap]::FromFile($imageTarget)

	# Resize to fit shell (reorganized from https://benoitpatra.com/2014/09/14/resize-image-and-preserve-ratio-with-powershell/)
	$canvasWidth = [math]::floor($host.ui.RawUI.windowsize.width)
	$canvasHeight = [math]::floor($host.ui.RawUI.windowsize.height -1)

	if ($bitmap.width -gt $canvasWidth -or $bitmap.height -gt $canvasHeight)
	{
		$ratioX = $canvasWidth / $bitmap.Width;
		$ratioY = $canvasHeight / $bitmap.Height;
		$ratio = $ratioY
		if ($ratioX -le $ratioY)
		{
			$ratio = $ratioX
		}

		#create resized bitmap
		$newWidth = [int] ($bitmap.Width*$ratio)
		$newHeight = [int] ($bitmap.Height*$ratio)
		$bitmapResized = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
		$graph = [System.Drawing.Graphics]::FromImage($bitmapResized)

		$graph.Clear([System.Drawing.Color]::White)
		$graph.DrawImage($bitmap, 0, 0, $newWidth, $newHeight)

		#save to file
		$bitmapResized.Save($($imageResizedTarget -replace "\\","\\\\"), $myImageCodecInfo, $encoderParams)
		$graph.Dispose()
		$bitmapResized.Dispose()
	}
	$bitmap.dispose()
	$bitmap = [System.Drawing.Bitmap]::FromFile($imageResizedTarget)

	$ansi_escape = [char]27

	$color_string = ""

	Foreach ($y in (0..($BitMap.Height-1)))
	{ 
		$color_string += "`n"
		Foreach ($x in (0..($BitMap.Width-1)))
		{ 
			$Pixel = $BitMap.GetPixel($X,$Y)         
			$color_string += Draw-Color -r $($Pixel).R -g $($Pixel).G -b $($Pixel).B
		}
	}

	$bitmap.dispose()
	rm $imageResizedTarget
	rm $imageTarget

	Return $color_string
}
# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU49FpLagwIYUtLj1prI/EwP5o
# tfGgggkzMIIEQzCCAyugAwIBAgITFAAAAALkqAddBvs0iQAAAAAAAjANBgkqhkiG
# 9w0BAQsFADAgMR4wHAYDVQQDExVTbWl0aCBCdXJnZXNzIFJvb3QgQ0EwHhcNMTgw
# OTAzMTczMDAzWhcNMjgwOTAzMTc0MDAzWjBWMRMwEQYKCZImiZPyLGQBGRYDbmV0
# MRwwGgYKCZImiZPyLGQBGRYMc21pdGhidXJnZXNzMSEwHwYDVQQDExhTbWl0aCBC
# dXJnZXNzIElzc3VpbmcgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDcgRoJqbMTHiy1J3XI2h3IeqNLUTl9pPcMvZhmkTmIPjZ+5jI5aIeDM27hEKt9
# KjpFq92Awf6+nNGby0RScQq8JqE5sUOqHlpv2foVsoMbcVDhed9VdAymAwdCym6T
# Nn7NvZzIPTN4HZRE4FYS9Z/iW1PV2PAOT9/2P2hHL555C5a8jzDXZZFSJ1QKar2c
# n8KN5kV/Lg1+3VFRY79xdAGnQIAz71JLt1JNpyeDz2Wp2MuONccrNcwRWKxIbV5q
# XYL3cSdwldqKJQhUNRlakAruHi8DQAygl4c3kWoSVCLEeFQ8oH0ofAcVc1zD1zBE
# J9WJeU6p9VNCjO07zTmHNODXAgMBAAGjggE+MIIBOjAQBgkrBgEEAYI3FQEEAwIB
# ADAdBgNVHQ4EFgQUgew6xGJVg5BrSTOWhwuDmmUgIkUwGQYJKwYBBAGCNxQCBAwe
# CgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
# BBgwFoAUUpW4ZSEe2xgfy8lJNLQZqVt1VmowUAYDVR0fBEkwRzBFoEOgQYY/aHR0
# cDovL3BraS5zbWl0aGJ1cmdlc3MubmV0L3BraS9TbWl0aCUyMEJ1cmdlc3MlMjBS
# b290JTIwQ0EuY3JsMFsGCCsGAQUFBwEBBE8wTTBLBggrBgEFBQcwAoY/aHR0cDov
# L3BraS5zbWl0aGJ1cmdlc3MubmV0L3BraS9TbWl0aCUyMEJ1cmdlc3MlMjBSb290
# JTIwQ0EuY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQDa2c/bOx/DRCk9AODBh/sHQgFx
# Iofc/XGVAMCmKjPKB/+x68UcxAJHGHUhiZRBxrypiyeVz0tthaDD3kVsM/mN4jTf
# SmFclHYJN48QvrJ14SXvBNfstYv2CCgj7Ggz7euLY34uOJ7V1c0vi2uo+29jx4P6
# 3tQvJdsQpr7/tj4e5beBtSfz/D0JG+cb5pi8SGNZ6T2snwGseQVdNqJu4nfZlxuK
# K5sgqNEDqmsSTWoCNoxuf4Oqd+ZcTLYxrRUeCZgGXB6i/LdQHo8/uIon4VZjB9xw
# EnIEzCI8wj2UGYjXH6lR8MNB9GxrORfa27or8wcTaEovmpCbnvAgYLhdpT57MIIE
# 6DCCA9CgAwIBAgITEgAAHByd3JBg2hWuigAAAAAcHDANBgkqhkiG9w0BAQsFADBW
# MRMwEQYKCZImiZPyLGQBGRYDbmV0MRwwGgYKCZImiZPyLGQBGRYMc21pdGhidXJn
# ZXNzMSEwHwYDVQQDExhTbWl0aCBCdXJnZXNzIElzc3VpbmcgQ0EwHhcNMTgxMjA0
# MjAyMzAxWhcNMTkxMjA0MjAyMzAxWjCBiDETMBEGCgmSJomT8ixkARkWA25ldDEc
# MBoGCgmSJomT8ixkARkWDHNtaXRoYnVyZ2VzczEdMBsGA1UECxMUaG91c3Rvbi10
# eC1jb3Jwb3JhdGUxDjAMBgNVBAsTBXVzZXJzMQ4wDAYDVQQLEwVQaWxvdDEUMBIG
# A1UEAxMLQmlsbCBDb25hbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCo0JTYCYYeRKqUKD9JHlARvO0sbGdgFVgN5ANM3nHmfj+xFYdbHOhi8uLpaTP6
# X4BgpuRfqHi/YsxCyBsXIThFmjwnX4RUX13ItvXsovurPQmGNpjv4FAC2MHZBGQG
# 7smTP++kFScPTagE0dgRNEQz+Tih/dcLYBfBjyVj86cY0ZhjtQRH5Hqwc2wqSZ87
# bnlRlEqIpenuvYukWIozliYFkqWyCuBpeFs7U1A9P3XPDV+nEHC9hPQtgDslvK7G
# RkovWyncmOjAaHD5W5PCABl9CUWu2sW3qpVzjimTk/WWwUI6fXjh+NvNWOQ4b4EG
# 8x9mKRyRfo22iPc60slr+6+VAgMBAAGjggF6MIIBdjAlBgkrBgEEAYI3FAIEGB4W
# AEMAbwBkAGUAUwBpAGcAbgBpAG4AZzATBgNVHSUEDDAKBggrBgEFBQcDAzAOBgNV
# HQ8BAf8EBAMCB4AwHQYDVR0OBBYEFONYy/uSKGpM30wSH/PraCusKV+aMB8GA1Ud
# IwQYMBaAFIHsOsRiVYOQa0kzlocLg5plICJFMFMGA1UdHwRMMEowSKBGoESGQmh0
# dHA6Ly9wa2kuc21pdGhidXJnZXNzLm5ldC9wa2kvU21pdGglMjBCdXJnZXNzJTIw
# SXNzdWluZyUyMENBLmNybDBeBggrBgEFBQcBAQRSMFAwTgYIKwYBBQUHMAKGQmh0
# dHA6Ly9wa2kuc21pdGhidXJnZXNzLm5ldC9wa2kvU21pdGglMjBCdXJnZXNzJTIw
# SXNzdWluZyUyMENBLmNydDAzBgNVHREELDAqoCgGCisGAQQBgjcUAgOgGgwYQ29u
# YW50QkBzbWl0aGJ1cmdlc3MubmV0MA0GCSqGSIb3DQEBCwUAA4IBAQAAFJECI3q/
# R9vm/6Xr03AqIe8Y4HS04wuUTZHg/fFtsm8IFjJGhiDHDG4EVhXxEmG/tGx+Tfj/
# JJT7cEd3bQJVmPxZem3D6qsZVxrl5cci8ywkGN02sD7ZaCkP46A/p8UmTFMfl4GN
# LgedJ2mo2jiI44hB6s1vtPEzWT843PHU8UQZBAg30sqDQ5Av6pnFeniy8+KSLmOp
# ycyXFdoXRsesUAC7RuYWjbe5ZX1KtiXg8Aj16f36x4ua4Lef30HzvkX+Y9XlIMvb
# 6atOzRbqKcb1PKdEI/p3w1LN3Df4O3kdn0Y31mJNifb87hMt0pEz1I6rrPRhzGQ/
# ZqDdGLR1orAIMYICDjCCAgoCAQEwbTBWMRMwEQYKCZImiZPyLGQBGRYDbmV0MRww
# GgYKCZImiZPyLGQBGRYMc21pdGhidXJnZXNzMSEwHwYDVQQDExhTbWl0aCBCdXJn
# ZXNzIElzc3VpbmcgQ0ECExIAABwcndyQYNoVrooAAAAAHBwwCQYFKw4DAhoFAKB4
# MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQB
# gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkE
# MRYEFDh9hZTAbCf1f34lPEx381Xi1SfxMA0GCSqGSIb3DQEBAQUABIIBACkISvNz
# Ct/uzBs6iQBjCe2HrY9XiRIJ+Ug674uKB65Ad5pLv0gyP8pFQu7WGuM9J+bKY/Le
# ufMtH1ZayCjc/9WF6FdghlDxq42pVh89OMhELUx1ShGZTgyPPdfsDeyWODQHdt2x
# ZISHpfCzBhYRx3Q1XuhITDa9WDGXjgqP0S1mp1SEbmDM1sBe8JtsH0jH1G0yhi+y
# 0QXSnRaWxMeJZ8DZZttMggdWzVfRAFAEtB1RizekSBjida3w2uBzQPGe+9WuGZwM
# SXcU/ZnygfS8PxoCQtzxqsVn2WZR1ISVv+Xk8IXir8GG98N9GoC7Mb9WqlCAcDBW
# /T1jnqWjwYJfVHA=
# SIG # End signature block
