# Session Insights - 2026-01-30

## shinyapps.io Deployment Debugging

### Problem: "could not find function bs_theme"

**Error message:**
```
Error in bs_theme(...) : could not find function "bs_theme"
```

**Root Cause:** shinyapps.io's `shiny::loadSupport()` function automatically sources all files in an `R/` subdirectory **without loading package dependencies first**.

When deploying with an R/ directory:
1. shinyapps.io detects DESCRIPTION + R/ directory
2. `loadSupport()` sources R/*.R files before app.R runs
3. R/theme.R calls `bs_theme()` from bslib
4. bslib isn't loaded yet → crash

**Solution:** Rename `R/` to `src/` in deployment. `loadSupport()` only looks in `R/`.

---

### Problem: GitHub API Rate Limiting (403 errors)

**Error message:**
```
⚠ GitHub install failed: Failed to install 'unknown package' from GitHub:
  HTTP error 403.
  API rate limit exceeded for 34.203.76.245.
  Rate limit remaining: 0/60
```

**Root Cause:** Using `.Rprofile` to install spiralizer from GitHub during shinyapps.io startup.

The `.Rprofile` was:
- Executed multiple times during parallel package installation
- Each execution called `remotes::install_github()`
- Quickly exhausted GitHub's unauthenticated rate limit (60 requests/hour)

**Solution:** Don't use `.Rprofile` for package installation on shinyapps.io. Instead:
1. List only CRAN dependencies in DESCRIPTION
2. Use app.R fallback to source files directly

---

## shinyapps.io Deployment Best Practices

### Directory Structure That Works

```
inst/app/
├── app.R           # Entry point with fallback logic
├── config.yml      # Configuration
├── DESCRIPTION     # Type: Shiny with CRAN deps only
├── src/            # Source files (NOT R/)
│   ├── aaa-utils.R
│   ├── constants.R
│   └── ...
└── www/            # Static assets
```

### Key Rules

1. **Never use `R/` subdirectory** - `loadSupport()` will source it without loading dependencies
2. **Never use `.Rprofile`** - Executes chaotically during parallel package installation
3. **Never rely on GitHub Remotes** - Rate limiting and unreliable on shinyapps.io
4. **Always use `Type: Shiny`** in DESCRIPTION - Tells shinyapps.io this is an app, not a package

### Robust app.R Pattern

```r
# Try package first, fall back to sourcing files
package_loaded <- tryCatch({
  library(mypackage)
  TRUE
}, error = function(e) {

  FALSE
})

if (!package_loaded) {
  # Load ALL dependencies explicitly
  library(shiny)
  library(bslib)
  # ... all other deps

  # Source from src/ (not R/)
  for (f in c("file1.R", "file2.R")) {
    source(file.path("src", f))
  }
}

# Run app
my_app()
```

---

## Deployment Script Pattern

```r
# deploy.R key steps:

# 1. Create Type: Shiny DESCRIPTION (CRAN deps only, no Remotes)
desc_content <- 'Type: Shiny
Imports:
    shiny,
    bslib,
    ...'

# 2. Copy R files to src/ (NOT R/)
file.copy("R/app.R", "inst/app/src/app.R")

# 3. Clean up any old R/ directory
if (dir.exists("inst/app/R")) unlink("inst/app/R", recursive = TRUE)

# 4. Deploy from inst/app
rsconnect::deployApp(appDir = "inst/app", ...)
```

---

## Files Modified This Session

| File | Changes |
|------|---------|
| `inst/scripts/deploy.R` | Complete rewrite - src/ instead of R/, no .Rprofile |
| `inst/app/app.R` | Robust fallback with all library() calls, sources from src/ |
| `.github/workflows/deploy-shiny.yaml` | Calls deploy.R script, retry logic, concurrency control |
| `inst/app/.rscignore` | New file - excludes renv files |

---

## Debugging Commands

```bash
# Check GitHub Actions deployment status
gh run list --workflow="deploy-shiny.yaml" --limit 3

# View deployment logs
gh run view <run-id> --log

# Check shinyapps.io logs (via web dashboard)
# https://www.shinyapps.io/admin/#/application/<app-id>/logs
```
