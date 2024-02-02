describe 'Get-WindowsDefenderFirewallEvents' {

    beforeAll {
        . $PSCommandPath.Replace('.Tests.ps1','.ps1')

        mock -CommandName Test-Path {
            Return $true
        }

        mock -CommandName Get-Content {
            @('skip', 'skip', 'skip', 'skip', 'skip',
              '2024-01-31 22:28:20 ALLOW UDP 10.0.0.13 75.75.75.75 57519 53 0 - - - - - - - SEND')
        }

        $result = Get-WindowsDefenderFirewallEvents
    }

    it 'Should have the correct datetime property and value' {
        $result[0].dateTime | Should -Be ([datetime]'1/31/2024 10:28:20 PM')
    }

    it 'Should have the correct action property and value' {
        $result[0].action | Should -Be 'ALLOW'
    }

    it 'Should have the correct protocol property and value' {
        $result[0].protocol | Should -Be 'UDP'
    }

    it 'Should have the correct source ip property and value' {
        $result[0].sourceIP | Should -Be '10.0.0.13'
    }

    it 'Should have the correct destination ip property and value' {
        $result[0].destIP | Should -Be '75.75.75.75'
    }

    it 'Should have the correct source port property and value' {
        $result[0].sourcePort | Should -Be '57519'
    }

    it 'Should have the correct destination port property and value' {
        $result[0].destPort | Should -Be '53'
    }

    it 'Should have the correct size property and value' {
        $result[0].size | Should -Be '0'
    }

    it 'Should have the correct TCP flags property and value' {
        $result[0].tcpFlags | Should -Be $null
    }

    it 'Should have the correct TCP Syn property and value' {
        $result[0].tcpSyn | Should -Be $null
    }

    it 'Should have the correct TCP windows property and value' {
        $result[0].tcpWin | Should -Be $null
    }

    it 'Should have the correct ICMP type property and value' {
        $result[0].icmpType | Should -Be $null
    }

    it 'Should have the correct ICMP code property and value' {
        $result[0].icmpCode | Should -Be $null
    }

    it 'Should have the correct Info property and value' {
        $result[0].info | Should -Be $null
    }

    it 'Should have the correct path property and value' {
        $result[0].path | Should -Be 'SEND'  
    }
}