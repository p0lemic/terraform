provider "aws" {
  profile = "${var.profile}"
  region  = "${var.region}"
}
data "aws_kms_key" "ssm" {
  key_id = "alias/ssm-key"
}

resource "aws_ssm_parameter" "domain_username" {
  name  = "/domain/username"
  description  = "Domain username"
  type  = "String"
  value = "${var.domain_username}"
}

resource "aws_ssm_parameter" "domain_password" {
  name  = "/domain/password"
  description  = "Domain password"
  type  = "SecureString"
  value = "${var.domain_password}"
  key_id = "${data.aws_kms_key.ssm.arn}"
}

resource "aws_ssm_parameter" "ipdns" {
  name  = "/domain/dns_ip"
  description  = "DNS IP Address"
  type  = "String"
  value = "${var.domain_dns_ip}"
}

resource "aws_ssm_parameter" "domain_name" {
  name  = "/domain/name"
  description  = "Domain name"
  type  = "String"
  value = "${var.domain_name}"
}


resource "aws_ssm_document" "windows_2012" {
  name          = "Windows_2012_Domain_Join"
  document_type = "Command"

  content = <<DOC
  {
   "schemaVersion":"2.0",
   "description":"Run a PowerShell script to securely domain-join a Windows instance",
   "mainSteps":[
      {
         "action":"aws:runPowerShellScript",
         "name":"runPowerShellWithSecureString",
         "inputs":{
            "runCommand":[
               "$ipdns = (Get-SSMParameterValue -Name /domain/dns_ip).Parameters[0].Value\n",
               "$domain = (Get-SSMParameterValue -Name /domain/name).Parameters[0].Value\n",
               "$username = (Get-SSMParameterValue -Name /domain/username).Parameters[0].Value\n",
               "$password = (Get-SSMParameterValue -Name /domain/password -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force\n",
               "$credential = New-Object System.Management.Automation.PSCredential($username,$password)\n",
               "Set-DnsClientServerAddress \"Ethernet 2\" -ServerAddresses $ipdns\n",
               "Add-Computer -DomainName $domain -Credential $credential\n",
               "Restart-Computer -force"
            ]
         }
      }
   ]
}
DOC
}

resource "aws_ssm_document" "windows_2016" {
  name          = "Windows_2016_Domain_Join"
  document_type = "Command"

  content = <<DOC
  {
   "schemaVersion":"2.0",
   "description":"Run a PowerShell script to securely domain-join a Windows instance",
   "mainSteps":[
      {
         "action":"aws:runPowerShellScript",
         "name":"runPowerShellWithSecureString",
         "inputs":{
            "runCommand":[
               "$ipdns = (Get-SSMParameterValue -Name /domain/dns_ip).Parameters[0].Value\n",
               "$domain = (Get-SSMParameterValue -Name /domain/name).Parameters[0].Value\n",
               "$username = (Get-SSMParameterValue -Name /domain/username).Parameters[0].Value\n",
               "$password = (Get-SSMParameterValue -Name /domain/password -WithDecryption $True).Parameters[0].Value | ConvertTo-SecureString -asPlainText -Force\n",
               "$credential = New-Object System.Management.Automation.PSCredential($username,$password)\n",
               "Set-DnsClientServerAddress \"Ethernet\" -ServerAddresses $ipdns\n",
               "Add-Computer -DomainName $domain -Credential $credential\n",
               "Restart-Computer -force"
            ]
         }
      }
   ]
}
DOC
}