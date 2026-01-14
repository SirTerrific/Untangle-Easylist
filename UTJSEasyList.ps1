<#
.SYNOPSIS
    Générateur de liste de blocage EasyList pour Untangle / Arista ETM.
    Optimisé pour la performance et la conformité JSON.

.NOTES
    Original by WebFooL for The Untangle Community.
    Optimized by ChatGPT (2026-01-14).
#>

# Configuration du protocole de sécurité (Requis pour easylist.to)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Variables
$EasyListSource = "https://easylist.to/easylist/easylist.txt"
$FilenameJson   = "$PSScriptRoot\ADImport.json"

# 1. Téléchargement
Write-Host "Téléchargement de la liste EasyList..." -ForegroundColor Cyan
try {
    $Response = Invoke-WebRequest -Uri $EasyListSource -UseBasicParsing
    if ($Response.StatusCode -ne 200) { throw "Erreur HTTP $($Response.StatusCode)" }
    
    # Découpage robuste (gère LF et CRLF)
    $Lines = $Response.Content -split "\r?\n"
}
catch {
    Write-Error "Échec critique du téléchargement : $_"
    exit 1
}

# 2. Initialisation de la liste (Méthode rapide)
$ProcessedList = [System.Collections.Generic.List[PSCustomObject]]::new()
$TotalLines = $Lines.Count
$Counter = 0

Write-Host "Traitement de $TotalLines lignes en cours..." -ForegroundColor Cyan

# 3. Traitement
foreach ($Line in $Lines) {
    $Counter++
    $CleanLine = $Line.Trim()

    # Mise à jour de la barre de progression (toutes les 2000 lignes pour ne pas ralentir)
    if ($Counter % 2000 -eq 0) {
        Write-Progress -Activity "Traitement EasyList" -Status "$Counter / $TotalLines" -PercentComplete (($Counter / $TotalLines) * 100)
    }

    # Filtres d'exclusion (Commentaires, Headers, Lignes vides)
    if ([string]::IsNullOrWhiteSpace($CleanLine) -or 
        $CleanLine.StartsWith("!") -or 
        $CleanLine -match "^\[.*\]$") {
        continue
    }

    # Création de l'objet règle
    $RuleObject = [PSCustomObject]@{
        string          = $CleanLine
        blocked         = "true"
        javaClass       = "com.untangle.uvm.app.GenericRule"
        markedForNew    = "true"
        markedForDelete = "false"
        enabled         = "true"
    }

    # Ajout à la liste en mémoire
    $ProcessedList.Add($RuleObject)
}

Write-Progress -Activity "Traitement EasyList" -Completed

# 4. Exportation
if ($ProcessedList.Count -gt 0) {
    Write-Host "Génération du JSON pour $($ProcessedList.Count) règles..." -ForegroundColor Cyan
    
    # @() force la structure de tableau [ ... ] requise par Untangle
    # -Compress réduit la taille du fichier
    @($ProcessedList) | ConvertTo-Json -Depth 2 -Compress | Set-Content -Path $FilenameJson -Encoding UTF8
    
    Write-Host "SUCCÈS : Fichier généré -> $FilenameJson" -ForegroundColor Green
    Write-Host "Vous pouvez maintenant importer ce fichier dans Untangle." -ForegroundColor Gray
}
else {
    Write-Warning "Aucune règle valide trouvée. Le fichier JSON n'a pas été créé."
}
