#Requires -Version 5.1
<#
.SYNOPSIS
    Prints devices currently connected over USB, with the details Windows exposes.

.DESCRIPTION
    Run this on the Windows PC you want to inspect:

        powershell -NoProfile -File .\list-usb-devices.ps1
        pwsh -NoProfile -File .\list-usb-devices.ps1

    A device is included when it is present and its instance id is on the USB
    bus (USB\ or USBSTOR\) or it is a USB host controller. Bluetooth-only
    devices are not listed.

    Optional:
        -IncludeDisconnected   Also list USB devices Windows still knows about
                               but that are not currently present.
#>
[CmdletBinding()]
param(
    [switch] $IncludeDisconnected
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Get-UsbInstanceParts {
    param([string] $InstanceId)

    $parts = [ordered]@{
        Vendor = ''
        Product = ''
        Vid = ''
        Pid = ''
        Revision = ''
        Interface = ''
        Serial = ''
        PortInstance = ''
    }

    if ([string]::IsNullOrWhiteSpace($InstanceId)) {
        return [pscustomobject]$parts
    }

    if ($InstanceId -match 'VID_([0-9A-Fa-f]{4})') { $parts.Vid = $Matches[1].ToUpperInvariant() }
    if ($InstanceId -match 'PID_([0-9A-Fa-f]{4})') { $parts.Pid = $Matches[1].ToUpperInvariant() }
    if ($InstanceId -match '(?:^|[&\\])REV_([0-9A-Fa-f]{4})(?:&|\\)') { $parts.Revision = $Matches[1].ToUpperInvariant() }
    if ($InstanceId -match 'MI_([0-9A-Fa-f]{2})') { $parts.Interface = $Matches[1].ToUpperInvariant() }

    if ($InstanceId -match '^USBSTOR\\[^\\]*Ven_([^&]+)&Prod_([^&]+)&Rev_([^\\]+)\\(.+)$') {
        $parts.Vendor = ($Matches[1] -replace '_', ' ').Trim()
        $parts.Product = ($Matches[2] -replace '_', ' ').Trim()
        $parts.Revision = $Matches[3].Trim()
        $parts.Serial = $Matches[4].Trim()
    }
    elseif ($InstanceId -match '^USB\\VID_[^\\]+\\(.+)$') {
        $tail = $Matches[1].Trim()
        # Windows invents an id like 5&xxxxxxxx&0&7 when the device has no serial number.
        if ($tail -match '^\d+&') {
            $parts.PortInstance = $tail
        }
        else {
            $parts.Serial = $tail
        }
    }

    return [pscustomobject]$parts
}

function Get-DeviceKind {
    param(
        [string] $InstanceId,
        [string] $Name
    )

    if ($InstanceId -match '^PCI\\' -or $Name -match 'Host Controller') {
        return 'Host controller'
    }
    if ($InstanceId -match '\\ROOT_HUB' -or $Name -match 'USB (Root |Composite )?Hub|Generic USB Hub|SuperSpeed USB Hub') {
        if ($Name -match 'Composite') {
            return 'Device'
        }
        return 'Hub'
    }
    return 'Device'
}

function Format-PropertyValue {
    param($Value)

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [datetime]) {
        return $Value.ToString('yyyy-MM-dd')
    }

    if ($Value -is [Array] -or $Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        $items = @(
            foreach ($item in $Value) {
                if ($null -ne $item -and -not [string]::IsNullOrWhiteSpace([string]$item)) {
                    [string]$item
                }
            }
        )
        return ($items -join '; ')
    }

    return ([string]$Value).Trim()
}

function Add-Detail {
    param(
        [System.Collections.Generic.List[object]] $Rows,
        [string] $Label,
        $Value
    )

    $text = Format-PropertyValue $Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return
    }

    $Rows.Add([pscustomobject]@{
        Label = $Label
        Value = $text
    }) | Out-Null
}

function Get-PnpPropertyMap {
    param(
        [string[]] $InstanceIds,
        [string[]] $KeyNames
    )

    $map = @{}
    if ($InstanceIds.Count -eq 0) {
        return $map
    }

    if (-not (Get-Command Get-PnpDeviceProperty -ErrorAction SilentlyContinue)) {
        return $map
    }

    foreach ($key in $KeyNames) {
        try {
            $found = @(Get-PnpDeviceProperty -InstanceId $InstanceIds -KeyName $key -ErrorAction Stop)
        }
        catch {
            continue
        }

        foreach ($entry in $found) {
            if ($null -eq $entry) { continue }
            $entryProps = @($entry.PSObject.Properties.Name)
            if ($entryProps -notcontains 'InstanceId' -or $entryProps -notcontains 'Data') {
                continue
            }
            $id = [string]$entry.InstanceId
            if ([string]::IsNullOrWhiteSpace($id)) { continue }
            if (-not $map.ContainsKey($id)) {
                $map[$id] = @{}
            }
            $map[$id][$key] = $entry.Data
        }
    }

    return $map
}

function Get-UsbDiskInfo {
    $byDeviceId = @{}

    try {
        $disks = @(Get-CimInstance -ClassName Win32_DiskDrive -ErrorAction Stop | Where-Object {
            $_.PNPDeviceID -like 'USB*' -or $_.InterfaceType -eq 'USB'
        })
    }
    catch {
        return $byDeviceId
    }

    foreach ($disk in $disks) {
        $volumes = New-Object System.Collections.Generic.List[string]
        try {
            $partitions = @(Get-CimAssociatedInstance -InputObject $disk -ResultClassName Win32_DiskPartition -ErrorAction Stop)
            foreach ($partition in $partitions) {
                $logicalDisks = @(Get-CimAssociatedInstance -InputObject $partition -ResultClassName Win32_LogicalDisk -ErrorAction SilentlyContinue)
                foreach ($logical in $logicalDisks) {
                    $sizeGb = if ($logical.Size) { '{0:N1} GB' -f ($logical.Size / 1GB) } else { '' }
                    $freeGb = if ($null -ne $logical.FreeSpace) { '{0:N1} GB free' -f ($logical.FreeSpace / 1GB) } else { '' }
                    $label = @($logical.DeviceID, $logical.VolumeName, $logical.FileSystem, $sizeGb, $freeGb) |
                        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                    $volumes.Add(($label -join ', ')) | Out-Null
                }
            }
        }
        catch {
            # Disk is still useful without a drive letter.
        }

        $byDeviceId[[string]$disk.PNPDeviceID] = [pscustomobject]@{
            Model = $disk.Model
            SerialNumber = $disk.SerialNumber
            Size = if ($disk.Size) { '{0:N1} GB' -f ($disk.Size / 1GB) } else { '' }
            InterfaceType = $disk.InterfaceType
            MediaType = $disk.MediaType
            Partitions = $disk.Partitions
            FirmwareRevision = $disk.FirmwareRevision
            Volumes = ($volumes -join ' | ')
        }
    }

    return $byDeviceId
}

$propertyKeys = @(
    'DEVPKEY_Device_BusReportedDeviceDesc',
    'DEVPKEY_Device_Manufacturer',
    'DEVPKEY_Device_Service',
    'DEVPKEY_Device_HardwareIds',
    'DEVPKEY_Device_CompatibleIds',
    'DEVPKEY_Device_LocationInfo',
    'DEVPKEY_Device_LocationPaths',
    'DEVPKEY_Device_Parent',
    'DEVPKEY_Device_Children',
    'DEVPKEY_Device_Address',
    'DEVPKEY_Device_EnumeratorName',
    'DEVPKEY_Device_DriverProvider',
    'DEVPKEY_Device_DriverVersion',
    'DEVPKEY_Device_DriverDate',
    'DEVPKEY_Device_ProblemCode',
    'DEVPKEY_Device_BaseContainerId'
)

$pnpParams = @{ PresentOnly = $true }
if ($IncludeDisconnected) {
    $pnpParams = @{}
}

$pnpDevices = @(Get-PnpDevice @pnpParams | Where-Object {
    $id = [string]$_.InstanceId
    $id -match '^(USB|USBSTOR)\\' -or ($_.Class -eq 'USB' -and $id -match '^(PCI|USB)\\')
})

$entityById = @{}
try {
    $entities = @(Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
        $id = [string]$_.PNPDeviceID
        $id -like 'USB\*' -or $id -like 'USBSTOR\*' -or ($_.PNPClass -eq 'USB' -and $id -like 'PCI\*')
    })
    foreach ($entity in $entities) {
        $entityById[[string]$entity.PNPDeviceID] = $entity
    }
}
catch {
    $entities = @()
}

if ($IncludeDisconnected) {
    foreach ($entity in $entities) {
        $id = [string]$entity.PNPDeviceID
        $already = $false
        foreach ($device in $pnpDevices) {
            if ([string]$device.InstanceId -eq $id) {
                $already = $true
                break
            }
        }
        if (-not $already) {
            $pnpDevices += [pscustomobject]@{
                InstanceId = $id
                FriendlyName = $entity.Name
                Class = $entity.PNPClass
                Status = $entity.Status
                Manufacturer = $entity.Manufacturer
                Service = $entity.Service
                Problem = $entity.ConfigManagerErrorCode
                Present = $false
            }
        }
    }
}

$instanceIds = @(
    $pnpDevices | ForEach-Object { [string]$_.InstanceId } | Where-Object { $_ } | Select-Object -Unique
)

$propertyMap = Get-PnpPropertyMap -InstanceIds $instanceIds -KeyNames $propertyKeys
$diskInfo = Get-UsbDiskInfo

$records = foreach ($device in $pnpDevices) {
    $instanceId = [string]$device.InstanceId
    $name = [string]$device.FriendlyName
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = [string]$device.Name
    }

    $parts = Get-UsbInstanceParts -InstanceId $instanceId
    $props = if ($propertyMap.ContainsKey($instanceId)) { $propertyMap[$instanceId] } else { @{} }
    $entity = if ($entityById.ContainsKey($instanceId)) { $entityById[$instanceId] } else { $null }
    $disk = if ($diskInfo.ContainsKey($instanceId)) { $diskInfo[$instanceId] } else { $null }
    $busName = Format-PropertyValue $(if ($props.ContainsKey('DEVPKEY_Device_BusReportedDeviceDesc')) { $props['DEVPKEY_Device_BusReportedDeviceDesc'] } else { '' })
    if ([string]::IsNullOrWhiteSpace($name) -and $busName) {
        $name = $busName
    }
    if ([string]::IsNullOrWhiteSpace($name)) {
        $name = '(unnamed USB device)'
    }

    $present = $true
    if ($device.PSObject.Properties.Name -contains 'Present') {
        $present = [bool]$device.Present
    }

    $manufacturer = ''
    if ($device.PSObject.Properties.Name -contains 'Manufacturer') {
        $manufacturer = [string]$device.Manufacturer
    }

    [pscustomobject]@{
        Kind = Get-DeviceKind -InstanceId $instanceId -Name $name
        Present = $present
        Name = $name
        Status = [string]$device.Status
        Class = [string]$device.Class
        Manufacturer = $manufacturer
        InstanceId = $instanceId
        Parts = $parts
        Props = $props
        Entity = $entity
        Disk = $disk
        BusName = $busName
    }
}

function Write-DeviceRecord {
    param($Record, [int] $Index)

    $rows = New-Object System.Collections.Generic.List[object]
    $props = $Record.Props
    $entity = $Record.Entity
    $disk = $Record.Disk

    Add-Detail $rows 'Status' $Record.Status
    Add-Detail $rows 'Present' $(if ($Record.Present) { 'Yes' } else { 'No' })
    Add-Detail $rows 'Class' $Record.Class
    Add-Detail $rows 'Reported name' $Record.BusName
    $manufacturer = ''
    if ($props.ContainsKey('DEVPKEY_Device_Manufacturer')) {
        $manufacturer = $props['DEVPKEY_Device_Manufacturer']
    }
    elseif ($entity -and -not [string]::IsNullOrWhiteSpace([string]$entity.Manufacturer)) {
        $manufacturer = $entity.Manufacturer
    }
    elseif (-not [string]::IsNullOrWhiteSpace([string]$Record.Manufacturer)) {
        $manufacturer = $Record.Manufacturer
    }
    else {
        $manufacturer = $Record.Parts.Vendor
    }
    Add-Detail $rows 'Manufacturer' $manufacturer
    Add-Detail $rows 'Vendor (USBSTOR)' $Record.Parts.Vendor
    Add-Detail $rows 'Product (USBSTOR)' $Record.Parts.Product
    $revision = [string]$Record.Parts.Revision
    $hardwareIds = if ($props.ContainsKey('DEVPKEY_Device_HardwareIds')) { $props['DEVPKEY_Device_HardwareIds'] } else { $null }
    if ([string]::IsNullOrWhiteSpace($revision)) {
        $hardwareText = Format-PropertyValue $hardwareIds
        if ($hardwareText -match 'REV_([0-9A-Fa-f]{4})') {
            $revision = $Matches[1].ToUpperInvariant()
        }
    }

    $serial = [string]$Record.Parts.Serial
    if ($disk -and -not [string]::IsNullOrWhiteSpace([string]$disk.SerialNumber)) {
        $serial = $disk.SerialNumber.Trim()
    }

    Add-Detail $rows 'VID' $Record.Parts.Vid
    Add-Detail $rows 'PID' $Record.Parts.Pid
    Add-Detail $rows 'Revision' $revision
    Add-Detail $rows 'Interface' $Record.Parts.Interface
    Add-Detail $rows 'Serial' $serial
    Add-Detail $rows 'Port instance' $Record.Parts.PortInstance
    Add-Detail $rows 'Service' $(
        if ($props.ContainsKey('DEVPKEY_Device_Service')) { $props['DEVPKEY_Device_Service'] }
        elseif ($entity) { $entity.Service }
        else { '' }
    )
    Add-Detail $rows 'Driver' $(if ($props.ContainsKey('DEVPKEY_Device_DriverProvider')) { $props['DEVPKEY_Device_DriverProvider'] } else { '' })
    Add-Detail $rows 'Driver version' $(if ($props.ContainsKey('DEVPKEY_Device_DriverVersion')) { $props['DEVPKEY_Device_DriverVersion'] } else { '' })
    Add-Detail $rows 'Driver date' $(if ($props.ContainsKey('DEVPKEY_Device_DriverDate')) { $props['DEVPKEY_Device_DriverDate'] } else { '' })
    Add-Detail $rows 'Location' $(if ($props.ContainsKey('DEVPKEY_Device_LocationInfo')) { $props['DEVPKEY_Device_LocationInfo'] } else { '' })
    Add-Detail $rows 'Location path' $(if ($props.ContainsKey('DEVPKEY_Device_LocationPaths')) { $props['DEVPKEY_Device_LocationPaths'] } else { '' })
    Add-Detail $rows 'Parent' $(if ($props.ContainsKey('DEVPKEY_Device_Parent')) { $props['DEVPKEY_Device_Parent'] } else { '' })
    Add-Detail $rows 'Children' $(if ($props.ContainsKey('DEVPKEY_Device_Children')) { $props['DEVPKEY_Device_Children'] } else { '' })
    Add-Detail $rows 'Address' $(if ($props.ContainsKey('DEVPKEY_Device_Address')) { $props['DEVPKEY_Device_Address'] } else { '' })
    Add-Detail $rows 'Enumerator' $(if ($props.ContainsKey('DEVPKEY_Device_EnumeratorName')) { $props['DEVPKEY_Device_EnumeratorName'] } else { '' })
    $problemCode = if ($props.ContainsKey('DEVPKEY_Device_ProblemCode')) { $props['DEVPKEY_Device_ProblemCode'] } else { $null }
    if ($null -ne $problemCode -and [string]$problemCode -ne '0' -and [string]$problemCode -ne 'CM_PROB_NONE') {
        Add-Detail $rows 'Problem code' $problemCode
    }
    Add-Detail $rows 'Container' $(if ($props.ContainsKey('DEVPKEY_Device_BaseContainerId')) { $props['DEVPKEY_Device_BaseContainerId'] } else { '' })
    Add-Detail $rows 'Hardware IDs' $hardwareIds
    Add-Detail $rows 'Compatible IDs' $(if ($props.ContainsKey('DEVPKEY_Device_CompatibleIds')) { $props['DEVPKEY_Device_CompatibleIds'] } else { '' })

    if ($entity) {
        Add-Detail $rows 'Description' $entity.Description
        if ($entity.ConfigManagerErrorCode -and [int]$entity.ConfigManagerErrorCode -ne 0) {
            Add-Detail $rows 'Config error' $entity.ConfigManagerErrorCode
        }
    }

    if ($disk) {
        Add-Detail $rows 'Disk model' $disk.Model
        Add-Detail $rows 'Disk size' $disk.Size
        Add-Detail $rows 'Interface' $disk.InterfaceType
        Add-Detail $rows 'Media type' $disk.MediaType
        Add-Detail $rows 'Partitions' $disk.Partitions
        Add-Detail $rows 'Firmware' $disk.FirmwareRevision
        Add-Detail $rows 'Volumes' $disk.Volumes
    }

    Add-Detail $rows 'Instance ID' $Record.InstanceId

    Write-Output ("[{0}] {1}" -f $Index, $Record.Name)
    foreach ($row in $rows) {
        Write-Output ('    {0,-16} {1}' -f ($row.Label + ':'), $row.Value)
    }
    Write-Output ''
}

$ordered = @(
    $records |
        Sort-Object @{ Expression = { switch ($_.Kind) { 'Device' { 0 } 'Hub' { 1 } default { 2 } } } }, Name, InstanceId
)

Write-Output ("Computer : {0}" -f $env:COMPUTERNAME)
Write-Output ("When     : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
Write-Output ("USB nodes: {0}" -f $ordered.Count)
Write-Output ''

if ($ordered.Count -eq 0) {
    Write-Output 'No USB devices were found.'
    exit 0
}

$index = 1
foreach ($kind in @('Device', 'Hub', 'Host controller')) {
    $group = @($ordered | Where-Object Kind -eq $kind)
    if ($group.Count -eq 0) {
        continue
    }

    Write-Output ("---- {0} ({1}) ----" -f $kind, $group.Count)
    Write-Output ''
    foreach ($record in $group) {
        Write-DeviceRecord -Record $record -Index $index
        $index++
    }
}
