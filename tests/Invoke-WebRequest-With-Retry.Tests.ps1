BeforeAll {
    . "$PSScriptRoot/../src/_functions.ps1"
}

Describe 'Invoke-WebRequest-With-Retry' {
    Context 'HTTP 404' {
        BeforeAll {
            Mock Invoke-WebRequest {
                $response = New-MockObject -type 'System.Net.HttpWebResponse'
                $code = [System.Net.HttpStatusCode]::NotFound
                $response | Add-Member -MemberType NoteProperty -Name StatusCode -Value $code -Force
                $status = [System.Net.WebExceptionStatus]::ProtocolError
                $exception = [System.Net.WebException]::new("404", $null, $status, $response)

                Throw $exception
            }
            Mock Start-Sleep { }
        }

        It 'Throws an error' {
            { Invoke-WebRequest-With-Retry -Uri 'https://404' -Outfile 'bogus' | Out-Null } `
            | Should -Throw "Failed to download 'https://404' after 5 attempts."
        }

        It 'Calls Invoke-WebRequest 5 times' {
            try { Invoke-WebRequest-With-Retry -Uri 'https://404' -Outfile 'bogus' | Out-Null } catch {}
            Should -Invoke -CommandName 'Invoke-WebRequest' -Times 5
        }

        It 'Calls Start-Sleep 4 times with increasing delays' {
            try { Invoke-WebRequest-With-Retry -Uri 'https://404' -Outfile 'bogus' | Out-Null } catch {}
            Should -Invoke -CommandName 'Start-Sleep' -Times 4
            Should -Invoke -CommandName 'Start-Sleep' -Times 1 -ParameterFilter { $Seconds -eq 2 }
            Should -Invoke -CommandName 'Start-Sleep' -Times 1 -ParameterFilter { $Seconds -eq 4 }
            Should -Invoke -CommandName 'Start-Sleep' -Times 1 -ParameterFilter { $Seconds -eq 8 }
            Should -Invoke -CommandName 'Start-Sleep' -Times 1 -ParameterFilter { $Seconds -eq 16 }
        }
    }

    Context 'Success' {
        BeforeAll {
            Mock Invoke-WebRequest { }
            Mock Start-Sleep { throw 'Start-Sleep should never be called in this context' }
        }

        It 'Throws no errors' {
            { Invoke-WebRequest-With-Retry -Uri 'https://200' -Outfile 'bogus' | Out-Null } `
            | Should -Not -Throw
        }

        It 'Calls Invoke-WebRequest only once' {
            Invoke-WebRequest-With-Retry -Uri 'https://200' -Outfile 'bogus' | Out-Null `
            | Should -Invoke -CommandName 'Invoke-WebRequest' -Times 1
        }

        It 'Never calls Start-Sleep' {
            Invoke-WebRequest-With-Retry -Uri 'https://200' -Outfile 'bogus' | Out-Null `
            | Should -Invoke -CommandName 'Start-Sleep' -Times 0
        }
    }
}
