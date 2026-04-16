SHELL := /bin/bash

.PHONY: validate validate-compose validate-compose-re-indicators validate-kubernetes validate-kubernetes-re-indicators

validate: validate-compose

validate-compose:
	./scripts/validate-local-compose.sh

validate-compose-re-indicators:
	COMPOSE_PROFILES=re-indicators ./scripts/validate-local-compose.sh

validate-kubernetes:
	./scripts/validate-local-kubernetes.sh

validate-kubernetes-re-indicators:
	K8S_OVERLAY=dev-re-indicators ./scripts/validate-local-kubernetes.sh
