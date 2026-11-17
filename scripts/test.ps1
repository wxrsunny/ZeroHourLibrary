param([string]$DevEcoHome = 'D:\Harmony\DevEco Studio')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$env:DEVECO_STUDIO_HOME = $DevEcoHome
Push-Location -LiteralPath $projectRoot
try {
  & (Join-Path $DevEcoHome 'tools\node\node.exe') tests/run.cjs
  if ($LASTEXITCODE -ne 0) { throw 'ģ�����ʧ�ܣ���鿴 tests/results/module-tests.json��' }
} finally { Pop-Location }
