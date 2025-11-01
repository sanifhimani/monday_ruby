# Documentation

Documentation for monday_ruby, built with [VitePress](https://vitepress.dev/) following the [Diátaxis](https://diataxis.fr/) framework.

## Development

```bash
cd docs
npm install
npm run dev
```

Visit `http://localhost:5173/monday_ruby/`

## Building

```bash
npm run build
```

## Documentation Structure

The documentation follows the Diátaxis framework with four distinct sections:

### 1. Tutorial (Learning-oriented)
- **Purpose**: Help beginners learn by building something
- **Location**: `/tutorial/`
- Takes users through their first integration step-by-step

### 2. How-to Guides (Problem-oriented)
- **Purpose**: Show how to solve specific problems
- **Location**: `/guides/`
- Task-based guides for common scenarios

### 3. API Reference (Information-oriented)
- **Purpose**: Technical description of the API
- **Location**: `/reference/`
- Complete documentation of all resources and methods

### 4. Explanation (Understanding-oriented)
- **Purpose**: Clarify concepts and design decisions
- **Location**: `/explanation/`
- Deep dives into architecture and best practices

## Adding New Pages

### Creating a New Page

1. Create a markdown file in the appropriate directory:
   ```
   docs/guides/my-guide.md
   docs/reference/resources/my-resource.md
   ```

2. Add to navigation in `docs/.vitepress/config.mjs`:
   ```js
   {
     text: 'My Guide',
     link: '/guides/my-guide'
   }
   ```

### Page Templates

See `DOCS_PLANNING.md` in the repository root for templates and guidelines.

## Deployment

Docs auto-deploy to GitHub Pages when you push to `main`.

Live at: `https://sanifhimani.github.io/monday_ruby/`

## Writing Guidelines

- **Professional tone** — No excessive enthusiasm or emojis
- **Clear and concise** — Short sentences, active voice
- **Complete examples** — All code should be runnable
- **Consistent terminology** — Follow monday.com's terms

See `DOCS_PLANNING.md` for complete guidelines.
