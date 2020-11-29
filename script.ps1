    #GitHub stuff
    
    $gitRepo = "<Full path to github file>"
    $bearerToken = "<GITHUB OAUTH TOKEN>"
    $gitHeaders = @{"Authorization"= "bearer $bearerToken"}

    #IPAM stuff
    $ipamBaseUrl = "<PHPIPAM API URL>"

    $ipamAppId = "<PHPIPAM APP ID>"
    $ipamAppUrl = $ipamBaseUrl + $ipamAppId

    $sectionsUrl = $ipamAppUrl + "/sections"
    $subnetsUrl = $ipamAppUrl + "/subnets"

    $ipamToken = "<PHPIPAM TOKEN>"
    $headers = @{"token"=$ipamToken}

    $sectionResult = Invoke-Restmethod -Method Get -Uri $sectionsUrl -Headers $headers -SkipCertificateCheck

    $section = $sectionResult.Data.Where{$_.Name -eq "<SECTION NAME>"}
    $sectionId = $section.id

    $secSubnetResults = Invoke-RestMethod -Method Get -Uri ($sectionsUrl + "/$sectionId/subnets") -Headers $headers -SkipCertificateCheck

    #Build output
    $out = @()
    if($secSubnetResults.code -eq 200){
        $subnets = $secSubnetResults.data

        foreach($subnet in $subnets){
            $subnetUrl = $subnetsUrl + "/$($subnet.id)/addresses"
            $subnetResults = Invoke-RestMethod -Method Get -Uri $subnetUrl -Headers $headers -SkipCertificateCheck
            if($subnetResults.data){
                $my = $subnetResults.data
                $out += $my | Select-Object @{l="subnet";e={$subnet.subnet}},ip,hostname,description,lastseen
            }
            elseif($subnetResults.message){
                $out += [PSCustomObject]@{
                    subnet = $subnet.subnet
                    ip = "n/a"
                hostname = $subnetResults.message
                description = "n/a"
                lastSeen = "n/a"
            }
        }
    }
}

$gitOut = @()
$gitOut += "subnet,ip,hostname,description,lastseen"
foreach($i in $out){
    $gitOut += "`n"
    $gitOut += "$($i.subnet),$($i.ip),$($i.hostname),$($i.description),$($i.lastseen)"
}
#$gitOut += "`n"

$Bytes = [System.Text.Encoding]::Unicode.GetBytes($gitOut)
$EncodedText =[Convert]::ToBase64String($Bytes)

#Build github request
$existingFile = Invoke-Restmethod -Method Get -Uri $gitRepo -Headers $gitHeaders -ContentType "application/json" -SkipCertificateCheck
$existingFileSha = $existingFile.sha

$gitBody = @{

    "message"= "Automated IPAM dump"
    "committer"= @{
        "name"= $inputs.committerName
        "email"= $inputs.committerEmail
    } 
"content"= $encodedText
"sha" = $existingFileSha

} | ConvertTo-Json

Invoke-Restmethod -Method Put -Uri $gitRepo -Headers $gitHeaders -Body $gitBody -ContentType "application/json" -SkipCertificateCheck
