$vsBase = 'C:\Program Files\Microsoft Visual Studio\2022'
if (Test-Path -Path "$vsBase/Enterprise" -PathType Container ) {
  $vsType = 'Enterprise'
} elseif (Test-Path -Path "$vsBase/Community" -PathType Container ) {
  $vsType = 'Community'
} else {
  exit 1
}

echo $vsType

$argList = ('updateAll', '--quiet', '--norestart', '--nocache', '--wait',
  '--installPath', """$vsBase\$vsType""")

echo $argList

$process = Start-Process -FilePath C:/vs_$VSType.exe -ArgumentList $argList -Wait -NoNewWindow
echo $process.ExitCode
