# Deploying the denier

- Build the image: `docker build -t admission-denier .`
- Create the `admission` namespace: `kubectl create namespace admission`
- Push the image to the correct registry (in `crc` use [Accessing the CRC internal registry](https://access.redhat.com/documentation/en-us/red_hat_codeready_containers/1.20/html/getting_started_guide/using-codeready-containers_gsg#accessing-the-internal-openshift-registry_gsg))
- Make the image ready for local use in `openshift`: `oc set image-lookup admission-denier`
- Deploy the `admission-webhook`: `make deploy`
