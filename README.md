# kind-cluster
Makefile with KinD setup


To use this, you'll need to install KinD and Helm.

- https://kind.sigs.k8s.io/


```bash

$ make help
 make help                 -> display make targets
 make up-kind              -> setup local kind cluster.
 make helm-prep            -> helm-prep
 make install-prometheus   -> install-prometheus
 make install-argo         -> install argo
 make patch-auth-mode      -> patch auth-mode
 make port-forward         -> port-forward
 make remove-argo          -> install argo
 make roles-argo           -> create roles in argo
 make remove-roles-argo    -> create roles in argo
 make roles-dev            -> create roles in argo
 make argo-cd              -> install argo-cd
 make argo-cd-password     -> get argo-cd password
 make down-kind            -> tear down local kind cluster

```