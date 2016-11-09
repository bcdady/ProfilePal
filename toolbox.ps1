
function Start-RemoteDesktop 
{
<#
    .SYNOPSIS
        Launch a Windows Remote Desktop admin session to a specified computername, with either FullScreen, or sized window
    .DESCRIPTION
        Start-RemoteDesktop calls the mstsc.exe process installed on the local instance of Windows.
        By default, Start-RemoteDesktop specifies the optional arguments of /admin, and /fullscreen.
        Start-RemoteDesktop also provides a -ScreenSize parameter, which supports optional window resolution specifications of 1440 x 1050, 1280 x 1024, and 1024 x 768.
        I first made this because I was tired of my last mstsc session hanging on to my last resolution (which would change between when I was docked at my desk, or working from the smaller laptop screen), so this could always 'force' /fullscreen.
    .PARAMETER ComputerName
        Specifies the DNS name or IP address of the computer / server to connect to.
    .PARAMETER ScreenSize
        Specifies the window resolution. If not specified, defaults to Full Screen.
    .PARAMETER Control
        Optional specifies if the remote session should function in Admin, RestrictedAdmin, or Control mode [default in this function].
    .PARAMETER FullScreen
        Unambiguously specifies that the RDP window open to full screen size.
    .PARAMETER PipelineVariable
        Accepts property ComputerName.
    .EXAMPLE
        PS C:\> Start-RemoteDesktop remotehost
        Invokes mstsc.exe /v:remotehost /control
    .EXAMPLE
        PS C:\> Start-RemoteDesktop -ComputerName <IP Address> -ScreenSize 1280x1024 -Control RestrictedAdmin
        Invokes mstsc.exe /v:<IP Address> /RestrictedAdmin /w:1280 /h:1024
    .NOTES
        NAME        :  Start-RemoteDesktop
        VERSION     :  1.7   
        LAST UPDATED:  4/4/2015
        AUTHOR      :  Bryan Dady; @bcdady; http://bryan.dady.us
    .INPUTS
        ComputerName
    .OUTPUTS
        None
#>
    [cmdletbinding()]
    param (
        [Parameter(Mandatory = $true,
                ValueFromPipelineByPropertyName = $true,
        Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName,

        [Parameter(Mandatory = $false,Position = 1)]
        [ValidateSet('FullAdmin','RestrictedAdmin')]
        [String]
        $Control = 'FullAdmin',

        [Parameter(Mandatory = $false,Position = 2)]
        [Switch]
        $FullScreen,

        [Parameter(Mandatory = $false,Position = 3)]
        [ValidateSet('FullScreen','1440x1050','1280x1024','1024x768')]
        [String]
        $ScreenSize = 'FullScreen'
    )

    Write-Output "$(Get-Date) Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) 
    {
        Write-Output -InputObject "Confirmed network availability of ComputerName $ComputerName"
    }
    else 
    {
        throw "Unable to confirm network availability of ComputerName $ComputerName [Test-Connection failed]"
    }

    switch ($Control) {
        'FullAdmin'  
        {
            $AdminLevel = '/admin' 
        }
        'RestrictedAdmin'  
        {
            $AdminLevel = '/RestrictedAdmin'
        }
        Default      
        {
            $AdminLevel = '/Control'
        }
    }

    if ($FullScreen) 
    {
        $Resolution = '/fullscreen' 
    }
    else 
    {
        switch ($ScreenSize) {
            'FullScreen' 
            {
                $Resolution = '/fullscreen' 
            }
            '1440x1050'  
            {
                $Resolution = '/w:1440 /h:1050'
            }
            '1280x1024'  
            {
                $Resolution = '/w:1280 /h:1024'
            }
            '1024x768'   
            {
                $Resolution = '/w:1024 /h:768'
            }
            Default      
            {
                $Resolution = '/fullscreen' 
            }
        }
    }

    Write-Debug -Message "Start-Process -FilePath mstsc.exe -ArgumentList ""/v:$ComputerName $AdminLevel $Resolution"""

    Start-Process -FilePath mstsc.exe -ArgumentList "/v:$ComputerName $AdminLevel $Resolution" 

    Write-Output "$(Get-Date) Exiting $($PSCmdlet.MyInvocation.MyCommand.Name)`n"
}

function Test-Port 
{
<#
    .SYNOPSIS
        Test-Port is effectively a PowerShell replacement for telnet, to support testing of a specified IP port of a remote computer
    .DESCRIPTION
        Test-Port enables testing for any answer or open indication from a remote network port.
    .PARAMETER Target
        DNS name or IP address of a remote computer or network device to test response from.
    .PARAMETER Port
        IP port number to test on the TARGET.
    .PARAMETER Timeout
        Time-to-live (TTL) parameter for how long to wait for a response from the TARGET PORT.
    .EXAMPLE
        PS C:\> Test-Port RemoteHost 9997
        Tests if the remote host is open on the default Splunk port.
    .NOTES
        NAME        :  Test-Port
        VERSION     :  1.1.1 
        LAST UPDATED:  4/4/2015
        AUTHOR      :  Bryan Dady
    .INPUTS
        None
    .OUTPUTS
        None
#>
    [cmdletbinding()]
    param(
        [parameter(mandatory = $true,
        position = 0)]
        [String]$Target,

        [parameter(mandatory = $true,
        position = 1)]
        [ValidateRange(1,50000)]
        [int32]$Port = 80,

        [int32]$Timeout = 2000
    )
    Write-Output "$(Get-Date) Starting $($PSCmdlet.MyInvocation.MyCommand.Name)"
    $outputobj = New-Object -TypeName PSobject
    $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostName -Value $Target
    if(Test-Connection -ComputerName $Target -Count 2 -ErrorAction SilentlyContinue) 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'ONLINE'
    } else 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'OFFLINE'
    } 
    $outputobj | Add-Member -MemberType NoteProperty -Name PortNumber -Value $Port
    $Socket = New-Object -TypeName System.Net.Sockets.TCPClient
    $Connection = $Socket.BeginConnect($Target,$Port,$null,$null)
    $null = $Connection.AsyncWaitHandle.WaitOne($Timeout,$false)
    if($Socket.Connected -eq $true) 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Success'
    } else 
    {
        $outputobj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Failed'
    }
    $null = $Socket.Close
    $outputobj |
    Select-Object -Property TargetHostName, TargetHostStatus, PortNumber, Connectionstatus |
    Format-Table -AutoSize
    Write-Output "$(Get-Date) Exiting $($PSCmdlet.MyInvocation.MyCommand.Name)`n"
}

New-Alias -Name telnet -Value Test-Port -ErrorAction Ignore
 