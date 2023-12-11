# TODO: Add step to back up original template

packer {
  required_version = ">= 1.8.6"
  required_plugins {
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
    vmware = {
      version = ">= 1.0.10"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

variable "vm_hostname" {
  type          = string
  description   = "Hostname for VM"
  default       = "kali-ops"
}

variable "vm_username" {
  type          = string
  description   = "Username for VM user"
  default       = "kali"
}

variable "vm_password" {
  type          = string
  description   = "Password for VM user"
  sensitive     = true
  default       = "kali"
}

variable "source_path" {
  type        = string
  description = "Source template for VM"
  default    = "${ env("HOME") }/Virtual Machines.localized/base-kali/base-kali.vmx"
}

variable "vm_tools_dir" {
  type        = string
  description = "Directory to store VM tools"
  default    = "/tools"
}

variable "output_directory" {
  type        = string
  description = "Output directory for Packer"
  default     = "${ env("HOME") }/Virtual Machines.localized/kali-ops"
}


source "vmware-vmx" "install-tools" {
  # VM Configuration
  source_path           = "${var.source_path}"
  vm_name               = "${var.vm_hostname}"
  display_name          = "${var.vm_hostname}"
  output_directory      = "${var.output_directory}"
  shutdown_command      = "echo '${var.vm_password}' | sudo -S shutdown -P now"
  format                = "ova"

  # VM Connection
  ssh_username          = "${var.vm_username}"
  ssh_password          = "${var.vm_password}"
  ssh_timeout           = "8000s"
  snapshot_name         = "Tools Installed - ${formatdate("YYYY-MM-DD hh:mm", timestamp())}"
}

build {
  name = "install-tools"
  sources = ["source.vmware-vmx.install-tools"]

  provisioner "ansible" {
    ###
    # Required for ansible in packer, change at your own risk
    user             = "${var.vm_username}"
    use_sftp         = true
    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False",
      "ANSIBLE_FORCE_COLOR=1"
    ]
    # End scary section
    ###

    extra_arguments  = [
      "--extra-vars",
      "{\"vm_tools_dir\": \"${var.vm_tools_dir}\", \"vm_username\": \"${var.vm_username}\", \"vm_hostname\": \"${var.vm_hostname}\"}", //", \"ansible_ssh_pass\": \"kali\"}",
      "--ssh-extra-args",
      "-o IdentitiesOnly=yes -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa -oPubkeyAcceptedKeyTypes=+ssh-rsa"
    ]

    playbook_file    = "ansible/playbook.yml"
  }
}
