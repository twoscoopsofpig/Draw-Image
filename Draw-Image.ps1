# Original concepts by /u/NotNotWrongUsually, /u/punisher1005, /u/Nation_State_Tractor, and benoitpatra.com
# Cruelly abused and twisted by /u/twoscoopsofpig
# Use by typing: 
#	Draw-Image "http://url.to.image/image.ext"
#	Draw-Image .\some\path\imagename.ext
#
# Date: 2019-03-12 and 2019-03-13

# Prep for font changes - Credit to /u/Nation_State_Tractor
if (-not ("Windows.Native.Kernel32" -as [type]))
{
	Add-Type -TypeDefinition @"
		namespace Windows.Native
		{
			using System;
			using System.ComponentModel;
			using System.IO;
			using System.Runtime.InteropServices;
			
			public class Kernel32
			{
				// Constants
				////////////////////////////////////////////////////////////////////////////
				public const uint FILE_SHARE_READ = 1;
				public const uint FILE_SHARE_WRITE = 2;
				public const uint GENERIC_READ = 0x80000000;
				public const uint GENERIC_WRITE = 0x40000000;
				public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);
				public const int STD_ERROR_HANDLE = -12;
				public const int STD_INPUT_HANDLE = -10;
				public const int STD_OUTPUT_HANDLE = -11;

				// Structs
				////////////////////////////////////////////////////////////////////////////
				[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
				public class CONSOLE_FONT_INFOEX
				{
					private int cbSize;
					public CONSOLE_FONT_INFOEX()
					{
						this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));
					}

					public int FontIndex;
					public short FontWidth;
					public short FontHeight;
					public int FontFamily;
					public int FontWeight;
					[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
					public string FaceName;
				}

				public class Handles
				{
					public static readonly IntPtr StdIn = GetStdHandle(STD_INPUT_HANDLE);
					public static readonly IntPtr StdOut = GetStdHandle(STD_OUTPUT_HANDLE);
					public static readonly IntPtr StdErr = GetStdHandle(STD_ERROR_HANDLE);
				}
				
				// P/Invoke function imports
				////////////////////////////////////////////////////////////////////////////
				[DllImport("kernel32.dll", SetLastError=true)]
				public static extern bool CloseHandle(IntPtr hHandle);
				
				[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
				public static extern IntPtr CreateFile
					(
					[MarshalAs(UnmanagedType.LPTStr)] string filename,
					uint access,
					uint share,
					IntPtr securityAttributes, // optional SECURITY_ATTRIBUTES struct or IntPtr.Zero
					[MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,
					uint flagsAndAttributes,
					IntPtr templateFile
					);
					
				[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
				public static extern bool GetCurrentConsoleFontEx
					(
					IntPtr hConsoleOutput, 
					bool bMaximumWindow, 
					// the [In, Out] decorator is VERY important!
					[In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont
					);
					
				[DllImport("kernel32.dll", SetLastError=true)]
				public static extern IntPtr GetStdHandle(int nStdHandle);
				
				[DllImport("kernel32.dll", SetLastError=true)]
				public static extern bool SetCurrentConsoleFontEx
					(
					IntPtr ConsoleOutput, 
					bool MaximumWindow,
					// Again, the [In, Out] decorator is VERY important!
					[In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx
					);
				
				
				// Wrapper functions
				////////////////////////////////////////////////////////////////////////////
				public static IntPtr CreateFile(string fileName, uint fileAccess, 
					uint fileShare, FileMode creationDisposition)
				{
					IntPtr hFile = CreateFile(fileName, fileAccess, fileShare, IntPtr.Zero, 
						creationDisposition, 0U, IntPtr.Zero);
					if (hFile == INVALID_HANDLE_VALUE)
					{
						throw new Win32Exception();
					}

					return hFile;
				}

				public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx()
				{
					IntPtr hFile = IntPtr.Zero;
					try
					{
						hFile = CreateFile("CONOUT$", GENERIC_READ,
						FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);
						return GetCurrentConsoleFontEx(hFile);
					}
					finally
					{
						CloseHandle(hFile);
					}
				}

				public static void SetCurrentConsoleFontEx(CONSOLE_FONT_INFOEX cfi)
				{
					IntPtr hFile = IntPtr.Zero;
					try
					{
						hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,
							FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);
						SetCurrentConsoleFontEx(hFile, false, cfi);
					}
					finally
					{
						CloseHandle(hFile);
					}
				}

				public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx
					(
					IntPtr outputHandle
					)
				{
					CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();
					if (!GetCurrentConsoleFontEx(outputHandle, false, cfi))
					{
						throw new Win32Exception();
					}

					return cfi;
				}
			}
		}
"@
}

# Set arbitrary font for better detail - Credit to /u/Nation_State_Tractor
function Set-ConsoleFont
{
	[Alias("Set-Font")]
	[CmdletBinding()]
	param
	(
		[string] $Name = "Consolas",
		[ValidateRange(5,25)]
		[int] $Height = 14,
		[switch] $square
	)

	$cfi = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx()
	$cfi.FontIndex = 0
	$cfi.FontFamily = 0
	$cfi.FaceName = $Name
	$cfi.FontWidth = if ($square)
	{
		$height
	}
	else
	{
		[int]($Height / 2)
	}
	$cfi.FontHeight = $Height
	[Windows.Native.Kernel32]::SetCurrentConsoleFontEx($cfi)
}

# Draw a single 1 x 1 pixel in any color
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

# Draw any image, local or on the web, resized to fit the console in full color
function Draw-Image
{
	# Original concepts by /u/punisher1005, and benoitpatra.com
	param(
		[String] $img = "https://upload.wikimedia.org/wikipedia/en/f/ff/SuccessKid.jpg",
		[ValidateRange(5,25)]
		[int] $pxsize = 8,
		[switch] $return,
		[switch] $max
	)

	if ($max)
	{
		Resize-Window -1
	}
	Add-Type -AssemblyName "System.Web"
	Add-Type -AssemblyName "System.Drawing"
	if ([bool](test-path $img))
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
	$mimetype = [System.Web.MimeMapping]::GetMimeMapping($img)
	if ($mimetype -notmatch "image")
	{
		gc $img
		Return "`r`nTry using an image."
	}
	cd c:
	if (!(test-path .\PSworking))
	{
		md .\PSworking
	}
	gci .\PSworking -recurse | rm
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

	Set-ConsoleFont Terminal -height $pxsize -square
	if ($Max)
	{
		$oldWidth = $host.ui.RawUI.windowsize.width
		Resize-Window 3
		while ($host.ui.RawUI.windowsize.width -eq $oldwidth){}
	}

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
		$bitmap.dispose()
		$bitmap = [System.Drawing.Bitmap]::FromFile($imageResizedTarget)
	}

	$ansi_escape = [char]27

	$color_string = $returnString = ""

	Foreach ($y in (0..($BitMap.Height-1)))
	{
		$color_string += "`n"
		Foreach ($x in (0..($BitMap.Width-1)))
		{ 
			$Pixel = $BitMap.GetPixel($X,$Y)				 
			$color_string += Draw-Color -r $($Pixel).R -g $($Pixel).G -b $($Pixel).B
		}
		if ($return)
		{
			Write-Progress "Drawing image '$img'" -Status "Rendering row $y/$($BitMap.Height-1)" -percentcomplete (100 * ($y/$($BitMap.Height-1)))
			$returnString += $color_string
			$color_string = ""
		}
		else
		{
			Write-Host $color_string -nonewline
			$color_string = ""
		}
	}

	$bitmap.dispose()
	if (test-path $imageResizedTarget)
	{
		rm $imageResizedTarget
	}
	if (test-path $imageTarget)
	{
		rm $imageTarget
	}

	if ($return)
	{
		Return $returnString
	}
}

# Resize the console window
Function Resize-Window
{
	Param (
		[int] $mode = -1
	)
	$Signature = @"
[DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
	$ShowWindowAsync = Add-Type -MemberDefinition $Signature -Name 'Win32ShowWindowAsync' -Namespace Win32Functions -PassThru
	$MainWindowHandle = (Get-Process -id $pid).MainWindowHandle
	if ($mode -eq -1)
	{
		$Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(110, 40)
		$Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(110, 3000)
		set-font
		$mode = 9
	}
	$null = $ShowWindowAsync::ShowWindowAsync($MainWindowHandle,$mode)
}
# SIG # Begin signature block
# MIIL1wYJKoZIhvcNAQcCoIILyDCCC8QCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBQtASzLjZ8g0QI2zgCjIIoVR
# +LagggkzMIIEQzCCAyugAwIBAgITFAAAAALkqAddBvs0iQAAAAAAAjANBgkqhkiG
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
# MRYEFCZjw99pXu/99YNOHJ7GtDXwFHCzMA0GCSqGSIb3DQEBAQUABIIBADcX0yh8
# eHfzymO0T7W3Hba6mrqG0BoihuASgnX93/TzLNCuT5e18vb/wzUw/kxDgEI1oIGf
# eIJs2mbuRp8KUcGdoDks63xFPvnKap9K8uUJia5CLdfQ+0JM6n+pKjvzUgSsegsI
# vvFXfcVJQUsZepSHhndg3oZnFrVZGx4vnmhU86ABlgqca245exq+Pel7IufeZnbt
# z7kGhIAmEhjGxZaKlas3GfLogtnXuLnxEpcS55bIi5GZEpwbTYMYiqmM05Nmw2Yw
# KXf4o67v2TjLA7yIzS81oTXBhQHZJAtyfSaWBdbLMy8i7YbU1xVpyKqgZE0Hv3Oi
# e0o+dVO9ZgfARVU=
# SIG # End signature block
