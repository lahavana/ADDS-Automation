configuration CreateADCSRootCA
{
    param
    (
        [Parameter(Mandatory)]
        [PSCredential]$adminCreds
    )

    Import-DscResource -ModuleName xAdcsDeployment, xDSCDomainjoin, ComputerManagementDSC

    Node localhost
    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }

        # Domain Join
        xDSCDomainjoin JoinDomain
        {
            DomainName = $adminCreds.UserName.Split('\')[0]  # Extract domain from "domain\username"
            Credential = $adminCreds
        }

        # Reboot after domain join
        PendingReboot RebootAfterDomainJoin
        {
            Name = "RebootAfterDomainJoin"
            DependsOn = "[xDSCDomainjoin]JoinDomain"
        }

        # Install ADCS Role
        WindowsFeature ADCSInstall
        {
            Ensure = "Present"
            Name = "ADCS-Cert-Authority"
            DependsOn = "[PendingReboot]RebootAfterDomainJoin"
        }

        # Install Management Tools
        WindowsFeature ADCSMgmt
        {
            Ensure = "Present"
            Name = "RSAT-ADCS"
            DependsOn = "[WindowsFeature]ADCSInstall"
        }

        # Configure Enterprise Root CA
        xADCSCertificationAuthority ADCSRootCA
        {
            Ensure = "Present"
            Credential = $adminCreds
            CAType = "EnterpriseRootCA"
            DependsOn = "[WindowsFeature]ADCSMgmt"
        }

        # Optional: Reboot after CA installation
        PendingReboot RebootAfterCAInstall
        {
            Name = "RebootAfterCAInstall"
            DependsOn = "[xADCSCertificationAuthority]ADCSRootCA"
        }
    }
}
