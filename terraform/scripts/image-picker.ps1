

function Show-InteractiveMenu {
    param (
        [string[]]$Options,
        [string]$Prompt = "Please select an option:"
    )
    
    do {
        Write-Host $Prompt
        
        for ($i = 0; $i -lt $Options.Length; $i++) {
            Write-Host "$($i + 1). $($Options[$i])"
        }
        
        $selection = Read-Host "Enter your choice (1-$($Options.Length))"
        
        if ($selection -ge 1 -and $selection -le $Options.Length) {
            $SelectedOption = $Options[$selection - 1]
            Write-Host "Selected Option: ${SelectedOption}"
            return $SelectedOption
        } else {
            Write-Warning "Invalid selection. Please try again."
        }
    } while ($true)
}

# $CacheKey = "region"
# $Regions = (redis-cli get $CacheKey) -split ","
# if(-not $Regions){
#     $Regions = (aws ec2 describe-regions --region us-east-1 | ConvertFrom-Json).Regions | ForEach-Object {$_.RegionName}
#     redis-cli set $CacheKey ($Regions -join ",")
# }



$ImageRegion = Show-InteractiveMenu -Options (Get-Content -Path cache/regions.txt)
$ImageOwner = Show-InteractiveMenu -Options (Get-Content -Path cache/owners.txt)
$ImageArchitecture = Show-InteractiveMenu -Options (Get-Content -Path cache/architectures.txt)
$ImagePlatform = Show-InteractiveMenu -Options (Get-Content -Path cache/platforms.txt)


aws ec2 describe-images `
	--region=$ImageRegion `
	--owners $ImageOwner `
	--filters "Name=owner-alias,Values=$ImageOwner" "Name=platform-details,Values=$ImagePlatform" "Name=architecture,Values=$ImageArchitecture" `
	--query "Images[*].[ImageId,Name]" `
    --output table



# $Data = redis-cli get "data-${ImageRegion}" | ConvertFrom-Json
# if (-not $Data){
#     Write-Host "Data does not contain in cache with data-${ImageRegion}. Fetching remotely ..."
#     $Data = (aws ec2 describe-images --region $ImageRegion | ConvertFrom-Json).Images
#     Write-Host "Caching the data ..."
#     $Data | ConvertTo-Json -Depth 10 | redis-cli -x set "data-${ImageRegion}"
# }


# $ImageOwnerList = $Data | ForEach-Object {
#     if ($_ | Get-Member -Name ImageOwnerAlias){
#         $_.ImageOwnerAlias 
#     } else {
#         "null"
#     }
# } | Sort-Object -Unique

# $ImageOwner = Show-InteractiveMenu -Options $ImageOwnerList


# $Data = $Data | Where-Object {$_.ImageOwnerAlias -eq $ImageOwner}


# $PlatformList = $Data | Select-Object -ExpandProperty "PlatformDetails" | Sort-Object -Unique

# $Platform = Show-InteractiveMenu -Options $PlatformList

# $Data = $Data | Where-Object { $_.PlatformDetails -eq $Platform }

# Write-Out "$(${Data}.Length)"
# Set-Content -Path "${ImageOwner}-${Platform}.json" -Value ($Data | ConvertTo-Json -Depth 10)
