import html
import json
import os
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJECTS_DIR = os.path.join(ROOT, "projects")
PUBLIC_DIR = os.path.join(ROOT, "public")
DOWNLOADS_DIR = os.path.join(PUBLIC_DIR, "downloads")


def list_projects():
    if not os.path.isdir(PROJECTS_DIR):
        return []
    return sorted(
        [name for name in os.listdir(PROJECTS_DIR) if os.path.isdir(os.path.join(PROJECTS_DIR, name))]
    )


def ensure_dirs():
    os.makedirs(PUBLIC_DIR, exist_ok=True)
    os.makedirs(DOWNLOADS_DIR, exist_ok=True)


def clean_downloads():
    if not os.path.isdir(DOWNLOADS_DIR):
        return
    for filename in os.listdir(DOWNLOADS_DIR):
        file_path = os.path.join(DOWNLOADS_DIR, filename)
        if os.path.isfile(file_path) and filename.lower().endswith(".zip"):
            os.remove(file_path)


def build_zip(project_name):
    src_dir = os.path.join(PROJECTS_DIR, project_name)
    zip_path = os.path.join(DOWNLOADS_DIR, f"{project_name}.zip")
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as bundle:
        for root, _, files in os.walk(src_dir):
            for filename in files:
                file_path = os.path.join(root, filename)
                archive_name = os.path.relpath(file_path, src_dir)
                bundle.write(file_path, archive_name)


def build_index(projects):
    page = [
        "<!doctype html>",
        "<html lang=\"en\">",
        "  <head>",
        "    <meta charset=\"utf-8\">",
        "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
        "    <title>Project Download Server</title>",
        "    <style>",
        "      body { font-family: Arial, sans-serif; margin: 2rem; background: #f7f7f7; color: #222; }",
        "      .card { background: white; border-radius: 12px; padding: 1.5rem; max-width: 760px; margin: auto; box-shadow: 0 18px 36px rgba(0,0,0,.08); }",
        "      h1 { margin-top: 0; }",
        "      a { color: #1d71b8; text-decoration: none; }",
        "      a:hover { text-decoration: underline; }",
        "      ul { padding-left: 1.2rem; }",
        "      .note { background: #eef6ff; border-left: 4px solid #1d71b8; padding: 1rem; margin: 1rem 0; }",
        "      code { background: #f3f3f3; padding: 0.25rem 0.4rem; border-radius: 4px; }",
        "    </style>",
        "  </head>",
        "  <body>",
        "    <div class=\"card\">",
        "      <h1>Project Download Server</h1>",
        "      <p>This site delivers project ZIP downloads for iOS/iPadOS Shortcuts and normal browser access.</p>",
        "      <div class=\"note\">",
        "        <strong>Shortcut-ready URL:</strong>",
        "        <code>/downloads/&lt;project-name&gt;.zip</code>",
        "      </div>",
        "      <h2>Available projects</h2>",
    ]
    if projects:
        page.append("      <ul>")
        for project in projects:
            safe_name = html.escape(project)
            page.append(
                f"        <li><strong>{safe_name}</strong> — <a href=\"downloads/{safe_name}.zip\">Download ZIP</a></li>"
            )
        page.append("      </ul>")
    else:
        page.extend([
            "      <p>No projects found yet. Add folders under <code>projects/</code>.</p>",
        ])

    page.extend([
        "      <h2>How to use</h2>",
        "      <p>Add a project folder in <code>projects/</code>, then run <code>python build.py</code> or push to Cloudflare Pages.</p>",
        "      <p>Example shortcut URL:</p>",
        "      <pre><code>https://your-domain.com/downloads/my-first-project.zip</code></pre>",
        "      <h2>API</h2>",
        "      <ul>",
        "        <li><code>/</code> — project list page</li>",
        "        <li><code>/projects.json</code> — JSON project list</li>",
        "        <li><code>/downloads/&lt;project-name&gt;.zip</code> — download ZIP</li>",
        "      </ul>",
        "    </div>",
        "  </body>",
        "</html>",
    ])
    with open(os.path.join(PUBLIC_DIR, "index.html"), "w", encoding="utf-8") as out:
        out.write("\n".join(page))


def build_projects_json(projects):
    output = {
        "projects": [
            {
                "name": project,
                "download": f"downloads/{project}.zip",
            }
            for project in projects
        ]
    }
    with open(os.path.join(PUBLIC_DIR, "projects.json"), "w", encoding="utf-8") as out:
        json.dump(output, out, indent=2)


def main():
    projects = list_projects()
    ensure_dirs()
    clean_downloads()
    for project in projects:
        build_zip(project)
    build_index(projects)
    build_projects_json(projects)
    print(f"Built {len(projects)} project(s) into {PUBLIC_DIR}")


if __name__ == "__main__":
    main()
