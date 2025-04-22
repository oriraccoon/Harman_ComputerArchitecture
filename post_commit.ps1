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

# Vivado 백그라운드 실행
Write-Host "Vivado 2020.2 Start!!"
$vivadoProcess = Start-Process -FilePath $vivadoPath -PassThru

# 사용자 입력 감지 쓰레드 (엔터 누르면 수동 커밋)
Start-Job {
    while ($true) {
        $null = Read-Host "`n[Manual] Press Enter to commit manually (type 'exit' to stop manual commits)"
        if ($_ -eq "exit") { break }
        Commit-And-Push
    }
} | Out-Null

# Vivado 종료까지 대기
$vivadoProcess.WaitForExit()

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

# 자동 커밋 후 종료
if ($hasChanges) {
    Commit-And-Push
} else {
    Write-Host "Nothing has changed today. No auto commit."
}

# PowerShell 종료
Exit
