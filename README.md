# iOS Shortcut Download Backend

This repository contains a simple Flask backend that lets an iOS/iPadOS Shortcut download your project folders as ZIP archives.

## Features

- `GET /` shows a web page with available projects
- `GET /projects.json` returns a JSON list of project names
- `GET /download?project=<name>` returns a ZIP file for the selected project
- `GET /download/<name>` returns the same ZIP archive

## Local Setup

1. Install Python and pip.
2. Create a virtual environment (optional but recommended):
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```
3. Install dependencies for the Flask backend (optional):
   ```bash
   pip install -r requirements.txt
   ```
4. Build the static site and ZIP archives:
   ```bash
   python build.py
   ```
5. Preview locally using a static server:
   ```bash
   python -m http.server --directory public 8000
   ```
6. Open `http://localhost:8000/` in your browser.

## Cloudflare Pages Deployment

This project can be hosted on Cloudflare Pages as a static site.

1. Connect your Git repository to Cloudflare Pages.
2. Set the build command to:
   ```bash
   python build.py
   ```
3. Set the output directory to:
   ```text
   public
   ```
4. Push changes to your repository. Cloudflare Pages will run the build and publish the static site.

## Adding or updating projects

1. Add a new folder under `projects/`.
2. Run:
   ```bash
   python build.py
   ```
3. If using Cloudflare Pages, commit and push the changes. Pages will rebuild automatically.

Example folder structure:

```
projects/
  my-first-project/
    README.txt
    code.txt
  another-project/
    script.js
```

## Shortcut usage

Use the project list JSON endpoint to let the Shortcut choose which project to install.

1. Fetch the project list from:
   ```text
   https://your-domain.com/projects.json
   ```
2. Use the Shortcut action **Get Contents of URL** and parse the JSON.
3. Present the `projects[].name` values to the user with **Choose from List**.
4. Build the download URL:
   ```text
   https://your-domain.com/downloads/<chosen-project>.zip
   ```
5. Download the chosen ZIP and save it.

### Example Shortcut flow

- Get Contents of URL: `https://your-domain.com/projects.json`
- Get Dictionary Value: `projects`
- Choose from List: `projects[].name`
- Text: `https://your-domain.com/downloads/[Chosen Item].zip`
- Get Contents of URL: download the ZIP
- Save File: save to iCloud Drive or Files

## Shortcut helper file

See `SHORTCUTS.md` for a ready-made iOS Shortcut workflow that lists projects and installs the selected one.
