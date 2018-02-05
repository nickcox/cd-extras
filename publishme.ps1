Copy-Item $PSScriptRoot/readme.md $PSScriptRoot/cd-extras/about_Cd-Extras.help.txt
Publish-Module -Path $PSScriptRoot/cd-extras -NuGetApiKey $env:PSNugetKey -Verbose