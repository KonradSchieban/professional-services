# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at 
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "google" {
  version = "~> 3.14.0"
  region  = var.region
}

module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 2.2"

    project_id   = var.project_id
    network_name = format("%s-inspec-test-vpc", var.project_id)
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = var.region
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = var.region
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
        }
    ]

    secondary_ranges = {
        subnet-01 = [
            {
                range_name    = "cidr-1"
                ip_cidr_range = "10.13.0.0/16"
            },
            {
                range_name    = "cidr-2"
                ip_cidr_range = "10.14.0.0/16"
            },
        ]

        subnet-02 = []
    }
}

resource "google_compute_instance" "test-vm" {
  project = var.project_id
  name         = format("%s-inspec-test-vm", var.project_id)
  machine_type = "f1-micro"
  zone         = var.zone
  allow_stopping_for_update = true

  metadata = {
      block-project-ssh-keys = true
      serial-port-enable = false
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  service_account {
      email = format("%s@appspot.gserviceaccount.com", var.project_id)
      scopes = ["pubsub"]
  }

  network_interface {
    network = module.vpc.network_name
    subnetwork = module.vpc.subnets_self_links[1]
  }

}


/* ** this code calls the module that create the cloud function that handles eMail notifications
** for this code to be functional, you must sign up for a Mailgun account and update placeholder values in env_setup.shared_vpc_name
** see the main README for details


module "notifications" {
  source                = "../modules/notifications"
  project_id            = var.project_id
  bucket_location       = var.bucket_location
  bucket_name           = format("%s-cloud-function-code", var.project_id)
  service_account_email = format("%s@appspot.gserviceaccount.com", var.project_id)
}
*/
