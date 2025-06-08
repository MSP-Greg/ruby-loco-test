Invoke-WebRequest https://aka.ms/vs/17/release/vs_Enterprise.exe -OutFile C:/vs_Enterprise.exe
$argList = ('/c', 'C:/vs_Enterprise.exe', 'update', '--quiet', '--norestart', '--nocache', '--installpath', '"C:/Program Files/Microsoft Visual Studio/2022/Enterprise"')
$process = Start-Process -FilePath cmd.exe  -ArgumentList $argList -Wait -PassThru -NoNewWindow
echo $process.ExitCode
