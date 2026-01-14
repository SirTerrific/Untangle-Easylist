# Source EasyList
$easylistsource = "https://easylist.to/easylist/easylist.txt"
$filenamejson   = "ADImport.json"

# Téléchargement
$EasyList = (Invoke-WebRequest $easylistsource).Content -split "`n"

# Filtrage rapide
$Filtered = $EasyList |
    Where-Object {
        $_ -and                               # Non vide
        $_ -notlike '! *' -and                # Pas un commentaire
        $_ -ne '[Adblock Plus 2.0]' -and      # En-tête à ignorer
        $_ -notmatch '^!'                     # Toutes lignes commençant par !
    }

# Conversion directe en objets
$Objects = foreach ($line in $Filtered) {
    [PSCustomObject]@{
        string         = $line
        blocked        = $true
        javaClass      = 'com.untangle.uvm.app.GenericRule'
        markedForNew   = $true
        markedForDelete= $false
        enabled        = $true
    }
}

# Export JSON compressé
$Objects | ConvertTo-Json -Compress | Set-Content $filenamejson

# Résumé
Write-Host "Généré : $filenamejson avec $($Objects.Count) règles."
