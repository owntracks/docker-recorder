# Kubernetes manifests to deploy Owntracks Recorder and Frontend

Some example files to be adapted to your Kubernetes cluster. Pay attention, you will need to adapt them to your liking.


## namespace.yaml

We create and deploy everything within the `otrecorder` namespace. If you wish to rename this, be sure to update the
reference to it in the other files.

## configmap.yaml

Where you define the contents of `recorder.conf` and other needed files, like e.g. certificates to verify your broker.
Optionally you can add files to be deployed on the frontend project as documented


## broker-user-secret.yaml and broker-user-secret-sealed.yaml

Assuming your broker needs authentication, username and password are defined in `broker-user-secret.yaml`. There is also
an example to create this respectively as a [sealed secret][https://github.com/bitnami-labs/sealed-secrets]. Both files
contain an example command to create them.

## pvc.yaml

Here you define the persistent storage, mapped on the `/store` directory of the recorder. Make sure you define this as
`ReadWriteOnce`, and not`ReadWriteMany`, as the recorder application can only run 1 instance concurrently.

## deployment.yaml

Here we define the pod that will be deployed, and match secrets, configs and volumes to the right containers. It's a
simple deployment of one (single replica) pod with two containers: `owntracks/recorder` and `owntracks/frontend`.

Part of the configuration can be done in the configMap defining `recorder.conf`, and certain parts can be configured by
setting environment variables.

The frontend will connect to the recorder('s API) within the pod.

## service.yaml

Here we define two services: the web interface of the recorder (and it's API), and the web interface of the gui
frontend. Service is defined as `CLusterIP` and will be used by the Ingress object we create to expose both service
outside of the cluster.

## ingress.yaml

This file might possible heavily be adapted, depending on what Ingress Controller you use. Current example assumes the
Nginx controller for the reverse proxying, and cert-manager for the (Let's Encrypt_) certificate creation.
