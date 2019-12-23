
# relative paths of imagepackages to the OTA sample (under the proviso being built for Debug)
$strIoTConnectHLPath = ".\\IoTConnectHL\\out\\ARM-Debug-3+Beta1909\\IoTConnectHL.imagepackage"
$strRedSphereRTPath = ".\\out\\ARM-Debug-3+Beta1909\\RedSphereRT\\RedSphereRT.imagepackage"
$strGreenSphereRTPath = ".\\out\\ARM-Debug-3+Beta1909\\GreenSphereRT\\GreenSphereRT.imagepackage"
$strBlueSphereRTPath = ".\\out\\ARM-Debug-3+Beta1909\\BlueSphereRT\\BlueSphereRT.imagepackage"

# .SYNOPSIS AppInfo structure with Component Name, ComponentID, ImageID and FilePath
Class AppInfo
{
    [String] $Name
    [Guid] $ComponentID
    [Guid] $ImageID
    [String] $FilePath
}

<# AppInfo structure for IoTConnectHL POSIX application #>
[AppInfo] $IoTConnectHL  = $null
<# AppInfo structure for RedSphereRT real-time application #>
[AppInfo] $RedSphereRT   = $null
<# AppInfo structure for GreenSphereRT real-time application #>
[AppInfo] $GreenSphereRT = $null
<# AppInfo structure for BlueSphereRT real-time application #>
[AppInfo] $BlueSphereRT  = $null

Class Product
{
    [Guid] $Id
    [String] $Name
    [String] $Description

    Product(){} 

    Product( 
        [Guid] $Id,
        [String] $Name,
        [String] $Description
    )
    {
        $this.Id = $Id
        $this.Name = $Name
        $this.Description = $Description
    }

Enum ApplicationUpdateType
{
    On
    Off
}

    [string] ToString()
    {
        return $this.Name
    }

    [string] IdString()
    {
        return $this.Id.ToString()
    }
}


$strRedSphereProduct = "RedSphere Product"
$strGreenSphereProduct = "GreenSphere Product"
$strBlueSphereProduct = "BlueSphere Product"

$strRedGreenEvaluationProduct = "RedGreen Evaluation"
$strRedBlueEvaluationProduct = "RedBlue Evaluation"

[Product] $ProductRedSphere = $null
[Product] $ProductGreenSphere = $null
[Product] $ProductBlueSphere = $null
[Product] $ProductRedGreenEvaluation = $null
[Product] $ProductRedBlueEvaluation = $null


Class DeploymentEntry
{
    [Guid] $Id
    [String] $Name

    FeedEntry(){} 

    FeedEntry( 
        [Guid] $Id,
        [String] $Name
    )
    {
        $this.Id = $Id
        $this.Name = $Name
    }

	[string] ToString()
    {
        return $this.Id.ToString()
    }
}

$strRetailFeedId = ""
$strEvalFeedId = ""



<#
.SYNOPSIS
Extracts ComponentID, ImageID from given imagepackage file.
.DESCRIPTION
Creates CustomPSObject of type AppInfo with Name, ComponentID, ImageID & FilePath properties from 
given imagepackage file.
.PARAMETER Path
Specifies the path to the .imagepackage file
.PARAMETER Name
(Optional) Specifies an alternative component name.
.INPUTS
None. You cannot pipe objects to ExtractFrom-Image.
.OUTPUTS
AppInfo structure containing Name, ComponentID, ImageID, FilePath 
.EXAMPLE
PS> ExtractFrom-ImagePackage -path "./RedSphereRT.imagepackage" -name "Test"
Name ComponentID                          ImageID                              FilePath                  
---- -----------                          -------                              --------                  
Test f4e25978-6152-447b-a2a1-64577582f327 1b45e9b9-d339-4905-89c1-2a0ecf16f665 .\RedSphereRT.imagepackage
#>
function ExtractFrom-ImagePackage( 
	[Parameter(Mandatory=$true, Position=0)] [Alias("f")]  [string] $Path, 
	[Parameter(Mandatory=$false, Position=1)] [Alias("n")] [string] $Name = "" )
{
    if( (Test-Path -Path $path ) -and ([System.IO.Path]::GetExtension($path) -eq ".imagepackage"))
    {
        $app = New-Object AppInfo
	    $app.Name = $Name
	    $app.FilePath = $Path

        $result = & azsphere pkg show -f "$($app.FilePath)"
        if( $? -eq $true )
        {
            if( $result[3].Contains("Component ID:") )
            {
                $app.ComponentID = [System.Guid]( $result[3].Split(":").Item(1).Trim() )
#                $app.ComponentID = [System.Guid]( $result[3].Split(":").Item(1).Trim() )
            }
            if( $result[4].Contains("Image ID:") )
            {
                $app.ImageID = [System.Guid]( $result[4].Split(":").Item(1).Trim() )
            }
            if( [string]::IsNullOrWhiteSpace($Name) -and $result[9].Contains("Image Name:") )
            {
                $app.Name = $result[9].Split(":").Item(1).Trim()
            }
        }
        Write-Host "ImagePackage $Path has ComponentID $($app.ComponentID) and ImageID $($app.ImageID)."
        return $app
    } else {
        Write-Error "Unable to find imagepackage '$Path'" -ErrorAction Stop
    }
}


<#
.SYNOPSIS
Creates a new DeviceGroup in Azure Sphere Security Service
.DESCRIPTION
Creates a new ProductSKU in Azure Sphere Security Service with the given Name and returns the Guid of the newly created ProductSKU
.PARAMETER Name
Specifies the name for the new ProductSKU.
.INPUTS
None. You cannot pipe objects to New-AS3ProductSKU.
.OUTPUTS
[System.Guid] ProductSKUId
.EXAMPLE
PS> New-AS3ProductSKU -Name "TestProduct" [-Description "What this product is about"]
Guid
-----------                          
f4e25978-6152-447b-a2a1-64577582f327
#>
function New-AS3Product(
	[Parameter(Mandatory=$true)]  [Alias("n")] [string] $Name,
	[Parameter(Mandatory=$false)] [Alias("d")] [string] $Description=""
)
{
	$result = & azsphere product create -n "$Name" -d "$Description"
    if( $LASTEXITCODE -eq 0 )
    {
        [String] $s = $result[ 0 ]
        Write-Host $s
		return [System.Guid]( $s.Split("'").Item(3) )
    } else {
		Write-Error $result[0] -ErrorAction Stop
	}
}


<#
.SYNOPSIS
Retrieves the current list of SKUs
.DESCRIPTION
Retrieves the current list of SKUs
.INPUTS
None. You cannot pipe objects to Find-AS3SKU.
.OUTPUTS
[System.Array] of [SkuEntry]
.EXAMPLE
PS> Get-AS3SKUList
Id                                   Name               SkuType
--                                   ----               -------
0d24af68-c1e6-4d60-ac82-8ba92e09f7e9 MT3620 A1 16MB     Chip
9d606c43-1fad-4990-b207-554a025e0869 MT3620 A0 16MB     Chip
25827902-db08-466d-a8dd-f30a6cb3428a Private Sphere SKU Product
#>
function Get-AS3SkuSet()
{

	$result = azsphere sku list
    if( Check-AS3Success $result 8 )
    {
        [System.Array] $lst = [System.Array]::CreateInstance( [object], $result.Length-7 )
        [System.Array]::Copy($result,5, $lst, 0, $result.Length-7)
        [System.Array] $SkuList = [System.Array]::CreateInstance( [SkuEntry], $result.Length-7 )
        [int] $i=0

        foreach($l in $lst)
        {
            # extract GUID sub string from "90c83845-cce1-4f45-abeb-e50a5aa0a854 GreenSphere SKU    Product "
            #                               0                               ->36|37        variable|  ->9|
            $SkuList[$i] = [SkuEntry]::new(
                [System.Guid]($l.Substring(0,36)),
                $l.Substring(37,$l.Length-45).Trim(),
                [System.Enum]::Parse([SkuEnum], $l.Substring($l.Length-8,8).Trim() )
            )
            $i = $i+1
        }
        return $SkuList
    } else {
		Write-Error $result[1] -ErrorAction Stop
	}
}



<#
.SYNOPSIS
Searches for a SKU in Azure Sphere Security Service by name
.DESCRIPTION
Finds a SKU in Azure Sphere Security Service with the given Name and returns the Guid of the SKU
.PARAMETER Name
Specifies the name for the SKU.
.PARAMETER SkuList
(Optional) supply previously retrieved list of Skus.
.INPUTS
None. You cannot pipe objects to Find-AS3Sku.
.OUTPUTS
[SkuEntry] SKU 
.EXAMPLE
PS> Find-AS3Product -Name "Test-SKU"
Id                                   Name     SkuType
--                                   ----     -------
f7c7a7d9-f890-4293-abe6-f15f7436006f Test-SKU Product
#>
function Find-AS3Product(
	[Parameter(Mandatory=$true, Position=0)] [Alias("n")] [string] $Name,
	[Parameter(Mandatory=$false, Position=1)] [Alias("s")] [System.Array] $SkuList=$null
)
{
    if( $SkuList -eq $null )
    {
        $skuList = Get-AS3SkuSet
    }
    foreach($sku in $SkuList)
    {
        if( $Name.CompareTo( $sku.Name ) -eq 0)
        {
            return $sku
        }
    }

	Write-Warning "Product SKU '$Name' not found"
    return $null
}











<#
.SYNOPSIS
Creates a new ImageSet in Azure Sphere Security Service
.DESCRIPTION
Creates a new ImageSet in Azure Sphere Security Service with the given ImageID(s)
.PARAMETER ImageID
Specifies the image id(s) for the new image-set
.PARAMETER Name
Specifies the name for the new image-set.
.INPUTS
None. You cannot pipe objects to New-AS3ImageSet.
.OUTPUTS
[System.Guid] ImageSetId 
.EXAMPLE
PS> New-AS3ImageSet -ImageID "f4e25978-6152-447b-a2a1-64577582f327", "1b45e9b9-d339-4905-89c1-2a0ecf16f665" -Name "Test"
Guid
-----------                          
f4e25978-6152-447b-a2a1-64577582f327
#>
function New-AS3ImageSet( 
	[Parameter(Mandatory=$true)] $ImageID, 
	[Parameter(Mandatory=$true)][string] $Name )
{
    [System.Guid] $imsID = [System.Guid]::Empty
    [string] $imgIDs = $null


function New-AS3DeviceGroup
{
<#
.SYNOPSIS
Creates a new Component in Azure Sphere Security Service
.DESCRIPTION
Creates a new application component in Azure Sphere Security Service with the given ComponentID
.PARAMETER ComponentID
Specifies the component id(s) for the new application component
.PARAMETER Name
Specifies the name for the new image-set.
.INPUTS
None. You cannot pipe objects to New-AS3Component.
.OUTPUTS
[System.Guid] ComponentId for consistency reasons
.EXAMPLE
PS> New-AS3Component -ComponentID "f4e25978-6152-447b-a2a1-64577582f327" -Name "Test"
Guid
-----------                          
f4e25978-6152-447b-a2a1-64577582f327
#>
function New-AS3Component(
	[Parameter(Mandatory=$true)] $ComponentID, 
	[Parameter(Mandatory=$true)][string] $Name
)
{
	$result = azsphere com create -i $ComponentID  -n $Name
    if( Check-AS3Success $result )
    {
        Write-Host $result[1]
        return $ComponentID
    } else {
		Write-Error $result[1] -ErrorAction Stop
	}
}

<#
.SYNOPSIS
Creates a new DeviceGroup in Azure Sphere Security Service
.DESCRIPTION
Creates a device group with the specified name for the specified product. The device group organizes devices 
that have the same product and receive the same applications from the cloud.
.PRAMETER Name
Specifies an alphanumeric name for the device group. If the name includes embedded spaces, enclose it in quotation marks. The device group name must be unique within the product, and is case insensitive.
.PRAMETER Description
Optional text to describe the Device Group. Can be empty.")]
.PRAMETER ProductName
The tenant-unique name of the product for which to create a device group. Either -ProductName or -ProductId is required.
.PRAMETER ApplicationUpdate
Disables or enables application updates for this device group. This is a binary option: On means that application updates are enabled, Off indicates application updates are disabled. Default is On.
.PRAMETER OsFeed
This is an enum value: Retail, RetailEval. Default is Retail.
.INPUTS
None. You cannot pipe objects to New-AS3DeviceGroup.
.OUTPUTS
[System.Guid] DeviceGroupId for consistency reasons
.EXAMPLE
PS> New-AS3DeviceGroup -Name "TestDeviceGroup"
Guid
-----------                          
f4e25978-6152-447b-a2a1-64577582f327
#>

param(
    [cmdletbinding( DefaultParameterSetName='ByName' )]
	[Parameter(ParameterSetName='ByName', Mandatory=$true)]
    [Parameter(ParameterSetName='ByID', Mandatory=$true)]
	[Parameter(HelpMessage="Specifies an alphanumeric name for the device group. If the name includes embedded spaces, enclose it in quotation marks. The device group name must be unique within the product, and is case insensitive.")]
    [Alias("n")]
    [string] $Name,

	[Parameter(ParameterSetName='ByName', Mandatory=$false)]
    [Parameter(ParameterSetName='ByID', Mandatory=$false)]
	[Parameter(HelpMessage="Optional text to describe the Device Group. Can be empty.")]
    [Alias("d")]
    [string] $Description = "",

	[Parameter(ParameterSetName='ByName', Mandatory=$true)]
	[Parameter(HelpMessage="Specifies an alphanumeric name for the device group. The device group name must be unique within the product, and is case insensitive.")]
    [Alias("pn")]
    [string] $ProductName,

	[Parameter(ParameterSetName='ByID', Mandatory=$true)]
	[Parameter(HelpMessage="The tenant-unique name of the product for which to create a device group. Either --productname or --productid is required.")]
    [Alias("pi")]
    [string] $ProductId,

	[Parameter(ParameterSetName='ByName', Mandatory=$false)]
    [Parameter(ParameterSetName='ByID', Mandatory=$false)]
	[Parameter(HelpMessage="Disables or enables application updates for this device group. This is a binary option: On means that application updates are enabled, Off indicates application updates are disabled. Default is On.")]
    [Alias("a")]
    [ApplicationUpdateType] $ApplicationUpdate = [ApplicationUpdateType]::On,

	[Parameter(ParameterSetName='ByName', Mandatory=$false)]
    [Parameter(ParameterSetName='ByID', Mandatory=$false)]
	[Parameter(HelpMessage="This is an enum value: Retail, RetailEval. Default is Retail.")]
    [Alias("o")]
    [OsFeedType] $OsFeed = [OsFeedType]::Retail
)

    if( $PSCmdlet.ParameterSetName -eq "ById")
    {
	    $result = azsphere dg create -n "$Name" -d "$Description" -pi $ProductId -a $ApplicationUpdate.ToString() -o $OsFeed.ToString()
    } else {
	    $result = azsphere dg create -n "$Name" -d "$Description" -pn $ProductName -a $ApplicationUpdate.ToString() -o $OsFeed.ToString()
    }
    if( $? -eq $true )
    {
        [String] $s = $result[ 1 ]
        Write-Host $s
		return [System.Guid]( $s.Split("'").Item(3) )
    } else {
		Write-Error $result[1] -ErrorAction Stop
	}
}

<#
.SYNOPSIS
Searches for a DeviceGroup in Azure Sphere Security Service by name
.DESCRIPTION
Finds a DeviceGroup in Azure Sphere Security Service with the given Name and returns the Guid of the DeviceGroup
.PARAMETER Name
Specifies the name for the new DeviceGroup.
.INPUTS
None. You cannot pipe objects to Find-AS3DeviceGroup.
.OUTPUTS
[System.Guid] DeviceGroupId
.EXAMPLE
PS> Find-AS3DeviceGroup -Name "TestDeviceGroup"
Guid
-----------                          
f4e25978-6152-447b-a2a1-64577582f327
#>
function Find-AS3DeviceGroup(
	[Parameter(Mandatory=$true)][string] $Name
)
{
	$result = azsphere dg list
    if( Check-AS3Success $result )
    {
        foreach($l in $result)
        {
            if( ($l.Length -gt 50 ) -and ($l.StartsWith(" --> [ID: ")) -and ($l.Substring(49, $l.Length-50).CompareTo( $Name ) -eq 0 ) )
            { 
                Write-Host $l
                # extract GUID sub string from " --> [ID: cd037ae5-27ca-4a13-9e3b-2a9d87f9d7bd] 'System Software Only'"
		        return [System.Guid]( $l.Substring(10,36) )
            }
        }
		Write-Warning "DeviceGroup '$Name' not found"
        return $null
    } else {
		Write-Error $result[1] -ErrorAction Stop
	}
}




<#
.SYNOPSIS
Uploads a new ImagePackage file into an Azure Sphere Security Service Image
.DESCRIPTION
Uploads a new ImagePackage file into an Azure Sphere Security Service Image
.PARAMETER FilePath
Specifies the path to the .imagepackage file
.INPUTS
None. You cannot pipe objects to New-AS3ComponentImage.
.OUTPUTS
[System.Guid] ImageId of the uploaded .imagepackage-file
.EXAMPLE
PS> New-AS3ComponentImage -FilePath ./testfile.imagepackage
Guid
-----------                          
f4e25978-6152-447b-a2a1-64577582f327
#>
function Add-AS3ComponentImage(
	[Parameter(Mandatory=$true, Position=0)] [Alias("f")] $FilePath
)
{
    Write-Host "Uploading $FilePath..."

	$result = azsphere com img add -f $FilePath --force
    if( Check-AS3Success $result 2 )
    {
        [String] $s = $result[ $result.Length-2 ]
        Write-Host $s
		return [System.Guid]( $s.Split("'").Item(1) )
    } else {
        if($result -is [System.Array])
        {
            if($result.Length -gt 6)
            {
        		Write-Error $result[ $result.Length-6 ] -ErrorAction Stop
            } else {
                Write-Error $result[0]
            }
        } else {
       		Write-Error "Unspecified Error" -ErrorAction Stop
        }
	}
}


<#
.SYNOPSIS
Lists all Feeds in the Azure Sphere Security Service 
.DESCRIPTION
Retrieves all Feeds in the Azure Sphere Security Service and returns a [System.Array] of [FeedEntry] instances
.INPUTS
None. You cannot pipe objects to Get-AS3FeedList.
.OUTPUTS
returns a [System.Array] of [FeedEntry] instances
.EXAMPLE
PS> Get-AS3FeedList
Id                                   Name                              
--                                   ----                              
3369f0e1-dedf-49ec-a602-2aa98669fd61 Retail Azure Sphere OS            
82bacf85-990d-4023-91c5-c6694a9fa5b4 Retail Evaluation Azure Sphere OS 
#>

function Get-AS3FeedList()
{
	$result = azsphere Feed list
    if( Check-AS3Success $result 4 )
    {
        [System.Array] $lst = [System.Array]::CreateInstance( [object], $result.Length-3 )
        [System.Array]::Copy($result,2, $lst, 0, $result.Length-3)
        [System.Array] $FeedList = [System.Array]::CreateInstance( [FeedEntry], $lst.Length )
        [int] $i=0

        foreach($l in $lst)
        {
            # extract GUID sub string from "--> [90c83845-cce1-4f45-abeb-e50a5aa0a854] 'GreenSphere Feed'"
            #                               0    5                               ->36|  44    ->variable
            $FeedList[$i] = [FeedEntry]::new(
				[System.Guid]($l.Substring(5,36)),
				$l.Substring(44,$l.Length-45).Trim()
			)
            $i = $i+1
        }
        return $FeedList
    } else {
		Write-Error $result[1] -ErrorAction Stop
	}
}


function New-AS3Feed(
	[Parameter(Mandatory=$true, Position=0)] [Alias("n")] [string] $Name,
	[Parameter(Mandatory=$true, Position=1)] [Alias("p")] [System.Array] $ProductSkus,
	[Parameter(Mandatory=$true, Position=2)] [Alias("s")] [System.Array] $ChipSkus,
	[Parameter(Mandatory=$true, Position=3)] [Alias("c")] [System.Array] $ComponentIds,
	[Parameter(Mandatory=$true, Position=4)] [Alias("f")] [System.Array] $DependentFeedId
)
{
    if( $ImageID -is [System.Array])
    { 
        $imgIDs = [System.String]::Join(",", $ImageID)
    } else {
        $imgIDs = $ImageID
    }

}


<#
.SYNOPSIS
Checks prerequisites.
.DESCRIPTION
Creates CustomPSObject of type AppInfo with Name, ComponentID, ImageID & FilePath properties from 
given imagepackage file.
.PARAMETER Path
Specifies the path to the .imagepackage file
.PARAMETER Name
(Optional) Specifies an alternative component name.
.INPUTS
None. You cannot pipe objects to ExtractFrom-Image.
.OUTPUTS
AppInfo structure containing Name, ComponentID, ImageID, FilePath 
.EXAMPLE
PS> ExtractFrom-ImagePackage -path "./RedSphereRT.imagepackage" -name "Test"
Name ComponentID                          ImageID                              FilePath                  
---- -----------                          -------                              --------                  
Test f4e25978-6152-447b-a2a1-64577582f327 1b45e9b9-d339-4905-89c1-2a0ecf16f665 .\RedSphereRT.imagepackage
#>
function Check-Prerequisites()
{
	if( -not (Test-Path -Path $strIoTConnectHLPath) )	{
		Write-Error "Cannot find $strIoTConnectHLPath." -ErrorAction Stop
	} else {
		$Global:IoTConnectHL = ExtractFrom-ImagePackage -Path $strIoTConnectHLPath -Name "IoTConnect-App (POSIX)"
	}
	if( -not (Test-Path -Path $strRedSphereRTPath) )	{
		Write-Error "Cannot find $strRedSphereRTPath" -ErrorAction Stop
	} else {
		$Global:RedSphereRT = ExtractFrom-ImagePackage -Path $strRedSphereRTPath -Name "RedSphere-App (real-time)"
	}
	if( -not (Test-Path -Path $strGreenSphereRTPath) )	{
		Write-Error "Cannot find $strGreenSphereRTPat" -ErrorAction Stop
	} else {
		$Global:GreenSphereRT = ExtractFrom-ImagePackage -Path $strGreenSphereRTPath -Name "GreenSphere-App (real-time)"
	}
	if( -not (Test-Path -Path $strBlueSphereRTPath) )	{
		Write-Error "Cannot find $strBlueSphereRTPath" -ErrorAction Stop
	} else {
		$Global:BlueSphereRT = ExtractFrom-ImagePackage -Path $strBlueSphereRTPath -Name "BlueSphere-App (real-time)"
	}

    write-host "Retrieving Retail and Evaluation OS Feed-ids"
    $feeds = Get-AS3FeedList 
    $Global:strRetailFeedId =  $feeds.Where({$_.Name.Contains("Retail Azure Sphere OS")}).Id.ToString()
    $Global:strEvalFeedId =  $feeds.Where({$_.Name.Contains("Retail Evaluation Azure Sphere OS")}).Id.ToString()

    write-host "Checking for existing SKUs..."
    $skus = Get-AS3SkuSet

    $found = $skus.Where({$_.Name.Equals( $strRedSphereSku )})
    if($found.Count -gt 0){
        write-host "Found '$($found[0].Name)', Id: $($found[0].Id.ToString())" 
        $SkuRedSphere = $found[0]
    }

    $found = $skus.Where({$_.Name.Equals( $strGreenSphereSku )})
    if($found.Count -gt 0){
        write-host "Found '$($found[0].Name)', Id: $($found[0].Id.ToString())" 
        $SkuGreenSphere = $found[0]
    }

    $found = $skus.Where({$_.Name.Equals( $strBlueSphereSku )})
    if($found.Count -gt 0){
        write-host "Found '$($found[0].Name)', Id: $($found[0].Id.ToString())" 
        $SkuBlueSphere = $found[0]
    }

    $found = $skus.Where({$_.Name.Equals( $strRedGreenEvaluationSku )})
    if($found.Count -gt 0){
        write-host "Found '$($found[0].Name)', Id: $($found[0].Id.ToString())" 
        $SkuRedGreenEvaluation = $found[0]
    }

    $found = $skus.Where({$_.Name.Equals( $strRedBlueEvaluationSku )})
    if($found.Count -gt 0){
        write-host "Found '$($found[0].Name)', Id: $($found[0].Id.ToString())" 
        $SkuRedBlueEvaluation = $found[0]
    }

}


Check-Prerequisites


