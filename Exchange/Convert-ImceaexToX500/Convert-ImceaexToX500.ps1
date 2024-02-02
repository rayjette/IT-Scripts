Function Convert-ImceaexToX500
{
    <#
    .SYNOPSIS
        Converts IMCEAEX into an X.500 address.

    .DESCRIPTION
        Converts IMCEAEX into an X.500 address.

    .PARAMETER ImceaexString
        The IMCEAEX string.

    .EXAMPLE
        Convert-ImceaexToX500 -ImceaexString '<string>'

    .EXAMPLE
        Get-Contents someFile.txt | Convert-ImceaexToX500

    .INPUTS
        System.String.  The ImceaexString parameter takes input from the pipeline.

    .OUTPUTS
        System.String

    .NOTES
        Author: Raymond Jette
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String[]]$ImceaexString
    )
    
    BEGIN
    {
        $replacementsToMake = @{
            '_'        = '/'
            '\+20'     = ' '
            '\+28'     = '('
            '\+29'     = ')'
            'imceaex-' = ''
            '@.*'      = ''
            '\+2E'     = '.'
            '\+40'     = '@'
        }
    }
    
    PROCESS
    {
        foreach ($string in $ImceaexString) {
            $X500String = $string
            foreach ($replacement in $replacementsToMake.GetEnumerator()) {
                $X500String =  $X500String -replace $replacement.Key, $replacement.Value
            }
            # Remove '\' from the end of the string and append X500 to the start
            $X500String = $X500String -replace "\\$", ''
            $X500String = "X500:{0}" -f $X500String

            [PSCustomObject]@{
                Imceaex = $string
                X500 = $X500String
            }
        }
    }
}