# Digic Sim — Landing Page

A responsive, static product landing page for the Digic Sim digital logic simulator. Built using plain HTML, CSS, and JavaScript, with no framework or build step.

## Preview

Open `index.html` in your browser, or run a local server from the project directory:

```bash
python3 -m http.server 8000
```

Then visit http://localhost:8000.

## Configure your links

Edit the `CONFIG` object at the top of **`script.js`**:

```js
const CONFIG = {
  appUrl: 'https://digic-sim.web.app',
  githubUrl: 'https://github.com/carbonanik/digic-sim',
};
```

The Launch buttons link to the live simulator at `https://digic-sim.web.app`. The GitHub links point to the [Digic Sim repository](https://github.com/carbonanik/digic-sim).

## Publish using GitHub Pages

1. Upload the **contents** of this folder to the root of your repository (or place the files in `/docs` and select that folder).
2. In GitHub, open **Settings → Pages**.
3. Under **Build and deployment**, select **Deploy from a branch**.
4. Choose your main branch and `/ (root)` (or `/docs`) and save.
5. Wait for GitHub to show your published URL.

No `npm install`, build command, or backend is required. Asset paths are relative and work on GitHub Pages project paths.

## Customize

- `index.html`: text, sections, SEO and accessibility metadata
- `styles.css`: theme, components and responsive styles
- `script.js`: URLs, mobile menu, interactive signal demo and scroll reveals
- `assets/simulator.png`: screenshot of the real Digic Sim application
- `assets/logic-lab-banner.png`: share preview image (AI-generated promotional graphic)
- `assets/favicon.svg`: brand favicon

**Note:** The visual wire demo is an interactive landing-page illustration, not a connection to the Flutter simulation engine. AI circuit generation is optional in the app, and requires a Gemini API key.
