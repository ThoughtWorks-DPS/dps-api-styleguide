# HTTP Methods, Headers, and Statuses

---

## Data Resources And HTTP Methods

Various business capabilities of an organization are exposed through APIs as a set of resources.

### Business Capabilities and Resource Modeling

Functionality **MUST NOT** be duplicated across APIs.
Resources (e.g. user account, credit card, etc.) are expected to be re-used as needed across use-cases.

### HTTP Methods

Most services will fall easily into the standard data resource model where primary operations can be represented by the acronym CRUD (Create, Read, Update, and Delete).
These map very well to standard HTTP verbs.

|HTTP Method|Description|
|-----------|-----------|
|GET|To retrieve a resource.|
|POST|To create a resource, or to execute a complex operation on a resource.|
|DELETE|To delete a resource.|
|PATCH*|To perform a partial update to a resource.|
|PUT|To update a resource.|

> NOTE: We recommend against using PATCH because of the potential complications arising from the semantics and race conditions of a partial record update.
> In general, we prefer using PUT to ensure atomic updates to a resource, and matching version numbers or last-updated timestamps to avoid race conditions. 
 
### Processing

The actual operation invoked **MUST** match the HTTP method semantics as defined in the table above.

- The GET method **MUST NOT** have side effects.
- It **MUST NOT** change the state of an underlying resource.
- The POST method **SHOULD** be used to create a new resource in a collection.
Example: To add a credit card on file, `POST https://api.example.com/v1/vault/credit-cards`
- Idempotency semantics: If this is a subsequent execution of the same invocation (including the `Idempotency-Key` header) and the resource was already created, then the request **SHOULD** be idempotent.
- The POST method **SHOULD** be used to create a new sub-resource and establish its relationship with the main resource.
Example: To refund a payment with transaction ID 12345: `POST https://api.example.com/v1/payments/12345/refund`
- The POST method **MAY** be used in complex operations, along with the name of the operation.
This is also known as the [controller pattern](https://learning.oreilly.com/library/view/RESTful+Web+Services+Cookbook/9780596809140/ch01.html#recipe-when-to-use-custom-http-methods) and is considered an exception to the RESTful model.
It is more applicable in cases when resources represent a business process, and operations are the steps or actions to be performed as part of it.
For more information, please refer to [section 2.6](https://learning.oreilly.com/library/view/RESTful+Web+Services+Cookbook/9780596809140/ch02.html#recipe-how-to-use-controllers) of the [RESTful Web Services Cookbook](https://learning.oreilly.com/library/view/RESTful+Web+Services+Cookbook/9780596809140).
- The PUT method **SHOULD** be used to update resource attributes or to establish a relationship from a resource to an existing sub-resource; it updates the main resource with a reference to the sub-resource.

Unless otherwise noted, request and response bodies **MUST** be sent using [JavaScript Object Notation (JSON)](http://json.org/).
JSON is a light-weight data representation for an object composed of unordered key-value pairs.
JSON can represent four primitive types (strings, numbers, booleans, and null) and two structured types (objects and arrays).
When processing an API method call, the following guidelines **SHOULD** be followed.

### Data Model

The data model for representation **MUST** conform to the JSON Data Interchange Format as described in [RFC 7159](https://tools.ietf.org/html/rfc7159).

### Serialization

- Resource endpoints **MUST** support `application/json` as content type.
- If an `Accept` header is sent and `application/json` is not an acceptable response, a `406 Not Acceptable` error **MUST** be returned.

### Input and Output Strictness

APIs **MUST** be strict in the information they produce, and they **SHOULD** be strict in what they consume as well.

Since we are dealing with programming interfaces, we need to avoid guessing the meaning of what is being sent to us as much as possible.
Given that integration is typically a one-time task for a developer and we provide good documentation, we need to be strict with using the data that is being received.
[Postel’s law](https://en.wikipedia.org/wiki/Robustness_principle) must be weighed against the many dangers of permissive parsing.

In order to improve developer experience, the APIs **SHOULD** provide feedback if we don’t understand the fields that the user is sending us.

## HTTP Header Policies

The purpose of HTTP headers is to provide metadata information about the body or the sender of the message in a uniform, standardized, and isolated way.

### Assumptions

Service Consumers and Service Providers:

- **SHOULD NOT** expect that a particular HTTP header is available.
  It is possible that an intermediary component in the call chain can drop an HTTP header.
  This is the reason business logic **SHOULD NOT** be based on HTTP headers.
- **SHOULD NOT** assume the value of a header has not been changed as part of HTTP message transmission.

Infrastructure Components (Web-services framework, Client invocation library, Enterprise Service Bus (ESB), Load Balancers (LB), etc.
involved in HTTP message delivery):

- **MAY** return an error based on availability and validity of a particular header without transmitting the message forward.
  For example, an authentication or authorization error for a request based on client identity and credentials.
- **MAY** add, remove, or change a value of an HTTP header.

### Policies

The guidelines below should be applied when adding HTTP headers to client requests or server responses.

- If available, HTTP standard headers **MUST** be used instead of creating a custom header.
- HTTP header names are NOT case sensitive.
- HTTP headers **SHOULD** only be used for the purpose of handling cross-cutting concerns such as Authorization.
- API implementations **SHOULD NOT** introduce or depend on headers.
- API implementations **MUST NOT** use headers in a way that changes the behaviour of HTTP methods
- API implementations **MUST NOT** use headers to communicate business logic or service logic (e.g. paging response info, PII query parameters)

### HTTP Standard Headers

These are headers defined or referenced from HTTP/1.1 specification ([RFC 7231](http://tools.ietf.org/html/rfc7231#page-33)).
Their purpose, syntax, values, and semantics are well-defined and understood by many infrastructure components.

#### `Accept`

This request header specifies the media types that the API client is capable of handling in the response.
Systems issuing the HTTP request **SHOULD** send this header.
Systems handling the request **SHOULD** NOT assume it is available.

It is assumed throughout these API guidelines that APIs accept `application/json`.

#### `Accept-Charset`

This request header specifies what character sets the API client is capable of handling in the response.
The value of `Accept-Charset` **SHOULD** include utf-8.

#### `Content-Language`

This request/response header is used to specify the language of the content.
The default locale is en-US.
API clients **SHOULD** identify the language of the data using Content-Language header.
APIs **MUST** provide this header in the response.

Example:
`Content-Language: en-US`

#### `Content-Type`

This request/response header indicates the media type of the request or response body.

- API client **MUST** include with request if the request contains a body, e.g. it is a POST request.
- API developer **MUST** include it with response if a response body is included (not used with 204 responses).
- If the content is a text-based type, such as JSON, the `Content-Type` **MUST** include a character-set parameter.
- The character-set **MUST** be `UTF-8`.
- The only supported media type for now is application/json.

Example:

(in HTTP request) `Accept: application/json; Accept-Charset: utf-8`

(in HTTP response) `Content-Type: application/json; charset=utf-8`

#### `Link`

According to Web Linking [RFC 5988](https://tools.ietf.org/html/rfc5988), a link is a typed connection between two resources that are identified by Internationalised Resource Identifiers (IRIs).
The Link `entity-header` field provides a means for serializing one or more links in HTTP headers.

APIs **SHOULD** be built with a design assumption that neither an API, nor an API client’s business logic should depend on information provided in the headers.
Headers must only be used to carry cross-cutting concern information such as security, traceability, monitoring, etc.
Therefore, usage of the Link header is prohibited with response codes 201 or 3xx.
Consider using [HATEOAS](hypermedia.md) links in the response body instead.

#### `Location`

This `response-header` field is used to redirect the recipient to a location other than the Request-URI for completion of the request or identification of a new resource.

APIs **SHOULD** be built with a design assumption that neither an API, nor an API client’s business logic should depend on information provided in the headers.
Headers must only be used to carry cross-cutting concern information such as security, traceability, monitoring, etc.

Therefore, usage of the Location header is prohibited with response codes 201 or 3xx.
Consider using [HATEOAS](hypermedia.md) links in the response body instead.

#### `Prefer`

The [Prefer](https://tools.ietf.org/html/rfc7240) request header field is used to indicate that a particular server behavior(s) is preferred by the client but is not required for successful completion of the request.
It is an end to end field and **MUST** be forwarded by a proxy if the request is forwarded unless `Prefer` is explicitly identified as being hop by hop using the Connection header field.
Following token values are possible to use for APIs provided an API documentation explicitly indicates support for `Prefer`.

`Prefer: respond-async`: API client prefers that API server processes its request asynchronously.

Server returns a `202 Accepted` response and processes the request asynchronously.
API server could use a webhook to inform the client subsequently, or the client may call GET to get the response at a later time.
Refer to Asynchronous Operations for more details.

`Prefer: read-consistent`: API client prefers that API server returns response from a durable store with consistent data.
For APIs that are not offering any optimization preferences for their clients, this behavior would be the default and it would not require the client to set this token.

`Prefer: read-eventual-consistent`: API client prefers that API server returns response from either cache or presumably eventually consistent datastore if applicable.
If there is a miss in finding the data from either of these two types of sources, the API server might return response from a consistent, durable datastore.

`Prefer: read-cache`: API client prefers that API server returns response from cache if available.
If the cache hit is a miss, the server could return response from other sources such as eventual consistent datastore or a consistent, durable datastore.

`Prefer: return=representation`: API client prefers that API server include an entity representing the current state of the resource in the response to a successful request.
This preference is intended to provide a means of optimizing communication between the client and server by eliminating the need for a subsequent GET request to retrieve the current representation of the resource following a creation (POST) modification operation (PUT or PATCH).

`Prefer: return=minimal`: API client indicates that the server returns only a minimal response to a successful request.
The determination of what constitutes an appropriate “minimal” response is solely at the discretion of the server.

#### `ETag`

[Entity tags (ETag)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/ETag) is a good approach to make update requests idempotent.
ETags are generated by the server based on the current resource representation.

#### `If-Match`

Using the `If-Match` header with the current `ETag` value representing the current resource state allows the server to provide idempotent operations and avoid race conditions.
The server would only execute the update if the `If-Match` value matches current `ETag` for the resource.

### HTTP Custom Headers

There are instances where custom headers may be required to send additional information such as a Correlation Id or Request Id to the server/client.
With respect to HTTP custom header naming conventions, the X- prefix has been deprecated (see [RFC 6648](https://tools.ietf.org/html/rfc6648)) and it is now recommended to simply name custom headers with something of relevance without the X- prefix, for example;

```
Idempotency-Key: cf172aa2-fddf-11ea-adc1-0242ac120002
```

#### `Idempotency-Key`

API consumers **MAY** choose to send this header with a unique ID identifying the request header for tracking purpose.

Such a header can be used internally for logging and tracking purpose too.
It is **RECOMMENDED** to send this header back as a response header if response is asynchronous or as request header of a webhook as applicable.

### HTTP Header Propagation

When services receive request headers, they **MUST** pass on relevant custom headers in addition to the HTTP standard headers in requests/messages dispatched to secondary systems.

