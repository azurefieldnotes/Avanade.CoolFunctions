#
# Module manifest for module 'PSGet_Avanade.CoolFunctions'
#
# Generated by: Chris Speers
#
# Generated on: 8/25/2016
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'CoolFunctions'

# Version number of this module.
ModuleVersion = '1.3.3'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'df139d5e-e08a-4ef3-99da-76763490a970'

# Author of this module
Author = 'Chris Speers'

# Company or vendor of this module
CompanyName = 'Avanade'

# Copyright statement for this module
Copyright = '(c) 2015 Chris Speers. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Potpourri Bundle of Handy Functions'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
CLRVersion = '4.0'

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = 'System.Windows.Forms', 'System.IO.Compression.FileSystem', 
               'System.Drawing', 'WindowsBase', 'PresentationCore'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
    "Compress-ZipFileFromFolder","ConvertFrom-UnixTime","ConvertFrom-Xml",
    "ConvertFrom-XmlElement","ConvertTo-BasicAuth","ConvertTo-BroadcastAddressFromCIDR",
    "ConvertTo-Iso8601Time","ConvertTo-NetworkAddressFromCIDR","ConvertTo-NetworkRangeEndFromCIDR",
    "ConvertTo-PrefixLengthFromSubnetMask",'ConvertTo-SubnetMaskFromPrefixLength',"ConvertTo-SubnetMaskFromCIDR",
    "ConvertTo-UnixTime","Copy-FileWithProgress","Copy-WebFile","Export-Base64StringToFile",
    "Export-FileToBase64String","Format-XML","Resize-Image",
    "ConvertTo-IPAddress","ConvertFrom-IPAddress","ConvertTo-StringFromIpAddress",
    'ConvertFrom-IpAddressToNetworkAddressCIDR',
    'ConvertTo-AddressCountFromSubnetMask','ConvertTo-AddressCountFromPrefixLength','ConvertTo-SupernetFromCIDR',
    'Test-NetworkContains'
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
#CmdletsToExport = '*-*'

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        Title = 'Handy Functions Module'

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Miscellaneous')

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/azurefieldnotes/Avanade.CoolFunctions'

        # A URL to an icon representing this module.
        IconUri = 'http://images.all-free-download.com/images/graphiclarge/vector_pocket_knife_47992.jpg'

        # ReleaseNotes of this module
        # ReleaseNotes = ''

        # External dependent modules of this module
        # ExternalModuleDependencies = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

