SHELL := /bin/bash

.PHONY: validate validate-helpers validate-compose validate-compose-re-indicators validate-compose-see-impacts validate-compose-calculations validate-kubernetes validate-kubernetes-re-indicators validate-kubernetes-see-impacts validate-kubernetes-calculations

validate: validate-compose

validate-helpers:
	python3 -B -m unittest discover -s tests

validate-compose:
	./scripts/validate-local-compose.sh

validate-compose-re-indicators:
	COMPOSE_PROFILES=re-indicators ./scripts/validate-local-compose.sh

validate-compose-see-impacts:
	COMPOSE_PROFILES=see-impacts ./scripts/validate-local-compose.sh

validate-compose-calculations:
	COMPOSE_PROFILES=re-indicators,see-impacts ./scripts/validate-local-compose.sh

validate-kubernetes:
	./scripts/validate-local-kubernetes.sh

validate-kubernetes-re-indicators:
	K8S_OVERLAY=dev-re-indicators ./scripts/validate-local-kubernetes.sh

validate-kubernetes-see-impacts:
	K8S_OVERLAY=dev-see-impacts ./scripts/validate-local-kubernetes.sh

validate-kubernetes-calculations:
	K8S_OVERLAY=dev-calculations ./scripts/validate-local-kubernetes.sh
