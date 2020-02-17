# http://inaz2.hatenablog.com/entry/2015/04/16/025953
Param([int] $port)

$ErrorActionPreference = "Stop"

function interact($client) {
    $stream = $client.GetStream()
    $buffer = New-Object System.Byte[] $client.ReceiveBufferSize
    $enc = New-Object System.Text.AsciiEncoding

    try {
        $ar = $stream.BeginRead($buffer, 0, $buffer.length, $NULL, $NULL)
            while ($TRUE) {
                if ($ar.IsCompleted) {
                    $bytes = $stream.EndRead($ar)
                    if ($bytes -eq 0) {
                        break
                    }
                    Write-Host -n $enc.GetString($buffer, 0, $bytes)
                    $ar = $stream.BeginRead($buffer, 0, $buffer.length, $NULL, $NULL)
                }
                if ($Host.UI.RawUI.KeyAvailable) {
                    $data = $enc.GetBytes((Read-Host) + "`n")
                    $stream.Write($data, 0, $data.length)
                }
            }
    } catch [System.IO.IOException] {
        # ignore exception at $stream.BeginRead()
    } finally {
        $stream.Close()
    }
}

$endpoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Loopback, $port)
$listener = New-Object System.Net.Sockets.TcpListener $endpoint
$listener.Start()
$handle = $listener.BeginAcceptTcpClient($null, $null)
while (!$handle.IsCompleted) {
    Start-Sleep -m 100
}
$client = $listener.EndAcceptTcpClient($handle)
interact $client
$client.Close()
$listener.Stop()
