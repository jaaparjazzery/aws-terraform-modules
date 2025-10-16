# Contributing to AWS Terraform Modules

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation Guidelines](#documentation-guidelines)
- [Commit Message Convention](#commit-message-convention)
- [Pull Request Process](#pull-request-process)
- [Module Development Guidelines](#module-development-guidelines)

## 🤝 Code of Conduct

This project adheres to a Code of Conduct. By participating, you are expected to:

- Use welcoming and inclusive language
- Be respectful of differing viewpoints
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Go](https://golang.org/dl/) >= 1.21 (for testing)
- [pre-commit](https://pre-commit.com/) >= 3.0
- [terraform-docs](https://terraform-docs.io/) >= 0.16
- [tflint](https://github.com/terraform-linters/tflint) >= 0.50
- [tfsec](https://github.com/aquasecurity/tfsec) >= 1.28
- [Git](https://git-scm.com/) >= 2.30

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/aws-terraform-modules.git
   cd aws-terraform-modules
   ```

3. **Add upstream remote:**
   ```bash
   git remote add upstream https://github.com/jaaparjazzery/aws-terraform-modules.git
   ```

4. **Install pre-commit hooks:**
   ```bash
   pip install pre-commit
   pre-commit install
   pre-commit install --hook-type commit-msg
   ```

5. **Verify installation:**
   ```bash
   pre-commit run --all-files
   ```

##  Development Workflow

### Branching Strategy

We follow a simplified Git Flow:

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation updates
- `test/*` - Test additions/updates

### Creating a Feature Branch

```bash
git checkout develop
git pull upstream develop
git checkout -b feature/your-feature-name
```

### Making Changes

1. Make your changes in your feature branch
2. Write or update tests as needed
3. Update documentation
4. Run pre-commit hooks: `pre-commit run --all-files`
5. Commit your changes (see commit message convention below)

### Syncing with Upstream

Keep your fork up to date:

```bash
git fetch upstream
git checkout develop
git merge upstream/develop
git push origin develop
```

##  Coding Standards

### Terraform Style Guide

Follow [HashiCorp's Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html):

#### Formatting

```hcl
# Use 2 spaces for indentation
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  
  tags = {
    Name = "example-instance"
  }
}

# Group related attributes together
# Use blank lines to separate logical sections
```

#### Naming Conventions

- **Resources:** Use snake_case: `aws_instance.web_server`
- **Variables:** Use snake_case: `instance_type`
- **Outputs:** Use snake_case: `instance_id`
- **Modules:** Use kebab-case: `modules/vpc-endpoints`

#### Variable Declarations

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition     = can(regex("^t[23]\\.", var.instance_type))
    error_message = "Instance type must be t2 or t3 family"
  }
}
```

#### Resource Naming

```hcl
# Good
resource "aws_instance" "web" { ... }
resource "aws_security_group" "web_server" { ... }

# Bad
resource "aws_instance" "my_instance_1" { ... }
resource "aws_security_group" "sg1" { ... }
```

### File Organization

Each module should have the following structure:

```
module-name/
├── main.tf           # Primary resource definitions
├── variables.tf      # Input variable declarations
├── outputs.tf        # Output value declarations
├── versions.tf       # Terraform and provider version constraints
├── data.tf          # Data source declarations (optional)
├── locals.tf        # Local value declarations (optional)
├── README.md        # Module documentation
└── examples/        # Usage examples (optional)
    └── complete/
        ├── main.tf
        └── README.md
```

### Code Comments

```hcl
# Use comments to explain WHY, not WHAT
# Good
# Disable public IP to enhance security in private subnet
associate_public_ip_address = false

# Bad
# Set associate_public_ip_address to false
associate_public_ip_address = false
```

##  Testing Requirements

### Pre-commit Tests

All code must pass pre-commit hooks:

```bash
pre-commit run --all-files
```

### Terraform Validation

```bash
cd modules/your-module
terraform init -backend=false
terraform validate
terraform fmt -check
```

### Security Scanning

```bash
# tfsec
tfsec modules/your-module

# checkov
checkov -d modules/your-module

# trivy
trivy config modules/your-module
```

### Terratest (Go Tests)

For significant modules, add integration tests:

```go
// test/vpc_test.go
package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
    t.Parallel()
    
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/vpc",
        Vars: map[string]interface{}{
            "vpc_name": "test-vpc",
            "vpc_cidr": "10.0.0.0/16",
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)
    
    vpcId := terraform.Output(t, terraformOptions, "vpc_id")
    assert.NotEmpty(t, vpcId)
}
```

Run tests:

```bash
cd test
go test -v -timeout 30m
```

##  Documentation Guidelines

### Module README Structure

Every module must have a comprehensive README.md:

```markdown
# Module Name

Brief description of what the module does.

## Features

- Feature 1
- Feature 2
- Feature 3

## Usage

### Basic Example

\`\`\`hcl
module "example" {
  source = "path/to/module"
  
  # Required variables
  name = "example"
}
\`\`\`

### Advanced Example

\`\`\`hcl
# Complex usage example
\`\`\`

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Inputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Outputs

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->

## Examples

See the [examples](./examples/) directory.

## Known Issues

Any known limitations or issues.
```

### Documentation Standards

- Use clear, concise language
- Include practical examples
- Document all variables with descriptions
- Explain output values
- Add architecture diagrams when helpful
- Include troubleshooting section
- Link to related modules

### Generating Documentation

Use terraform-docs to auto-generate sections:

```bash
terraform-docs markdown table --output-file README.md modules/your-module
```

##  Commit Message Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

### Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semi-colons, etc)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes
- `perf`: Performance improvements
- `revert`: Revert a previous commit

### Examples

```bash
# Feature
git commit -m "feat(vpc): add support for VPC endpoints"

# Bug fix
git commit -m "fix(rds): correct backup window validation"

# Documentation
git commit -m "docs(alb): update listener configuration examples"

# Breaking change
git commit -m "feat(eks)!: upgrade to EKS 1.28

BREAKING CHANGE: EKS 1.27 is no longer supported"
```

### Commit Message Rules

- Use imperative mood ("add" not "added")
- Don't capitalize first letter
- No period at the end
- Keep subject line under 72 characters
- Separate subject from body with blank line
- Explain WHAT and WHY, not HOW

##  Pull Request Process

### Before Submitting

1.  All tests pass locally
2.  Code follows style guidelines
3.  Documentation is updated
4.  Commits follow convention
5.  Branch is up to date with develop

### Creating a Pull Request

1. **Push your branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create PR on GitHub:**
   - Base branch: `develop` (not `main`)
   - Title follows commit convention
   - Fill out PR template completely

3. **PR Title Format:**
   ```
   feat(module-name): brief description
   ```

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Pre-commit hooks pass
- [ ] Terraform validate passes
- [ ] Security scans pass
- [ ] Tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No breaking changes (or documented)
- [ ] Tests added for new features
- [ ] All tests passing

## Screenshots (if applicable)

## Additional Notes
```

### Review Process

1. Automated checks must pass
2. At least one maintainer approval required
3. No unresolved conversations
4. All comments addressed
5. Documentation reviewed
6. Tests verified

### After Approval

- Maintainer will merge to develop
- Changes will be included in next release
- Credit will be added to CHANGELOG

##  Module Development Guidelines

### Creating a New Module

1. **Module Structure:**
   ```bash
   mkdir -p modules/new-module
   cd modules/new-module
   touch main.tf variables.tf outputs.tf versions.tf README.md
   ```

2. **versions.tf Template:**
   ```hcl
   terraform {
     required_version = ">= 1.0"
     
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = ">= 5.0"
       }
     }
   }
   ```

3. **variables.tf Guidelines:**
   - Group related variables
   - Provide sensible defaults
   - Add validation rules
   - Mark sensitive variables

4. **outputs.tf Guidelines:**
   - Export useful information
   - Add descriptions
   - Group related outputs

### Module Best Practices

#### Security

-  Encryption enabled by default
-  Use KMS keys where applicable
-  Private subnets for sensitive resources
-  Security groups with least privilege
-  No hardcoded credentials
-  IAM roles over access keys

#### Reliability

-  Support Multi-AZ deployments
-  Enable backups by default
-  Include health checks
-  Use lifecycle policies
-  Implement auto-scaling

#### Maintainability

-  Use consistent naming
-  Avoid deeply nested modules
-  Keep modules focused (single responsibility)
-  Use count/for_each appropriately
-  Document complex logic

#### Performance

-  Right-size resources
-  Use appropriate instance types
-  Enable caching where beneficial
-  Optimize network architecture

#### Cost Optimization

-  Support Spot instances
-  Implement lifecycle policies
-  Enable auto-scaling
-  Right-size by default
-  Document cost implications

### Testing New Modules

1. **Unit Tests** (terraform validate)
2. **Security Tests** (tfsec, checkov)
3. **Integration Tests** (terratest)
4. **Manual Testing** (deploy to sandbox)

##  Examples

### Adding Examples

Create comprehensive examples:

```
modules/your-module/examples/
├── basic/              # Minimal configuration
│   ├── main.tf
│   └── README.md
├── complete/           # Full-featured example
│   ├── main.tf
│   └── README.md
└── advanced/           # Complex use case
    ├── main.tf
    └── README.md
```

##  Questions?

-  Check existing documentation
-  Search existing issues
-  Start a discussion
-  Contact maintainers

##  Recognition

Contributors will be:
- Listed in CHANGELOG.md
- Mentioned in release notes
- Added to README.md (if significant contribution)

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to AWS Terraform Modules!** 🚀
