# Test the exact release archive, not an implicitly rebuilt approximation.
archive <- ".github/ci/fitdistrBayes_0.8.0.tar.gz"
manifest <- read.dcf(".github/ci/archive.dcf")
stopifnot(file.exists(archive),
          identical(unname(tools::md5sum(archive)), unname(manifest[1, "MD5"])),
          file.info(archive)$size == as.numeric(manifest[1, "Bytes"]))
dir.create("check", showWarnings = FALSE)
platform <- Sys.getenv("FDB_CI_PLATFORM")
info <- capture.output({
  cat("Platform:", platform, "\n")
  cat("Archive SHA256 (manifest, transport verified by MD5):", manifest[1, "SHA256"], "\n")
  cat("Archive MD5:", unname(tools::md5sum(archive)), "\n")
  cat("Archive bytes:", file.info(archive)$size, "\n")
  cat("Git commit:", Sys.getenv("GITHUB_SHA"), "\n")
  print(sessionInfo())
  print(capabilities())
  print(.Machine[c("double.eps", "sizeof.longdouble", "longdouble.digits")])
  for (pkg in c("survival", "posterior", "loo", "rcmdcheck"))
    cat(pkg, as.character(packageVersion(pkg)), "\n")
})
writeLines(info, "check/environment.txt")
writeLines(info)
if (identical(platform, "nold"))
  stopifnot(identical(unname(capabilities("long.double")), FALSE))

checked <- rcmdcheck::rcmdcheck(archive,
  args = c("--as-cran", "--run-donttest", "--no-manual", "--install-args=--build"),
  error_on = "never", check_dir = "check")
saveRDS(checked, "check/rcmdcheck-result.rds")
summary <- capture.output({
  cat("Errors:", length(checked$errors), "\nWarnings:", length(checked$warnings),
      "\nNotes:", length(checked$notes), "\n")
  print(checked)
})
writeLines(summary, "check/summary.txt")
writeLines(summary)
if (length(checked$errors) || length(checked$warnings))
  stop("The release archive failed R CMD check; see preserved results.")
