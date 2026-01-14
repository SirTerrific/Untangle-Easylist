## Script Create by WebFooL for The Untangle Community

$easylistsource = "https://easylist.to/easylist/easylist.txt"
$Request = Invoke-WebRequest $easylistsource
$EasyList = $Request.Content
$filenamejson = "ADImport.json"
$filenamecsv = "ADImport.csv"
$easylistsourcecount = ($EasyList | Measure-Object -Line).Lines
$hash = $null
$counter = 0
$hash = @'
string,blocked,javaClass,markedForNew,markedForDelete,enabled

'@

Write-Host "Will now work for a while do not panic!"

foreach ($line in ($EasyList -split "`n")) {

    Write-Progress -Activity "Processing Easylist" -CurrentOperation $line -PercentComplete (($counter / $easylistsourcecount) * 100)

    if ($line -clike '!*') {
        # Commentaire
    }
    elseif ($line -eq "[Adblock Plus 2.0]") {
    }
    elseif ($line -eq "") {
    }
    else {
        $hash += "$line,true,com.untangle.uvm.app.GenericRule,true,false,true`r`n"
        $counter++
    }
}

$hash | Set-Content -Path $filenamecsv

Import-Csv $filenamecsv | ConvertTo-Json -Compress | Set-Content -Path $filenamejson

$numberoflines = (Import-Csv $filenamecsv | Measure-Object -Property string).Count

Write-Host "Done. You now have a $filenamejson with $numberoflines lines from $easylistsource"
