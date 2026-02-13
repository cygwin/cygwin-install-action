$ErrorActionPreference = 'Stop'

# Import functions.
. "$PSScriptRoot/_functions.ps1"

$platform = Get-Validated-Platform -Platform "$env:inputs_platform"
$vol = Get-Validated-Work-Volume -WorkVolume "$env:inputs_work_vol"
$error_on_missing_packages = Get-Validated-Error-On-Missing-Packages -Value "$env:inputs_error_on_missing_packages"

$setupExe = "$vol\setup.exe"
$setupFileName = "setup-$platform.exe"
Invoke-WebRequest-With-Retry "https://cygwin.com/$setupFileName" $setupExe

if ((Get-Item -LiteralPath $setupExe).Length -eq 0) {
    throw "The downloaded setup has a zero length!"
}

$signature = Get-AuthenticodeSignature -FilePath $setupExe
echo "Signature status: $($signature.Status) fingerprint: $($signature.SignerCertificate.GetCertHashString("SHA256"))"
# TBD: this should check against a list of fingerprints for valid certs we have used
if (!$signature.Status -ne 'Valid' -or $signature.SignerCertificate.GetCertHashString("SHA256") -ne '2ce11da3a675a9d631e06a28ddfd6f730b9cc6989b43bd30ad7cc79d219cf2bd') {
    if ("$env:inputs_check_installer_sig" -eq 'true') {
            throw "Invalid CodeSign signature on the downloaded setup!"
    }
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

Invoke-Cygwin-Setup -SetupExePath $setupExe -SetupExeArgs $args -ErrorOnMissingPackages $error_on_missing_packages

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

# set outputs
echo "setup=$setupExe" >> $env:GITHUB_OUTPUT
echo "root=$installDir" >> $env:GITHUB_OUTPUT
echo "package-cache=$packageDir" >> $env:GITHUB_OUTPUT
