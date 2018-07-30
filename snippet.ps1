$cluster=read-host "Enter your vSAN cluster name to delete the diskgroup: "
$esxnodes=Get-VMHost -Location $cluster
foreach($node in $esxnodes) {
    write-host "Working on node $node" -ForegroundColor green
    $esxcli = get-esxcli -VMHost $node -V2
    $vsanEnabled=$esxcli.vsan.cluster.get.Invoke()
 
    if(($vsanEnabled)){ #(If vSAN is Enabled)
        Remove-Variable -Name "vSanStorage" -force -ErrorAction SilentlyContinue    
        $vSanStorage=$esxcli.vsan.storage.list.Invoke()
        if ($vSanStorage){
            $cache=$vSanStorage | Where-Object {$_.IsSSD -eq "true" -and $_.IsCapacityTier -eq "false"}
            foreach($dgssd in $cache.Device) {
            $arguments=$esxcli.vsan.storage.remove.createargs()
            $arguments.ssd=$dgssd
            $arguments.evacuationmode="noAction"
            $result=$esxcli.vsan.storage.remove.Invoke($arguments)
           if($result -match "true") {
               write-host "VSAN diskgroup with cache disk $dgssd deleted on node $node" -ForegroundColor green
            }
            }
        }else {
            Write-Host "No diskgroup on node $node" -ForegroundColor Yellow
        }
    } else {
        Write-host "$node thinks VSAN is Still enabled - No Action Taken" -ForegroundColor Magenta
    }
}