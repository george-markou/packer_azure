packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "azure-arm" "vm" {
  azure_tags = {
    dept = "Engineering"
    task = "Image deployment"
  }
  build_resource_group_name         = "rg-dev-packer-builds-weu-01"
  client_id                         = "<YOUR CLIENT ID GOES HERE>"
  client_secret                     = "<YOUR CLIENT SECRET GOES HERE>"
  communicator                      = "winrm"
  image_offer                       = "WindowsServer"
  image_publisher                   = "MicrosoftWindowsServer"
  image_sku                         = "2019-Datacenter"
  managed_image_name                = "prodimgws2k1921102024"
  managed_image_resource_group_name = "rg-dev-packer-builds-weu-01"
  os_type                           = "Windows"
  subscription_id                   = "<YOUR SUBSCRIPTION ID GOES HERE>"
  tenant_id                         = "<YOUR TENANT ID GOES HERE>"
  vm_size                           = "Standard_D2_v2"
  winrm_insecure                    = true
  winrm_timeout                     = "5m"
  winrm_use_ssl                     = true
  winrm_username                    = "packer"
}

build {
  sources = ["source.azure-arm.vm"]

  provisioner "powershell" {
    inline = ["Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"]
  }

  provisioner "windows-restart" {}


  provisioner "powershell" {
    inline = [
      "try { choco install microsoftazurestorageexplorer -y } catch { Write-Host 'Failed to install microsoftazurestorageexplorer'; exit 0 }",
      "try { choco install az.powershell -y } catch { Write-Host 'Failed to install az.powershell'; exit 0 }",
      "try { choco install azcopy10 -y } catch { Write-Host 'Failed to install azcopy10'; exit 0 }",
      "try { choco install windows-admin-center -y } catch { Write-Host 'Failed to install windows-admin-center'; exit 0 }",
      "try { choco install azure-cli -y } catch { Write-Host 'Failed to install azure-cli'; exit 0 }",
      "try { choco install powershell-core -y } catch { Write-Host 'Failed to install powershell-core'; exit 0 }",
      "try { choco install 7zip -y } catch { Write-Host 'Failed to install 7zip'; exit 0 }"
  ]
  valid_exit_codes = [0, 3010]
}

  provisioner "powershell" {
    inline = ["while ((Get-Service RdAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "while ((Get-Service WindowsAzureGuestAgent).Status -ne 'Running') { Start-Sleep -s 5 }", "& $env:SystemRoot\\System32\\Sysprep\\Sysprep.exe /oobe /generalize /quiet /quit", "while($true) { $imageState = Get-ItemProperty HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Setup\\State | Select ImageState; if($imageState.ImageState -ne 'IMAGE_STATE_GENERALIZE_RESEAL_TO_OOBE') { Write-Output $imageState.ImageState; Start-Sleep -s 10  } else { break } }"]
  }
}
