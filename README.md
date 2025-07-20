# EKS Infrastructure with Terraform

This repository contains Terraform modules to deploy a secure EKS cluster with ALB and proper networking setup and as mentioned in the doc it can be close to production ready but not completely , somethings are assumed that logging is via Cloudwatch but in generally Cloudwatch logs are transmitted to Dataddog(for lambda datadog forwarder is required) or some other observability platforms like grafana cloud.

# Pending things
1. For persistence RDS / elasticache can be used but RDS can be used for prod/ actual cloud env and for now I am using sql lite to store data

# Regarding k8s / Helm charts

Right now for the sake of simplicity I have kept secrets in values.yaml file to show but I have created them via secret on K8s. Also for prod in helm charts

1. Install aws external secrets for automount of SSM https://external-secrets.io/latest/provider/aws-secrets-manager/
2. Remove secrets form values-ENV.yaml file 
3. I have used github actions for image building and storing images on docker hub (CI) and using argocd for CD to deploy.
4. Updating the values.yaml when new image is created https://github.com/devd-s/babbel-task/blob/main/url-shortener-helm/values-dev.yaml, it will update the  the image on manifests and argocd will deploy that image.
5. To install argocd kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
6. Command to create helm chart ´helm create url-shortener´

# Another way
The application code can also be deployed on lambda + api gateway and rules can be added to api gateway and whitelisting/blacklisting can added on api gateway using certain rules.

Client ──▶ API Gateway ──▶ Lambda Authorizer ──▶ Allow or Deny
                                          └─▶ Main Lambda if allowed


## Architecture

The infrastructure includes:

- **VPC with public and private subnets** across multiple AZs for HA, reliability and resilience
- **EKS cluster** with managed node groups using launch templates
- **Application Load Balancer (ALB)** with WAF protection
- **Security Groups** with least privilege access
- **CloudFront IP whitelisting** on ALB level
- **VPC Flow Logs** for monitoring
- **Autoscaling** configuration for EKS nodes

## Directory Structure

```
terraform/
├── modules/
│   ├── networking/          # VPC, subnets, NAT gateways
│   ├── security-groups/     # Security groups for EKS, ALB, RDS
│   ├── eks/                # EKS cluster and node groups
│   └── alb/                # Application Load Balancer with WAF
├── environments/
│   ├── dev/                # Development environment
│   ├── staging/            # Staging environment
│   └── prod/               # Production environment
└── README.md
```

## Security Features

### EKS Security
- Private subnets for worker nodes
- Encrypted EBS volumes
- IMDSv2 enforced on EC2 instances
- Cluster encryption with KMS
- OIDC provider for SA
- Comprehensive IAM policies

### ALB Security
- WAF with managed rule sets
- CloudFront IP whitelisting
- Rate limiting protection for malicious traffic
- Security groups restricting access of malicious traffic
- HTTPS enforcement with SSL certificates

### Network Security
- VPC Flow Logs enabled
- Private subnets for workloads
- NAT gateways for outbound traffic
- Security groups with least privilege

## Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** for cluster management


## Required AWS Permissions

The deploying user/role needs the following permissions:
- EC2 (VPC, Security Groups, Launch Templates)
- EKS (Cluster, Node Groups)
- IAM (Roles, Policies, OIDC Provider)
- ELB (Load Balancers, Target Groups)
- WAF (Web ACLs, IP Sets)
- S3 (ALB access logs)
- CloudWatch (Log Groups)
- KMS (Encryption keys)

## Deployment

### 1. Configure Backend (Optional but Recommended)

Update the backend configuration in `environments/{env}/main.tf`:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "dev/terraform.tfstate"
  region         = "us-west-2"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

### 2. Set Variables

Copy and customize the variables file:

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy Infrastructure

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Plan deployment
terraform plan

# Apply changes
terraform apply
```

### 4. Configure kubectl

After deployment, configure kubectl to access the cluster:

```bash
# Get the kubectl config command from Terraform output
terraform output kubectl_config_command

# To get the eks kubeconfig
aws eks update-kubeconfig --region us-west-2 --name url-shortener-dev-eks
```

## Environment-Specific Configurations

### Development (`environments/dev/`)
- Smaller instance types (t3.medium)
- Lower node counts
- Public EKS endpoint access
- No deletion protection on ALB
- Spot instances for cost optimization

### Staging (`environments/staging/`)
- Medium instance types
- Moderate node counts
- Restricted EKS endpoint access
- Deletion protection enabled
- Spot instances for cost optimization

### Production (`environments/prod/`)
- Larger instance types
- Higher node counts with autoscaling
- Private EKS endpoint access only
- Full security hardening
- Deletion protection enabled
- Spot instances for cost optimization

## Customization

### Adding New Security Groups

Add rules to `modules/security-groups/main.tf`:

```hcl
resource "aws_security_group" "custom" {
  name_prefix = "${var.environment}-custom-"
  vpc_id      = var.vpc_id
  
  #More rules can be Added here
}
```

### Modifying Node Groups

Updating the launch template for `modules/eks/main.tf`:

```hcl
resource "aws_launch_template" "eks_nodes" {
  # Customize instance configuration
  instance_type = var.node_instance_types[0]
  # Adding additional configuration
}
```

### Adding ALB Listener Rules

rules can be added here `modules/alb/main.tf`:

```hcl
resource "aws_lb_listener_rule" "custom" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 200
  
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.custom.arn
  }
  
  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}
```

## CloudFront IP Whitelisting

The ALB security groups automatically whitelist CloudFront IP ranges. These IPs are:
- Defined in `modules/security-groups/variables.tf`
- Applied to ALB security group ingress rules
- Used in WAF IP sets for additional protection

To update CloudFront IPs, modify the `cloudfront_ips` variable in the security groups module.

## Monitoring and Logging

- **VPC Flow Logs**: Are getting Stored in CloudWatch
- **EKS Control Plane Logs**: For API, audit, authenticator, controllerManager, scheduler
- **ALB Access Logs**: For Storing in S3 bucket
- **WAF Logs**: For CloudWatch metrics 

## Autoscaling

The EKS cluster includes:
- **Cluster Autoscaler**: Automatically scaling nodes based on pod requirements
- **Horizontal Pod Autoscaler (HPA)**: Configured in Helm charts


## Cost Optimization

- Using Spot instances for workloads
- Enabling cluster autoscaler to scale down unused nodes
- Setting appropriate resource requests/limits in applications

## Troubleshooting

### Common Issues

   - Checking security group rules
   - Verifying IAM roles & policies
   - Checking subnet routing using reachability analyzer
   - Verify target group health check path
   - Checking security group rules between ALB & EKS nodes
   - Ensuring application is running on correct port
   - Verifying IAM permissions
   - Checking aws-auth ConfigMap in EKS cluster
   - Ensuring OIDC provider is configured correctly

### Useful Commands

```bash
# To Check EKS cluster status
aws eks describe-cluster --name url-shortener-dev-eks

# To List EKS node groups
aws eks describe-nodegroup --cluster-name url-shortener-dev-eks --nodegroup-name dev-eks-nodes

# To Check ALB status
aws elbv2 describe-load-balancers --names dev-alb

# To View VPC Flow Logs
aws logs describe-log-groups --log-group-name-prefix "/aws/vpc/flowlogs"
```

## Cleanup

To destroy the infrastructure:

```bash
cd environments/dev
terraform destroy
```

For upgrading in the form of blue green deployments

## Contributing

1. Following up Terraform best practices
2. Updating documentation when adding new features
3. Testing changes in dev environment first
4. Using consistent naming conventions
5. Adding appropriate tags to all resources

## Security Considerations

- Regularly updating CloudFront IP ranges
- Monitoring WAF blocked requests
- Reviewing VPC Flow Logs for suspicious activity
- Keeping Kubernetes and node AMIs updated
- Rotating SSL certificates before expiration
- Reviewing IAM permissions periodically
