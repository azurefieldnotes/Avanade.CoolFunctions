
#region Network Calcuators

<#
    .SYNOPSIS
        Converts a CIDR as string to a network address
    .PARAMETER CIDR
        The CIDR to convert
#>
Function ConvertTo-NetworkAddressFromCIDR
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String[]]
        $CIDR
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($IpRange in $CIDR)
        {
            $IpString=$IpRange.Split("/")|Select-Object -First 1
            $PrefixLength=[System.Convert]::ToInt32(($IpRange.Split("/")|Select-Object -Last 1))
            [System.Net.IPAddress]$IpAddress=$null
            if([System.Net.IPAddress]::TryParse($IpString,[ref]$IpAddress))
            {
                $AddressBytes=$IpAddress.GetAddressBytes()
                [Array]::Reverse($AddressBytes)
                $IpAsUint=[System.BitConverter]::ToInt32($AddressBytes,0)
                #Bitwise AND the NetMask and the IP
                $NetMask=[Convert]::ToUInt32(("1" * $PrefixLength).PadRight(32, "0"), 2)
                $NetAddressBytes=[BitConverter]::GetBytes(($IpAsUint -band $NetMask))
                [System.Array]::Reverse($NetAddressBytes)
                $NetAddressAsIp=New-Object System.Net.IPAddress -ArgumentList (,$NetAddressBytes)
                Write-Output $NetAddressAsIp.IPAddressToString
            }
            else
            {
                throw "Unable to parse the IP Address from $IpRange"
            }
        }
    }
    END
    {

    }
}

<#
    .SYNOPSIS
        Converts a CIDR as string to a broadcast address
    .PARAMETER CIDR
        The CIDR to convert
#>
Function ConvertTo-BroadcastAddressFromCIDR
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String[]]
        $CIDR
    )
    BEGIN
    {

    }
    PROCESS
    {
        
        foreach ($IpRange in $CIDR)
        {
            $IpString=$IpRange.Split("/")|Select-Object -First 1
            $PrefixLength=[System.Convert]::ToInt32(($IpRange.Split("/")|Select-Object -Last 1))
            [System.Net.IPAddress]$IpAddress=$null
            if([System.Net.IPAddress]::TryParse($IpString,[ref]$IpAddress))
            {
                $AddressBytes=$IpAddress.GetAddressBytes()
                [Array]::Reverse($AddressBytes)
                $IpAsUint=[System.BitConverter]::ToInt32($AddressBytes,0)
                #Bitwise OR the Host Mask and the IP
                if($PrefixLength -lt 32)
                {
                    $HostMask = [Convert]::ToUInt32("1" * (32 - $PrefixLength), 2)
                    $NetAddressBytes=[BitConverter]::GetBytes(($IpAsUint -bor $HostMask))
                    [System.Array]::Reverse($NetAddressBytes)
                    $NetAddressAsIp=New-Object System.Net.IPAddress -ArgumentList (,$NetAddressBytes)
                    Write-Output $NetAddressAsIp.IPAddressToString
                }
                else
                {
                    Write-Output $IpString
                }
            }
            else
            {
                throw "Unable to parse the IP Address from $IpRange"
            }  
        }
    }
    END
    {

    }
}

<#
    .SYNOPSIS
        Converts a CIDR as string to the last address
    .PARAMETER CIDR
        The CIDR to convert
#>
Function ConvertTo-NetworkRangeEndFromCIDR
{
    [CmdletBinding()]
    [OutputType([String])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String[]]
        $CIDR
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($IpRange in $CIDR)
        {
                $IpString=$IpRange.Split("/")|Select-Object -First 1
                $PrefixLength=[System.Convert]::ToInt32(($IpRange.Split("/")|Select-Object -Last 1))
                [System.Net.IPAddress]$IpAddress=$null
                if([System.Net.IPAddress]::TryParse($IpString,[ref]$IpAddress))
                {
                    $AddressBytes=$IpAddress.GetAddressBytes()
                    [Array]::Reverse($AddressBytes)
                    $IpAsUint=[System.BitConverter]::ToInt32($AddressBytes,0)
                    #Bitwise OR the Host Mask and the IP
                    if($PrefixLength -lt 32)
                    {
                        $HostMask = [Convert]::ToUInt32("1" * (32 - $PrefixLength), 2)
                        $LastAddress=($IpAsUint -bor $HostMask)-1
                        $NetAddressBytes=[BitConverter]::GetBytes($LastAddress)
                        [System.Array]::Reverse($NetAddressBytes)
                        $NetAddressAsIp=New-Object System.Net.IPAddress -ArgumentList (,$NetAddressBytes)
                        Write-Output $NetAddressAsIp.IPAddressToString
                    }
                    else
                    {
                        Write-Output $IpString
                    }
                }
                else
                {
                    throw "Unable to parse the IP Address from $IpRange"
                }     
        }
    }
    END
    {

    }
}

Function ConvertTo-AddressCountFromPrefixLength
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [int[]]$PrefixLength
    )
    PROCESS
    {
        foreach ($item in $PrefixLength)
        {
            switch ($item)
            {
                32 {
                    $UsableAddresses=1
                }
                31 {
                    $UsableAddresses=2
                }
                0 {
                    $UsableAddresses=0
                }
                Default {
                    $UsableAddresses=[math]::Pow(2,(32 - $item))-2
                }
            }
            Write-Output $UsableAddresses
        }
    }
}

Function ConvertTo-AddressCountFromSubnetMask
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$Subnet
    )
    PROCESS
    {
        foreach ($item in $Subnet)
        {
            $UsableAddresses=$item|ConvertTo-PrefixLengthFromSubnetMask|ConvertTo-AddressCountFromPrefixLength
            Write-Output $UsableAddresses
        }
    }
}

<#
    .SYNOPSIS
        Converts a Subnet Mask to a Prefix Length
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
        [string[]]
        $SubnetMask
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($NetMask in $SubnetMask)
        {
            [System.Net.IPAddress]$SubnetAsIp=$null
            if([System.Net.IPAddress]::TryParse($NetMask,[ref]$SubnetAsIp))
            {
                $MaskString=[String]::Empty
                foreach ($AddressByte in $SubnetAsIp.GetAddressBytes())
                {
                    $MaskString+=[Convert]::ToString($AddressByte,2)
                }
                $MaskString=$MaskString -Replace '[\s0]'
                Write-Output $MaskString.Length
            }
            else
            {
                throw "Unable to parse the Subnet Mask $$NetMask"
            }
        }
    }
    END
    {

    }
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
        [String[]]
        $CIDR
    )
    PROCESS
    {
        foreach ($IpRange in $CIDR)
        {
            $CIDRLength=[System.Convert]::ToInt32(($IpRange.Split('/')|Select-Object -Last 1).Trim())
            Write-Debug "[ConvertTo-SubnetMaskFromCIDR] Converting Prefix Length $CIDRLength from input $IpRange"
            Write-Output $($CIDRLength|ConvertTo-SubnetMaskFromPrefixLength)
        }
    }
}

Function ConvertTo-SubnetMaskFromPrefixLength
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [int[]]$PrefixLength
    )
    PROCESS
    {
        foreach ($CIDRLength in $PrefixLength) {
            $NetMask="0.0.0.0"
            Write-Debug "[ConvertTo-SubnetMaskFromPrefixLength] Converting Prefix Length $CIDRLength"
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
            Write-Output $NetMask            
        }
    }
}

Function ConvertTo-SupernetFromCIDR
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String[]]$NetworkCIDR
    )
    BEGIN
    {
        $NetworkIds=@()
        $PreviousMaskLength=0
        $MaskLength=0
    }
    PROCESS
    {
        #Check that these all have the same subnet mask
        foreach ($item in $NetworkCIDR)
        {
            $NetworkIds+=$item.Split('/')[0]|ConvertFrom-IPAddress
            $MaskLength=[Convert]::ToInt32($item.Split('/')[1])
            if($PreviousMaskLength -ne 0)
            {
                if($MaskLength -ne $PreviousMaskLength){
                    throw "The subnets are not the same length"
                }
            }
            $PreviousMaskLength=$MaskLength
        }
    }
    END
    {
        $HighestNetwork=$NetworkIds|Sort-Object -Descending|Select-Object -First 1
        $HighestCIDR="$(($HighestNetwork|ConvertTo-IPAddress).IPAddressToString)/$MaskLength"
        $HighestBroadcast=$HighestCIDR|ConvertTo-BroadcastAddressFromCIDR
        Write-Verbose "[ConvertTo-SupernetFromCIDR] Highest Network: $HighestCIDR Broadcast:$HighestBroadcast"
        $LowestNetwork=$NetworkIds|Sort-Object -Descending|Select-Object -Last 1
        $LowestCIDR="$(($LowestNetwork|ConvertTo-IPAddress).IPAddressToString)/$MaskLength"
        $LowestBroadcast=$LowestCIDR|ConvertTo-BroadcastAddressFromCIDR
        Write-Verbose "[ConvertTo-SupernetFromCIDR] Lowest Network: $LowestCIDR Broadcast:$LowestBroadcast"
        for ($i = 1; $i -lt 33; $i++)
        { 
            Write-Verbose "[ConvertTo-SupernetFromCIDR] Checking for mask length alignment $($i|ConvertTo-SubnetMaskFromPrefixLength) ..."
            if(($HighestNetwork -shr $i) -eq ($LowestNetwork -shr $i))
            {
                $SupernetCIDR="$(($LowestNetwork|ConvertTo-IPAddress).IPAddressToString)/$i"
                Write-Verbose "[ConvertTo-SupernetFromCIDR] Found an alignment match $i $SupernetCIDR!"
                Write-Output $SupernetCIDR
                break
            }
        }
    }
}

Function Test-NetworkContains
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String]$NetworkCIDR,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string]$IPAddress
    )

    $NetworkLong=$NetworkCIDR.Split('/')[0]|ConvertFrom-IPAddress
    $IpLong=0
    $NetworkBroadcast=$NetworkCIDR|ConvertTo-BroadcastAddressFromCIDR|ConvertFrom-IPAddress
    $Contains=($NetworkLong -ge $IpLong) -and ($IpLong -le $NetworkBroadcast)
    Write-Output $Contains
}

<#
    .SYNOPSIS
        Converts a value to a System.Net.IPAddress entity
    .PARAMETER IPAddress
        The IPAddress as a long integer
    .PARAMETER Address
        The IPAddress as a string
#>
Function ConvertTo-IPAddress
{
    param
    (
        [Parameter(ParameterSetName='ip',ValueFromPipeline=$true,Mandatory=$true)]
        [long[]]$IPAddress,
        [Parameter(ParameterSetName='string',ValueFromPipeline=$true,Mandatory=$true)]
        [String[]]$Address
    )
    PROCESS
    {
        if ($PSCmdlet.ParameterSetName -eq 'ip')
        {
            foreach ($item in $IPAddress) {
                [System.Net.IPAddress]$ip=New-Object System.Net.IPAddress($item)
                Write-Output $ip
            }
        }
        else
        {
            foreach ($item in $Address)
            {
                [System.Net.IPAddress]$ip=$null
                if ([System.Net.IPAddress]::TryParse($item,[ref]$ip)) {
                    Write-Output $ip
                }
                else {
                    Write-Warning "[ConvertTo-IPAddress] Error parsing $item $_"
                }
            }
        }
    }
}

<#
    .SYNOPSIS
        Converts an ip address to the long integer value
    .PARAMETER IPAddress
        The System.Net.IPAddress
    .PARAMETER Address
        The IPAddress as a string
#>
Function ConvertFrom-IPAddress
{
    param
    (
        [Parameter(ParameterSetName='ip',ValueFromPipeline=$true,Mandatory=$true)]
        [System.Net.IPAddress[]]$IPAddress,
        [Parameter(ParameterSetName='string',ValueFromPipeline=$true,Mandatory=$true)]
        [String[]]$Address
    )
    PROCESS
    {
        if ($PSCmdlet.ParameterSetName -eq 'string')
        {
            $IPAddress=@()
            foreach ($IpString in $Address)
            {
                [System.Net.IPAddress]$ip=$null
                if ([System.Net.IPAddress]::TryParse($IpString,[ref]$ip))
                {
                    $IPAddress+=$ip
                }
                else
                {
                    Write-Warning "[ConvertFrom-IPAddress] Error parsing $item $_"
                }
            }
        }
        foreach ($IpItem in $IPAddress)
        {

            [long]$IpLong=0
            $IpBytes=$IpItem.GetAddressBytes()
            for($i=($IpBytes.Count-1);$i -ge 0;$i--)
            {
                $CurrBytes=[Convert]::ToInt64($IpBytes[$i])
                $IpLong+=$CurrBytes
                if($i -ne 0)
                {
                    $IpLong=$IpLong -shl 8
                }                
            }
            Write-Output $IpLong
        }
    }
}

<#
    .SYNOPSIS
        Converts an IP Address to the string representation
    .PARAMETER IPAddress
        The System.Net.IPAddress
    .PARAMETER Address
        The IPAddress as a long integer
#>
Function ConvertTo-StringFromIpAddress
{
    param
    (
        [Parameter(ParameterSetName='ip',ValueFromPipeline=$true,Mandatory=$true)]
        [System.Net.IPAddress[]]$IPAddress,
        [Parameter(ParameterSetName='long',ValueFromPipeline=$true,Mandatory=$true)]
        [long[]]$Address
    )
    PROCESS
    {
        if ($PSCmdlet.ParameterSetName -eq 'long') {
            $IPAddress=$Address|ForEach-Object{New-Object System.Net.IPAddress($_)}
        }
        foreach ($item in $IPAddress)
        {
            $IpString="{0}.{1}.{2}.{3}" -f $($item.GetAddressBytes())
            Write-Output $IpString
        }
    }
}

<#
    .SYNOPSIS
        Converts an IP Address and Subnet Mask to the CIDR for the host network
    .PARAMETER IpAddress
        The ip address as a string
    .PARAMETER SubnetMask
        The subnet mask as a string
    .PARAMETER Ip
        The ip address as System.Net.IPAddress
    .PARAMETER Subnet
        The subnet mask as System.Net.IPAddress
#>
Function ConvertFrom-IpAddressToNetworkAddressCIDR
{
    [CmdletBinding(DefaultParameterSetName='AsString')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='AsString')]
        [String]$IpAddress,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='AsString')]
        [String]$SubnetMask,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='AsNetIp')]
        [System.Net.IPAddress]$Ip,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='AsNetIp')]
        [System.Net.IPAddress]$Subnet,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='AsLong')]
        [long]$IpAsInteger,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='AsLong')]
        [long]$SubnetAsInteger     
    )
    PROCESS
    {
        if($PSCmdlet.ParameterSetName -in 'AsNetIp','AsLong')
        {
            if($PSCmdlet.ParameterSetName -eq 'AsLong')
            {
                $Ip=$IpAsInteger|ConvertTo-IPAddress
                $Subnet=$SubnetAsInteger|ConvertTo-IPAddress
            }
            $IpAddress=$Ip|ConvertTo-StringFromIpAddress
            $SubnetMask=$Subnet|ConvertTo-StringFromIpAddress
        }
        elseif($PSCmdlet.ParameterSetName -eq 'AsLong')
        {
            $IpAddress=$
        }
        #Get the prefix length
        $PrefixLength=$SubnetMask|ConvertTo-PrefixLengthFromSubnetMask
        $IpCIDR="$IpAddress/$PrefixLength"
        #Convert to network range
        $NetworkAddress=$IpCIDR|ConvertTo-NetworkAddressFromCIDR
        Write-Output "$NetworkAddress/$PrefixLength"
    }
}

#endregion

#region File Copy/Compress Methods

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
        Write-Debug "[Compress-ZipFileFromFolder] -IncludeParent Switch Specified"
        $Parent=$true
    }
    if($PSCmdlet.ParameterSetName -eq 'io')
    {
        $FileName=$File.FullName
        $SourcePath=$Source.FullName
    }
    if($OverWrite)
    {
        Write-Debug "[Compress-ZipFileFromFolder] -Overwrite Switch Specified"
        if(Test-Path -Path $FileName)
        {
            Write-Warning "[Compress-ZipFileFromFolder] Deleting $FileName"
            Remove-Item -Path $FileName -Force
        }
    }

   if($OptimalCompression)
   {
        Write-Debug "[Compress-ZipFileFromFolder] -Overwrite Switch Specified"
        $CompressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
   }
   [System.IO.Compression.ZipFile]::CreateFromDirectory($SourcePath,$FileName, $CompressionLevel, $Parent)
   Write-Verbose "[Compress-ZipFileFromFolder] Created Zip File $FileName"
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
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Uri[]]$Source,
        [Parameter(Mandatory=$false)]
        [System.String]$DownloadPath=(Join-Path $env:USERPROFILE "Downloads"),
        [Parameter(Mandatory=$false)]
        [Int]$BufferLength=1MB,
        [Parameter(Mandatory=$false)]
        [Int]$TimeOutInSec=360,
        [Parameter(Mandatory=$false)]
        [Int]$ActivityId=90210          
    )

    BEGIN
    {

    }
    PROCESS
    {
        foreach ($Uri in $Source)
        {
            $StopWatch=[System.Diagnostics.Stopwatch]::StartNew()
            $FileName=Split-Path $Uri.AbsolutePath -Leaf
            $Destination=New-Object System.IO.FileInfo((Join-Path $DownloadPath $FileName))
            $Activity="Downloading $Uri to $Destination"
            Write-Progress -Id $ActivityId -Activity $Activity -Status 'Beginning Download'
            Write-Verbose "[Copy-WebFile] Downloading $Uri->$Destination"
            $DownloadedBytes=0
            $HttpRequest=[System.Net.HttpWebRequest]::Create($Uri)
            $HttpRequest.TimeOut=$TimeOutInSec*1000
            [System.Net.HttpWebResponse]$Response=$null
            [System.IO.Stream]$ResponseStream=[System.IO.Stream]::Null
            [System.IO.Stream]$TargetStream=$Destination.OpenWrite()
            try
            {
                $Response=$HttpRequest.GetResponse()
                Write-Verbose "[Copy-WebFile] Received a response of $($Response.ContentType) size $($Response.ContentLength)"
                $TotalSize=$Response.ContentLength
                $TotalSizeInMb=[System.Math]::Floor($TotalSize / 1MB)                
                $ResponseStream=$Response.GetResponseStream()
                $ReadBuffer=New-Object Byte[]($BufferLength)
                $ReadCount=$ResponseStream.Read($ReadBuffer,0,$ReadBuffer.Length)
                $DownloadedBytes+=$ReadCount
                while ($ReadCount -gt 0)
                {
                    $TargetStream.Write($ReadBuffer,0,$ReadCount)
                    $ReadCount=$ResponseStream.Read($ReadBuffer,0,$ReadBuffer.Length)
                    $DownloadedBytes+=$ReadCount
                    $CurrentlyDownloaded=[System.Math]::Floor($downloadedBytes / 1MB)
                    $CurrentProgress=[int](($DownloadedBytes / $TotalSize) * 100)
                    $CurrentSpeed=($DownloadedBytes/1MB/$StopWatch.Elapsed.TotalSeconds).ToString("#.##")
                    $CurrentStatus = "Downloaded $($CurrentlyDownloaded) MB of $($TotalSizeInMb)MB). ($CurrentSpeed MB/Sec)"
                    Write-Progress -Id $ActivityId -Activity $Activity -Status $CurrentStatus -PercentComplete $CurrentProgress
                    #Write-Verbose "[Copy-WebFile] Read: $ReadCount bytes. $CurrentStatus %$($CurrentProgress) completed."
                }
                Write-Progress -Id $ActivityId -Activity $Activity -Completed
                $StopWatch.Stop()
            }
            catch
            {
                Write-Warning "[Copy-WebFile] Error $Uri->$Destination $_"
            }
            finally
            {
                $TargetStream.Close()
                if ($Response -ne $null) {
                    $ResponseStream.Close()
                    $Response.Dispose()
                }
            }
        }
    }
    END
    {

    }
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
Function Copy-FileWithProgress
{
    [CmdletBinding(DefaultParameterSetName='fileinfo')]
    param
    (
        [Parameter(Mandatory=$true,ParameterSetName='fileinfo',ValueFromPipeline=$true)]
        [Parameter(Mandatory=$true,ParameterSetName='dirinfo',ValueFromPipeline=$true)]
        [System.IO.FileInfo[]]
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
    PROCESS
    {
        foreach ($item in $From)
        {
            if($PSCmdlet.ParameterSetName -eq 'dirinfo')
            {
                if(-not $ToDirectory.Exists)
                {
                    New-Item -Path $ToDirectory.Parent.FullName -Name $ToDirectory.Name -ItemType Directory -Force|Out-Null
                }
                $To=New-Object System.IO.FileInfo((Join-Path $ToDirectory.FullName $From.Name))
                Write-Verbose "[Copy-FileWithProgress] Directory option specified -> $($To.FullName)"
            }
            $ffile = $item.OpenRead()
            $Tofile = $To.OpenWrite()
            $CurrentProgress=0
            $FileSizeInMb=$item.Length/1MB
            $StopWatch=[System.Diagnostics.Stopwatch]::StartNew()
            Write-Verbose "[Copy-FileWithProgress] BEGIN:Copying $item -> $To ..."
            Write-Progress -Id $ActivityId -Activity $ActivityName `
                -ParentId $ParentActivityId `
                -Status "Copying $item -> $To" `
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
                    if ($Total % 1mb -eq 0 -and ($FileSizeInMb -ge 1))
                    {
                        $EstSecondsRemaining=[Math]::Max(1, ($StopWatch.Elapsed.TotalSeconds / $($TotalCopiedInMb/$FileSizeInMb)) - $StopWatch.Elapsed.TotalSeconds)
                        $CurrentProgress=[int]($TotalCopiedInMb/$FileSizeInMb * 100)
                        $ProgressParams=@{
                            Id=$ActivityId;
                            ParentId=$ParentActivityId;
                            Activity="$ActivityName %$CurrentProgress";
                            Status="Copying $item -> $To ($($TotalCopiedInMb.ToString("#.##")) of $($FileSizeInMb.ToString("#.##")) Mb) $($CurrentSpeed) MB/s";
                            PercentComplete=$CurrentProgress;
                            SecondsRemaining=$EstSecondsRemaining;
                        }
                        Write-Progress @ProgressParams
                    }
                } while ($ReadCount -gt 0)
                Write-Progress -Id $ActivityId -Activity $ActivityName `
                    -ParentId $ParentActivityId `
                    -PercentComplete $CurrentProgress -Completed
                $StopWatch.Stop()     
                Write-Verbose "END:Copy $item -> $To Took:$($StopWatch.ElapsedMilliseconds)ms. $($CurrentSpeed) MB/s"
            }
            catch [System.IO.IOException],[System.Exception]
            {
                Write-Warning "[Copy-FileWithProgress] Error Copying File $($From.FullName) $_"
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
    }
}

<#
    .SYNOPSIS
        Converts a file to a Base64 string
    .PARAMETER
    .PARAMETER FilePath
        The path to the file to be created
#>
function Export-Base64StringToFile
{
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [String]
        $Base64String,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [String]
        $FilePath,
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [Switch]
        $Force
    )

    if ((Test-Path -Path $FilePath) -and $Force.IsPresent -eq $false) {
        throw "$FilePath already exists! Specify -Force to Overwrite"
    }
    $ContentBytes=[Convert]::FromBase64String($Base64String)
    $ContentBytes|Set-Content -Path $FilePath -Encoding Byte -Force:$Force.IsPresent
    Get-Item -Path $FilePath
}

<#
    .SYNOPSIS
        Converts a file to a Base64 string
    .PARAMETER File
        The file to be converted
#>
function Export-FileToBase64String
{
    [CmdletBinding(ConfirmImpact='None')]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.IO.FileInfo[]]
        $File
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $File)
        {
            try
            {
                $FileContentBytes=Get-Content -Path $item.FullName -Encoding Byte -ErrorAction Stop
                $FileAsString=[Convert]::ToBase64String($FileContentBytes)
                Write-Output $FileAsString
            }
            catch {
                Write-Warning "[Export-FileToBase64String] Failed gathering Base64 string for $($item.FullName) $_"
            }
        }
    }
    END
    {

    }
}

#endregion

#region Time Functions

<#
    .SYNOPSIS
        Converts a Unix Timestamp to DateTime
    .PARAMETER UnixTime
        The Unix Timestamp to be converted
#>
Function ConvertFrom-UnixTime
{
    [OutputType([System.DateTime])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [double[]]
        $UnixTime
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $UnixTime)
        {
            $epoch = New-Object System.DateTime(1970, 1, 1, 0, 0, 0, 0)
            $DateTime=$epoch.AddSeconds($item)
            Write-Output $DateTime
        }
    }
    END
    {

    }
}

<#
    .SYNOPSIS
        Converts a DateTime to a Unix Timestamp
    .PARAMETER DateTime
        The DateTime to be converted
#>
Function ConvertTo-UnixTime
{
    [OutputType([System.Double])]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [datetime[]]
        $DateTime
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $DateTime)
        {
            $epoch = New-Object System.DateTime(1970, 1, 1, 0, 0, 0, 0);
            $delta = $item - $epoch;
            $UnixTime=[Math]::Floor($delta.TotalSeconds)
            Write-Output $UnixTime
        }
    }
    END
    {

    }
}

<#
    .SYNOPSIS
    Converts a DateTime to ISO 5601 Time string
#>
Function ConvertTo-Iso8601Time
{
    [OutputType([String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.DateTime[]]
        $Time
    )
    BEGIN
    {

    }
    PROCESS
    {
        foreach ($item in $Time)
        {
            $Offset=New-Object System.DateTimeOffset($item)
            $IsoTime=$Offset.ToString('o')
            Write-Output $IsoTime
        }
    }
    END
    {

    }
}

#endregion

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
        $ScaleTransform=New-Object System.Windows.Media.ScaleTransform($Scale,$Scale)
    }
    PROCESS
    {
	    foreach($item in $Source)
	    {
            Write-Verbose "[Resize-Image] Resizing image $($item.FullName)->$destinationPath using Scale ScaleTransform $Scale"
            #Prevent the file from getting locked
		    $ImageSource=New-Object System.Windows.Media.Imaging.BitmapImage
            $ImageSource.BeginInit()
            $ImageSource.UriSource=$item.FullName
            $ImageSource.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $ImageSource.EndInit()
		    ## Open and resize the image
		    $image = New-Object System.Windows.Media.Imaging.TransformedBitmap ($ImageSource,$ScaleTransform)
		    ## Put it on the clipboard (just for fun)
		    #[System.Windows.Clipboard]::SetImage($image)

		    $destinationPath=Join-Path $Destination $item.Name
		    ## Write out an image file:
		    $stream = [System.IO.File]::Open($destinationPath, "OpenOrCreate")
		    $encoder = New-Object System.Windows.Media.Imaging.$($item.Extension.Substring(1))BitmapEncoder
		    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($image))
		    $encoder.Save($stream)
            Write-Verbose "[Resize-Image] Saved $destinationPath"
		    $stream.Dispose()
	    }
    }
    END
    {

    }
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
        [System.Xml.XmlDocument[]]$Xml,
        [Parameter(Position=0,ValueFromPipeLine=$true,Mandatory=$true,ParameterSetName="string")]
        [System.String[]]$XmlString
    )
    BEGIN
    {

    }
    PROCESS
    {
        if($PSCmdlet.ParameterSetName -eq "string")
        {
            foreach($RawXml in $XmlString)
            {
                $Doc=New-Object System.Xml.XmlDocument
                $Doc.LoadXml($RawXml)
                $Xml+=$Doc
            }
        }
        foreach ($item in $Xml)
        {
            $StringWriter=New-Object System.IO.StringWriter
            $TextWriter=New-Object System.Xml.XmlTextWriter($StringWriter)
            $TextWriter.Formatting = [System.Xml.Formatting]::Indented
            $item.WriteContentTo($TextWriter)
            Write-Output $StringWriter.ToString()         
        }
    }
    END
    {

    }
}

<#
    .SYNOPSIS
        Converts a PSCredential to as Basic Authorization string
    .PARAMETER Credential
        The PSCredential to be converted
    .PARAMETER AsHeader
        Returns in the format of a header (e.g. "Basic [YourHeader]")
#>
function ConvertTo-BasicAuth
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [pscredential[]]
        $Credential,
        [Parameter(Mandatory=$false)]
        [Switch]
        $AsHeader
    )
    begin
    {

    }

    process
    {
        foreach ($item in $Credential)
        {
            $AuthInfo="$($item.UserName):$($item.GetNetworkCredential().Password)"
            $BasicCredential = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($AuthInfo))
            if ($AsHeader.IsPresent) {
                Write-Output "Basic $BasicCredential"
            }
            else {
                Write-Output $BasicCredential
            }
        }
    }
    end
    {

    }
}

<#
    .SYNOPSIS
        Returns an XML element as a string or pscustomobject value
    .PARAMETER Element
        The XML elements to be converted
    .REMARKS
        This should go away
#>
function ConvertFrom-XmlElement
{
    [CmdletBinding(ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Xml.XmlElement[]]
        $Element
    )

    BEGIN
    {

    }
    PROCESS
    {
        foreach ($XElement in $Element)
        {
            $ChildElements=$XElement.SelectNodes('*')
            $ChildAttributes=$XElement.SelectNodes('@*')
            if($ChildElements.Count -gt  0 -or $ChildAttributes.Count -gt 0)
            {
                #An object or array
                $ElementProperties=[ordered]@{}
                if($ChildAttributes.Count -gt 0)
                {
                    foreach ($ChildAttribute in $ChildAttributes)
                    {
                        $ElementProperties.Add($ChildAttribute.LocalName,$ChildAttribute.Value)
                    }
                }
                if($ChildElements.Count -gt 0)
                {
                    Write-Verbose "$($XElement.LocalName) - Processing Child Elements"
                    $ChildElementsGroups=$ChildElements|Group-Object -Property LocalName
                    foreach ($ChildElementsGroup in $ChildElementsGroups)
                    {
                        if($ChildElementsGroup.Count -gt 1)
                        {
                            $IsArray=$true;
                            $ChildValue=@()
                        }
                        else
                        {
                            $IsArray=$false
                            $ChildValue=$null
                        }
                        foreach ($ChildElement in $ChildElementsGroup.Group)
                        {
                            if($IsArray)
                            {
                                $ChildValue+=(ConvertFrom-XmlElement -Element $ChildElement)
                            }
                            else
                            {
                                $ChildValue=ConvertFrom-XmlElement -Element $ChildElement
                            }
                        }
                        $ElementProperties.Add($ChildElementsGroup.Name,$ChildValue)
                    }
                }
                $ElementValue=New-Object PSObject -Property $ElementProperties
            }
            else
            {
                #Just a value
                $ElementValue=$XElement.InnerText
            }
            Write-Output $ElementValue
        }
    }
    END
    {
    }
}

<#
    .SYNOPSIS
        Returns an XML document as a pscustomobject
    .PARAMETER Element
        The XML elements to be converted
    .PARAMETER Document
        The XML documents to be converted
    .PARAMETER Flatten
        Whether to flatten the top-level object graph
    .REMARKS
        This should go away
#>
function ConvertFrom-Xml
{
    [CmdletBinding(DefaultParameterSetName='element',ConfirmImpact='None')]
    param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='element')]
        [System.Xml.XmlElement[]]
        $Element,
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='document')]
        [System.Xml.XmlDocument[]]
        $Document,
        [Parameter(Mandatory=$false,ParameterSetName='element')]
        [Parameter(Mandatory=$false,ParameterSetName='document')]
        [Switch]
        $Flatten
    )
    BEGIN
    {

    }
    PROCESS
    {
        if($PSCmdlet.ParameterSetName -eq 'document')
        {
            $Element=@($Document|Select-Object -ExpandProperty DocumentElement)
        }
        foreach ($XElement in $Element)
        {
            $ElementValue=ConvertFrom-XmlElement -Element $XElement
            if ($Flatten.IsPresent) {
                Write-Output $ElementValue
            }
            else {
                Write-Output (New-Object PSObject -Property @{$XElement.LocalName=$ElementValue})
            }
        }
    }
    END
    {

    }
}

Function Get-RandomFreeDriveLetter
{
    [CmdletBinding()]
    param()
    Write-Output $((Get-ChildItem function:[d-z]: -n | Where-Object{ !(Test-Path $_) } | Get-Random).ToCharArray()[0])
}