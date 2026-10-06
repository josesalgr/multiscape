# Run from the repository root after installing development dependencies.
build_multiscape_site <- function() {
  # pkgdown regenerates HTML and Markdown companions (including LLM docs).
  # Keep the canonical root Markdown license even if rendering fails.
  on.exit(unlink(file.path("docs", "LICENSE.md")), add = TRUE)
  pkgdown::build_site(preview = FALSE)
  dir.create(file.path("docs", "reference", "figures"), showWarnings = FALSE, recursive = TRUE)
  invisible(file.copy(list.files(file.path("man", "figures"), pattern = "meseta-.*[.]png$", full.names = TRUE),
    file.path("docs", "reference", "figures"), overwrite = TRUE))
  dir.create(file.path("docs", "examples"), showWarnings = FALSE, recursive = TRUE)
  invisible(file.copy(list.files("examples", full.names = TRUE),
    file.path("docs", "examples"), overwrite = TRUE))
}
build_multiscape_site()
