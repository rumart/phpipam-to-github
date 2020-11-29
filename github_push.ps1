function Handler($context, $inputs) {

    $gitRepo = $inputs.path
    $bearerToken = $inputs.token
    $gitHeaders = @{"Authorization"= "bearer $bearerToken"}

    $existingFile = Invoke-Restmethod -Method Get -Uri $gitRepo -Headers $gitHeaders -ContentType "application/json" -SkipCertificateCheck
    $existingFileSha = $existingFile.sha

    $gitBodyProps = @{}
    $gitBodyProps.Add("message",$inputs.commitMessage)
    $gitCommitterProps = @{"name"=$inputs.committer;"email"=$inputs.committerEmail}
    $gitBodyProps.Add("committer",$gitCommitterProps)
    $gitBodyProps.Add("content",$inputs.content)
    if($existingFileSha){$gitBodyProps.Add("sha",$existingFileSha)}

    $gitBody = $gitBodyProps | ConvertTo-Json

    Invoke-Restmethod -Method Put -Uri $gitRepo -Headers $gitHeaders -Body $gitBody -ContentType "application/json" -SkipCertificateCheck

    $output=@{status = 'done'}

    return $output
}
