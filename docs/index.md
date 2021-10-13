----

# API Style Guide Standards (DRAFT)

This is a draft REST API style guide created by the Digital Platform Strategy group that will enable development teams building APIs to provide a consistent experience for API consumers.
This document provides a comprehensive set of guidelines which fully specify how to document, build and interact with a REST API.

By following this guide, the APIs should be:

- Easy to understand and learn
- General and abstracted from specific implementation and use cases
- Robust and easy to use
- Have common look and feel
- Follow a consistent RESTful style and syntax
- Consistent with other teams’ REST APIs and the Organization’s global architecture

> Note: For the remainder of the document, unless specifically noted, when we mention “API” we mean “REST API.”

## Intended Audience

This document is for architects and developers responsible for building APIs and provides base-level guidance on RESTful API and style for the contracts.
If there are any questions around design standards, please refer back to this guide.

## Existing APIs

By adhering to the API standards outlined in this document, APIs across the Organization should provide a consistent experience for consumers.
However, it is expected that pre-existing APIs and clients might not receive the same experience due to outdated API standards.
Given that these guidelines are expected to evolve, the following rules apply:

- Existing APIs don’t have to be changed, but change is recommended
  - If an existing API is publicly available externally, it is required to provide an API which adheres to current guidelines.
- New clients of existing APIs based on outdated rules (inconsistent experience) should trigger the creation of an updated API conformant with the API Styleguide
  - This could be a façade API which proxies requests to the existing API.
Normal Evolutionary Architecture principles may be applied to migrate clients to the new (conformant) API.
- New APIs are required to adhere to current guidelines.

> Note: APIs conforming to specific industry standards (e.g. FHIR) are expected to follow the above rules unless in direct conflict with the specific standard.

## Types of APIs

In general, APIs generally fall into one of two categories:

1. Domain APIs (aka Process APIs) – core services that expose data and capabilities
2. Experience APIs (aka Backend for Frontends or BFFs) – specific APIs for channels (mobile, web, customer gateways, etc.)

This style guide focuses only on Domain APIs (1).
Experience APIs (2) are often presentation focused and optimized for different use cases such as flexibility in data retrieval or mobile device battery performance.

This style guide does not distinguish between internal and external APIs primarily because all Domain APIs should be built with a view towards being externalizable.
That is, always build internal APIs as if they were external APIs.

Domain APIs within the Organization should follow the RESTful architectural style.
To support this objective, this guide outlines a set of rules, standards, and conventions to follow that apply to RESTful API design.
