# Math105

Source files stay in LaTeX. GitHub Actions builds both PDF and HTML output and publishes the HTML site with GitHub Pages.

## Local build

```bash
./scripts/build.sh
```

Generated files are written to `site/`.

## Published output

After pushing to `main`, GitHub Actions builds and deploys:

- HTML pages at `https://<username>.github.io/Math105/Part1/<file>.html`
- PDF downloads at `https://<username>.github.io/Math105/Part1/<file>.pdf`

The root `index.html` is generated automatically with links to all built lessons.

## Notes

- Standalone lesson `.tex` files are built from subdirectories like `Part1/`.
- Shared support files like `105Notes.tex` at the repo root are not built directly.
- GitHub Pages should be configured to deploy from GitHub Actions.
- GitHub Actions uses a prebuilt container image with Pandoc and TeX already installed, so normal page builds do not reinstall TeX Live every run.
- If you update the toolchain, edit `.github/docker/build-env.Dockerfile` and let the `Build Build Image` workflow publish a refreshed image to GHCR.
