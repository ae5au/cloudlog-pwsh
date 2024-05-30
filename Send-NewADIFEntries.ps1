$ErrorActionPreference = "Inquire"

# Update these values for your Cloudlog instance
$CL_URL = "http://cloudlog.local/index.php/api/qso"
$CL_Key = ""
$CL_Station = ""

# Determine platform and make assumption about logfile path. Manually set it if this doesn't work for you
if ($IsLinux) { cd "~/.local/share/WSJT-X/" }
elseif ($IsMacOS) { cd "~/Library/Application Support/WSJT-X/" }
else { cd "~/AppData/Local/WSJT-X/" }

$ADIF_File = Get-Content .\wsjtx_log.adi
$LastExport = ($ADIF_File -match "^# Exported |<eoh>")[-1]
$HitMatch = $false
$ADIF_Output = @()
$Results = @()

foreach($ADIF_Line in $ADIF_File)
{
  if($HitMatch)
  {
    $ADIF_Output += $ADIF_Line
  }
  else
  {
    if($ADIF_Line -eq $LastExport)
    {
      $HitMatch = $true
    }
  }
}

Write-Host "Records to check: $($ADIF_Output.Length)"

foreach($ADIF_Output_Line in $ADIF_Output)
{
  $JSON = [PSCustomObject]@{
    key                = $CL_Key
    station_profile_id = $CL_Station
    type               = "adif"
    string             = $ADIF_Output_Line.ToString()
  } | ConvertTo-JSON
  
  $Results += Invoke-RestMethod -Uri $CL_URL -Body $JSON -Method POST
}

$Results | ?{$_.imported_count -ne 0} | ft status,imported_count,messages,string

$ThisExport = "# Exported $([DateTime]::UtcNow.ToString('u'))"
$ThisExport | Out-File -FilePath .\wsjtx_log.adi -Encoding ascii -Append

Pause
