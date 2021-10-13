# API Style Guide Tech Docs

The API Style Guide is in the docs directory.
There is an `./docs/index.md` file which contains an overview of the API Styleguide.

In addition, each sub-section of the documentation is in the `./docs/unified` folder.
The content was split into sections to allow easy reordering and reuse of the content, depending on the context.
The overall document structure is defined in the `./mkdocs.yml` file.

## Backstage integration

The documentation structure, and the choice of [MkDocs](https://mkdocs.org), is intended to follow conventions required by [Backstage](https://backstage.io) for inclusion as TechDocs.
The `./catalog-info.yaml` file provides metadata that allows the repo to be registered with Backstage as a source of TechDocs.

## Viewing documentation

There are a few different methods for viewing the documentation.
The easiest is if you have a helpful IDE that provides a rendered view of the Markdown (i.e. VS Code, Intellij)

Another option is to use the MkDocs server-mode to display the docs.
This can be invoked via a gradle task: `./gradlew serveDocs`
Then open `http://127.0.0.1:8000/` in your browser to see the documentation.

## Single-file document

There is also a Gradle task `generateMarkdownDoc` which uses the `./docs/styleguide.mdx` file as an index for constructing a full document.
The `.mdx` file is just a list of filenames with optional numerical heading offset (i.e. 1, 2).  
The offset will increase the headings in the file when output to the full document.
Note, this is similar to capabilities in Asciidoc, except the script only supports positive heading offsets.
