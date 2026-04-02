function Get-Validated-Platform {
    param (
        $Platform
    )

    switch ($platform) {
        # Valid values
        'x86_64'    { return 'x86_64'   }
        'x86'       { return 'x86'      }

        # Default value
        ''          { return 'x86_64'   }

        # Backwards-compatibility strings
        'x64'       { return 'x86_64'   }
        'amd64'     { return 'x86_64'   }
        'i686'      { return 'x86'      }

        # Unrecognized platform
        default     { throw "Unknown platform $Platform." }
    }
}


function Get-Validated-Sites {
    param (
        $Platform,
        $Sites
    )

    if ("$Sites" -eq '') {
        switch ("$Platform") {
            'x86'   { return @( 'https://mirrors.kernel.org/sourceware/cygwin-archive/20221123' ) }
            # This is the default site for x86_64 platforms.
            default { return @( 'https://mirrors.kernel.org/sourceware/cygwin/' ) }
        }
    }

    return "$Sites" -Split '\s+' | Where-Object { $_ }
}


function Invoke-Cygwin-Setup {
    param (
        $SetupExePath,
        $SetupExeArgs
    )

    # Because setup is a Windows GUI app, make it part of a pipeline
    # to make PowerShell wait for it to exit.
    Write-Host $SetupExePath $SetupExeArgs
    & $SetupExePath $SetupExeArgs | Out-Default

    # Check the exit code.
    if ($LASTEXITCODE -ne 0) {
        throw "$SetupExePath exited with error code $LASTEXITCODE"
    }
}


function Get-Validated-Work-Volume {
    param (
        $WorkVolume
    )

    # Prefer the user's chosen volume.
    if ("$WorkVolume" -ne '') {
        if ("$WorkVolume" -notmatch '^[A-Za-z]:$') {
            throw "The work-vol parameter, '$WorkVolume', must be only a drive letter and a colon, like 'D:'."
        }
        if (-Not (Test-Path -LiteralPath "$WorkVolume\")) {
            throw "The work-vol parameter, '$WorkVolume', is not a valid drive."
        }
        return "$WorkVolume".ToUpper()
    }

    # Prefer the 'D:' drive but fall back to SYSTEMDRIVE.
    # 'D:' is preferred on hosted runners for performance reasons.
    if (Test-Path -LiteralPath 'D:\') {
        return 'D:'
    }

    return Get-SystemDrive
}


function Invoke-WebRequest-With-Retry {
    param (
        $Uri,
        $OutFile
    )

    $maxRetries = 5

    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile
            return
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($attempt -ne $maxRetries) {
                $delaySeconds = [Math]::Pow(2, $attempt)
                Write-Output "Attempt $attempt failed (HTTP Status $statusCode). Retrying in $delaySeconds seconds..."
                Start-Sleep -Seconds $delaySeconds
            }
            else {
                Write-Output "Attempt $attempt failed (HTTP Status $statusCode)."
            }
        }
    }

    throw "Failed to download '$Uri' after $maxRetries attempts."
}

function Check-Installer-Sig {
   param (
         $SetupExePath
   )

   $signature = Get-AuthenticodeSignature -FilePath $SetupExePath
   if ($signature.SignerCertificate) {
      $signature_certhash = $signature.SignerCertificate.GetCertHashString("SHA256")
   } else {
      $signature_certhash = '-'
   }

   echo "Signature status: $($signature.Status) fingerprint: $signature_certhash"

   if (!$signature.Status -ne 'Valid') {
      throw "Invalid CodeSign signature on the downloaded setup!"
   }

   # check against a list of fingerprints for valid certs we have used
   $certhashes = Get-CertHashes

   if ($signature_certhash -notin $certhashes) {
      throw "Unexpected key certificate made CodeSign signature on the downloaded setup!"
   }
}

# ---------------------------------------------------------------------
# Functions below this line exist so the test suite can mock them.

function Get-SystemDrive { "$Env:SYSTEMDRIVE" }

function Get-CertHashes {
  (
    '2CE11DA3A675A9D631E06A28DDFD6F730B9CC6989B43BD30AD7CC79D219CF2BD',
    '3AB2B14363B58A1856D4902C737797C899118095F7025DF7832C1B52483865A0'
  )
}
