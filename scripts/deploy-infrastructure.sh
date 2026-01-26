  #!/bin/bash
  set -e

  cd "$(dirname "$0")/../terraform"

  echo "Initializing Terraform..."
  terraform init

  echo "Planning infrastructure..."
  terraform plan -out=tfplan

  echo "Apply? (y/n)"
  read -r response
  if [[ "$response" == "y" ]]; then
    terraform apply tfplan
    echo "Done!"
  else
    echo "Cancelled."
  fi