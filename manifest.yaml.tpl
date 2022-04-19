---
apiVersion: v1
kind: Service
metadata:
  name: ${SERVICE}
  labels:
    name: ${SERVICE}
spec:
  ports:
  - name: webhook
    port: 443
    targetPort: 8080
  selector:
    name: ${SERVICE}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SERVICE}
  labels:
    name: ${SERVICE}
spec:
  replicas: 1
  selector:
    matchLabels:
      name: ${SERVICE}
  template:
    metadata:
      name: ${SERVICE}
      labels:
        name: ${SERVICE}
    spec:
      containers:
        - name: webhook
          image: ${IMAGE}
          imagePullPolicy: Always
          args:
            - /app/admission-denier
            - -alsologtostderr
            - --log_dir=/
            - -v=10
            - 2>&1
          resources:
            limits:
              memory: 50Mi
              cpu: 300m
            requests:
              memory: 00Mi
              cpu: 300m
          volumeMounts:
            - name: webhook-certs
              mountPath: /etc/certs
              readOnly: true
            - name: logs
              mountPath: /tmp
          securityContext:
            readOnlyRootFilesystem: true
      volumes:
        - name: webhook-certs
          secret:
            secretName: ${SERVICE}
        - name: logs
          emptyDir: {}
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: ${SERVICE}
webhooks:
  - name: ${SERVICE}.${NAMESPACE}.svc
    clientConfig:
      service:
        name: ${SERVICE}
        namespace: ${NAMESPACE}
        path: "/validate"
      caBundle: "${CA_BUNDLE}"
    rules:
      - operations: ["CREATE","UPDATE"]
        apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
        scope: "*"
    failurePolicy: Ignore
    sideEffects: None
    admissionReviewVersions: ["v1beta1", "v1"]
