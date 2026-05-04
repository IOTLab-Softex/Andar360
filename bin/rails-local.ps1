$localRubyBin = Join-Path $env:USERPROFILE 'Ruby33-local\bin'

if (-not (Test-Path (Join-Path $localRubyBin 'ruby.exe'))) {
  Write-Error "Ruby local nao encontrado em $localRubyBin"
  exit 1
}

$env:PATH = "$localRubyBin;$env:PATH"

& (Join-Path $localRubyBin 'bundle.bat') exec ruby bin/rails @args
exit $LASTEXITCODE
