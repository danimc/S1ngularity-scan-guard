#!/bin/bash


set -e


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color


WAVE1_ISSUES=0
WAVE2_ISSUES=0
CLEANUP_SUCCESS=0

echo -e "${CYAN}🔍 s1ngularity Security Check Script${NC}"
echo -e "${CYAN}====================================${NC}"
echo ""
echo "This script verifies if your machine was compromised by the s1ngularity attack."
echo "Created to check for both known attack waves."
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Ensure you have internet connection and adequate permissions${NC}"
echo ""


log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅ OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠️  WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌ FAIL]${NC} $1"
    return 1
}


check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}



check_wave1() {
    echo -e "\n${CYAN}🚨 WAVE 1 VERIFICATION - Secret Exfiltration${NC}"
    echo "=============================================="
    

    log_info "Checking for suspicious local files..."
    if [[ -f "/tmp/inventory.txt" ]] || [[ -f "/tmp/inventory.txt.bak" ]]; then
        log_error "Found inventory.txt files in /tmp/ - MACHINE COMPROMISED"
        WAVE1_ISSUES=$((WAVE1_ISSUES + 1))
        ls -la /tmp/inventory.txt*
    else
        log_success "No suspicious inventory.txt files found"
    fi
    
    # Check 2: Search for s1ngularity related files
    log_info "Searching for s1ngularity related files..."
    SUSPICIOUS_FILES=$(find /tmp -name "*inventory*" -o -name "*s1ngularity*" 2>/dev/null | head -5)
    if [[ -n "$SUSPICIOUS_FILES" ]]; then
        log_error "Suspicious files found:"
        echo "$SUSPICIOUS_FILES"
        WAVE1_ISSUES=$((WAVE1_ISSUES + 1))
    else
        log_success "No s1ngularity related files found"
    fi
    

    log_info "Checking local AI tools..."
    AI_TOOLS_FOUND=""
    for tool in claude gemini q; do
        if check_command "$tool"; then
            AI_TOOLS_FOUND="$AI_TOOLS_FOUND $tool"
        fi
    done
    
    if [[ -n "$AI_TOOLS_FOUND" ]]; then
        log_warning "AI tools found:$AI_TOOLS_FOUND - Manually check for suspicious activity"
    else
        log_success "No AI CLI tools found installed"
    fi
    

    log_info "Inspecting shell profiles..."
    PROFILE_ISSUES=0
    
    for profile in ~/.bashrc ~/.zshrc; do
        if [[ -f "$profile" ]]; then
            if grep -q "sudo shutdown" "$profile" 2>/dev/null; then
                log_error "Malicious 'sudo shutdown' command found in $profile"
                WAVE1_ISSUES=$((WAVE1_ISSUES + 1))
                PROFILE_ISSUES=$((PROFILE_ISSUES + 1))
            fi
            
            if grep -E "(curl|wget|bash|sh).*s1ngularity" "$profile" >/dev/null 2>&1; then
                log_error "Suspicious scripts related to s1ngularity in $profile"
                WAVE1_ISSUES=$((WAVE1_ISSUES + 1))
                PROFILE_ISSUES=$((PROFILE_ISSUES + 1))
            fi
        fi
    done
    
    if [[ $PROFILE_ISSUES -eq 0 ]]; then
        log_success "Shell profiles clean - no malicious modifications"
    fi
    

    log_info "Checking GitHub repositories..."
    if check_command "gh"; then
        SUSPICIOUS_REPOS=$(gh repo list --limit 50 2>/dev/null | grep -i "s1ngularity" | head -3 || echo "")
        if [[ -n "$SUSPICIOUS_REPOS" ]]; then
            log_error "s1ngularity repositories found:"
            echo "$SUSPICIOUS_REPOS"
            WAVE1_ISSUES=$((WAVE1_ISSUES + 1))
        else
            log_success "No s1ngularity repositories found"
        fi
    else
        log_warning "GitHub CLI not installed - check manually at github.com"
    fi
}


check_wave2() {
    echo -e "\n${CYAN}🔍 WAVE 2 VERIFICATION - Repository Vandalism${NC}"
    echo "================================================"
    
    # Check 1: Verify local repositories
    log_info "Checking local repositories..."
    

    GIT_REPOS=$(find ~ -name ".git" -type d 2>/dev/null | sed 's/\/.git$//')
    
    if [[ -n "$GIT_REPOS" ]]; then
        # Count total repos found first
        TOTAL_REPOS=$(echo "$GIT_REPOS" | wc -l)
        log_info "Scanning $TOTAL_REPOS Git repositories..."
        
        while IFS= read -r repo; do
            if [[ -d "$repo" ]]; then
                echo "  📁 $repo"
                cd "$repo" 2>/dev/null || continue
                
            
                REMOTES=$(git remote -v 2>/dev/null | head -5)
                if echo "$REMOTES" | grep -i "s1ngularity" >/dev/null; then
                    log_error "Suspicious remote found in $repo"
                    echo "$REMOTES"
                    WAVE2_ISSUES=$((WAVE2_ISSUES + 1))
                fi
            fi
        done <<< "$GIT_REPOS"
        
        if [[ $WAVE2_ISSUES -eq 0 ]]; then
            log_success "No suspicious remotes found in $TOTAL_REPOS repositories"
        else
            log_error "Found suspicious remotes in $WAVE2_ISSUES repositories"
        fi
    else
        log_info "No local Git repositories found"
    fi
}

check_nx_vulnerability() {
    echo -e "\n${CYAN}⚡ NX VULNERABILITY CHECK${NC}"
    echo "=========================="
    
    log_info "Checking for NX dependencies..."
    

    NX_FOUND=0
    # Search in common development directories, avoiding node_modules and limiting results
    PACKAGE_FILES=$(find ~/Documents ~/Desktop ~/Projects ~/src ~/dev ~/workspace ~/code -name "node_modules" -prune -o -name "package.json" -type f -print 2>/dev/null | head -100)
    
    # Also check home directory root (non-recursive for common files)
    HOME_PACKAGES=$(find ~ -maxdepth 2 -name "package.json" -type f 2>/dev/null | head -20)
    if [[ -n "$HOME_PACKAGES" ]]; then
        PACKAGE_FILES="$PACKAGE_FILES$'\n'$HOME_PACKAGES"
    fi
    
    if [[ -n "$PACKAGE_FILES" ]]; then
      
        TOTAL_PACKAGES=$(echo "$PACKAGE_FILES" | wc -l)
        log_info "Scanning $TOTAL_PACKAGES package.json files..."
        
        while IFS= read -r package_file; do
            if [[ -f "$package_file" && -s "$package_file" ]]; then
                if grep -q '"@nx\|"nx\|"@nrwl\|"lerna"' "$package_file" 2>/dev/null; then
                    DIR=$(dirname "$package_file")
                    log_warning "NX/Lerna dependencies found in: $DIR"
                    
                
                    DEPS=$(grep -o '"@nx[^"]*"\|"nx[^"]*"\|"@nrwl[^"]*"\|"lerna[^"]*"' "$package_file" 2>/dev/null | tr '\n' ' ')
                    if [[ -n "$DEPS" ]]; then
                        echo "  📦 Dependencies: $DEPS"
                    fi
                    NX_FOUND=$((NX_FOUND + 1))
                fi
            fi
        done <<< "$PACKAGE_FILES"
        
        if [[ $NX_FOUND -eq 0 ]]; then
            log_success "No problematic NX dependencies found in $TOTAL_PACKAGES files"
        else
            log_warning "Found NX/Lerna in $NX_FOUND out of $TOTAL_PACKAGES projects"
        fi
    fi
    

    if check_command "nx"; then
        NX_VERSION=$(nx --version 2>/dev/null | head -1 || echo "unknown")
        log_warning "NX CLI installed globally - Version: $NX_VERSION"
    fi
}

cleanup_caches() {
    echo -e "\n${CYAN}🧹 CLEANUP - Cache Cleaning${NC}"
    echo "============================="
    

    if check_command "npm"; then
        log_info "Cleaning npm cache..."
        if npm cache clean --force >/dev/null 2>&1; then
            log_success "npm cache cleaned"
            CLEANUP_SUCCESS=$((CLEANUP_SUCCESS + 1))
        else
            log_warning "Error cleaning npm cache"
        fi
        
        if npm cache verify >/dev/null 2>&1; then
            log_success "npm cache verified"
        fi
    fi
    

    if check_command "yarn"; then
        log_info "Cleaning yarn cache..."
        if yarn cache clean >/dev/null 2>&1; then
            log_success "yarn cache cleaned"
            CLEANUP_SUCCESS=$((CLEANUP_SUCCESS + 1))
        else
            log_warning "Error cleaning yarn cache"
        fi
    fi
    

    if check_command "pnpm"; then
        log_info "Cleaning pnpm store..."
        if pnpm store prune >/dev/null 2>&1; then
            log_success "pnpm store cleaned"
            CLEANUP_SUCCESS=$((CLEANUP_SUCCESS + 1))
        else
            log_warning "Error cleaning pnpm store"
        fi
    fi
    
    if [[ $CLEANUP_SUCCESS -eq 0 ]]; then
        log_warning "No package managers found to clean"
    fi
}


generate_final_report() {
    echo -e "\n${CYAN}📋 FINAL SECURITY REPORT - s1ngularity${NC}"
    echo "========================================"
    

    echo -e "\n${BLUE}🖥️  System Information:${NC}"
    echo "  User: $(whoami)"
    echo "  Hostname: $(hostname)"
    echo "  OS: $(uname -s)"
    echo "  Date: $(date)"
    

    echo -e "\n${BLUE}📊 Verification Results:${NC}"
    echo ""
    printf "%-35s %-15s %-10s\n" "CHECK" "RESULT" "STATUS"
    printf "%-35s %-15s %-10s\n" "=====" "======" "======"
    

    if [[ $WAVE1_ISSUES -eq 0 ]]; then
        printf "%-35s %-15s ${GREEN}%-10s${NC}\n" "Wave 1 - Secret Exfiltration" "✅ No issues" "CLEAN"
    else
        printf "%-35s %-15s ${RED}%-10s${NC}\n" "Wave 1 - Secret Exfiltration" "❌ $WAVE1_ISSUES issues" "COMPROMISED"
    fi
    
    
    if [[ $WAVE2_ISSUES -eq 0 ]]; then
        printf "%-35s %-15s ${GREEN}%-10s${NC}\n" "Wave 2 - Repo Vandalism" "✅ No issues" "CLEAN"
    else
        printf "%-35s %-15s ${RED}%-10s${NC}\n" "Wave 2 - Repo Vandalism" "❌ $WAVE2_ISSUES issues" "COMPROMISED"
    fi
    

    if [[ $NX_FOUND -eq 0 ]]; then
        printf "%-35s %-15s ${GREEN}%-10s${NC}\n" "NX Vulnerability" "✅ No NX" "SECURE"
    else
        printf "%-35s %-15s ${YELLOW}%-10s${NC}\n" "NX Vulnerability" "⚠️  NX present" "VULNERABLE"
    fi
    
  
    if [[ $CLEANUP_SUCCESS -gt 0 ]]; then
        printf "%-35s %-15s ${GREEN}%-10s${NC}\n" "Cache Cleanup" "✅ Completed" "CLEAN"
    else
        printf "%-35s %-15s ${YELLOW}%-10s${NC}\n" "Cache Cleanup" "⚠️  Partial" "REVIEW"
    fi
    
    echo ""
    

    TOTAL_ISSUES=$((WAVE1_ISSUES + WAVE2_ISSUES))
    if [[ $TOTAL_ISSUES -eq 0 ]]; then
        echo -e "${GREEN}🎉 FINAL RESULT: YOUR MACHINE APPEARS TO BE CLEAN${NC}"
        echo -e "${GREEN}   No s1ngularity compromise indicators detected${NC}"
    else
        echo -e "${RED}🚨 FINAL RESULT: POSSIBLE COMPROMISE DETECTED${NC}"
        echo -e "${RED}   Found $TOTAL_ISSUES compromise indicators${NC}"
        echo -e "${RED}   ACTION REQUIRED: Contact security team immediately${NC}"
    fi
    
    if [[ $NX_FOUND -gt 0 ]]; then
        echo -e "\n${YELLOW}⚠️  WARNING: NX dependencies detected${NC}"
        echo -e "${YELLOW}   Your machine remains vulnerable to future attacks${NC}"
        echo -e "${YELLOW}   Recommendation: Migrate projects to eliminate NX dependencies${NC}"
    fi
       
    echo ""
    echo -e "${CYAN}Script completed. Keep this report for your records.${NC}"
}


main() {

    if [[ "$OSTYPE" != "darwin"* ]] && [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_warning "This script is optimized for macOS and Linux"
    fi
    
    check_wave1
    check_wave2
    check_nx_vulnerability
    cleanup_caches
    generate_final_report
    
 
    TOTAL_CRITICAL=$((WAVE1_ISSUES + WAVE2_ISSUES))
    exit $TOTAL_CRITICAL
}


main "$@"
