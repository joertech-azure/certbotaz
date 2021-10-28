# certbotaz


based on erjosito/certbot-azcli repository. 

- removed -dev packages after installing of certbot, restulting conatainer image got reduced in size from 850 MB to 65MB.

- with an addition of possibility for dns-zonefile to be in a different subscription as where certbotaz container will be runnning and keyvault will be stored.

Additional environment variables can be provided to the containder: 

`DNS_SID=....`  - Azure Subscription id, of DNS Zone file, to do the dns-acme.

`KEYVAULT_SID=....`   - Azure Subscription id, of keyvault, to store the certificate.

 
Certbotaz container can be deployed as an azure container, for exmaple with terraform:


<PRE>
...
...
you need : 
- managed identity
- keyvault,
- role assignment
- keyvault access policy
...
...
resource "azurerm_container_group" "certbotaz" {
    name                = "certbotaz"
    location            = azurerm_resource_group.certbotaz-rg.location
    resource_group_name = azurerm_resource_group.certbotaz-rg.name
    ip_address_type     = "public"  # private does not support managed identities
    dns_name_label      = "certbotaz"
    os_type             = "linux"
    restart_policy      = "OnFailure"

    # identity {
    #   type = "SystemAssigned"
    # }
    
    identity {
        type         = "UserAssigned"
        identity_ids = [ azurerm_user_assigned_identity.certbotaz-uai.id, ]
    }

    container {
        name   = "certbotaz"
        image  = "ghcr.io/joertech-azure/certbotaz/certbotaz:main"
        cpu    = "0.2"
        memory = "0.4"
        ports {
            port     = 80
            protocol = "TCP"
        }
        environment_variables = {
            "DOMAIN"       = var.certbotaz_domain_to_certify
            "EMAIL"        = var.certbotaz_email_for_certificate
            "AKV"          = azurerm_key_vault.my-key-vault.name
            "STAGING"      = "yes"
            "DEBUG"        = "yes"
            "DNS_SID"      = var.certbotaz_dns-subscription
            "KEYVAULT_SID" = module.tf-var-project.subscription_id_poc 
        }
    
        commands =  ["/bin/bash", "-c", "/home/certbot_generate.sh" ]

    }

    lifecycle {
        ignore_changes = [ tags, ]
    }
}

</PRE>