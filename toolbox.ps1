
function Start-RemoteDesktop {
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
        [Parameter(Position = 0,
          Mandatory,
          HelpMessage='Provide the DNS name or IP address of the computer/server to connect to.',
          ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [String]
        $ComputerName,

        [Parameter(Position = 1)]
        [ValidateSet('FullAdmin','RestrictedAdmin')]
        [String]
        $Control = 'FullAdmin',

        [Parameter(Position = 2)]
        [Switch]
        $FullScreen,

        [Parameter(Position = 3)]
        [ValidateSet('FullScreen', '1920×1080', '1680×1050', '1440x1050', '1280x1024', '1280×720', '1280×768', '1280×800', '1280×960', '1366×768', '1600×1200', '1600×900', '1920×1200', '1920×1280', '1920×1440', '2048×1152', '2160×1440', '2560×1080', '2560×1440', '2560×1600', '2560×1920', '2736×1824', '3000×2000', '3200×2400', '3840×2160', '4096×2304', '1024x768')]
        [String]
        $ScreenSize = 'FullScreen'
    )

    Write-Output -InputObject ('{0} Starting {1}' -f (Get-Date), $PSCmdlet.MyInvocation.MyCommand.Name)

    if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
        Write-Output -InputObject ('Confirmed network availability of ComputerName {0}' -f $ComputerName)
    } else {
        throw ('Unable to confirm network availability of ComputerName {0} [Test-Connection failed]' -f $ComputerName)
    }

    switch ($Control) {
        'FullAdmin' {
            $AdminLevel = '/admin' 
        }
        'RestrictedAdmin'  {
            $AdminLevel = '/RestrictedAdmin'
        }
        Default {
            $AdminLevel = '/Control'
        }
    }

    if ($FullScreen) {
        $Resolution = '/fullscreen' 
    } else {
        switch ($ScreenSize) {
            'FullScreen' {
                $Resolution = '/fullscreen' 
            }
            '1440x1050' {
                $Resolution = '/w:1440 /h:1050'
            }
            '1280x1024' {
                $Resolution = '/w:1280 /h:1024'
            }
            '1024x768' {
                $Resolution = '/w:1024 /h:768'
            }
            Default {
                $Resolution = '/fullscreen' 
            }
        }
    }

    Write-Debug -Message ('Start-Process -FilePath mstsc.exe -ArgumentList "/v:{0} {1} {2}"' -f $ComputerName, $AdminLevel, $Resolution)

    Start-Process -FilePath mstsc.exe -ArgumentList ('/v:{0} {1} {2}' -f $ComputerName, $AdminLevel, $Resolution) 

    Write-Output -InputObject ("{0} Exiting {1}`n" -f (Get-Date), $PSCmdlet.MyInvocation.MyCommand.Name)
}

Function Test-Port {
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
        [parameter(position = 0,
          mandatory,
          HelpMessage='Provide a DNS name or IP address of a remote computer or network device to test response from.'
        )]
        [String]$Target,

        [parameter(position = 1,
          mandatory,
          HelpMessage='Specify an IP port number to test on the Target'
        )]
        [ValidateRange(1,50000)]
        [int]$Port,

        [int]$Timeout = 2000
    )
    Write-Verbose -Message ('{0} Starting {1}' -f (Get-Date), $PSCmdlet.MyInvocation.MyCommand.Name)
    $OutputObj = New-Object -TypeName PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name TargetHostName -Value $Target
    if((Get-Command Test-Connection -ErrorAction Ignore) -and (Test-Connection -ComputerName $Target -Count 2 -ErrorAction SilentlyContinue)) {
        $OutputObj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'ONLINE'
    } else {
        $OutputObj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'OFFLINE'
    } 
    $OutputObj | Add-Member -MemberType NoteProperty -Name PortNumber -Value $Port

    $Socket = New-Object -TypeName System.Net.Sockets.TCPClient
    $Connection = $Socket.BeginConnect($Target,$Port,$null,$null)
    $null = $Connection.AsyncWaitHandle.WaitOne($Timeout,$false)
    if($Socket.Connected -eq $true) {
        $OutputObj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Success'
        $OutputObj | Add-Member -MemberType NoteProperty -Name TargetHostStatus -Value 'ONLINE' -Force
    } else {
        $OutputObj | Add-Member -MemberType NoteProperty -Name ConnectionStatus -Value 'Failed'
    }
    $null = $Socket.Close
    $OutputObj | Select-Object -Property TargetHostName, TargetHostStatus, PortNumber, ConnectionStatus
    Write-Verbose -Message ("{0} Exiting {1}`n" -f (Get-Date), $PSCmdlet.MyInvocation.MyCommand.Name)
}

New-Alias -Name telnet -Value Test-Port -ErrorAction Ignore
 