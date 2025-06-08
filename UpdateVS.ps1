Invoke-WebRequest https://aka.ms/vs/17/release/vs_Enterprise.exe -OutFile C:/vs_Enterprise.exe
C:/vs_Enterprise.exe updateall --quiet --includeOptional --wait --clean
