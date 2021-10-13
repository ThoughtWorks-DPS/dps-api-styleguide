# Hypermedia

---

## HATEOAS

Hypermedia, an extension of the term [hypertext](https://en.wikipedia.org/wiki/Hypertext), is a nonlinear medium of information which includes graphics, audio, video, plain text and hyperlinks according to [wikipedia](https://en.wikipedia.org/wiki/Hypermedia).
Hypermedia As The Engine Of Application State ([HATEOAS](https://en.wikipedia.org/wiki/HATEOAS)) is a constraint of the REST application architecture described by Roy Fielding in his dissertation.

In the context of RESTful APIs, a client could interact with a service entirely through hypermedia provided dynamically by the service.
A hypermedia-driven service provides representation of resource(s) to its clients to navigate the API dynamically by including hypermedia links in the responses.
This is different than other form of SOA, where servers and clients interact based on WSDL-based specification defined somewhere on the web or exchanged off-band.

### Hypermedia Compliant API

A hypermedia compliant API exposes a finite state machine of a service.
Here, requests such as DELETE and POST typically initiate a transition in state while responses indicate the change in the state.
Let's take an example of an API that exposes a set of operations to manage a user account lifecycle and implements the HATEOAS interface constraint.
A client starts interaction with a service through a fixed URI `/users`.
This fixed URI supports both GET and POST operations.
The client decides to do a POST operation to create a user in the system.

#### Request:

```
POST https://api.example.com/v1/customer/users
{
  "given_name": "James",
  "surname" : "Greenwood",
  ...
}
```

#### Response:

The API creates a new user from the input and returns the following links to the client in the response.

- A link to retrieve the complete representation of the user (aka self link) (GET).
- A link to delete the user (DELETE).

```
HTTP/1.1 201 CREATED
Content-Type: application/json
...
{
  "links": [
    {
      "href": "https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI",
      "rel": "self",
    },
    {
      "href": "https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI",
      "rel": "delete",
      "method": "DELETE"
    }
  ]
}
```

A client can store these links in its database for later use.

A client may then want to display a set of users and their details before the admin decides to delete one of the users.
So the client does a GET to the same fixed URI `/users`.

#### Request:

`GET https://api.example.com/v1/customer/users`

The API returns all the users in the system with respective self links.

#### Response:

```json
{
  "total_items": "166",
  "total_pages": "83",
  "users": [
    {
      "given_name": "James",
      "surname": "Greenwood",
      ...
      "links": [
        {
          "href": "https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI",
          "rel": "self"
        }
      ]
    },
    {
      "given_name": "David",
      "surname": "Brown",
      ...
      "links": [
        {
          "href": "https://api.example.com/v1/customer/users/ALT-MDFSKFGIFJ86DSF",
          "rel": "self"
        }
      ],
      ...
    }
  ]
}
```

The client **MAY** follow the self link of the user and figure out all the possible operations that it can perform on the user resource.

#### Request:

`GET https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI`

```json
Response:
HTTP/1.1 200 OK
Content-Type: application/json
{
  "given_name": "James",
  "surname": "Greenwood",
  ...

  "links": [
    {
      "href": "https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI",
      "rel": "self",
    },
    {
      "href": "https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI",
      "rel": "delete",
      "method": "DELETE"
    }
  ]
}
```

To delete the user, the client retrieves the URI of the link relation type delete from its data store and performs a delete operation on the URI.

#### Request:

`DELETE https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI`

Summary

- There is a well defined entry point for an API which a client navigates to in order to access all other resources.
- The client does not need to build the logic of composing URIs to execute different requests or code any kind of business rule by looking into the response details (more in detail is described in the later sections) that may be associated with the URIs and state changes.
- The client acknowledges the fact that the process of creating URIs belongs to the server.
- Client treats URIs as opaque identifiers.
  There is no semantic meaning to be inferred by the value of the identifier.
  For example, resources added consecutively do not have consecutive identifiers.
- APIs using hypermedia in representations could be extended seamlessly.
  As new methods are introduced, responses could be extended with relevant HATEOAS links.
  In this way, clients could take advantage of the functionality in incremental fashion.
  For example, if the API starts supporting a new PATCH operation then clients could use it to do partial updates.

The mere presence of links does not decouple a client from having to learn the data required to make requests for a transition and all associated link semantics, particularly for POST/PUT/PATCH operations.
An API **MUST** provide documentation to clearly describe all the links, link relation types and request response formats for each of the URIs.

Subsequent sections provide more details about the structure of a link and what different relationship types mean.

## Link Description Object

Links **MUST** be described using the [Link Description Object (LDO)] [4] schema.
An LDO describes a single link relation in the links array.
Following is a brief description for properties of Link Description Object.

### href:

- A value for the href property **MUST** be provided.
- The value of the href property **MUST** be a [URI template] and used to determine the target URI of the related resource.
  It **SHOULD** be resolved as a URI template per RFC 6570.
- Use ONLY absolute URIs as a value for href property.
  Clients usually bookmark the absolute URI of a link relation type from the representation to make API requests later.
  Developers **MUST** use the URI Component Naming Conventions to construct absolute URIs.
  The value from the incoming Host header (e.g. api.example.com) **MUST** be used as the host field of the absolute URI.

### rel:

- `rel` stands for relation as defined in Link Relation Type
- The value of the rel property indicates the name of the relation to the target resource.
- A value for the `rel` property **MUST** be provided.

### method:

- The `method` property identifies the HTTP verb that **MUST** be used to make a request to the target of the link.
  The `method` property assumes a default value of GET if it is omitted.

### title:

- The `title` property provides a title for the link and is a helpful documentation tool to facilitate understanding by the end clients.
  This property is NOT REQUIRED.

### Not Using HTTP Headers For LDO

Note that these API guidelines do not recommend using the HTTP Location header to provide a link.
Also, they do not recommend using the Link header as described in [JAX-RS](https://java.net/projects/jax-rs-spec/pages/Hypermedia).
The scope of HTTP header is limited to point-to-point interaction between a client and a service.
Since responses might be passed around to other layers and components on the client side which may not directly interact with the service, any information that is stored in a header may not be available.
Therefore, we recommend returning Link Description Object(s) in HTTP response body.

### Links Array

The links array property of schemas is used to associate a Link Description Objects with a [JSON hyper-schema draft-04] [3] instance.

- This property **MUST** be an array.
- Items in the array **MUST** be of type Link Description Object.

### Specifying the Links array

Here’s an example of how you would describe links in the schema.

- A links array similar to the one defined in the sample JSON schema below **MUST** be provided as part of the API resource schema definition.
  Please note that the links array needs to be declared within the `properties` keyword of an object.
  This is required for code generators to add setter/getter methods for the links array in the generated object.
- All possible links that an API returns as part of the response **MUST** be declared in the response schema using a URI template.
  The links array of URI templates **MUST** be declared outside the `properties` keyword.

```json
{
  "type": "object",
  "$schema": "http://json-schema.org/draft-04/hyper-schema#",
  "description": "A sample resource representing a customer name.",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique ID to identify a customer."
    },
    "first_name": {
      "type": "string",
      "description": "Customer's first name."
    },
    "last_name": {
      "type": "string",
      "description": "Customer's last name."
    },
    "links": {
      "type": "array",
      "items": {
      "$ref": "http://json-schema.org/draft-04/hyper-schema#definitions/linkDescription"
    }
  }
},
  "links": [
    {
      "href": "https://api.example.com/v1/customer/users/{id}",
      "rel": "self"
    },
    {
      "href": "https://api.example.com/v1/customer/users/{id}",
      "rel": "delete",
      "method": "DELETE"
    }
  ]
}
```

Below is an example response that is compliant with the above schema.

```json
{
  "id": "ALT-JFWXHGUV7VI",
  "first_name": "John",
  "last_name": "Doe",
  "links": [
    {
      "href": "https://api.example.com/v1/cusommer/users/ALT-JFWXHGUV7VI",
      "rel": "self"
    },
    {
      "href": "https://api.example.com/v1/customer/users/ALT-JFWXHGUV7VI",
      "rel": "delete",
      "method": "DELETE"
    }
  ]
}
```

## Link Relation Type

A Link Relation Type serves as an identifier for a link.
An API **MUST** assign a meaningful link relation type that unambiguously describes the semantics of the link.
Clients use the relevant Link Relation Type in order to identify the link to use from a representation.

When the semantics of a Link Relation Type defined in [IANA’s list of standardized link relations] matches with the one you want to define, then it **MUST** be used.
The table below describes some of the commonly used link relation types.
It also lists some additional lin relation types defined by these guidelines.

For all controller style complex operations, the controller action name must be used as the link relation type (e.g. activate,cancel,refund).

|Link Relation Type|Description|
|------------------|-----------|
|self|Conveys an identifier for the link’s context. Usually a link pointing to the resource itself.|
|create|Refers to a link that can be used to create a new resource.|
|edit|Refers to editing (or partially updating) the representation identified by the link. Use this to represent a PATCH operation link.|
|delete|Refers to deleting a resource identified by the link. Use this Extended link relation type to represent a DELETE operation link.|
|replace|Refers to completely update (or replace) the representation identified by the link. Use this Extended link relation type to represent a PUT operation link.|
|first|Refers to the first page of the result list.|
|last|Refers to the last page of the result list provided `total_required` is specified as a query parameter.|
|next|Refers to the next page of the result list.|
|prev|Refers to the previous page of the result list.|
|collection|Refers to a collections resource (e.g /v1/users).|
|latest-version|Points to a resource containing the latest (e.g.  current) version.|
|search|Refers to a resource that can be used to search through the link’s context and related resources.|
|up|Refers to a parent resource in a hierarchy of resources.|

### Use Cases

See [HATEOAS Use Cases](controller-resources.md) to find where HATEOAS could be used.
