variable "vnet_resource_groupname"{
    description = "This is the resourcegroup of the vnet"
    type = string
}

variable "influx_subnet_id"{
    description = "This is the subnet where the vm will be created"
    type = string
}

variable "influx_vnet_name"{
    description = " This is the vnet into which the vm will be created"
    type = string
}

variable "vm_password"{
    description = "This is the password for the influx-machine vm"
    type = string
}

variable "service_principal_id"{
    description = "service principal name"
    type = string
}

variable "service_principal_secret"{
    description = "Service principal secret"
    type = string
}

variable "tenant_id"{
    description = "Tenant id"
    type = string
}
