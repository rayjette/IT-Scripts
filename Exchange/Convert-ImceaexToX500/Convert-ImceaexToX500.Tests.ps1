BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
}

Describe "Convert-ImceaexToX500" {
    It "Should return a valid X.500 string" {
        $imceaex = 'IMCEAEX-_O=MMS_OU=EXCHANGE+20ADMINISTRATIVE+20GROUP+20+28FYDIBOHF23SPDLT+29_CN=RECIPIENTS_CN=User6ed4e168-addd-4b03-95f5-b9c9a421957358d\@mgd.domain.com'
        $X500 = 'X500:/O=MMS/OU=EXCHANGE ADMINISTRATIVE GROUP (FYDIBOHF23SPDLT)/CN=RECIPIENTS/CN=User6ed4e168-addd-4b03-95f5-b9c9a421957358d'
    
        $value = Convert-ImceaexToX500 -ImceaexString $imceaex
        $result
        $value.x500 | Should -Be $X500
    }
}