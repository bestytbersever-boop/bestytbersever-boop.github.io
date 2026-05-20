# iOS Shortcut Setup for Project Downloads

This repository provides a `projects.json` endpoint and static ZIP download links.

## What the Shortcut should do

1. Request the list of available projects:
   - URL: `https://your-domain.com/projects.json`
2. Parse the JSON response.
3. Show the project names to the user.
4. Build the chosen download URL:
   - `https://your-domain.com/downloads/<project-name>.zip`
5. Download the selected ZIP file.
6. Save the file in Files or iCloud Drive.

## Shortcut actions

- Get Contents of URL
  - URL: `https://your-domain.com/projects.json`
  - Method: GET
  - Response: JSON
- Get Dictionary Value
  - Key: `projects`
- Repeat with Each (if needed) or Choose from List
  - Input: `projects`
  - Select: `item.name`
- Text
  - `https://your-domain.com/downloads/[Chosen Item].zip`
- Get Contents of URL
  - URL: from the Text action
- Save File
  - Destination: iCloud Drive or On My iPad

## Example URL format

- `https://your-domain.com/downloads/my-first-project.zip`
- `https://your-domain.com/downloads/second-project.zip`

## Notes

- The build script creates `projects.json` and ZIP files for every folder in `projects/`.
- On Cloudflare Pages, the site is static and updates whenever you commit new project folders.
