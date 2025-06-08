Invoke-WebRequest https://aka.ms/vs/17/release/vs_Enterprise.exe -OutFile C:/vs_Enterprise.exe
Start-Process -Wait -FilePath C:/vs_Enterprise.exe -ArgumentList "update --quiet --norestart --installpath ""C:\Program Files\Microsoft Visual Studio\2022\Enterprise"""
