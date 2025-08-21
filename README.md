# Simple Web Demo (Terraform + Docker + GitHub Actions)

A minimal, portfolio-friendly project that ties together **Terraform**, **Docker**, and **GitHub Actions**.

## What this project proves
- **Terraform**: Provisions a tiny DigitalOcean Droplet via Infrastructure as Code.
- **Docker**: Packages a static web page into a reproducible container.
- **GitHub Actions**: Builds & pushes the image on every `main` push and triggers Terraform to (re)deploy it.

> You can adapt this for AWS/GCP if you prefer. DigitalOcean is chosen for simplicity.

---

## Quick Start (Local)

1. Build the image:
   ```bash
   docker build -t simple-web-demo .
   ```

2. Run it:
   ```bash
   docker run -p 8080:80 simple-web-demo
   ```

3. Open http://localhost:8080 to see the page.

---

## Cloud Deploy with Terraform (DigitalOcean example)

### Prerequisites
- DigitalOcean account with an API token
- An SSH key added to your DO account (we use its **fingerprint**)
- Docker Hub account

### One-time setup (locally)
```bash
cd terraform
export TF_VAR_do_token=YOUR_DO_TOKEN
export TF_VAR_ssh_fingerprint=YOUR_SSH_FINGERPRINT
export TF_VAR_docker_image=YOUR_DOCKERHUB_USERNAME/simple-web-demo:latest

terraform init
terraform apply -auto-approve
```

Output will show the `droplet_ipv4` address. Visit `http://<that-ip>`.

> The droplet uses cloud-init to pull and run your Docker image on port 80.

### Destroy when done
```bash
cd terraform
terraform destroy -auto-approve
```

---

## GitHub Actions (CI/CD)

This repository includes `.github/workflows/deploy.yml` which:

1. Logs in to Docker Hub using secrets
2. Builds and pushes the Docker image
3. Runs `terraform init` and `terraform apply` to (re)provision the droplet and run the new image

### Required GitHub Secrets
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN` (a Personal Access Token with write:packages)
- `DO_TOKEN` (DigitalOcean API token)
- `DO_SSH_FINGERPRINT` (matches an SSH key you've already added in DO Console)

> Terraform reads these via `TF_VAR_*` environment variables set in the workflow.

---

## Notes
- The Terraform config uses the DigitalOcean image slug `docker-20-04` which has Docker preinstalled.
- For AWS, you could replace this with an EC2 instance and user-data that installs Docker.
- Keep costs in mind; destroy the droplet when you're finished experimenting.

---

## Folder Structure
```
simple-web-demo/
├── app/                # Static site content
│   └── index.html
├── Dockerfile          # Container definition
├── terraform/          # IaC for the droplet + user-data
│   ├── main.tf
│   └── variables.tf
├── .github/
│   └── workflows/
│       └── deploy.yml  # CI/CD
└── README.md
```
