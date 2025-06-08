$vsBase = 'C:/Program Files/Microsoft Visual Studio/2022'
if (Test-Path -Path "$vsBase/Enterprise" -PathType Container ) {
  $vsType = 'Enterprise'
} elseif (Test-Path -Path "$vsBase/Community" -PathType Container ) {
  $vsType = 'Community'
} else {
  exit 1
}

echo $vsType

#$argList = ('/c', "C:/vs_$VSType.exe", 'updateall', '--quiet', '--norestart', '--nocache',
#  'channelUri', 'https://aka.ms/vs/17/release/channel', '--channelId', 'VisualStudio.17.release',
#  '--installpath', "$vsBase/$vsType")

# $process = Start-Process -FilePath cmd.exe  -ArgumentList $argList -Wait -NoNewWindow

$argList = ('updateall', '--quiet', '--norestart', '--nocache', '--wait',
  'channelUri', 'https://aka.ms/vs/17/release/channel', '--channelId', 'VisualStudio.17.release',
  '--installpath', "$vsBase/$vsType")

echo $argList

$process = Start-Process -FilePath C:/vs_$VSType.exe -ArgumentList $argList -Wait -NoNewWindow
echo $process.ExitCode
