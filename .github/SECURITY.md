# Security Policy

## Supported Versions

We release patches for security vulnerabilities in the following versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

###  Private Disclosure (Preferred)

1. **Do NOT create a public GitHub issue**
2. Go to https://github.com/jaaparjazzery/aws-terraform-modules/security/advisories/new
3. Click "Report a vulnerability"
4. Provide detailed information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### 📧 Email Disclosure (Alternative)

If you prefer email, send details to: security@quidgee.com

**Include:**
- Subject: "[SECURITY] Description"
- Detailed description
- Steps to reproduce
- Your contact information

## What to Expect

1. **Acknowledgment:** Within 48 hours
2. **Initial Assessment:** Within 5 business days
3. **Status Updates:** Weekly until resolved
4. **Resolution:** We aim to fix critical issues within 30 days

## Security Best Practices

When using these modules:

###  DO

- **Use latest versions** - Always use the latest stable release
- **Enable encryption** - Use KMS encryption for sensitive data
- **Restrict access** - Use least privilege IAM policies
- **Private subnets** - Place sensitive resources in private subnets
- **Enable logging** - Turn on CloudWatch Logs and VPC Flow Logs
- **Scan regularly** - Use tfsec, checkov, or Trivy
- **Rotate credentials** - Regularly rotate secrets and keys
- **Use HTTPS** - Enable SSL/TLS for all endpoints
- **Enable MFA** - Require MFA for privileged operations
- **Review security groups** - Minimize open ports

###  DON'T

- **Hardcode secrets** - Never put passwords or keys in code
- **Commit sensitive data** - Don't commit terraform.tfstate
- **Use default credentials** - Always change default passwords
- **Disable encryption** - Don't turn off encryption features
- **Open to world** - Avoid 0.0.0.0/0 in security groups
- **Skip updates** - Don't ignore security advisories
- **Ignore warnings** - Address security scan findings
- **Use root credentials** - Don't use AWS root account
- **Share IAM keys** - Don't share access keys
- **Disable logging** - Keep audit logs enabled

## Security Features

Our modules include security by default:

### Encryption
-  EBS volumes encrypted
-  RDS storage encrypted
-  S3 server-side encryption
-  EKS secrets encryption

### Network Security
-  Private subnets for databases
-  Security groups with least privilege
-  NAT Gateways for outbound only
-  No direct internet access to sensitive resources

### Access Control
-  IAM roles (no access keys)
-  IRSA for EKS workloads
-  Instance profiles for EC2
-  Least privilege policies

### Compliance
-  IMDSv2 enforcement
-  Public access blocking (S3)
-  Deletion protection
-  Backup retention

## Known Security Considerations

### Default Configurations

1. **Database Passwords:**
   - Must be provided via variables
   - Should use AWS Secrets Manager in production
   - Never commit to version control

2. **SSH Keys:**
   - Optional for EC2 instances
   - Use SSM Session Manager instead when possible
   - Restrict key access if used

3. **API Endpoints:**
   - EKS API can be public by default
   - Configure `endpoint_private_access` and `public_access_cidrs`
   - Use VPN or bastion for production

## Security Scanning

We run automated security scans:

- **tfsec** - Terraform security scanner
- **checkov** - Policy-as-code scanner
- **trivy** - Infrastructure security scanner
- **Dependabot** - Dependency updates
- **GitHub Code Scanning** - Static analysis

## Vulnerability Disclosure Timeline

1. **Day 0:** Vulnerability reported
2. **Day 1-2:** Acknowledgment sent
3. **Day 3-7:** Initial assessment
4. **Day 7-30:** Patch development
5. **Day 30:** Public disclosure (if resolved)
6. **Day 30+:** Advisory published

## Security Hall of Fame

We recognize security researchers who responsibly disclose vulnerabilities:

| Researcher | Date | Severity | Issue |
|------------|------|----------|-------|
| - | - | - | - |

## Contact

- **Security Issues:** security@quidgee.com
- **General Questions:** GitHub Discussions
- **Documentation:** See [README.md](../README.md)

## Legal

This security policy is subject to our [Code of Conduct](CODE_OF_CONDUCT.md).

---

## File: .github/CODE_OF_CONDUCT.md

# Contributor Covenant Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, religion, or sexual identity
and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming,
diverse, inclusive, and healthy community.

## Our Standards

Examples of behavior that contributes to a positive environment:

* Using welcoming and inclusive language
* Being respectful of differing viewpoints and experiences
* Gracefully accepting constructive criticism
* Focusing on what is best for the community
* Showing empathy towards other community members
* Providing helpful feedback
* Being patient with new contributors

Examples of unacceptable behavior:

* The use of sexualized language or imagery
* Trolling, insulting or derogatory comments, and personal attacks
* Public or private harassment
* Publishing others' private information without permission
* Other conduct which could reasonably be considered inappropriate

## Enforcement Responsibilities

Community leaders are responsible for clarifying and enforcing our standards of
acceptable behavior and will take appropriate and fair corrective action in
response to any behavior that they deem inappropriate, threatening, offensive,
or harmful.

## Scope

This Code of Conduct applies within all community spaces, and also applies when
an individual is officially representing the community in public spaces.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to the community leaders responsible for enforcement at
conduct@quidgee.com.

All complaints will be reviewed and investigated promptly and fairly.

## Enforcement Guidelines

### 1. Correction

**Community Impact:** Use of inappropriate language or other behavior deemed
unprofessional or unwelcome.

**Consequence:** A private, written warning, providing clarity around the nature
of the violation and an explanation of why the behavior was inappropriate.

### 2. Warning

**Community Impact:** A violation through a single incident or series of actions.

**Consequence:** A warning with consequences for continued behavior.

### 3. Temporary Ban

**Community Impact:** A serious violation of community standards.

**Consequence:** A temporary ban from any sort of interaction or public
communication with the community.

### 4. Permanent Ban

**Community Impact:** Demonstrating a pattern of violation of community
standards.

**Consequence:** A permanent ban from any sort of public interaction within
the community.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage],
version 2.0, available at
https://www.contributor-covenant.org/version/2/0/code_of_conduct.html.

[homepage]: https://www.contributor-covenant.org

For answers to common questions about this code of conduct, see
https://www.contributor-covenant.org/faq
