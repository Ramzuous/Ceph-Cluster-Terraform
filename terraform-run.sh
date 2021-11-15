#!/bin/bash

# run terraform script

terraform init

terraform validate

terraform plan -out=/root/plan

terraform apply "/root/plan"
