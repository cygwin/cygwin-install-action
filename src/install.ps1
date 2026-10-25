$ErrorActionPreference = 'Stop'

# Import functions.
. "$PSScriptRoot/_functions.ps1"

$platform = Get-Validated-Platform -Platform "$env:inputs_platform"
$vol = Get-Validated-Work-Volume -WorkVolume "$env:inputs_work_vol"

$setupExe = "$vol\setup.exe"
$setupFileName = "setup-$platform.exe"
Invoke-WebRequest-With-Retry "https://cygwin.com/$setupFileName" $setupExe

if ((Get-Item -LiteralPath $setupExe).Length -eq 0) {
    throw "The downloaded setup has a zero length!"
}

if ("$env:inputs_check_installer_sig" -ne 'false') {
   Check-Installer-Sig -SetupExePath $setupExe
}

if ("$env:inputs_check_hash" -eq 'true') {
    $hashFile = "$vol\sha512.sum"
    Invoke-WebRequest-With-Retry https://cygwin.com/sha512.sum $hashFile
    $expectedHashLines = Get-Content $hashFile
    $expectedHash = ''
    foreach ($expectedHashLine in $expectedHashLines) {
        if ($expectedHashLine.EndsWith(" $setupFileName")) {
            $expectedHash = $($expectedHashLine -split '\s+')[0]
            break
        }
    }
    if ($expectedHash -eq '') {
        Write-Output -InputObject "::warning::Unable to find the hash for the file $setupFileName in https://cygwin.com/sha512.sum"
    } else {
        $actualHash = $(Get-FileHash -LiteralPath $setupExe -Algorithm SHA512).Hash
        if ($actualHash -ine $expectedHash) {
            throw "Invalid hash of the downloaded setup!`nExpected: $expectedHash`nActual  : $actualHash"
        } else {
            Write-Output -InputObject "The downloaded file has the expected hash ($expectedHash)"
        }
    }
}

$installDir = "$vol\cygwin"
if ("$env:inputs_install_dir" -ne '') {
    $installDir = "$env:inputs_install_dir"
}

$packageDir = "$vol\cygwin-packages"
if ("$env:inputs_package_cache_dir" -ne '') {
    $packageDir = "$env:inputs_package_cache_dir"
}

$packages = "$env:inputs_packages"
$pkg_list = $packages.Split('', [System.StringSplitOptions]::RemoveEmptyEntries)
$pkg_list = $pkg_list | % { $_.Trim() }
$pkg_list = $pkg_list | % { $_.Trim(',') }

$args = @(
 '-qnO',
 '-l', "$packageDir",
 '-R', "$installDir"
)

if ( "$env:inputs_allow_test_packages" -eq 'true' ) {
    $args += '-t' # --allow-test-packages
}

$site_list = Get-Validated-Sites -Platform "$platform" -Sites "$env:inputs_site"
foreach ($site in $site_list) {
    $args += '-s'
    $args += $site
}

if ($pkg_list.Count -gt 0) {
    $args += '-P'
    $args += $pkg_list -Join(',')
}

if ("$env:inputs_check_sig" -eq $false) {
    $args += '-X'
}

if ( "$env:inputs_pubkeys" ) {
    $pubkeys = "$env:inputs_pubkeys"
    $pubkey_list = $pubkeys.Split('', [System.StringSplitOptions]::RemoveEmptyEntries)
    $pubkey_list = $pubkey_list | % { $_.Trim() }
    foreach ($pubkey in $pubkey_list) {
        $args += '-K'
        $args += $pubkey
    }
}

if ($platform -eq 'x86') {
    $args += '--allow-unsupported-windows'
}

Invoke-Cygwin-Setup -SetupExePath $setupExe -SetupExeArgs $args

if ("$env:inputs_work_vol" -eq '' -and "$env:inputs_install_dir" -eq '') {
    # Create a symlink for compatibility with previous versions of this
    # action, just in case something relies upon C:\cygwin existing
    cmd /c mklink /d C:\cygwin $installDir
}

if ("$env:inputs_add_to_path" -eq 'true') {
    echo "$installDir\bin" >> $env:GITHUB_PATH
}

# run login shell to copy skeleton profile files
& "$installDir\bin\bash.exe" --login

# Compute a hash for the package cache
#
# It seems like the cache action doesn't provide a way to natively hash the
# directory it's caching (and hashFiles appears to be useless for that
# purpose, since it refuses to work outside of GITHUB_WORKSPACE), so roll
# our own.
#
# We just hash the file name and size of all files in the package cache
# (ignoring the contents for performance, and the timestamp because setup
# always touches setup.ini). If setup wrote some sort of package cache
# index, we'd just use the hash of that instead!
$cmd= @"
  cache_dir=`$(cygpath -ua "$packageDir");
  find "`${cache_dir}" -type f -exec stat -c '%n %s' {} + | sha256sum | cut -d' ' -f1
"@

$env:CYGWIN_NOWINPATH = "1"
$hash = & "$installDir\bin\bash.exe" -lc "$cmd"
$hash = $hash.Trim()
echo "package cache directory hash is $hash"

# set outputs
echo "setup=$setupExe" >> $env:GITHUB_OUTPUT
echo "root=$installDir" >> $env:GITHUB_OUTPUT
echo "package-cache=$packageDir" >> $env:GITHUB_OUTPUT
echo "package-cache-hash=$hash" >> $env:GITHUB_OUTPUT
