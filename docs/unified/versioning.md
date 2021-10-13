# API Versioning

This section describes how to version APIs.
It describes API’s lifecycle states, enumerates versioning policy, describes backwards compatibility related guidelines and describes an End-Of-Life policy.

---

## API Versioning Strategy

APIs should be designed so that they are extensible and backward compatible.
An API is backward compatible if a new change to the API does not break existing API consumers.
This minimizes the work required for consumers to utilize new releases of the API services.

However, there are cases where API providers need to introduce breaking changes.
In such cases, API versioning provides the flexibility to roll out a new version of the API containing breaking changes.
The following strategies help consumers migrate to new versions of the API in an efficient and cost-effective manner.

## API Lifecycle

An API Version has its own lifecycle as it starts with planned improvements.
As it progresses through its maturity cycle, consumers test it, use it, and eventually migrate away from it.
Ultimately the API Version is replaced with an updated API and is retired from service.

|State|Description|
|-----|-----------|
|PLANNED|API has been scheduled for development. API release plans have been established.|
|BETA|API is operational and is available to selected new subscribers in production for the purposes of testing, validating, and rolling out a new API.|
|LIVE|API is operational and is available to new subscribers in production. API version is fully supported.|
|DEPRECATED|API is operational and available at runtime to existing subscribers for a fixed period of time. API version is fully supported, including bug fixes addressed in a backwards compatible way. API version is not available to new subscribers.|
|RETIRED|API is unpublished from production and no longer available at runtime to any subscribers. The footprint of all deployed applications entering this state must be completely removed from production and stage environments.|

## API Versioning Identification

APIs are versioned products and **MUST** adhere to the following versioning principles.

- API specifications **MUST** follow the versioning scheme where the `v` introduces the version, the major is an ordinal starting with 1 for the first LIVE release, and minor is an ordinal starting with 0 for the first minor release of any major release.
- Every time there is an incremental change to an API, whether or not backward compatible, the API specification **MUST** be versioned.
    - This allows the change to be labeled, documented, reviewed, discussed, published and communicated.
- API endpoints **MUST** only reflect the major version.
- API specification versions reflect interface changes and **MAY** be separate from service implementation versioning schemes.
- A minor API version **MUST** maintain backward compatibility with all previous minor versions, within the same major version.
- A major API version **MAY** maintain backward compatibility with a previous major version.
- For a given functionality set, there **MUST** be only one API version in the LIVE state at any given time across all major and minor versions. 
    - This ensures that subscribers always understand which versioned API product they should be using. For example, v1.2 RETIRED, v1.3 DEPRECATED, or v2.0 LIVE.

## Backwards API Compatibility

APIs **SHOULD** be designed in a forward and extensible way to maintain compatibility and avoid duplication of resources, functionality and excessive versioning.

APIs **MUST** adhere to the following principles to be considered backwards compatible:

- All changes **MUST** be additive.
- All changes **MUST** be optional.
- The semantics of an existing parameter, entire representation, or resource **MUST NOT** be changed.
- Existing URI attributes such as query parameter keys or path parameters **MUST NOT** be renamed.
- There **MUST NOT** be any change in the behavior of the API for request URIs without the newly added query parameters.
- Query-parameters and request body parameters **MUST** be unordered.
- All additional query parameters on resource URIs **MUST** be optional.
- Additional functionality for an existing resource **MUST** be implemented either:
    - As an optional extension, or
    - As an operation on a new child resource, or
    - By altering a request body, while still accepting all the previous, existing request variations, if an existing operation (e.g. resource creation) cannot be reasonably extended.
- The API implementation (service) **MUST** recognize a previously valid value for a request parameter and **SHOULD NOT** throw an error when used.
- There **MUST NOT** be any change in the HTTP status codes returned by the URIs.
- There **MUST NOT** be any change in the HTTP verbs (e.g. GET, POST, PUT or PATCH) supported earlier by the URI.
    - The URI **MAY** however support a new HTTP verb.
- There **MUST NOT** be any change in the name and type of the request or response headers of a URI.
    - Additional headers **MAY** be added, provided they’re optional.

### Backwards Payload Compatibility

Ensure that the previous JSON API schema is extensible.
There are simple traps in JSON that make an API contract impossible to evolve without making breaking changes.
One common pitfall is returning a raw JSON array from an API endpoint.
Without an object wrapper, there’s no ability to later add metadata like paging without breaking the contract.
Similarly, when working with international context (or expect to), use objects for monetary amounts in order to support adding currency without breaking the contract.
It is also common to use objects for strings (messages) which may need to be internationalized with additional locale-specific translations.

- An existing property in a JSON object of an API response **MUST** continue to be returned with the same name and JSON type (number, integer, string, array, object).
- If the value of a response field is an array, then the type of the contents in the array **MUST NOT** change.
- If the value of the response field is an object, then the compatibility policy **MUST** apply to the JSON object as a whole.
- New properties added to the request body **MUST NOT** be mandatory.
- If the property of an object is a URI, then it **MUST** have the same stability mentioned as URIs.
- For an API returning [HATEOAS](hypermedia.md) links as part of the representation, the values of rel and href **MUST** remain the same.
- For primitive types, unless there is a constraint described in the API documentation (e.g. length of the string, possible values for an ENUM type), clients **MUST** not assume that the values are constrained in any way.
- For ENUM types, there **MUST NOT** be any change in already supported enumerated values or meaning of these values.
- New properties **MAY** be added to a representation any time, but it **SHOULD NOT** alter the meaning of an existing property.
- New properties that are added **MUST NOT** be mandatory.
- Previously mandatory fields **MUST** be present in the response.

### Consumer Compatibility Guidelines

Being able to make changes to an API in a backward compatible manner requires that API providers add new fields and expect API consumers not to break when they do so.
API consumers need to follow these guidelines in order to support backward compatible API providers:

- Be tolerant with unknown fields in the payload (see Martin Fowler’s ["TolerantReader"](https://martinfowler.com/bliki/TolerantReader.html) post), that is to say, ignore deserialization of new fields but do not eliminate them from the payload if needed for subsequent PUT requests.
- Be prepared to handle HTTP status codes not explicitly specified in endpoint definitions.
- Follow the redirect when the server returns HTTP status code 301 (Moved Permanently)
- Support redirection in case a URL has to change 301 (Moved Permanently).

## Plan to Version

The following guidelines should be applied when breaking changes require a new version of the APIs:

- *Put the API version in the URL* – While header-based versioning is arguably more RESTful, it’s also less obvious.
  Keeping the version in the URL allows the API consumer to open it in a browser, send it in email, and bookmark it.
  It’s also immediately visible in logs.
- *Use only the major version* – API versioning **MUST** follow a scheme where the v introduces the version, and the major is an ordinal starting with 1 for the first release version.
  For example; http://api.example.com/v1/users.
  Minor versions **SHOULD NOT** be supported because it adds versioning overhead and brings no value to the API consumers.
- *Use a version number* – There are popular APIs who use a different identifier (e.g. Twilio uses a date).
  This is both less obvious and exposes information that should not matter to the API consumer.
- *Always start with a versioned URL* – It can seem convenient for an API provider to start without a version and only add it in when needed.
  The down side of this approach is that it’s less obvious, requires out-of-band information to be understood, and provides an inconsistent experience to API consumers.
  In the unlikely event that the API provider starts with an unversioned URL and later needs to version, they **SHOULD** treat the unversioned URL as an alias for v1, so that both URLs route to the same implementation.
- *Manage multiple concurrent versions as separate instances* – Multiple concurrent versions **SHOULD** be managed as separately running instances of a service with a router in front, rather than multiple versions managed concurrently in the same codebase.
  This approach avoids any accidental breaking changes of older versions while refactoring code.

When releasing a new version of the API, take this opportunity to re-evaluate the optionality of parameters and properties which have been added.
If there will be breaking changes, this is an opportunity to rationalize optional properties.
Removing legacy options, making the API clear, consistent and easy to use will benefit users while also simplifying code and removing accumulated tech debt.

## End of Life Policy

The End-of-Life (EOL) policy regulates how API versions move from the LIVE to the RETIRED state.
It is designed to ensure a consistent and reasonable transition period for API customers who need to migrate from the old to the new API version while enabling a healthy process to retire technical debt.

### Minor API Version EOL

Per versioning policy, minor API versions **MUST** be backwards compatible with preceding minor versions within the same major version.
Thus, minor API versions are RETIRED immediately after a newer minor version of the same major version becomes LIVE.
This change should have no impact on existing subscribers so there is no need to transition through a DEPRECATED state to facilitate client migration.

### Major API Version EOL

Per versioning policy, major API versions **MAY** be backwards compatible with preceding major versions.
As such, the following rules apply when retiring a major API version.

- A major API version **MUST NOT** be in the DEPRECATED state until a replacement service is LIVE that provides a clear customer migration path for all functionality that will be retained moving forward.
This **SHOULD** include documentation and, as appropriate, migration tools and sample code that provide customers what they need to make a clean migration.
- The deprecated API version **MUST** be in the DEPRECATED state for a minimum period of time to give client customers adequate notice to migrate.
Deprecation of API versions with external clients **SHOULD** be considered on a case-by-case basis and may require additional deprecation time and/or constraints to minimize impact on customer base.
- If a versioned API in LIVE or DEPRECATED state has no clients, it **MAY** move to the RETIRED state immediately.

### End of Life Policy: Replacement Major API Version Introduction

Since a new major API version that results in deprecation of a pre-existing API version is a significant business investment decision, API owners **MUST** justify the new major version before beginning significant design and development work.
API owners **SHOULD** explore all possible alternatives to introducing a new major API version with the objective of minimizing the impact on customers before deciding to introduce a new version.

Justification **SHOULD** include the following:

#### Business Case

- Customer value delivered by a new version that is not possible with the existing version.
- Cost-benefit analysis of deprecated version versus the new version.
- Explanation of alternatives to introducing a new major version and why those were not chosen.
- If a backwards incompatible change is required to address a critical security issue, items 1 and 2 (above) are not required.

#### API Design

- A domain model of all resources in the new API version and how they compare to the domain model of the previous major API version.
- Description of APIs operations and use cases they implement.
- Definition of service level objectives for performance and availability that are equal or better to the major API version to be deprecated.

#### Migration Strategy

- Number of existing customers impacted; internal, external, and partners.
- Communication and support plan to inform existing customers of new version, value, and migration path.

### Background

When defining your API, you must make a lot of material decisions that have long lasting implications.
The objective is to make a long-lived, durable, and reusable API.
You are trying to get it “right”.
Practically speaking, however, you are not going to succeed every time.
In fact, [evidence](https://hbr.org/2017/09/the-surprising-power-of-online-experiments) suggests you will be wrong more often then you are right.
New requirements come in.
Your understanding of the problem changes.
What probably looked like a good decision at the time, may now limit your ability to elegantly extend your API to satisfy your new understanding.
Lightweight decisions made in the past now seem somewhat heavy as the implications come into focus.
Maintaining backward compatibility is a persistent challenge.

One option is to create a new major version of your API.
This allows you to leave past decisions behind and start fresh.
Unfortunately, it also means that all of your clients now need to migrate to new endpoints for any of the new work to deliver customer value.
This is hard.
Many clients will not move without good incentives.
There is a lot of overhead in managing the customer migration.
You also need to support two sets of interfaces for quite some time.

The other consideration is that your API product may have multiple endpoints, but the breaking changes that you want to make only affect one.
Making your customers migrate their applications for all the API endpoints just so you can “fix” one small part is a pretty heavyweight and expensive change.
While pure and simple from a philosophical and engineering point of view, it is often unjustifiable from an ROI standpoint.
The goal of this guideline is to find a middle ground that provides a more practical path forward when minor changes are needed, but which is still consistent, in spirit, with the API Versioning Policy.

### Deprecation Process

As the API evolves, a need may arise to deprecate an API version, an API endpoint or a field in the API.
The goal of deprecation is to progress to a state in which there are no consumers using the version, endpoint or field to be deprecated.
Once this state is reached, the API version can be retired and removed from production.

The following requirements should be applied when deprecating an API;

- An API developer **SHOULD** be able to deprecate an API Element in a minor version of an API.
- An API specification **MUST** highlight one or more deprecated elements of the API so the API consumers are aware.
- An API provider **MUST** inform API consumers regarding deprecated elements present in request and/or response at runtime so that tools can recognize this, log warnings and highlight the usage of deprecated elements as needed.
- Deprecated API Elements **MUST** remain supported for the life of the major version.

The requirements listed above can be addressed by documenting deprecated elements via the API specification.
Listed below are a couple of examples that illustrate deprecation of elements when using [OpenAPI Specification 3.1](https://swagger.io/specification/)

### Deprecation Documentation

The most important part of deprecation is providing documentation for the user to understand what/when parts of the API will be deprecated.
The API Documentation must include not only what is being deprecated, but when.
The timeline should be selected to be sufficient to allow consumers to migrate their systems onto the new API.

#### Deprecating an HTTP Method

Deprecating an endpoint involves adding “deprecated: true” attribute to the endpoint method as shown below:

```yaml
openapi: 3.1
...
paths:
  /appeals:
    get:
      description: Deprecated endpoint to retrieve appeals
      deprecated: true
```

#### Deprecating a query parameter

```yaml
openapi: 3.1
...
paths:
  /appeals:
    get:
      description: Retrieve appeals status
      parameters:
        - name: fromDate
          in: query
          description: Deprecated Start date of appeal
          deprecated: true
```

#### Deprecating a header

```yaml
openapi: 3.1
...
paths:
  /appeals:
    get:
      description: Retrieve appeals status
      parameters:
        - name: ORG-Authorization-Token
          in: header
          description: Deprecated ORG-Authorization-Token Header
          deprecated: true
```

#### Deprecating a property in a resource

```yaml
openapi: 3.1
...
paths:
  /appeals:
    get:
      description: Retrieve appeals status
      responses:
        200:
          description: Successful Appeal
          content:
            application/json:
              schema:
                \$ref: "#/components/schemas/Appeal"
components:
  schemas:
    Appeal:
      description: Appeal status schema
      properties:
        appealType:
          type: string
          description: The decision review option chosen by the appellant
          deprecated: true
```

### Adding a Deprecation header

During the deprecation phase, the API provider should add a Deprecation HTTP response header.
See draft: [RFC Deprecation HTTP Header](https://tools.ietf.org/html/draft-dalal-deprecation-header)).
A Sunset HTTP response header can be added (see [RFC 8594](https://tools.ietf.org/html/rfc8594#section-3)) on a resource that will be deprecated.
The deprecation header can either be set to true if a feature is retired, or carry a deprecation timestamp, at which point a replacement will become available and consumers must not on-board any longer.

> NOTE: Applications consuming this header **MUST** not take any action based on the value of the header at this time.
Instead, we recommend that these applications **SHOULD** take action based only on the existence of the header in the response.

