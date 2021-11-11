# certbotaz


based on erjosito/certbot-azcli repository. 

- Removed -dev packages after installation of certbot, restulting conatainer image got reduced in size from 850 MB to 65MB.

- Container is running under unprivelegd user, instead of root. 

- All working dirs are placed in user's homedir. 

- With an addition of possibility for dns-zonefile to be in a different subscription as where certbotaz container will be runnning and keyvault will be stored.

- Can now also authenticate to azure via Service Principal, provided as an environment variable. 

- So now, using Service Principal auth ( instead of azure managed identity), it can also run in kubernetes, or localy in docker. 

Additional, optional environment variables can be provided to the containder: 

- To have DNS zone file and Keyvault in two different subscriptions: 

`DNS_SID=....`  - Azure Subscription id, of DNS Zone file, to do the dns-acme.

`KEYVAULT_SID=....`   - Azure Subscription id, of keyvault, to store the certificate.

- To make use of Service Principal auth, instead of azure managed identity: 

$SP_ID" --password "$SP_PASS" --tenant "$SP_TENANT"

`SP_ID=....`  - Service Principal ID.

`SP_PASS=....`   - Service Principal PASSWORD.

`SP_TENANT=....`  - TENANT to be used to access azure resources.

-------------

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
    
        commands =  ["/bin/bash", "-c", "/home/crtbot/certbot_generate.sh" ]

    }

    lifecycle {
        ignore_changes = [ tags, ]
    }
}

</PRE>

-----------------

To run it in docker: 

<PRE>
echo "DOMAIN=some-domain" >> myenv
echo "EMAIL=some-email_to_register_certificate" >> myenv
echo "AKV=some-keyvaultname" >> myenv

docker pull "ghcr.io/joertech-azure/certbotaz/certbotaz:main"
docker run --env-file myenv certbotaz:main
</PRE>
