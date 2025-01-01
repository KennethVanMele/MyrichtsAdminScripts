function Set-Hypervisor {
    <#
    .SYNOPSIS
        Switch between Hypervisors.
    .DESCRIPTION
        Hyper-V doesn't play nice with other hypervisors like Oracles Virtual Box. This script lets you switch so you can use docker and Virtual Box side by side.
    .EXAMPLE
        PS C:\> Set-Hypervisor -HypervisorName "Other"
        Will set hypervisor to Virtual Box or any other hypervisor.
    .EXAMPLE
        PS C:\> Set-Hypervisor -Name "Hyper-V"
        Will set hypervisor to Hyper-V
    .PARAMETER HypervisorName
        Hypervisor to switch to.
    .PARAMETER HypervisorName
        Should pc reboot immediately?
    .NOTES
        Date latest change: 05/09/2019
    #>
    #Requires -RunAsAdministrator
    [CmdletBinding(ConfirmImpact = 'High')]
    Param (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateSet('Other', 'Hyper-V')]
        [Alias('Name')]
        [string]$HypervisorName,

        [switch]$reboot
    )
    BEGIN {}
    PROCESS {
        function Get-Reboot {
            param(
                [parameter(mandatory = $True)]
                [boolean]$reboot
            )

            if ($reboot) {
                Restart-Computer -Confirm
            }
            else {
                Write-Information "Reboot pending..."
            }
    
            try {
                $status = (bcdedit | Out-String -stream | select-string "hypervisorlaunchtype")
                if ($hypervisorname = 'Other') {
                    if ($status | Select-String "off") {
                        Write-Verbose "Already on Other"
                    }
                    else {
                        Write-Verbose "Setting hypervisor to Other"
                        bcdedit /set hypervisorlaunchtype off
                        Get-Reboot $reboot
                    }
                }
                elseif ($hypervisorname = 'Hyper-V') {
                    if ($status | Select-String "auto") {
                        Write-Verbose "Already on Hyper-V"
                    }
                    else {
                        Write-Verbose "Setting hypervisor to Hyper-V"
                        bcdedit /set hypervisorlaunchtype auto
                        Get-Reboot $reboot
                    }
                }
            }
            catch {
                Write-Error "Can't set hypervisor to $HypervisorName."
            }
        }
    }
    END {}
}

Export-ModuleMember -Function Set-Hypervisor

function Get-DisableBitLockerPercentage {
    <#
    .SYNOPSIS
        Check how much BitLocker has yet to decrypt.
    .DESCRIPTION
        When moving a BitLocked drive to you might consider disabeling BitLocker. This might take a while.
        This script keeps track of it. BitLocker is done when it returns 0.
    .EXAMPLE
        PS C:\> Get-DisableBitLockerPercentage
        After disabeling BitLocker either through the GUI of PowerShell you can run this to check how much is left.
    .NOTES
        Date latest change: 19/07/2012
    #>
    #Requires -RunAsAdministrator
    BEGIN {}
    PROCESS {    
        $Done = $false

        do {
            $PercentageDone = get-bitlockervolume c:
            $PercentageDone = $PercentageDone.EncryptionPercentage
            if ($PercentageDone -eq 0) {
                $Done = $true
            }else {
                Clear-Host
                Write-Host "Done" $PercentageDone
                Start-sleep -Seconds 20
            }
        }until ($Done)
    }
    END {}
}

Export-ModuleMember Get-DisableBitLockerPercentage
function Add-Path {
    <#
    .SYNOPSIS
        Add folder to $env:path
    .DESCRIPTION
        This function provides an easy way to permanently add a folder to the $env:path environment variable.
    .EXAMPLE
        PS C:\> Add-Path -FolderName "c:\test"
        This will add the c:\test folder to $env:path.
    .PARAMETER FolderName
        Folder you want to add.
    .NOTES
        Date latest change: 18/07/2021
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    Param (
        [parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [Alias('Path')]
        [string]$FolderName
    )
    BEGIN {}
    PROCESS {
        if ($PSCmdlet.ShouldProcess("$FolderName")) {
            if (Test-Path -Path $FolderName -PathType Container) {
                $oldPath = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
                Write-Verbose $oldPath
                $newPath = $oldPath + ';' + $FolderName
                Write-Verbose $newPath
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH -Value $newPath
            }
            else {
                write-error "Folder does not exist." -ErrorAction Stop
            }
        }
    }
    END {}
}

Export-ModuleMember -Function Add-Path

function Edit-Path {
    <#
    .SYNOPSIS
        Edit $env:path
    .DESCRIPTION
        This function provides an easy way to edit the $env:path environment variable by making it editable in notepad.
    .EXAMPLE
        PS C:\> Remove-Path
        This will open your $env:path variable in a list in notepad. Remove any line you want, save and close notepad.
    .PARAMETER Backup
        Create a backup in c:\temp.back.
    .NOTES
        Date latest change: 05/09/2019
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    Param (
        [Switch] $Backup
    )
    BEGIN {}
    PROCESS {
        try {
            $file = "c:\temp.txt"
            $i = (Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path
            $i -Split ";" | Out-File $file | notepad.exe $file
    
            if ($Backup) {
                Copy-Item -Path $file -Destination "c:\temp.back"
                Write-host "Backup created"
            }
    
            do { Start-Sleep 2 }while (Get-Process notepad -ErrorAction SilentlyContinue)
    
            $lines = Get-Content $file
            $newPath = ""
        }
        
        finally {
            foreach ($line in $lines) {
                $newPath += $line + ";"
            }
    
            Write-Host $newPath
            Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment" -Name PATH -Value $newPath -Confirm
            Remove-Item c:\temp.txt
        }
    }
    END {}
}

Export-ModuleMember -Function Edit-Path