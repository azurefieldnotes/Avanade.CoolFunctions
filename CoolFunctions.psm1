
<#
    .SYNOPSIS
        Resize an image using the specified scaling factor
    .PARAMETER Source
        The image to be resized
    .PARAMETER Destination
        The output path for the resized image
    .PARAMETER Scale
        The scaling factor to apply
#>
Function Resize-Image
{
    [CmdletBinding()]
    [OutputType([void])]
	param
	(
		[Parameter(ValueFromPipeline=$true,Mandatory=$true,ParameterSetName='io')]
		[System.IO.FileInfo[]]$Source,        
		[Parameter()]
        [System.String]$Destination = $env:TEMP,
		[Parameter()]
        [System.Double]$Scale = 0.50
	)
    BEGIN
    {
        $ScaleTransform=New-Object System.Windows.Media.ScaleTransform($Scale,$scale)
    }
    PROCESS
    {
	    foreach($item in $Source)
	    {
		    $ImageSource=New-Object System.Windows.Media.Imaging.BitmapImage($item.FullName)
		    ## Open and resize the image
		    $image = New-Object System.Windows.Media.Imaging.TransformedBitmap ($ImageSource,$ScaleTransform)
		    ## Put it on the clipboard (just for fun)
		    [System.Windows.Clipboard]::SetImage($image)

		    $destinationPath=Join-Path $Destination $item.Name
		    Write-Verbose "Creating $destinationPath"
		    ## Write out an image file:
		    $stream = [System.IO.File]::Open($destinationPath, "OpenOrCreate")
		    $encoder = New-Object System.Windows.Media.Imaging.$($item.Extension.Substring(1))BitmapEncoder
		    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($image))
		    $encoder.Save($stream)
		    $stream.Dispose()
	    }
    }
    END
    {

    }
}

<#
    .SYNOPSIS
        Compresses the contents of the specified folder to a Zip file
    .PARAMETER FileName
        The path to the file to be created
    .PARAMETER SourcePath
        The path of the content to compress
    .PARAMETER File
        The file to be created
    .PARAMETER Source
        The source of the content
    .PARAMETER Overwrite
        Overwrite an existing file
    .PARAMETER IncludeParent
        Include the specified folder within the archive
    .PARAMETER OptimalCompression
        Use optimal compression
    .PARAMETER FastestCompression
        Use fastest compression
#>
function Compress-ZipFileFromFolder
{
    [CmdletBinding(DefaultParameterSetName='string')]
    param
    (
        [Parameter(Position=0,Mandatory=$true,ParameterSetName='string')]
        [System.String]$FileName,
        [Parameter(Position=1,Mandatory=$true,ParameterSetName='string')]
        [System.String]$SourcePath,
        [Parameter(Position=0,Mandatory=$true,ParameterSetName='io')]
        [System.IO.FileInfo]$File,
        [Parameter(Position=1,Mandatory=$true,ParameterSetName='io')]
        [System.IO.FileSystemInfo]$Source,
        [Parameter(Position=2,ParameterSetName='string')]
        [Parameter(Position=2,ParameterSetName='io')]
        [Switch]$OverWrite,
        [Parameter(Position=3,ParameterSetName='string')]
        [Parameter(Position=3,ParameterSetName='io')]
        [bool]$IncludeParent=$true,
        [Parameter(Position=4,ParameterSetName='string')]
        [Parameter(Position=4,ParameterSetName='io')]
        [bool]$OptimalCompression=$true,
        [Parameter(Position=5,ParameterSetName='string')]
        [Parameter(Position=5,ParameterSetName='io')]
        [Switch]$FastestCompression
    )
    $Parent=$false
    if($IncludeParent)
    {
        Write-Debug "New-ZipFileFromFolder - IncludeParent Switch Specified"
        $Parent=$true
    }
    if($PSCmdlet.ParameterSetName -eq 'io')
    {
        $FileName=$File.FullName
        $SourcePath=$Source.FullName
    }
    if($OverWrite)
    {
        Write-Debug "New-ZipFileFromFolder - Overwrite Switch Specified"
        if(Test-Path -Path $FileName)
        {
            Write-Warning "New-ZipFileFromFolder - Deleting $FileName"
            Remove-Item -Path $FileName -Force
        }
    }

   if($OptimalCompression)
   {
        Write-Debug "New-ZipFileFromFolder - Overwrite Switch Specified"
        $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   }
   [System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath,$FileName, $CompressionLevel, $Parent)
   Write-Verbose "New-ZipFileFromFolder - Created Zip File $FileName"
}

<#
    .SYNOPSIS
        Downloads a file from a URL to the specified location
    .PARAMETER Source
        The uri of the item to download
    .PARAMETER DownloadPath
        The path of the downloaded file
#>
Function Copy-WebFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.Uri]$Source,
        [Parameter()]
        [System.String]$DownloadPath=(Join-Path $env:USERPROFILE "Downloads")

    )

    $FileName=Split-Path $Source.AbsolutePath -Leaf
    $Destination=Join-Path $DownloadPath $FileName
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($Source,$Destination)

}

<#
    .SYNOPSIS
        Formats and indents an XmlDocument to a string
    .PARAMETER Xml
        An XmlDocument to be formatted
    .PARAMETER XmlString
        A valid string of an XML document
        
#>
Function Format-XML
{
    [CmdletBinding(DefaultParameterSetName="dom")]
    Param
    (
        [Parameter(Position=0,ValueFromPipeLine=$true,Mandatory=$true,ParameterSetName="dom")]
        [System.Xml.XmlDocument]$Xml,
        [Parameter(Position=0,ValueFromPipeLine=$true,Mandatory=$true,ParameterSetName="string")]
        [System.String]$XmlString
    )
    if($PSCmdlet.ParameterSetName -eq "string")
    {
        $Xml=New-Object System.Xml.XmlDocument
        $Xml.LoadXml($XmlString)
    }
    $sw=New-Object System.IO.StringWriter
    $writer=New-Object System.Xml.XmlTextWriter($sw)
    $writer.Formatting = [System.Xml.Formatting]::Indented
    $Xml.WriteContentTo($writer)
    return $sw.ToString()
}

<#
    .SYNOPSIS
        Converts a CIDR or Prefix Length as string to a Subnet Mask
    .PARAMETER CIDR
        The CIDR or Prefix Length to convert

#>
Function ConvertTo-SubnetMaskFromCIDR
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String]
        $CIDR
    )
    $NetMask="0.0.0.0"
    $CIDRLength=[System.Convert]::ToInt32(($CIDR.Split('/')|Select-Object -Last 1).Trim())
    Write-Debug "Converting Prefix Length $CIDRLength from input $CIDR"
    switch ($CIDRLength) {
        {$_ -gt 0 -and $_ -lt 8}
        {
            $binary="$( "1" * $CIDRLength)".PadRight(8,"0")
            $o1 = [System.Convert]::ToInt32($binary.Trim(),2)       
            $NetMask = "$o1.0.0.0"
            break
        }
        8 {$NetMask="255.0.0.0"}
        {$_ -gt 8 -and $_ -lt 16}
        {
            $binary="$( "1" * ($CIDRLength - 8))".PadRight(8,"0")
            $o2 = [System.Convert]::ToInt32($binary.Trim(),2)       
            $NetMask = "255.$o2.0.0"
            break
        }
        16 {$NetMask="255.255.0.0"}
        {$_ -gt 16 -and $_ -lt 24}
        {
            $binary="$("1" * ($CIDRLength - 16))".PadRight(8,"0")
            $o3 = [System.Convert]::ToInt32($binary.Trim(),2)
            $NetMask = "255.255.$o3.0"
            break
        }
        24 {$NetMask="255.255.255.0"}
        {$_ -gt 24 -and $_ -lt 32}
        {
            $binary="$("1" * ($CIDRLength - 24))".PadRight(8,"0")
            $o4 = [convert]::ToInt32($binary.Trim(),2)              
            $NetMask= "255.255.255.$o4"
            break
        }
        32 {$NetMask="255.255.255.255"}
    }
    return $NetMask
}

<#
    .SYNOPSIS
        Converts a Subnet Mask to a Prefix Length in a less than clever way
    .PARAMETER SubnetMask
        The SubnetMask to convert
#>
Function ConvertTo-PrefixLengthFromSubnetMask
{
    [CmdletBinding()]
    [OutputType([Int32])]
    param
    (
        # Subnet Mask
        [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]
        $SubnetMask
    )
    $cLength=0
    switch ($SubnetMask)
    {
        "128.0.0.0"{$cLength=1}
        "192.0.0.0"{$cLength=2}
        "224.0.0.0"{$cLength=3}
        "240.0.0.0"{$cLength=4}
        "248.0.0.0"{$cLength=5}
        "252.0.0.0"{$cLength=6}
        "254.0.0.0" {$cLength=7}
        "255.0.0.0"{$cLength=8}
        "255.128.0.0"{$cLength=9}
        "255.192.0.0"{$cLength=10}
        "255.192.0.0"{$cLength=11}
        "255.240.0.0"{$cLength=12}
        "255.248.0.0"{$cLength=13}
        "255.252.0.0"{$cLength=14}
        "255.254.0.0"{$cLength=15}
        "255.255.0.0"{$cLength=16}
        "255.255.128.0"{$cLength=17}
        "255.255.192.0"{$cLength=18}
        "255.255.224.0"{$cLength=19}
        "255.255.240.0"{$cLength=20}
        "255.255.248.0"{$cLength=21}
        "255.255.252.0"{$cLength=22}
        "255.255.254.0"{$cLength=23}
        "255.255.255.0"{$cLength=24}
        "255.255.255.128"{$cLength=25}
        "255.255.255.192"{$cLength=26}
        "255.255.255.224"{$cLength=27}
        "255.255.255.240"{$cLength=28}
        "255.255.255.248"{$cLength=29}
        "255.255.255.252"{$cLength=30}
        "255.255.255.254"{$cLength=31}
        "255.255.255.255"{$cLength=32}
        default{throw "I could not be bothered to calculate $SubnetMask's Length"}
    }
    return $cLength
}

<#
    .SYNOPSIS
        Copies a file with a progress stream
    .PARAMETER From
        The file to be copied
    .PARAMETER To
        The destination file
    .PARAMETER ToDirectory
        The destination directory
    .PARAMETER ActivityName
        The Progress ActivityName
    .PARAMETER ActivityId
        The Progress Activity Id
    .PARAMETER ParentActivityId
        The Parent Activity

#>
function Copy-FileWithProgress 
{
    [CmdletBinding(DefaultParameterSetName='fileinfo')]
    param
    (
        [Parameter(Mandatory=$true,ParameterSetName='fileinfo',ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true,ParameterSetName='dirinfo',ValueFromPipeline=$true)]
        [System.IO.FileInfo]
        $From,
        [Parameter(Mandatory=$true,ParameterSetName='fileinfo')]
        [System.IO.FileInfo]
        $To,
        [Parameter(Mandatory=$true,ParameterSetName='dirinfo')]
        [System.IO.DirectoryInfo]
        $ToDirectory,        
        [Parameter(Mandatory=$false,ParameterSetName='dirinfo')]
        [Parameter(Mandatory=$false,ParameterSetName='fileinfo')]
        [System.String]
        $ActivityName="Copying file",
        [Parameter(Mandatory=$false,ParameterSetName='fileinfo')]
        [Parameter(Mandatory=$false,ParameterSetName='dirinfo')]
        [System.Int32]
        $ActivityId=80085,
        [Parameter(Mandatory=$false,ParameterSetName='dirinfo')]
        [Parameter(Mandatory=$false,ParameterSetName='fileinfo')]
        [System.Int32]
        $ParentActivityId=0,
        [Parameter(Mandatory=$false,ParameterSetName='dirinfo')]
        [Parameter(Mandatory=$false,ParameterSetName='fileinfo')]
        [uint32]$BufferLength=1MB
    )

  if($PSCmdlet.ParameterSetName -eq 'dirinfo')
    {
        if(-not $ToDirectory.Exists)
        {
            New-Item -Path $ToDirectory.Parent.FullName -Name $ToDirectory.Name -ItemType Directory -Force|Out-Null
        }
        $To=New-Object System.IO.FileInfo((Join-Path $ToDirectory.FullName $From.Name))
    }

    $ffile = $From.OpenRead()
    $Tofile = $To.OpenWrite()
    $CurrentProgress=0
    $FileSizeInMb=$From.Length/1MB
    $StopWatch=[System.Diagnostics.Stopwatch]::StartNew()

    Write-Verbose "BEGIN:Copying $From -> $To ..."
    Write-Progress -Id $ActivityId -Activity $ActivityName `
        -ParentId $ParentActivityId `
        -Status "Copying $From -> $To" `
        -PercentComplete $CurrentProgress
    try 
    {
        [System.Byte[]]$FileBuffer = New-Object System.Byte[] $BufferLength
        [long]$Total = [long]$ReadCount = 0
        [long]$TotalCopiedInMb=0
        do 
        {
            $ReadCount = $ffile.Read($FileBuffer, 0, $FileBuffer.Length)
            $Tofile.Write($FileBuffer, 0, $ReadCount)
            $Total += $ReadCount
            $TotalCopiedInMb=$Total/1MB
            $CurrentSpeed=($TotalCopiedInMb/$StopWatch.Elapsed.TotalSeconds).ToString("#.##")
            if ($Total % 1mb -eq 0)
            {
                $CurrentProgress=[int]($TotalCopiedInMb/$FileSizeInMb * 100)
                Write-Progress -Id $ActivityId `
                -Activity "$ActivityName %$CurrentProgress"`
                -ParentId $ParentActivityId `
                -Status "Copying $From -> $To ($($TotalCopiedInMb.ToString("#.##")) of $($FileSizeInMb.ToString("#.##")) Mb) $($CurrentSpeed) MB/s" `
                -PercentComplete $CurrentProgress
            }
        } while ($ReadCount -gt 0)
        Write-Progress -Id $ActivityId -Activity $ActivityName `
            -ParentId $ParentActivityId `
            -Status "Copying $From -> $To" `
            -PercentComplete $CurrentProgress -Completed
        $StopWatch.Stop()
        Write-Verbose "END:Copy $From -> $To Took:$($StopWatch.ElapsedMilliseconds)ms. $($CurrentSpeed) MB/s"
    }
    catch [System.IO.IOException],[System.Exception]
    {
        Write-Warning "Error Copying File $_"
    }
    finally
    {
        $ffile.Dispose()
        $Tofile.Dispose()
        if($StopWatch -ne $null -and $StopWatch.IsRunning)
        {
            $StopWatch.Stop()
        }
    }
}