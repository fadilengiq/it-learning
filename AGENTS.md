# Base44 development notes

- This is a static HTML/CSS/JavaScript site; no build, database, or external credentials are needed.
- `docker-compose.base44.yml` serves the bind-mounted repo with a live-reload server on port 3000. Editing source files should update the preview without rebuilding the image.
- Check `/` and a lesson page such as `/computer-basics.html` to verify the site. Lesson completion is stored in the browser's localStorage, not a backend.
