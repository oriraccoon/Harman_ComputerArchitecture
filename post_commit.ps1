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

    Write-Host "`n[✔] Git commit & push complete at $currentTime"
}

# 사용자 입력 루프: c 누르면 수동 커밋
Start-Job {
    while ($true) {
        $input = Read-Host "`n[Manual Commit] 입력: 'c' 입력 시 커밋, 'exit' 입력 시 종료"
        if ($input -eq "c") {
            Commit-And-Push
        } elseif ($input -eq "exit") {
            break
        }
    }
} | Out-Null

# Vivado 실행 (현재 창에서 실행하고 종료까지 대기)
Write-Host "Vivado 2020.2 Start!!"
& $vivadoPath
Write-Host "`nVivado Closed. Checking for modified projects..."

# 오늘 수정된 프로젝트 찾기
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
} else {
    Write-Host "Nothing has changed today. No auto commit."
}

# 종료
Exit
