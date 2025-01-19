# Set paths for the folders containing models and instances
$modelsFolder = "."
$instancesFolder = ".\instancies"
$minizincPath = "C:\Program Files\MiniZinc\minizinc.exe" # Specify the path to minizinc.exe

# Get all model files from folder A (assuming .mzn files)
$models = Get-ChildItem -Path $modelsFolder -Filter *.mzn

# Get all instance files from folder B (assuming .dzn files)
$instances = Get-ChildItem -Path $instancesFolder -Filter *.dzn

# Loop through each model
foreach ($instance in $instances) {
    # Loop through each instance
    foreach ($model in $models) {
        # Create a filename for the output file based on model and instance
        $outputFile = "$modelsFolder\outputs\$($model.BaseName)-$($instance.BaseName).out"
        
        # Execute the minizinc command and redirect the output to the file
        & $minizincPath --solver cp-sat -v -s -O3 -p 16 -r 123123 --solver-statistics $model .\instancies\$instance > $outputFile
    }
}