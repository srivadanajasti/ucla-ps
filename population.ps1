# Define the Get-PrimeFactors function
function Get-PrimeFactors {
    param (
        [Parameter(Mandatory=$true)]
        [int]$Number
    )
    $factors = @()
    for ($i = 2; $i -le $Number; $i++) {
        while ($Number % $i -eq 0) {
            $factors += $i
            $Number /= $i
        }
    }
    return $factors
}

# Read the JSON data from the API endpoint
$json = Invoke-RestMethod -Uri "https://datausa.io/api/data?drilldowns=State&measures=Population"

# Create a hashtable to store the data
$data = @{}

# Loop through each record in the JSON data and populate the hashtable
foreach ($record in $json.data) {
    $state = $record.State
    $year = $record.Year
    $value = $record.Population

    if ($data.ContainsKey($state)) {
        $data[$state].$year = $value
    } else {
        $data[$state] = @{ $year = $value }
    }
}

# Get a list of all years
$years = $json.data | Select-Object -Unique Year | Sort-Object Year | Select-Object -ExpandProperty Year
$finalYear = $years[-1]

# Create the CSV file
$header = "State Name," + ($years -join ",") + ",$finalYear Factors"
$output = @()
foreach ($state in $data.Keys) {
    $row = [ordered]@{
        "State Name" = $state
    }
    $previousValue = 0
    foreach ($year in $years) {
        $currentValue = $data[$state].$year
        if ($previousValue -ne 0) {
            $percentageChange = [Math]::Round(($currentValue - $previousValue) / $previousValue * 100, 2)
            $formattedValue = "$currentValue ($percentageChange%)"
        } else {
            $formattedValue = $currentValue
        }
        $row[$year] = $formattedValue
        $previousValue = $currentValue
    }
    $primeFactors = Get-PrimeFactors -Number $previousValue
    $primeFactorsString = $primeFactors -join ";"
    $row["$finalYear Factors"] = $primeFactorsString
    $output += New-Object PSObject -Property $row
}

# Save the CSV file
$output | Export-Csv -Path "file.csv" -NoTypeInformation