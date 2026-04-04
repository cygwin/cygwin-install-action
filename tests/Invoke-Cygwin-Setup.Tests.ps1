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

    It 'can warn on missing packages' {
        $arguments = @('-Command', 'Write-Host', "setup had a problem``nPackage 'xyz' not found.``nother text")
        $output = Invoke-Cygwin-Setup -SetupExePath 'pwsh' -SetupExeArgs $arguments -ErrorOnMissingPackages "false"
        Should -ActualValue $output -Match '::warning::One or more packages could not be found'
    }

    It 'can error on missing packages' {
        $arguments = @('-Command', 'Write-Host', "setup had a problem``nPackage 'xyz' not found.``nother text")
        { Invoke-Cygwin-Setup -SetupExePath 'pwsh' -SetupExeArgs $arguments -ErrorOnMissingPackages "true" } | Should -Throw "One or more packages could not be found"
    }
}
