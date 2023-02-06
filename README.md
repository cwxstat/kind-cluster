# kind-cluster
Makefile with KinD setup


To use this, you'll need to install KinD and Helm.

- https://kind.sigs.k8s.io/


```bash
$ make

make help                 -> display make targets
 make up-kind              -> setup local kind cluster.
 make ingress              -> setup cluster for ingress
 make helm-prep            -> helm-prep
 make install-prometheus   -> install-prometheus
 make install-argo         -> install argo
 make install-argo-events  -> install argo-events
 make install-tekton       -> install tekton
 make patch-auth-mode      -> patch auth-mode
 make port-forward         -> port-forward
 make roles-argo           -> create roles in argo
 make roles-dev            -> create roles in argo
 make argo-cd              -> install argo-cd
 make argo-cd-password     -> get argo-cd password
 make remove-argo          -> install argo
 make remove-argo-events   -> remove argo-events
 make remove-roles-argo    -> create roles in argo
 make down-kind            -> tear down local kind cluster
 


```

# Instructions on building Kubernetes from source



## Step 1:

Close source code, and ckeckout the release you want to build.

```bash
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes
git checkout release-1.26
```


## Step 2:

Build. You'll need to be in the kubernetes directory. 

```bash
kind build node-image . 
```

## Step 3: (run it)

```bash
kind create cluster --name v2.6 --image kindest/node:latest

```