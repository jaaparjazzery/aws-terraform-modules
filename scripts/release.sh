#!/bin/bash
# scripts/release.sh
# Automated release script with semantic versioning

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}INFO: $1${NC}"
}

success() {
    echo -e "${GREEN}SUCCESS: $1${NC}"
}

warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

# Check if git is clean
check_git_clean() {
    if [[ -n $(git status -s) ]]; then
        error "Git working directory is not clean. Commit or stash changes first."
    fi
    success "Git working directory is clean"
}

# Get current version
get_current_version() {
    git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"
}

# Parse version
parse_version() {
    local version=$1
    version=${version#v} # Remove 'v' prefix
    
    IFS='.' read -r major minor patch <<< "$version"
    
    echo "$major" "$minor" "$patch"
}

# Increment version
increment_version() {
    local current=$1
    local type=$2
    
    read -r major minor patch <<< "$(parse_version "$current")"
    
    case $type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            error "Invalid version type: $type. Use major, minor, or patch."
            ;;
    esac
    
    echo "v${major}.${minor}.${patch}"
}

# Update CHANGELOG
update_changelog() {
    local new_version=$1
    local date=$(date +%Y-%m-%d)
    
    info "Updating CHANGELOG.md..."
    
    # Create backup
    cp CHANGELOG.md CHANGELOG.md.bak
    
    # Get commits since last tag
    local last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    local commits=""
    
    if [[ -n $last_tag ]]; then
        commits=$(git log $last_tag..HEAD --pretty=format:"- %s (%h)" --no-merges)
    else
        commits=$(git log --pretty=format:"- %s (%h)" --no-merges)
    fi
    
    # Insert new version in CHANGELOG
    sed -i.tmp "/## \[Unreleased\]/a\\
\\
## [${new_version#v}] - $date\\
\\
### Changes\\
$commits
" CHANGELOG.md
    
    rm CHANGELOG.md.tmp 2>/dev/null || true
    
    success "CHANGELOG.md updated"
}

# Create git tag
create_tag() {
    local version=$1
    
    info "Creating git tag $version..."
    
    git add CHANGELOG.md
    git commit -m "chore: prepare release $version"
    git tag -a "$version" -m "Release $version"
    
    success "Tag $version created"
}

# Push changes
push_changes() {
    local version=$1
    
    info "Pushing changes to remote..."
    
    git push origin main
    git push origin "$version"
    
    success "Changes pushed to remote"
}

# Main function
main() {
    local version_type=${1:-patch}
    
    echo -e "${BLUE}╔════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   AWS Terraform Modules Release   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════╝${NC}"
    echo ""
    
    # Validate input
    if [[ ! $version_type =~ ^(major|minor|patch)$ ]]; then
        error "Invalid version type. Use: major, minor, or patch"
    fi
    
    # Check git status
    check_git_clean
    
    # Get current and new version
    local current_version=$(get_current_version)
    local new_version=$(increment_version "$current_version" "$version_type")
    
    info "Current version: $current_version"
    info "New version: $new_version"
    echo ""
    
    # Confirm with user
    read -p "Create release $new_version? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        warning "Release cancelled"
        exit 0
    fi
    
    # Run tests
    info "Running tests..."
    make ci || error "Tests failed. Fix issues before releasing."
    success "All tests passed"
    echo ""
    
    # Update CHANGELOG
    update_changelog "$new_version"
    
    # Create tag
    create_tag "$new_version"
    
    # Push changes
    push_changes "$new_version"
    
    echo ""
    success "Release $new_version completed!"
    echo ""
    info "GitHub Actions will now:"
    info "  1. Create a GitHub Release"
    info "  2. Generate release notes"
    info "  3. Attach artifacts"
    echo ""
    info "View release at: https://github.com/jaaparjazzery/aws-terraform-modules/releases/tag/$new_version"
}

# Run main function
main "$@"

