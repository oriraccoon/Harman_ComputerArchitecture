$repoPath = "C:\Users\kccistc\Documents\GitHub\Harman_ComputerArchitecture"
$gitExe = "C:\Program Files\Git\bin\git.exe"
$vivadoPath = "C:\Xilinx\Vivado\2020.2\bin\vivado.bat"
$vivadoWorkspace = "$env:USERPROFILE\Desktop\workspace"
$gitWorkspace = "$repoPath\workspace"
$today = Get-Date -Format "yyyy-MM-dd"

function Commit-And-Push {
    Set-Location -Path $repoPath
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm"
    $commitMessage = "Auto commit for modified projects on $currentTime"
    
    & $gitExe add .
    & $gitExe commit -m $commitMessage
    & $gitExe push origin main

    Write-Host "`n[✔] Git Auto Commit & Push done at $currentTime"
}

# Vivado 실행
Write-Host "Vivado 2020.2 Start!!"
Start-Process -FilePath $vivadoPath -NoNewWindow -Wait

Write-Host "`nVivado Closed. Checking for modified projects..."

# 수정된 날짜가 오늘인 폴더 찾기
$modifiedProjects = Get-ChildItem -Path $vivadoWorkspace -Directory | Where-Object {
    $_.LastWriteTime.Date -eq (Get-Date $today).Date
}

$hasChanges = $false

foreach ($project in $modifiedProjects) {
    $projectName = $project.Name
    $srcPath = "$vivadoWorkspace\$project\$project.srcs"
    $dstPath = "$gitWorkspace\$projectName\$projectName.srcs"

    if (Test-Path $srcPath) {
        Write-Host "Detected Changed Project: $projectName"
        $hasChanges = $true

        if (Test-Path $dstPath) {
            Write-Host "Deleting old version of: $dstPath"
            Remove-Item -Path $dstPath -Recurse -Force
        }

        Copy-Item -Path $srcPath -Destination $dstPath -Recurse -Force
    }
}

if ($hasChanges) {
    Commit-And-Push
    Start-Sleep -Seconds 2
    Exit
} else {
    Write-Host "`nNothing has changed today. You can still manually commit."
}

# 사용자 입력 루프: 엔터 누르면 커밋
while ($true) {
    $input = Read-Host "`nPress Enter to commit manually (or type 'exit' to quit)"
    if ($input -eq "exit") {
        break
    } else {
        Commit-And-Push
    }
}

Write-Host "`nExiting script."
