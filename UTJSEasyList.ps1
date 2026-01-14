# Optimisation pour TLS 1.2 (nécessaire pour certains téléchargements HTTPS modernes)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$easyListSource = "https://easylist.to/easylist/easylist.txt"
$filenameJson = "ADImport.json"

Write-Host "Téléchargement de la liste EasyList..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri $easyListSource -UseBasicParsing
    # Séparation en lignes en gérant les différents types de sauts de ligne (CRLF, LF)
    $lines = $response.Content -split "\r?\n"
}
catch {
    Write-Error "Échec du téléchargement : $_"
    exit
}

$totalLines = $lines.Count
$processedList = [System.Collections.Generic.List[PSCustomObject]]::new()
$counter = 0

Write-Host "Traitement de $totalLines lignes..." -ForegroundColor Cyan

foreach ($line in $lines) {
    $counter++
    
    # Nettoyage des espaces
    $cleanLine = $line.Trim()

    # Affichage de la progression tous les 1000 items pour ne pas ralentir le script
    if ($counter % 1000 -eq 0) {
        Write-Progress -Activity "Traitement EasyList" -Status "$counter / $totalLines" -PercentComplete (($counter / $totalLines) * 100)
    }

    # Logique de filtrage (Commentaires, Entêtes, Lignes vides)
    if ([string]::IsNullOrWhiteSpace($cleanLine) -or 
        $cleanLine.StartsWith("!") -or 
        $cleanLine -match "^\[.*\]$") {
        continue
    }

    # Création directe de l'objet (plus rapide et sûr que la concaténation de string CSV)
    $obj = [PSCustomObject]@{
        string          = $cleanLine
        blocked         = "true"
        javaClass       = "com.untangle.uvm.app.GenericRule"
        markedForNew    = "true"
        markedForDelete = "false"
        enabled         = "true"
    }

    $processedList.Add($obj)
}

Write-Progress -Activity "Traitement EasyList" -Completed

# Exportation JSON
Write-Host "Conversion et sauvegarde en JSON..." -ForegroundColor Cyan
$processedList | ConvertTo-Json -Depth 2 -Compress | Set-Content -Path $filenameJson -Encoding UTF8

Write-Host "Terminé ! $($processedList.Count) règles importées dans $filenameJson." -ForegroundColor Green
