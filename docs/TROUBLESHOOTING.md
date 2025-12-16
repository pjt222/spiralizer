# 🔧 Spiralizer Troubleshooting Guide

## 🚨 Common Issues & Solutions

### 1. R Version & renv Issues

#### Problem: "This project is configured to use R version X but Y is currently being used"
```
Warnmeldung: This project is configured to use R version '4.1.3', but '4.5.0' is currently being used.
```

**Solution:**
```r
# Update renv to use current R version
Rscript -e "source('.Rprofile'); renv::snapshot()"
```

#### Problem: renv version mismatch
```
renv 1.1.4 was loaded from project library, but this project is configured to use renv 0.15.4
```

**Solution:**
```r
# Record the new renv version
renv::record("renv@1.1.4")
# OR restore old version
renv::restore(packages = "renv")
```

### 2. Package Installation Issues

#### Problem: "es gibt kein Paket namens 'X'" (package not found)
**Solution:**
```r
# Always source .Rprofile first!
source('.Rprofile')
renv::install('package_name')
```

#### Problem: "Fehler: package 'cxhull' is not available" with tessellation
**Root Cause:** Both tessellation and cxhull were archived from CRAN in March 2025.

**Complete Solution:**
```r
source('.Rprofile')
# Install in correct order:
renv::install('remotes')          # For GitHub installs
renv::install('stla/cxhull')      # Required dependency first
renv::install('stla/tessellation') # Main package second
renv::snapshot()                  # Update lockfile
```

#### Problem: "konnte Funktion '%>%' nicht finden" (pipe operator not found)
**Solution:**
```r
# Add magrittr to app dependencies
library(magrittr)
# Or use native pipe |> instead of %>%
```

#### Problem: tessellation package not available on CRAN
**Note:** As of March 2025, both tessellation and cxhull packages were archived from CRAN.

**Solution:**
```r
# Install remotes first if needed
renv::install('remotes')

# Install dependencies from GitHub
renv::install('stla/cxhull')     # Required dependency
renv::install('stla/tessellation')

# Alternative using remotes directly:
remotes::install_github('stla/cxhull')
remotes::install_github('stla/tessellation')
```

### 3. Running the App

#### Problem: Rscript command not found in WSL
**Solution:**
```bash
# Use full path to R installation
"/path/to/R/bin/Rscript.exe" script.R
# Or add R to your PATH environment variable
```

#### Problem: --vanilla flag breaks renv
**Solution:**
```bash
# NEVER use --vanilla with renv projects!
# Bad: Rscript --vanilla -e "..."
# Good: Rscript -e "source('.Rprofile'); ..."
```

#### Problem: "'free' not found" on Windows
**Root Cause:** Unix commands like `free` don't exist on Windows.

**Solution:**
```r
# Fixed in performance.R with Windows detection
if (.Platform$OS.type == "windows") {
  # Use Windows-compatible fallbacks
}
```

#### Problem: "Failed to warm cache" on startup
**Root Cause:** Functions not loaded before cache warming attempted.

**Solution:**
```r
# Load utilities before cache warming
source("R/utils/spiral_math.R")      # Load first
source("R/utils/cache_manager.R")    # Then cache manager
warm_cache()                         # Finally warm cache
```

#### Problem: "qhull input error: not enough points to construct initial simplex"
**Error:**
```
QH6214 qhull input error: not enough points(3) to construct initial simplex (need 4)
```

**Root Cause:** The tessellation package uses qhull for Delaunay/Voronoi computation. qhull requires at least 4 non-collinear points for 2D triangulation.

**Solution:**
```r
# Ensure minimum point count is at least 10 (provides safety margin)
# In config.yml:
spiral:
  min_points: 10
sliders:
  density_min: 10

# The UI slider minimum prevents users from selecting < 10 points
```

### 4. Shiny App Issues

#### Problem: App won't start locally
**Solution:**
```r
# Check all dependencies are installed
source('.Rprofile')
renv::status()
renv::restore()  # If packages are missing

# Run with explicit port
shiny::runApp('app.R', port = 3838, host = '0.0.0.0')
```

#### Problem: Modules not found
**Solution:**
```r
# Use here package for reliable paths
library(here)
source(here::here("R/modules/ui_controls.R"))
```

### 5. Deployment Issues

#### Problem: rsconnect not configured
**Solution:**
```r
# 1. Create account at shinyapps.io
# 2. Get token from Account > Tokens
# 3. Configure:
rsconnect::setAccountInfo(
  name = 'your_account_name',
  token = 'your_token',
  secret = 'your_secret'
)
```

#### Problem: Deployment fails with missing packages
**Solution:**
```r
# Ensure all packages are in renv.lock
renv::snapshot()

# For GitHub packages, may need to specify in DESCRIPTION or manually
```

### 6. Performance Issues

#### Problem: Slow computation
**Solution:**
```r
# Check cache is working
source("R/utils/cache_manager.R")
get_cache_stats()

# Clear cache if needed
clear_spiral_cache()

# Warm cache with common patterns
warm_cache()
```

### 7. File Path Issues

#### Problem: Files not found after modularization
**Solution:**
```r
# Project structure for deployment:
spiralizer/
├── app.R              # Main entry point
├── R/
│   ├── modules/       # Shiny modules
│   └── utils/         # Utility functions
└── www/               # Static assets
    ├── css/
    └── js/
```

### 8. JavaScript/CSS Not Loading

#### Problem: Custom CSS/JS not applied
**Solution:**
```r
# Ensure www folder structure is correct
# Files in www/ are automatically served
# Reference as: href = "css/theme.css"
# Not: href = "www/css/theme.css"
```

## 🛠️ Debugging Commands

### Check R and Package Status
```bash
# Check R version
Rscript -e "R.version.string"

# Check renv status
Rscript -e "source('.Rprofile'); renv::status()"

# List installed packages
Rscript -e "source('.Rprofile'); installed.packages()[,'Package']"
```

**Note:** On Windows with WSL, you may need to use the full path to Rscript.exe

### Test Individual Components
```r
# Test spiral generation
source('.Rprofile')
source('R/utils/spiral_math.R')
points <- generate_fermat_spiral(0, 100, 300)
str(points)

# Test caching
source('R/utils/cache_manager.R')
get_cache_stats()
```

### Run Tests
```bash
# Run all tests
Rscript -e "source('.Rprofile'); testthat::test_dir('tests/testthat')"

# Run benchmarks
Rscript tests/benchmarks/benchmark_spiral.R
```

## 📝 Key Learnings

1. **ALWAYS source .Rprofile** when using renv
2. **NEVER use --vanilla** flag with Rscript in renv projects
3. **Use full paths** for Rscript.exe in WSL
4. **Check renv::status()** when packages seem missing
5. **tessellation** is a GitHub-only package (stla/tessellation)
6. **Use here::here()** for reliable file paths
7. **www/ folder** contents are automatically served by Shiny

## 🔍 Useful Diagnostic Functions

```r
# Check session info
sessionInfo()

# Check loaded packages
loadedNamespaces()

# Check search path
search()

# Check current working directory
getwd()

# List files in project
list.files(recursive = TRUE)

# Check shinyapps.io accounts
rsconnect::accounts()

# Check deployment history
rsconnect::deployments(".")
```

## 🚀 Quick Fixes

### Reset Everything
```bash
# Nuclear option - start fresh
rm -rf renv/library
Rscript -e "source('.Rprofile'); renv::restore()"
```

### Update All Packages
```r
source('.Rprofile')
renv::update()
renv::snapshot()
```

### Fix GitHub API Rate Limit
```r
# Set GitHub PAT for higher rate limits
Sys.setenv(GITHUB_PAT = "your_github_personal_access_token")
```

## 📱 Platform-Specific Issues

### Windows/WSL
- Use full paths to R installation when needed
- Line ending issues: use dos2unix if needed
- Path separators: R handles both / and \

### Memory Issues
```r
# Increase memory limit (Windows)
memory.limit(size = 16000)  # 16GB

# Check memory usage
gc()
memory.size()
```

## 🎯 Remember

- Use descriptive variable names (as per coding guidelines)
- Test locally before deploying
- Keep renv.lock updated with renv::snapshot()
- Document any new issues found!
- Set up proper deployment credentials before publishing

## ✅ Current Working State (Updated)

### Successfully Fixed Issues:
1. **Windows compatibility** - Performance monitoring works on Windows
2. **Package installation** - All dependencies properly installed via renv
3. **Cache warming** - Functions load in correct order
4. **Pipe operators** - magrittr library loaded
5. **Module loading** - Proper sourcing sequence established

### Ready to Run Commands:
```r
# From RStudio (recommended):
source("R/app.R")

# Check all is well:
renv::status()  # Should show "No issues found"
```

### App Features Confirmed Working:
- 🌀 Zen dark theme loads
- ⚡ Performance monitoring active
- 🎨 Cache warming completes successfully  
- 💨 All modules load without errors
- 🔥 Voronoi generation functional

---
*Last updated: During the Zen transformation 🌀*