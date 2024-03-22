param(
    [Parameter(Mandatory=$True, ValueFromPipeline = $true)]
    [string]$value
)

return [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($value))