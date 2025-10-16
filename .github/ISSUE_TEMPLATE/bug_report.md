---
name: Bug Report
about: Report a bug or issue with the modules
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of the bug.

## Module Affected

- [ ] VPC
- [ ] S3 Bucket
- [ ] EC2 Instance
- [ ] RDS Database
- [ ] Application Load Balancer
- [ ] EKS Cluster
- [ ] Example: Simple Web App
- [ ] Example: Microservices Platform
- [ ] Example: Data Processing Pipeline

## Steps to Reproduce

1. 
2. 
3. 

## Expected Behavior

What you expected to happen.

## Actual Behavior

What actually happened.

## Configuration

```hcl
# Paste relevant Terraform configuration (sanitized)
```

## Error Output

```
# Paste error messages
```

## Environment

- **Terraform Version:** [e.g., 1.6.0]
- **AWS Provider Version:** [e.g., 5.30.0]
- **Module Version:** [e.g., v1.0.0]
- **AWS Region:** [e.g., us-east-1]
- **Operating System:** [e.g., macOS 14.0, Ubuntu 22.04]

## Debug Logs

<details>
<summary>Debug logs (if applicable)</summary>

```
# Paste debug logs here (sanitize sensitive data)
TF_LOG=DEBUG output
```

</details>

## Additional Context

Any other information that might help resolve the issue.

## Possible Solution

If you have ideas on how to fix this.

---

## File: .github/ISSUE_TEMPLATE/feature_request.md

---
name: Feature Request
about: Suggest a new feature or enhancement
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Feature Description

A clear and concise description of the feature you'd like to see.

## Problem Statement

What problem does this solve? Why is this needed?

## Proposed Solution

Describe your proposed solution in detail.

## Module Affected

Which module(s) would this feature affect?

- [ ] VPC
- [ ] S3 Bucket
- [ ] EC2 Instance
- [ ] RDS Database
- [ ] Application Load Balancer
- [ ] EKS Cluster
- [ ] New Module (specify below)
- [ ] Examples
- [ ] Documentation

## Example Usage

```hcl
# Show how you'd like to use this feature
module "example" {
  source = "./modules/vpc"
  
  # New feature usage
  new_feature_parameter = "value"
}
```

## Alternatives Considered

What alternatives have you considered?

## Additional Context

Any other context, screenshots, or examples.

## Are you willing to contribute?

- [ ] Yes, I can submit a PR for this
- [ ] I need help implementing this
- [ ] I can test this feature

---

## File: .github/ISSUE_TEMPLATE/documentation.md

---
name: Documentation Issue
about: Report issues or suggest improvements to documentation
title: '[DOCS] '
labels: documentation
assignees: ''
---

## Documentation Issue

What documentation needs improvement?

## Location

- **File/Module:** 
- **Section:** 
- **URL:** 

## Issue Type

- [ ] Incorrect information
- [ ] Missing information
- [ ] Unclear explanation
- [ ] Broken link
- [ ] Outdated example
- [ ] Typo/Grammar
- [ ] Other (please specify)

## Current Documentation

What does the current documentation say?

## Suggested Improvement

What should it say instead?

## Additional Context

Any other relevant information.

---

