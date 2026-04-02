BeforeAll {
    . "$PSScriptRoot/../src/_functions.ps1"
}

Describe 'Check-Installer-Sig' {
   # should succeed on a selection of installer versions covering all expected certs
   It 'Correct signature' -ForEach "setup-2.938", "setup-2.937" {
       Invoke-WebRequest-With-Retry -Uri "https://cygwin.com/setup/$_.x86_64.exe" -Outfile "setup.exe"
       Check-Installer-Sig -SetupExePath "setup.exe"
   }

   # should fail on missing signature
   It 'Missing signature' -ForEach "setup-2.932" {
       Invoke-WebRequest-With-Retry -Uri "https://cygwin.com/setup/$_.x86_64.exe" -Outfile "setup.exe"
       { Check-Installer-Sig -SetupExePath "setup.exe" }
       | Should -Throw "Invalid CodeSign signature on the downloaded setup!"
   }

   # should fail on unexpected signature key cert
   It 'Incorrect signature' -ForEach "setup-2.937" {
       Mock Get-CertHashes {
         return ('8B9867F6585CC76A7C27AC60B7E3EC35AEC739B448BB07CA863335E056CEA593')  # 256 bits of randomness
       }

       Invoke-WebRequest-With-Retry -Uri "https://cygwin.com/setup/$_.x86_64.exe" -Outfile "setup.exe"
       { Check-Installer-Sig -SetupExePath "setup.exe" }
       | Should -Throw "Unexpected key certificate made CodeSign signature on the downloaded setup!"
   }
}
