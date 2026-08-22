# Incident Runbook

| Alert / Event Subject | What It Means | First Action |
| --- | --- | --- |
| `[SecureCloud] CI_FAILURE` | Tests or security scan failed on a push | Open the GitHub Actions run link, read the failing step, fix and re-push[cite: 1] |
| `[SecureCloud] DEPLOY_FAILURE` | Kubernetes rollout didn't complete[cite: 1] | Run `kubectl rollout undo deployment/<name> -n secure-cloud` to roll back[cite: 1] |
| `HighFailedLoginRate` | Possible brute-force attack[cite: 1] | Check Grafana dashboard for source IPs, consider a temporary WAF IP block[cite: 1] |
| `PodCrashLooping` | A container keeps restarting[cite: 1] | Run `kubectl logs <pod> -n secure-cloud --previous` to see why it died[cite: 1] |
