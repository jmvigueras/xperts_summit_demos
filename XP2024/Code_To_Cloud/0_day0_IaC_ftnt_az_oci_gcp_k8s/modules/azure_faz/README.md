# Terraform Module: FortiAnalyzer

Create a FortiAnalyzer instance wihin Azure Cloud

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_interface.faz_ni_private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_network_interface.faz_ni_public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface) | resource |
| [azurerm_public_ip.faz_public-ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_virtual_machine.faz](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine) | resource |
| [random_string.random](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [template_file.faz_config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_password"></a> [admin\_password](#input\_admin\_password) | n/a | `string` | `null` | no |
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | n/a | `string` | `"azureadmin"` | no |
| <a name="input_api_key"></a> [api\_key](#input\_api\_key) | n/a | `string` | `null` | no |
| <a name="input_faz_extra-config"></a> [faz\_extra-config](#input\_faz\_extra-config) | n/a | `string` | `""` | no |
| <a name="input_faz_ni_0"></a> [faz\_ni\_0](#input\_faz\_ni\_0) | n/a | `string` | `"public"` | no |
| <a name="input_faz_ni_1"></a> [faz\_ni\_1](#input\_faz\_ni\_1) | n/a | `string` | `"private"` | no |
| <a name="input_faz_ni_ips"></a> [faz\_ni\_ips](#input\_faz\_ni\_ips) | n/a | `map(string)` | `null` | no |
| <a name="input_faz_offer"></a> [faz\_offer](#input\_faz\_offer) | n/a | `string` | `"fortinet-fortianalyzer"` | no |
| <a name="input_faz_sku"></a> [faz\_sku](#input\_faz\_sku) | AMI | `map(string)` | <pre>{<br>  "byol": "fortinet-fortianalyzer",<br>  "payg": ""<br>}</pre> | no |
| <a name="input_faz_version"></a> [faz\_version](#input\_faz\_version) | n/a | `string` | `"latest"` | no |
| <a name="input_license_file"></a> [license\_file](#input\_license\_file) | license file for the active fgt | `string` | `"./licenses/licenseFMG.lic"` | no |
| <a name="input_license_type"></a> [license\_type](#input\_license\_type) | License Type to create FortiGate-VM Provide the license type for FortiGate-VM Instances, either byol or payg. | `string` | `"payg"` | no |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | `"francecentral"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | n/a | `string` | `"terraform"` | no |
| <a name="input_private_port"></a> [private\_port](#input\_private\_port) | n/a | `string` | `"port2"` | no |
| <a name="input_public_port"></a> [public\_port](#input\_public\_port) | n/a | `string` | `"port1"` | no |
| <a name="input_publisher"></a> [publisher](#input\_publisher) | n/a | `string` | `"fortinet"` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group where group all resources | `string` | `null` | no |
| <a name="input_rsa-public-key"></a> [rsa-public-key](#input\_rsa-public-key) | SSH RSA public key for KeyPair if not exists | `string` | `null` | no |
| <a name="input_size"></a> [size](#input\_size) | n/a | `string` | `"Standard_D2s_v3"` | no |
| <a name="input_storage-account_endpoint"></a> [storage-account\_endpoint](#input\_storage-account\_endpoint) | Account storage endpoint | `string` | `null` | no |
| <a name="input_subnet_cidrs"></a> [subnet\_cidrs](#input\_subnet\_cidrs) | Map of subnet CIDRS VNet FGT | `map(string)` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Map of subnet IDs VNet FGT | `map(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Azure resourcers tags | `map(any)` | <pre>{<br>  "Deploy": "module-faz",<br>  "Project": "terraform-fortinet"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password"></a> [admin\_password](#output\_admin\_password) | n/a |
| <a name="output_admin_username"></a> [admin\_username](#output\_admin\_username) | n/a |
| <a name="output_faz_id"></a> [faz\_id](#output\_faz\_id) | n/a |
| <a name="output_faz_private_ip"></a> [faz\_private\_ip](#output\_faz\_private\_ip) | n/a |
| <a name="output_faz_public_ip"></a> [faz\_public\_ip](#output\_faz\_public\_ip) | n/a |