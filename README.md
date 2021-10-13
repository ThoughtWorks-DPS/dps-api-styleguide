# API Style Guide Tech Docs

The API Style Guide is in the docs directory.
See the `CONTRIBUTING.md` file for advice on how to make updates to the documentation.

## Backstage integration

The documentation structure, and the choice of [MkDocs](https://mkdocs.org), is intended to follow conventions required by [Backstage](https://backstage.io) for inclusion as TechDocs.
The `./catalog-info.yaml` file provides metadata that allows the repo to be registered with Backstage as a source of TechDocs.

## Single-file document

Should you have a need for a single Markdown file, there is a custom Gradle task to generate a single file.
The task `generateMarkdownDoc` uses the `./docs/styleguide.mdx` file as an index for constructing a full document.
The `.mdx` file is just a list of filenames with optional numerical heading offset (i.e. 1, 2).  
The offset will increase the headings in the file when output to the full document.
Note, this is similar to capabilities in Asciidoc, except the script only supports positive heading offsets.
