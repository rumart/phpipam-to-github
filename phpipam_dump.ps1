function Handler($context, $inputs) {

    #IPAM stuff
    $ipamBaseUrl = $inputs.ipamBaseUrl

    $ipamAppId = $inputs.ipamAppId
    $ipamAppUrl = $ipamBaseUrl + $ipamAppId

    $sectionsUrl = $ipamAppUrl + "/sections"
    $subnetsUrl = $ipamAppUrl + "/subnets"

    $ipamToken = $inputs.ipamToken
    $headers = @{"token"=$ipamToken}

    $sectionResult = Invoke-Restmethod -Method Get -Uri $sectionsUrl -Headers $headers -SkipCertificateCheck

    $section = $sectionResult.Data.Where{$_.Name -eq "Proact"}
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

    #Write-Host $out
    $output=@{out = $out}

    return $output
}
