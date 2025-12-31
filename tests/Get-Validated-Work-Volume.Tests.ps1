BeforeAll {
    . "$PSScriptRoot/../src/_functions.ps1"
}

Describe 'Get-Validated-Work-Volume' {
    Context '-WorkVolume parameter' {
        It 'Wrong format' {
            Mock Test-Path { $false }
            { Get-Validated-Work-Volume -WorkVolume 'A:\' } | Should -Throw "*must be only a drive letter and a colon*"
        }
        It 'Does not exist' {
            Mock Test-Path { $false }
            { Get-Validated-Work-Volume -WorkVolume 'A:' } | Should -Throw "*not a valid drive*"
        }
        It 'Lowercase success' {
            Mock Test-Path { $true }
            Get-Validated-Work-Volume -WorkVolume 'a:' | Should -Be "A:"
        }
        It 'Uppercase success' {
            Mock Test-Path { $true }
            Get-Validated-Work-Volume -WorkVolume 'A:' | Should -Be "A:"
        }
    }

    It 'D: drive default' {
        Mock Test-Path { $true }
        Get-Validated-Work-Volume | Should -Be 'D:'
    }

    It 'Fallback to SYSTEMDRIVE' {
        # Setup
        Mock Test-Path { $false }
        Mock Get-SystemDrive { 'A:' }

        # Verify
        Get-Validated-Work-Volume | Should -Be 'A:'
    }
}
