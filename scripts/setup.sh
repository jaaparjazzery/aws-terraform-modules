#!/bin/bash
# scripts/setup.sh
# Initial repository setup script

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   AWS Terraform Modules - Initial Setup       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}✗ $1 not found${NC}"
        echo -e "${YELLOW}  Install from: $2${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 installed${NC}"
        return 0
    fi
}

all_good=true

check_command "terraform" "https://www.terraform.io/downloads" || all_good=false
check_command "aws" "https://aws.amazon.com/cli/" || all_good=false
check_command "git" "https://git-scm.com/downloads" || all_good=false
check_command "make" "Built-in or install build-essential" || all_good=false

if [ "$all_good" = false ]; then
    echo ""
    echo -e "${RED}Please install missing prerequisites and run again.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}All prerequisites installed!${NC}"
echo ""

# Install development tools
echo -e "${YELLOW}Installing development tools...${NC}"
make install-tools

# Configure AWS
echo ""
echo -e "${YELLOW}Checking AWS configuration...${NC}"

if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    echo ""
    read -p "Configure AWS now? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        aws configure
    else
        echo -e "${YELLOW}⚠ AWS credentials required for testing and deployment${NC}"
    fi
else
    echo -e "${GREEN}✓ AWS credentials configured${NC}"
    aws sts get-caller-identity
fi

# Initialize Terraform
echo ""
echo -e "${YELLOW}Initializing Terraform modules...${NC}"
make init

# Run initial validation
echo ""
echo -e "${YELLOW}Running initial validation...${NC}"
make quick-check

# Setup complete
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Setup Complete! 🎉                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo ""
echo "1. Explore the modules:"
echo -e "   ${YELLOW}ls modules/${NC}"
echo ""
echo "2. Check out an example:"
echo -e "   ${YELLOW}cd examples/simple-web-app${NC}"
echo ""
echo "3. Review available commands:"
echo -e "   ${YELLOW}make help${NC}"
echo ""
echo "4. Read the documentation:"
echo -e "   ${YELLOW}cat README.md${NC}"
echo ""
echo "5. Run your first deployment:"
echo -e "   ${YELLOW}cd examples/simple-web-app${NC}"
echo -e "   ${YELLOW}cp terraform.tfvars.example terraform.tfvars${NC}"
echo -e "   ${YELLOW}# Edit terraform.tfvars${NC}"
echo -e "   ${YELLOW}terraform init${NC}"
echo -e "   ${YELLOW}terraform plan${NC}"
echo ""
echo -e "${GREEN}Happy Terraforming! 🚀${NC}"

---
