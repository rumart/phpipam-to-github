function Handler($context, $inputs) {
    $out = $inputs.addresses
    $gitOut = @()
    $gitOut += "subnet,ip,hostname,description,lastseen"
    foreach($i in $out){
        $gitOut += "`n"
        $gitOut += "$($i.subnet),$($i.ip),$($i.hostname),$($i.description),$($i.lastseen)"
    }

    $Bytes = [System.Text.Encoding]::Unicode.GetBytes($gitOut)
    $EncodedText =[Convert]::ToBase64String($Bytes)

    $output= @{base64Content=$EncodedText}

    return $output
}
