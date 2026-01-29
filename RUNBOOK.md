# StartTech Operations Runbook

## Common Operations

### Check Infrastructure Status

```bash
# View all resources
cd terraform
terraform state list

# Check specific resource
terraform state show module.compute.aws_autoscaling_group.main
```

### View Application Logs

```bash
# Via AWS CLI
aws logs tail /aws/starttech/backend --follow --region eu-west-2

# Via CloudWatch Console
# Go to CloudWatch > Log Groups > /aws/starttech/backend
```

### SSH into EC2 Instance (via SSM)

```bash
# List instances
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=starttech-backend" \
  --query 'Reservations[].Instances[].InstanceId' \
  --region eu-west-2

# Connect via SSM
aws ssm start-session --target i-1234567890abcdef0 --region eu-west-2
```

### Check Target Group Health

```bash
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn) \
  --region eu-west-2
```

---

## Deployments

### Deploy Backend (Rolling Update)

```bash
# Trigger instance refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name starttech-asg \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}' \
  --region eu-west-2

# Monitor progress
aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name starttech-asg \
  --region eu-west-2
```

### Deploy Frontend

```bash
# Sync to S3
aws s3 sync dist/ s3://starttech-frontend-buc --delete --region eu-west-2

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

### Rollback Backend

```bash
# Cancel current refresh if in progress
aws autoscaling cancel-instance-refresh \
  --auto-scaling-group-name starttech-asg \
  --region eu-west-2

# Update Docker Hub image tag to previous version, then trigger refresh
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name starttech-asg \
  --region eu-west-2
```

---

## Troubleshooting

### Issue: 502 Bad Gateway from ALB

**Symptoms**: ALB returns 502 errors

**Diagnosis**:
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region eu-west-2

# Check instance logs
aws logs tail /aws/starttech/backend --since 10m --region eu-west-2
```

**Common Causes**:
1. Application not started - check user-data logs
2. Health check failing - verify `/health` endpoint
3. Security group misconfigured - check port 8080 allowed from ALB

**Resolution**:
```bash
# SSH into instance and check
aws ssm start-session --target <instance-id>

# Inside instance
sudo docker ps
sudo docker logs backend
cat /var/log/user-data.log
```

---

### Issue: Instances Keep Terminating

**Symptoms**: ASG continuously replacing instances

**Diagnosis**:
```bash
# Check ASG activity
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name starttech-asg \
  --region eu-west-2

# Check instance health
aws autoscaling describe-auto-scaling-instances \
  --region eu-west-2
```

**Common Causes**:
1. Health check failing before app starts (increase `health_check_grace_period`)
2. Application crashing on startup
3. Docker image pull failing

**Resolution**:
- Check user-data logs: `/var/log/user-data.log`
- Check Docker logs: `docker logs backend`
- Verify Docker Hub image exists and is accessible

---

### Issue: High Latency / Slow Response

**Symptoms**: API responses taking too long

**Diagnosis**:
```bash
# Check ALB metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=<alb-arn-suffix> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average \
  --region eu-west-2

# Check Redis connection
aws elasticache describe-replication-groups \
  --replication-group-id starttech-redis \
  --region eu-west-2
```

**Common Causes**:
1. Redis connection issues
2. MongoDB connection issues
3. Insufficient instance capacity

---

### Issue: CloudFront Not Updating

**Symptoms**: Frontend changes not visible

**Resolution**:
```bash
# Create invalidation
aws cloudfront create-invalidation \
  --distribution-id <distribution-id> \
  --paths "/*"

# Check invalidation status
aws cloudfront list-invalidations \
  --distribution-id <distribution-id>
```

---

## Monitoring Commands

### CloudWatch Alarms Status

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix starttech \
  --region eu-west-2
```

### EC2 CPU Utilization

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=AutoScalingGroupName,Value=starttech-asg \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Average \
  --region eu-west-2
```

### ALB Request Count

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=<alb-arn-suffix> \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum \
  --region eu-west-2
```

---

## Emergency Procedures

### Scale Up Immediately

```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name starttech-asg \
  --desired-capacity 4 \
  --region eu-west-2
```

### Disable Traffic to Backend

```bash
# Set desired capacity to 0
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name starttech-asg \
  --desired-capacity 0 \
  --region eu-west-2
```

### Complete Infrastructure Teardown

```bash
cd terraform
terraform destroy
```

---

## Useful Links

- [AWS Console](https://eu-west-2.console.aws.amazon.com/)
- [CloudWatch Logs](https://eu-west-2.console.aws.amazon.com/cloudwatch/home?region=eu-west-2#logsV2:log-groups)
- [EC2 Instances](https://eu-west-2.console.aws.amazon.com/ec2/home?region=eu-west-2#Instances)
- [ALB Target Groups](https://eu-west-2.console.aws.amazon.com/ec2/home?region=eu-west-2#TargetGroups)
