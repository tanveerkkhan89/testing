#!/bin/bash

# Set variables
RELEASE_NAME=my-app
NAMESPACE=default

# Upgrade or install the Helm chart
helm upgrade --install $RELEASE_NAME ./my-spring-app --namespace $NAMESPACE