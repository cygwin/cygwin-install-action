BeforeAll {
    . "$PSScriptRoot/../src/_functions.ps1"
}

Describe 'Get-Validated-Sites' {
    Context 'Platform defaults' {
        It 'Default (x86_64)' {
            $sites = Get-Validated-Sites
            Should -ActualValue $sites -Be @( 'https://mirrors.kernel.org/sourceware/cygwin/' )
        }
        It 'x86' {
            $sites = Get-Validated-Sites -Platform 'x86'
            Should -ActualValue $sites -Be @( 'https://mirrors.kernel.org/sourceware/cygwin-archive/20221123' )
        }
    }

    Context 'Custom sites' {
        It 'Single value' {
            Get-Validated-Sites -Sites 'a' | Should -Be @( 'a' )
        }

        It 'Spaces' {
            Get-Validated-Sites -Sites ' a  b   c ' | Should -Be @( 'a', 'b', 'c' )
        }

        It 'Newlines and tabs' {
            Get-Validated-Sites -Sites "`n`ta`n`tb`n`t" | Should -Be @( 'a', 'b' )
        }
    }
}
