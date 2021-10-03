#!/usr/bin/env bash

set -euo pipefail

source ./vars.env

main() {
    terraform destroy \
        -var region=$AWS_REGION \
        -var account_id=$AWS_ACCOUNT_ID \
        -var app_name=$APP_NAME \
        -var image_name=$IMAGE_NAME \
        -var image_tag=$IMAGE_TAG \
        -var stage_name=$STAGE_NAME \
        -var environment=$ENVIRONMENT_NAME
}

main
