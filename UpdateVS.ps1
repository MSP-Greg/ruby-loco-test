$argList = ('/c', 'C:/vs_Enterprise.exe', 'install', '--quiet', '--norestart', '--nocache', 'channelUri', 'https://aka.ms/vs/17/release/channel', '--channelId', 'VisualStudio.17.release','--installpath', '"C:/Program Files/Microsoft Visual Studio/2022/Enterprise"')
$process = Start-Process -FilePath cmd.exe  -ArgumentList $argList -Wait -PassThru -NoNewWindow
echo $process.ExitCode
