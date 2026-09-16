param([ValidateSet('start','stop','status','install','uninstall')][string]$Action = 'start')
$ErrorActionPreference = 'Stop'
$appRoot = Split-Path $PSScriptRoot -Parent
$rubyRoot = 'C:\Ruby33-x64'
$nginxRoot = 'C:\nginx'
$startupFile = Join-Path ([Environment]::GetFolderPath('Startup')) 'Andar360Startup.vbs'
$mutex = New-Object Threading.Mutex($false, 'Local\Andar360Launcher')
if (-not $mutex.WaitOne(0)) { Write-Output 'Inicializador ja esta em execucao.'; exit 0 }

function App-Process([string]$kind) {
  $scriptPath = Join-Path $PSScriptRoot "andar360_$kind.rb"
  Get-CimInstance Win32_Process -Filter "Name='ruby.exe'" | Where-Object { $_.CommandLine -and $_.CommandLine.Contains($scriptPath) }
}
function Start-AppProcess([string]$kind) {
  if (App-Process $kind) { return }
  $scriptPath = Join-Path $PSScriptRoot "andar360_$kind.rb"
  Start-Process -FilePath "$rubyRoot\bin\ruby.exe" -ArgumentList "`"$scriptPath`"" -WorkingDirectory $appRoot -WindowStyle Hidden -RedirectStandardOutput "$appRoot\log\andar360_${kind}_stdout.log" -RedirectStandardError "$appRoot\log\andar360_${kind}_stderr.log" | Out-Null
}
try {
  Set-Location $appRoot
  if ($Action -eq 'install') {
    $command = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $PSCommandPath + '" start'
    $vbs = 'Set shell = CreateObject("WScript.Shell")' + "`r`n" + 'shell.Run "' + $command.Replace('"','""') + '", 0, False' + "`r`n"
    [IO.File]::WriteAllText($startupFile, $vbs, [Text.Encoding]::Default)
    Write-Output "Inicio automatico ao entrar no Windows instalado: $startupFile"
    return
  }
  if ($Action -eq 'uninstall') {
    Remove-Item -LiteralPath $startupFile -ErrorAction SilentlyContinue
    Write-Output 'Inicio automatico removido.'
    return
  }
  if ($Action -eq 'stop') {
    foreach ($kind in @('server','worker')) { App-Process $kind | ForEach-Object { Stop-Process -Id $_.ProcessId } }
    Write-Output 'Andar360 parado. O Nginx compartilhado continua em execucao.'
    return
  }
  if ($Action -eq 'status') {
    foreach ($kind in @('server','worker')) {
      $processes = @(App-Process $kind)
      Write-Output "$kind : $($processes.Count) processo(s) $($processes.ProcessId)"
    }
    Write-Output "Inicio automatico: $(Test-Path -LiteralPath $startupFile)"
    return
  }
  New-Item -ItemType Directory -Force -Path "$appRoot\log", "$appRoot\storage" | Out-Null
  $env:RI_FORCE_PATH_FOR_DLL = '1'
  $env:RUBYLIB = Join-Path $appRoot 'ruby_overrides'
  $env:PATH = "$rubyRoot\bin;$rubyRoot\lib\ruby\3.3.0\x64-mingw-ucrt;$rubyRoot\msys64\ucrt64\bin;$rubyRoot\msys64\usr\bin;" + $env:PATH
  $env:RAILS_ENV = 'production'
  $env:RACK_ENV = 'production'
  $env:RAILS_SERVE_STATIC_FILES = 'true'
  $secretPath = Join-Path $appRoot 'storage\andar360_secret_key_base'
  if (-not $env:SECRET_KEY_BASE) {
    if (-not (Test-Path -LiteralPath $secretPath)) {
      $secret = & "$rubyRoot\bin\ruby.exe" -rsecurerandom -e 'puts SecureRandom.hex(64)'
      if ($LASTEXITCODE -ne 0) { throw 'Falha ao gerar chave local.' }
      [IO.File]::WriteAllText($secretPath, $secret.Trim())
    }
    $env:SECRET_KEY_BASE = [IO.File]::ReadAllText($secretPath).Trim()
  }
  $databaseReady = $false
  for ($attempt = 0; $attempt -lt 30; $attempt++) {
    $tcp = New-Object Net.Sockets.TcpClient
    try { $tcp.Connect('127.0.0.1',5432); $databaseReady = $true; break } catch { Start-Sleep -Seconds 2 } finally { $tcp.Dispose() }
  }
  if (-not $databaseReady) { throw 'PostgreSQL indisponivel na porta 5432.' }
  $listener = Get-NetTCPConnection -LocalPort 3001 -State Listen -ErrorAction SilentlyContinue
  if ($listener -and -not (App-Process 'server')) { throw 'Porta 3001 ocupada por outro processo.' }
  Start-AppProcess 'server'
  $ready = $false
  for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
      $response = Invoke-WebRequest 'http://127.0.0.1:3001/users/sign_in' -UseBasicParsing -TimeoutSec 5
      if ($response.StatusCode -eq 200) { $ready = $true; break }
    } catch { Start-Sleep -Seconds 2 }
  }
  if (-not $ready) { throw 'Servidor nao respondeu. Consulte log\andar360_server_stderr.log.' }
  Start-AppProcess 'worker'
  Start-Sleep -Seconds 3
  if (-not (App-Process 'worker')) { throw 'Worker nao iniciou. Consulte log\andar360_worker_stderr.log.' }
  $nginx = Get-CimInstance Win32_Process -Filter "Name='nginx.exe'" | Where-Object { $_.ExecutablePath -eq "$nginxRoot\nginx.exe" }
  if (-not $nginx) {
    & "$nginxRoot\nginx.exe" -p 'C:/nginx/' -t
    if ($LASTEXITCODE -ne 0) { throw 'Configuracao do Nginx invalida.' }
    Start-Process "$nginxRoot\nginx.exe" -WorkingDirectory $nginxRoot -WindowStyle Hidden
  }
  Write-Output 'Andar360 iniciado: http://localhost:3001 | http://localhost:8081 | http://andar360.ddns.net'
} catch {
  $message = "$(Get-Date -Format s) $($_.Exception.Message)"
  Add-Content -LiteralPath "$appRoot\log\andar360_startup.log" -Value $message
  Write-Error $message
} finally {
  $mutex.ReleaseMutex()
  $mutex.Dispose()
}
