function Create-FullNamesWordlist
{
    param (
        [Parameter(Position=0,Mandatory)]
        $NamesWordlist,
        [Parameter(Position=1,Mandatory)]
        $SurnamesWordlist,
        [Parameter(Position=2,Mandatory)]
        $OutputFile
    )


    if (Test-Path -Path $OutputFile)
    {
        Write-Host "[+] Output file '${OutputFile}' already exists"
        Write-Host "[+] Clearing it ..."
        Clear-Content $OutputFile
    }

    $names = Get-Content $NamesWordlist
    $surnames = Get-Content $SurnamesWordlist
    
    for ($i = 0; $i -lt 1000; $i++)
    {
        $names_index = Get-Random -Minimum 0 -Maximum $names.Length
        $surnames_index = Get-Random -Minimum 0 -Maximum $surnames.Length

        $name = $names[$names_index]
        $surname = $surnames[$surnames_index]
        $full_name = [string]::Format("{0};{1}", $name, $surname)
        
        Add-Content -Path $OutputFile -Value $full_name
    }
}
