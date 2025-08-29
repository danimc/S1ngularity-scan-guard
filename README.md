# 🚨 URGENT s1ngularity VERIFICATION

## RUN NOW (One command line)

```bash
chmod +x s1ngularityCheck.sh && ./s1ngularityCheck.sh
```

## EXPECTED RESULTS

### GOOD

``` bash
FINAL RESULT: YOUR MACHINE APPEARS TO BE CLEAN
```

### ATTENTION

``` bash
⚠️ WARNING: NX dependencies detected
Your machine remains vulnerable to future attacks
```

### 🚨 EMERGENCY

``` bash
🚨 FINAL RESULT: POSSIBLE COMPROMISE DETECTED
ACTION REQUIRED: Contact security team immediately
```

## 🎯 What does the script do?

- ✅ **Scans ALL Git repositories** 
- ✅ **Searches for malicious files** (`/tmp/inventory.txt`)
- ✅ **Verifies shell profiles** (`.zshrc`, `.bashrc`)
- ✅ **Detects compromised repositories**
- ✅ **Identifies vulnerable NX/Lerna dependencies**
- ✅ **Cleans caches** (npm, yarn, pnpm)
- ✅ **Safe execution** - Does NOT modify source code

## Customizing Search Directories

**For performance reasons**, the script searches for `package.json` files only in common development directories:

- `~/Documents`
- `~/Desktop`
- `~/Projects`
- `~/src`
- `~/dev`
- `~/workspace`
- `~/code`

### 🔧 To add more directories:

If your projects are in different locations, edit line ~192 in `s1ngularityCheck.sh`:

```bash
PACKAGE_FILES=$(find ~/Documents ~/Desktop ~/Projects ~/src ~/dev ~/workspace ~/code ~/YOUR_DIRECTORY -name "node_modules" -prune -o -name "package.json" -type f -print 2>/dev/null | head -100)
```
