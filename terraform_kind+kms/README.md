# Terraform Kubernetes+FluxCD Bootstrap

This project uses Terraform to
- create a Kubernetes cluster
- set up a Github repository to store Kubernetes manifests
- bootstrap the cluster using FluxCD

## Pre-requisites

- Terraform installed (version >= 1.15.2)
- Docker
- Github account
- FluxCD CLI

## Terraform modules used
### `cluster-kind`
Creates local k8s cluster using kind tool.
### `tf-hashicorp-tls-keys`
Creates a TLS private key and self-signed certificate, exports the private key in PEM format and the public key in OpenSSH format.
### `tf-github-repository`
Creates a private Github repository, provision deploy key passed from the `tls_private_key` module.
### `fluxcd-flux-bootstrap`
Installs Flux in the Kubernetes cluster and sets it up to read manifests from the Github repository created by the `github-repository` module. It also generates a private key for Flux to use to authenticate with Github.

## Configuration
Export variables:
```
export TF_VAR_GITHUB_OWNER=
export TF_VAR_GITHUB_TOKEN=
export TF_VAR_FLUX_GITHUB_REPO=
```

## Usage
```shell
terraform init
terraform apply
export KUBECONFIG=$(terraform output -raw kubeconfig_path)
kubectl get nodes
kubectl -n flux-system get all
```
# FluxCD operations

## Flux GitOps Helm-based flow

`Git repo (github) → GitRepository (source) → Kustomization (reconciler) → HelmRelease → Helm controller -> Kubernetes API -> Deployment/Pods`

GitRepository (kind: GitRepository): clones Git repo, pulls changes every interval, produces an “artifact”

Kustomization (kind: Kustomization): points to a path in Git repo, runs kustomize build, applies manifests to cluster, handles pruning (delete removed resources). Applies ./clusters/$CLUSTER_NAME from repo.

## Install CLI
```
brew install fluxcd/tap/flux
```
## Generate and push manifests to FluxCD repo under $FLUX_GITHUB_REPO/cluster/$CLUSTER_NAME/
#### kbot-gr.yaml
```
flux create source git kbot \
  --url=https://github.com/dmzopi/kbot \
  --branch=main \
  --namespace=demo \
  --export
```  
#### kbot-hr.yaml
```
flux create helmrelease kbot \
    --namespace=demo \
    --source=GitRepository/kbot \
    --chart="./helm" \
    --interval=1m \
    --export
```
Watch logs for reconcilation
```
flux logs -f
```
Verify installed components
```
flux get -A all
```
Specifically gitrepo, helmreleases must exist
```
kubectl get gitrepository -A
NAMESPACE     NAME          URL                                      AGE     READY   STATUS
demo          kbot          https://github.com/dmzopi/kbot           6m11s   True    stored artifact for revision 'main@sha1:9560bb1b7b88875b64ab99b6f1baebce9f853887'
flux-system   flux-system   ssh://git@github.com/dmzopi/fluxcd.git   65m     True    stored artifact for revision 'main@sha1:2c9b772e9566bd84e319f51ff3d7b98d904d2901'

kubectl get kustomizations -A
NAMESPACE     NAME          AGE   READY   STATUS
flux-system   flux-system   61m   True    Applied revision: main@sha1:2c9b772e9566bd84e319f51ff3d7b98d904d2901

kubectl get helmreleases -A
NAMESPACE   NAME   AGE     READY     STATUS
demo        kbot   5m55s   Unknown   Running 'upgrade' action with timeout of 5m0s
```

### Testing concept of using AWS KMS for secrets cypher/decypher (manual mode)

#### 1. Create dedicated AWS IAM User
#### 2. Create AWS KMS Customer managed key, add section to key policy allowing IAM user to use this key:
```
    {
      "Sid": "KeyUsage",
      "Effect": "Allow",
      "Principal": {
        "AWS": "__arn_of_iam_user__"
      },
      "Action": [
        "kms:Encrypt",
        "kms:DescribeKey",
        "kms:Decrypt"
      ],
      "Resource": "__arn_of_your_key__"
    }
```
#### 3. Assign policy to IAM, add permissions:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:DescribeKey"
            ],
            "Resource": "__arn_of_your_key__"
        }
    ]
}
```
#### 4. Create secret with AWS credentials
```
kubectl create secret generic aws-sops-credentials \
  -n flux-system \
  --from-literal=AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID" \
  --from-literal=AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY" \
  --from-literal=AWS_REGION="YOUR_AWS_REGION"
```
#### 5. Patch the Flux Kustomize Controller to get AWS authentication
```
kubectl patch deployment kustomize-controller \
  -n flux-system \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/envFrom",
      "value": [
        {
          "secretRef": {
            "name": "aws-sops-credentials"
          }
        }
      ]
    }
  ]'
```  
#### 6. Configure Flux Kustomization to use sops for secrets decryption
```
k -n flux-system edit kustomizations.kustomize.toolkit.fluxcd.io flux-system 

spec:
  decryption:
    provider: sops
```

#### 7. Create plain secret kbot-secret.yaml. 

Data to be cyphered in

token: some_token_you_need_to_cypher

#### 8. Install sops https://github.com/getsops/sops

#### 9. Create cyphered secret (must be authenticated in AWS beforehand)
```
sops -e --kms __arn_of_your_key__ --encrypted-regex '^(token)$' kbot-secret.yaml > kbot-secret-enc.yaml
```
#### 10. Put kbot-secret-enc.yaml to github fluxcd repo.
#### 11. Verify secter is fetched and decyphered by kubernetes


## General CI/CD layout

![Flow](docs/img/flow.png)

## ToDO:
AWS ELB provision

## License
MIT License. See LICENSE for full details.