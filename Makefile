##
# Admission Denier
#
# @file
# @version 0.1

export NAMESPACE := openshift-admission
export SERVICE := openshift-admission-hook
export IMAGE := quay.io/fbergman/admission-denier:latest
CERTS_DIR := "certs"

predeploy:
	@echo "Creating namespace before deploying"
	kubectl create namespace "${NAMESPACE}" || true

$(CERTS_DIR)/server.conf:
	envsubst < $(CERTS_DIR)/server.conf.tpl > $(CERTS_DIR)/server.conf

certificates: $(CERTS_DIR)/server.conf predeploy
	@echo "Generating certificates required for the webhook"
	# Generate the CA cert and private key
	openssl req -nodes -new -x509 -keyout ${CERTS_DIR}/ca.key -out ${CERTS_DIR}/ca.crt -subj "/CN=Admission Controller Webhook Demo CA"
	# Generate the private key for the webhook server
	openssl genrsa -out ${CERTS_DIR}/webhook-server-tls.key 2048
	# Generate a Certificate Signing Request (CSR) for the private key, and sign it with the private key of the CA.
	openssl req -new -key ${CERTS_DIR}/webhook-server-tls.key -subj "/CN=${SERVICE}.${NAMESPACE}.svc" -config ${CERTS_DIR}/server.conf \
		| openssl x509 -req -CA ${CERTS_DIR}/ca.crt -CAkey ${CERTS_DIR}/ca.key -CAcreateserial -out ${CERTS_DIR}/webhook-server-tls.crt -extensions v3_req -extfile ${CERTS_DIR}/server.conf

secret: predeploy certificates
	@echo "Create secret for the webhook"
	kubectl delete secret -n $(NAMESPACE) $(SERVICE) || true
	kubectl create secret generic $(SERVICE) -n "$(NAMESPACE)" --from-file=key.pem=certs/webhook-server-tls.key --from-file=cert.pem=certs/webhook-server-tls.crt

manifest.yaml: certificates
	CA_BUNDLE=$(shell openssl base64 -A < "$(CERTS_DIR)/ca.crt") envsubst < manifest.yaml.tpl > manifest.yaml

deploy: predeploy secret manifest.yaml
	kubectl apply -n $(NAMESPACE) -f manifest.yaml

all: deploy

# end
