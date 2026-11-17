param([string]$DevEcoHome = 'D:\Harmony\DevEco Studio')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$nodePath = Join-Path $DevEcoHome 'tools\node\node.exe'
$builderPath = Join-Path $DevEcoHome 'tools\hvigor\bin\hvigorw.js'
if (!(Test-Path -LiteralPath $nodePath)) { throw '��ͨ�� -DevEcoHome ָ�� DevEco Studio ��װĿ¼��' }
$env:DEVECO_SDK_HOME = Join-Path $DevEcoHome 'sdk'
$env:JAVA_HOME = Join-Path $DevEcoHome 'jbr'
$env:Path = (Join-Path $DevEcoHome 'tools\node') + ';' + (Join-Path $DevEcoHome 'tools\ohpm\bin') + ';' + $env:Path
Push-Location -LiteralPath $projectRoot
try {
  & $nodePath $builderPath --mode module -p product=default -p module=entry@default assembleHap --no-daemon
  if ($LASTEXITCODE -ne 0) { throw 'Hvigor ����ʧ�ܣ���鿴�Ϸ���һ������' }
} finally { Pop-Location }
