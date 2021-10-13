# Contributing

The developer workflow describes the development process, as well as how to navigate the project structure.

## Documentation guidelines

There are a few documentation guidelines that help ensure the generated documentation resembles what you intend.
MkDocs has some quirks (bugs??) that require specific practices in the documentation to avoid.
Our intention is to provide automated help via the linting, but that's still a work in progress.

In the meantime, follow these guidelines, and make sure you view the resulting output when you've completed updating the docs.

- Make sure there's a blank line between headings and the first paragraph
- Make sure there's a blank line between a paragraph and a list (ordered or unordered)
- Make sure each block identifies the type of content (i.e. bash, json, java, etc.)
- When in doubt, add a blank line between different content blocks

In addition to the MkDocs-specific rules, we also follow a few conventions to make diffs easier to grok.

- One line, one sentence.
This makes it easy to see what actually changed, avoiding spurious diffs due to paragraph reflow
- Actually, that's pretty much the only important convention we follow.

## Development Process

> Note: The gradle build dependencies are published in Github Packages. Make sure to create a PAT in Github and set that as the GITHUB_ACCESS_TOKEN environment variable.

> Note: Make sure you have the pre-commit hooks installed.
> ```bash
> pre-commit install
> ```

To make changes to the documentation, perform the following from the root of the project:

- Pull latest (assuming you've already cloned the repo):
    ```bash
    git pull origin main
    ```
- Update the documentation in the `docs/` directory
- Generate and serve the documentation (we use MkDocs)
    ```bash
    ./gradlew serveDocs
    ```
- Commit the updates
   ```bash
   git add -u .
   git commit -m "<commit message>"
   ```
   NOTE: you may have to resolve issues detected by the linting and secrets checking.

## Viewing documentation

There are a few different methods for viewing the documentation.
The easiest is if you have a helpful IDE that provides a rendered view of the Markdown (i.e. VS Code, Intellij)

Another option is to use the MkDocs server-mode to display the docs.
This can be invoked via a gradle task: `./gradlew serveDocs`
Then open `http://127.0.0.1:8000/` in your browser to see the documentation.

## Project Structure

The API Style Guide is in the `./docs` directory.
There is an `./docs/index.md` file which contains an overview of the API Styleguide.
In addition, each sub-section of the documentation is in the `./docs/unified` folder.

The content was split into sections to allow easy reordering and reuse of the content, depending on the context.
The overall document structure is defined in the `./mkdocs.yml` file.

```
project
│ .pre-commit-config.yaml
│ .gitignore
│ .talismanrc
│ build.gradle
│ catalog.yaml
│ gradle.properties
│ mkdocs.yml
│ README.md
│ settings.gradle
└─docs/
│  └─.gitignore
│  └─build.gradle
│  └─index.md
│  └─styleguide.mdx
│  └─unified
│     └─*.md
└─scripts/
   └─build.gradle
   └─generate-doc.sh
   └─generate-toc.sh
```
