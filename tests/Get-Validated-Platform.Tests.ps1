BeforeAll {
    . "$PSScriptRoot/../src/_functions.ps1"
}

Describe 'Get-Validated-Platform' {
    Context 'canonical strings' {
        It 'x86_64' {
            Get-Validated-Platform -Platform 'x86_64' | Should -Be 'x86_64'
        }
        It 'x86' {
            Get-Validated-Platform -Platform 'x86' | Should -Be 'x86'
        }
    }

    Context 'backwards-compatibility strings' {
        It 'amd64' {
            Get-Validated-Platform -Platform 'amd64' | Should -Be 'x86_64'
        }
        It 'i686' {
            Get-Validated-Platform -Platform 'i686' | Should -Be 'x86'
        }
        It 'x64' {
            Get-Validated-Platform -Platform 'x64' | Should -Be 'x86_64'
        }
    }

    Context 'default value' {
        It 'default value' {
            Get-Validated-Platform -Platform '' | Should -Be 'x86_64'
        }
    }

    Context 'unknown value' {
        It 'unknown value' {
            { Get-Validated-Platform -Platform 'bogus' } | Should -Throw 'Unknown platform bogus.'
        }
    }
}
