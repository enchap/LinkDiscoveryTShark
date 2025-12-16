# ==========================================
#  Link-Discovery-TShark.ps1
#  High-Precision Link Discovery (TShark/Npcap)
# ==========================================

# 1. Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires Administrator privileges to access the Npcap driver."
    Start-Sleep -Seconds 3
    Exit
}

# 2. TShark.exe Path Variable
$tsharkPaths = @(
    "${env:ProgramFiles}\Wireshark\tshark.exe",
    "${env:ProgramFiles(x86)}\Wireshark\tshark.exe"
)
$tsharkBinary = $tsharkPaths | Where-Object { Test-Path $_ } | Select-Object -First 1

if (!$tsharkBinary) {
    Write-Error "TShark.exe not found! Please install Wireshark to the default path."
    Start-Sleep -Seconds 5
    Exit
}

# 3. User input adapter selection
Clear-Host
Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "`n   Select Network Adapter for Capture" -ForegroundColor Cyan
Write-Host "`n============================================" -ForegroundColor Cyan

$interfaces = & $tsharkBinary -D

if (!$interfaces) {
    Write-Error "TShark could not find any interfaces. Ensure Npcap is installed."
    Start-Sleep -Seconds 5
    Exit
}

# Display adapters
foreach ($iface in $interfaces) {
    Write-Host $iface -ForegroundColor White
}

Write-Host "`n--------------------------------------------" -ForegroundColor Gray

# Prompt the user for input
$validInput = $false
while (-not $validInput) {
    $targetIndex = Read-Host "Enter the number of the adapter to use (e.g. 1)"
    
    # Basic validation to ensure they typed a number
    if ($targetIndex -match "^\d+$") {
        $validInput = $true
    } else {
        Write-Warning "Invalid input. Please enter a number."
    }
}

# 4. Start Capture
$htmlFile = "$env:USERPROFILE\Desktop\Link-Discovery-Report.html"
Write-Host "`nStarting 60s capture on Interface #$targetIndex..." -ForegroundColor Yellow

# Add Augments to the execution
$tsharkArgs = @(
    "-i", $targetIndex,
    "-a", "duration:60",
    "-Y", "lldp || cdp",
    "-T", "fields",
    "-E", "separator=|",
    "-e", "lldp.tlv.system.name", 
    "-e", "lldp.port.id", 
    "-e", "lldp.port.desc", 
    "-e", "lldp.chassis.id.mac",
    "-e", "cdp.deviceid", 
    "-e", "cdp.portid", 
    "-e", "cdp.platform",
    "-e", "cdp.address"
)

# Run TShark
$captureData = & $tsharkBinary $tsharkArgs 2>$null

# 6. Parse Results
$resultsHTML = ""
$packetCount = 0

if ($captureData) {
    foreach ($line in $captureData) {
        # Split the pipe-separated values
        $fields = $line -split "\|"
        
        # Map fields to variables for readability
        $lldpName = $fields[0]
        $lldpPort = $fields[1]
        $lldpDesc = $fields[2]
        $lldpMac  = $fields[3]
        $cdpName  = $fields[4]
        $cdpPort  = $fields[5]
        $cdpPlat  = $fields[6]
        $cdpIP    = $fields[7]

        # Construct a nice HTML block for this packet
        $resultsHTML += "<div class='packet-block'>"
        
        if ($lldpName -or $lldpPort) {
            $resultsHTML += "<h3>LLDP Packet Detected</h3>"
            $resultsHTML += "<b>Switch Name:</b> $lldpName<br>"
            $resultsHTML += "<b>Port ID:</b> $lldpPort<br>"
            $resultsHTML += "<b>Description:</b> $lldpDesc<br>"
            $resultsHTML += "<b>Chassis MAC:</b> $lldpMac<br>"
        }
        
        if ($cdpName -or $cdpPort) {
            $resultsHTML += "<h3>CDP Packet Detected</h3>"
            $resultsHTML += "<b>Device ID:</b> $cdpName<br>"
            $resultsHTML += "<b>Port ID:</b> $cdpPort<br>"
            $resultsHTML += "<b>Platform:</b> $cdpPlat<br>"
            $resultsHTML += "<b>Mgmt IP:</b> $cdpIP<br>"
        }
        $resultsHTML += "</div><hr>"
    }
} 
else {
    $resultsHTML = "<span class='no-data'>No LLDP or CDP packets received.<br>Time out reached (60s).</span>"
}

# 7. Generate HTML Report
$computerName = $env:COMPUTERNAME
$dateGen = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Npcap Link Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f2f2f2; color: #333; margin: 0; padding: 40px; }
        .container { background-color: #fff; max-width: 800px; margin: 0 auto; padding: 40px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        h1 { font-weight: 300; margin-bottom: 5px; color: #0078d7; }
        .subtitle { font-size: 14px; color: #666; margin-bottom: 30px; display: block;}
        .packet-block { background-color: #e6f7ff; border-left: 5px solid #0078d7; padding: 15px; margin-bottom: 15px; }
        .no-data { color: #d90000; font-weight: bold; }
        hr { border: 0; border-top: 1px solid #eee; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Link Discovery (Npcap Engine)</h1>
        <span class="subtitle">Generated via TShark on $computerName at $dateGen through interface $targetIndex</span>
        
        $resultsHTML
        
    </div>
</body>
</html>
"@

# 8. Save and Open
Write-Host "`nDisplaying results in browser." -ForegroundColor Green
$htmlContent | Out-File -FilePath $htmlFile -Encoding utf8
Invoke-Item $htmlFile