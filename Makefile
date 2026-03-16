SHELL := /bin/bash

.PHONY: validate validate-compose validate-kubernetes

validate: validate-compose

validate-compose:
	./scripts/validate-local-compose.sh

validate-kubernetes:
	./scripts/validate-local-kubernetes.sh
