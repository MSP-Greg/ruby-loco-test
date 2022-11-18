<# Code by MSP-Greg
Script for building & installing MinGW Ruby for CI
Assumes a Ruby exe is in path
Assumes 'Git for Windows' is installed at $env:ProgramFiles\Git
Assumes '7z             ' is installed at $env:ProgramFiles\7-Zip
For local use, set items in local.ps1

cmd /k "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"

powershell ./mswin.ps1
#>

#————————————————————————————————————————————————————————————————— Apply-Patches
# Applies patches in ruby source folder
function Apply-Patches($p_dir) {
  if (Test-Path -Path $p_dir -PathType Container ) {
    $patch_exe = "$d_msys2/usr/bin/patch.exe"
    Push-Location "$d_repo/$p_dir"
    [string[]]$patches = Get-ChildItem -Include *.patch -Path . -Recurse |
      select -expand name
    Pop-Location
    if ($patches.length -ne 0) {
      Push-Location "$d_ruby"
      foreach ($p in $patches) {
        if ($p.StartsWith("__")) { continue }
        EchoC "$($dash * 55) $p" yel
        & $patch_exe -p1 -N --no-backup-if-mismatch -i "$d_repo/$p_dir/$p"
      }
      Pop-Location
    }
    Write-Host ''
  }
}

#————————————————————————————————————————————————————————————————— Apply-Install-Patches
# Applies patches in install folder
function Apply-Install-Patches($p_dir) {
  $patch_exe = "$d_msys2/usr/bin/patch.exe"
  Push-Location "$d_repo/$p_dir"
  [string[]]$patches = Get-ChildItem -Include *.patch -Path . -Recurse |
    select -expand name
  Pop-Location
  Push-Location "$d_install"
  foreach ($p in $patches) {
    EchoC "$($dash * 55) $p" yel
    & $patch_exe -p1 -N --no-backup-if-mismatch -i "$d_repo/$p_dir/$p"
  }
  Pop-Location
  Write-Host ''
}

#————————————————————————————————————————————————————————————————— Files-Hide
# Hides files for compiling/linking
function Files-Hide($f_ary) {
  foreach ($f in $f_ary) {
    if (Test-Path -Path $f -PathType Leaf ) { ren $f ($f + '__') }
  }
}

#————————————————————————————————————————————————————————————————— Files-Unhide
# UnHides files previously hidden
function Files-Unhide($f_ary) {
  foreach ($f in $f_ary) {
    if (Test-Path -Path ($f + '__') -PathType Leaf ) { ren ($f + '__') $f }
  }
}

#———————————————————————————————————————————————————————————————— Print-Time-Log
function Print-Time-Log {
  $diff = New-TimeSpan -Start $script:time_start -End $script:time_old
  $script:time_info += ("{0:mm}:{0:ss} {1}" -f @($diff, "Total"))

  EchoC $($dash * 80) yel
  Write-Host $script:time_info
  $fn = "$d_logs/time_log_build.log"
  [IO.File]::WriteAllText($fn, $script:time_info, $UTF8)
  if ($is_av) {
    Add-AppveyorMessage -Message "Time Log Build" -Details $script:time_info
  }
}

#—————————————————————————————————————————————————————————————————————— Time-Log
function Time-Log($msg) {
  if ($script:time_old) {
    $time_new = Get-Date
    $diff = New-TimeSpan -Start $time_old -End $time_new
    $script:time_old = $time_new
    $script:time_info += ("{0:mm}:{0:ss} {1}`n" -f @($diff, $msg))
  } else {
    $script:time_old   = Get-Date
    $script:time_start = $script:time_old
  }
}

#———————————————————————————————————————————————————————————————————— Check-Exit
# checks whether to exit
function Check-Exit($msg, $pop) {
  if ($LastExitCode -and $LastExitCode -ne 0) {
    if ($pop) { Pop-Location }
    EchoC "Failed - $msg" yel
    exit 1
  }
}

#——————————————————————————————————————————————————————————————————————————— Run
# Run a command and check for error
function Run($e_msg, $exec) {
  $orig = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'

  if ($is_actions) {
    echo "##[group]$(color $e_msg yel)"
  } else {
    echo "$(color $e_msg yel)"
  }

  &$exec

  Check-Exit $eMsg
  $ErrorActionPreference = $orig
  if ($is_actions) { echo ::[endgroup] } else { echo '' }
}

#——————————————————————————————————————————————————————————————————— Strip-Build
# Strips dll & so files in build folder
function Strip-Build {
  Push-Location $d_build
  $strip = "$d_mingw/strip.exe"

  [string[]]$dlls = Get-ChildItem -Include *.dll -Recurse |
    select -expand fullname
  foreach ($dll in $dlls) {
    Set-ItemProperty -Path $dll -Name IsReadOnly -Value $false
    $t = $dll.replace('\', '/')
    &$strip -Dp --strip-unneeded $t
  }

  [string[]]$exes = Get-ChildItem -Path ./*.exe |
    select -expand fullname
  foreach ($exe in $exes) {
    Set-ItemProperty -Path $exe -Name IsReadOnly -Value $false
    $t = $exe.replace('\', '/')
    &$strip -Dp --strip-all $t
  }

  $d_so = "$d_build/.ext/$rarch"

  [string[]]$sos = Get-ChildItem -Include *.so -Path $d_so -Recurse |
    select -expand fullname
  foreach ($so in $sos) {
    Set-ItemProperty -Path $so -Name IsReadOnly -Value $false
    $t = $so.replace('\', '/')
    &$strip -Dp --strip-unneeded $t
  }
  $msg = "Build:   Stripped {0,2} dll files, {1,2} exe files, and {2,3} so files" -f `
    @($dlls.length, $exes.length, $sos.length)
  EchoC $($dash * 80) yel
  echo $msg
  Pop-Location
}

#————————————————————————————————————————————————————————————————— Strip-Install
# Strips dll & so files in install folder
function Strip-Install {
  Push-Location $d_install
  $strip = "$d_mingw/strip.exe"

  $d_bin = "$d_install/bin"

  [string[]]$dlls = Get-ChildItem -Path ./bin/*.dll |
    select -expand fullname
  foreach ($dll in $dlls) {
    Set-ItemProperty -Path $dll -Name IsReadOnly -Value $false
    $t = $dll.replace('\', '/')
    &$strip -Dp --strip-unneeded $t
  }

  [string[]]$exes = Get-ChildItem -Path ./bin/*.exe |
    select -expand fullname
  foreach ($exe in $exes) {
    Set-ItemProperty -Path $exe -Name IsReadOnly -Value $false
    $t = $exe.replace('\', '/')
    &$strip -Dp --strip-all $t
  }

  $abi = ruby.exe -e "print RbConfig::CONFIG['ruby_version']"
  $d_so = "$d_install/lib/ruby/$abi/$rarch"

  [string[]]$sos = Get-ChildItem -Include *.so -Path $d_so -Recurse |
    select -expand fullname
  foreach ($so in $sos) {
    Set-ItemProperty -Path $so -Name IsReadOnly -Value $false
    $t = $so.replace('\', '/')
    &$strip -Dp --strip-unneeded $t
  }

  $msg = "Install: Stripped {0,2} dll files, {1,2} exe files, and {2,3} so files" -f `
    @($dlls.length, $exes.length, $sos.length)
  EchoC $($dash * 80) yel
  echo $msg
  Pop-Location
}

#————————————————————————————————————————————————————————————————— Set-Variables-Local
# set variables only used in this script
function Set-Variables-Local {
  $script:ruby_path = $(ruby.exe -e "puts RbConfig::CONFIG['bindir']").trim().replace('\', '/')
  $script:time_info = ''
  $script:time_old  = $null
  $script:time_start = $null
}

#——————————————————————————————————————————————————————————————————— start build
cd $PSScriptRoot

$global:build_sys = "mswin"
$env:MINGW_PREFIX = "ucrt64"

. ./0_common.ps1

Set-Variables

Set-Variables-Local
$env:Path = "$ruby_path;$d_repo/git/cmd;$env:Path;$d_msys2/usr/bin;$d_mingw;"

$files = "C:/Windows/System32/libcrypto-1_1-x64.dll",
         "C:/Windows/System32/libssl-1_1-x64.dll"

Files-Hide $files

Apply-Patches "mswin_patches"

Create-Folders

# set time stamp for reproducible build
$ts = $(git log -1 --format=%at).Trim()
if ($ts -match '\A\d+\z' -and $ts -gt "1540000000") {
  $env:SOURCE_DATE_EPOCH = [String][int]$ts
  # echo "SOURCE_DATE_EPOCH = $env:SOURCE_DATE_EPOCH"
}

cd $d_build

$cmd_config = "..\ruby\win32\configure.bat --disable-install-doc --prefix=$d_install --without-ext=+,dbm,gdbm --with-opt-dir=C:/vcpkg/installed/x64-windows"
Run "$($dash * 55) configure.bat" { cmd.exe /c "$cmd_config" }

# below sets some directories to normal in case they're set to read-only
Remove-Read-Only $d_ruby
Remove-Read-Only $d_build

Run "$($dash * 55) nmake incs" { iex "nmake incs" }

Run "$($dash * 55) nmake extract-extlibs" { iex "nmake extract-extlibs" }

$env:Path = "C:\vcpkg\installed\x64-windows\bin;$env:Path"

Run "$($dash * 55) nmake" { iex "nmake" }

Files-Unhide $files

Run "$($dash * 55) nmake 'DESTDIR=' install-nodoc" { iex "nmake `"DESTDIR=`" install-nodoc" }

# generates string like 320, 310, etc
$ruby_abi = ([regex]'\Aruby (\d+\.\d+)').match($(./miniruby.exe -v)).groups[1].value.replace('.', '') + '0'

# set correct ABI version for manifest file
$file = "$d_repo/mswin/ruby-exe.xml"
(Get-Content $file -raw) -replace "ruby\d{3}","ruby$ruby_abi" | Set-Content $file

cd $d_repo
del $d_install\lib\x64-vcruntime140-ruby$ruby_abi-static.lib

cd $d_install\bin\ruby_builtin_dlls
$d_vcpkg_install = "$d_vcpkg/installed/x64-windows"
Copy-Item $d_vcpkg_install/bin/libcrypto-3-x64.dll
Copy-Item $d_vcpkg_install/bin/libssl-3-x64.dll
Copy-Item $d_vcpkg_install/bin/libffi.dll
Copy-Item $d_vcpkg_install/bin/yaml.dll
Copy-Item $d_vcpkg_install/bin/readline.dll
Copy-Item $d_vcpkg_install/bin/zlib1.dll
Copy-Item $d_repo/mswin/ruby_builtin_dlls.manifest

cd $d_repo
# below can't run from built Ruby, as it needs valid cert files
ruby 1_2_post_install_common.rb run

cd $d_install\bin
EchoC "$($dash * 55) manifest ruby.exe, rubyw.exe" yel
mt.exe -manifest $d_repo\mswin\ruby-exe.xml -outputresource:ruby.exe;1
mt.exe -manifest $d_repo\mswin\ruby-exe.xml -outputresource:rubyw.exe;1

# below needs to run from built/installed Ruby
EchoC "$($dash * 55)" yel
cd $d_repo
$env:Path = "$d_install\bin;$no_ruby_path"
&"$d_install/bin/ruby.exe" 1_4_post_install_bin_files.rb

if (Test-Path Env:\SOURCE_DATE_EPOCH ) { Remove-Item Env:\SOURCE_DATE_EPOCH }

$ruby_exe  = "$d_install/bin/ruby.exe"
$ruby_v = &$ruby_exe -v

if (-not ($ruby_v -cmatch "$rarch\]\z")) {
  throw("Ruby may have compile/install issue, won't start")
} else {
  Write-Host $ruby_v
}

# reset to original
$env:Path = $orig_path

# Apply-Patches "mswin_test_patches"