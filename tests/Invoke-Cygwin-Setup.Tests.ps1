BeforeAll {
    . "$PSScriptRoot/../src/_functions.ps1"
}

Describe 'Invoke-Cygwin-Setup' {
    It 'success' {
        $arguments = @('-Command', 'Write-Host "success"')
        Invoke-Cygwin-Setup -SetupExePath 'pwsh' -SetupExeArgs $arguments | Should -Be $null
    }

    It 'non-zero exit code' {
        $arguments = @('-Command', 'throw "error!"')
        { Invoke-Cygwin-Setup -SetupExePath 'pwsh' -SetupExeArgs $arguments } | Should -Throw "*exited with error code 1"
    }
}
