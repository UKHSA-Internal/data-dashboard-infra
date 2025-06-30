#!/bin/bash
chmod -x bridge_client_linux_arm64
chmod 755 bridge_client_linux_arm64
./bridge_client_linux_arm64 --token ${TOKEN} --organization-id ${ORGANIZATION_ID} --bridge bridge2.virtuoso.qa:443 -n DD_BRIDGE