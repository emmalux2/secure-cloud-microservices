# Incident Runbook

| Alert / Event Subject | What It Means | First Action |
| --- | --- | --- |
| `[SecureCloud] CI_FAILURE` | Tests or security scan failed on a push | Open the GitHub Actions run link, read the failing step, fix and re-push[cite: 1] |
| `[SecureCloud] DEPLOY_FAILURE` | Kubernetes rollout didn't complete[cite: 1] | Run `kubectl rollout undo deployment/<name> -n secure-cloud` to roll back[cite: 1] |
| `HighFailedLoginRate` | Possible brute-force attack[cite: 1] | Check Grafana dashboard for source IPs, consider a temporary WAF IP block[cite: 1] |
| `PodCrashLooping` | A container keeps restarting[cite: 1] | Run `kubectl logs <pod> -n secure-cloud --previous` to see why it died[cite: 1] |

## Deployment Lifecycle

Pushing changes to `main` runs the deployment workflow. Pull requests run Terraform planning but do not apply infrastructure or deploy services.

To stop AWS infrastructure after practice:

1. Open the repository's **Actions** tab.
2. Select **Destroy SecureCloud (Manual)** and choose **Run workflow**.
3. Type `DESTROY` into the confirmation input and run it.

The destroy workflow removes Terraform-managed infrastructure and the two application ECR repositories. It retains the S3 Terraform state bucket and the GitHub OIDC deployment role so a later deployment can recreate the environment. Destruction is irreversible for ephemeral PostgreSQL and Redis data.

The application Ingress is disabled by default. For a disposable test only, run **Provision Infrastructure (Terraform)** with `enable_disposable_public_http` enabled. This provisions an internet-facing HTTP-only ALB and applies the `main-waf` Web ACL; the workflow verifies the association. Do not use this mode for real authentication traffic because it has no TLS. Run the workflow again with the input disabled to remove the test Ingress and its ALB.

## Practice Deployment

The practice Helm release uses a single ephemeral PostgreSQL pod, Redis without persistence, and internal ClusterIP services. Data is lost if those pods are recreated. No cloud load balancer is created.

The Floci Terraform root is for LocalStack practice only. LocalStack's EKS API currently does not support EKS access entries, `AssociateEncryptionConfig`, or cluster logging updates, and omits the cluster OIDC issuer and logging state from its responses. Accordingly, that root disables EKS access-entry administration and auth-service IRSA, and does not manage EKS encryption configuration or cluster logging. The production AWS Terraform root retains the GitHub Actions cluster-admin access entry, auth-service IRSA trust configuration, EKS encryption, and cluster logging.

Forward the API gateway to localhost:

```sh
kubectl port-forward -n securecloud svc/api-gateway 8080:80
```

Forward Grafana in a second terminal:

```sh
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

Open Grafana at `http://localhost:3000`, sign in as `admin`, and retrieve the generated password:

```sh
kubectl get secret securecloud-grafana-admin -n monitoring -o jsonpath='{.data.admin-password}' | base64 --decode
```

The dashboard is named **SecureCloud Security Overview**. Prometheus alert rules are installed, but email notifications are disabled until valid Alertmanager/SMTP credentials are configured.
