

## Example, it's important that type is [string[]]
## But you can set it like string "something ; something", and it will also work
## [string[]] $VSTSParameter = $env:VSTSPARAMETER

# Example of text
[string[]] $VSTSParameter = 'gmail@gmail.com; ya@ya.ru', 'something@domain.level'

if (-not [string]::IsNullOrEmpty($VSTSParameter)) {
    Write-Host "Parsing parameter, it is not NULL"
    $MultiValues = @()

    foreach ($Value in $VSTSParameter) {
        $MultiValues += $Value.ToString().Split(',').Split(';').Trim()
    }

    Write-Host ("Values: {0}" -f ($MultiValues -join ', '))
    $VSTSParameter = $MultiValues
} else {
    Write-Host "Parameter is NULL"
}

# It's match one of the array items. 
#It's better to check it below within the foreach
if ($VSTSParameter -match ".+\@.+$")  { "TRUE" }