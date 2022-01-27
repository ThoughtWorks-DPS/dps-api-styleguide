# HTTP Request Standards

---

This section defines how HTTP Requests should be constructed.
It includes definitions and examples for each of the HTTP verbs.
It also defines how URLs are constructed, and how the URL structure communicates request semantics to the server.

## HTTP Verb Semantics

API calls may fail for a number of reasons, and the client may not always know if the server failed or if the client simply didn’t get notified of success.
For example, there may be a temporary network failure preventing the server’s response from getting back to the client, or the server may have responded but the client HTTP connection already timed out before receiving the response.
The following two characteristics help us think about these failure conditions:

- *Safety* - Safe calls have no client-visible side effects (in other words, writing to a server-side log file is fine, but changing resource state is not).
  Read-only APIs should be safe.
- *Idempotency* - Idempotent APIs are those where the end result of two or more (identical) successful API calls is the same as the end result of one successful call.
  Idempotent APIs are therefore retry-able when the client does not know if the call succeeded on the server or not.

### Safety and Idempotency

These two characteristics allow us to reason about failure scenarios with HTTP verb semantics:

| HTTP Verb | Safe? | Idempotent? |
|-----------|-------|-------------|
|GET|Yes|Yes|
|POST|No|Maybe - sending multiple POST requests will result in multiple resources unless both client and server implement idempotency logic via the value of the `Idempotency-Key` HTTP header property.|
|PUT|No|Maybe - overwriting a resource with the same state twice is fine, provided there is a way to fail the retry if the resource has been further modified by another actor in the meantime|
|PATCH|No|No - updating a few fields twice may not result in the same resource state as other fields may change between the two updates|
|DELETE|No|Yes - deleting a resource that’s already deleted is fine|

> Note: The above analysis is true only for the resource in question.
> If the service triggers other workflows as a result of an API call, then the service must implement logic to maintain the safety and/or idempotency of the API request.
> For example, in the case where changing a resource triggers a workflow, systems of record should only be notified if a PUT *actually changes the resource*.

### Resource Operations - HTTP Verbs and URL Paths

The HTTP verbs to support endpoint requests should follow standard HTTP semantics.

|Verb|Collection|Singular|Reified|Non-resourceful|
|----|----------|--------|-------|---------------|
|GET|Search|Read|Status of workflow request|Not applicable|
|POST|Create (server returns new resource id)|Tunnel|Create|Tunnel|
|PUT|Overwrite all|Overwrite (or create with client provided id)|Not applicable|Not applicable|
|PATCH|Bulk update|Partial update|Not applicable|Not applicable|
|DELETE|Delete all|Delete|Cancel a workflow request|Not applicable|

"Tunnel" refers to taking any action not otherwise represented in the table.
It is a way of bypassing the Uniform Interface of REST to take some action that requires more than standard HTTP semantics.
HTTP supports two standard ways of updating a resource through the PUT and PATCH verbs.
PUT is more common, but expects the client to pass all fields back.
PATCH supports partial updates, allowing the client to only send changed fields back.
Our recommendation is to use PUT wherever possible, as it’s easier to understand and generally provides a better client experience.
PATCH has complicated semantics and is more prone to errors and race conditions.

Prefer POST over PUT-with-id for creation of resources.
Supporting PUT-with-id requires extra overhead for synchronization and ensuring an id is unique.
This can have an impact on performance and reliability.
It also adds complexity on the client-side implementation in the form of handling an additional set of error conditions.

This style guide does not dictate whether DELETEs are hard deletes or soft.
Those semantics will be defined within each API as appropriate to the business.

### Standard Querystring Operations

Where a standard operation isn’t listed below, prefer JSON API format where feasible.

## Create Resource

For creating a new resource, use POST method. The request body for POST may be somewhat different than for GET/PUT response/request (typically fewer fields as the server will generate some values).
In most cases, the service produces an identifier for the resource.
In cases where identifier is supplied by the API consumer, use Create New Resource - Client Supplied ID

Once the POST has successfully completed, a new resource will be created.
Hypermedia links provide an easy way to get the URL of the newly created resource, using the rel: self, in addition to other links for operations that are allowed on the newly created resource.
You may provide complete representation of the resource or partial with just [HATEOAS](hypermedia.md) links to retrieve the complete representation.

### URI Template

`POST /{version}/{namespace}/{resource}`

##### Example Request:

Note that server-generated values are not provided in the request.

`POST /v1/vault/credit-cards`

```json
{
  "payer_id": "user12345",
  "type": "visa",
  "number": "4417119669820331",
  "expire_month": "11",
  "expire_year": "2018",
  "first_name": "Betsy",
  "last_name": "Buyer",
  "billing_address": {
    "line1": "111 First Street",
    "city": "Saratoga",
    "country_code": "US",
    "state": "CA",
    "postal_code": "95070"
  }
}
```

##### Example Response

On successful execution, the method returns with status code 201.

`201 Created`

```json
{
  "id": "CARD-1MD19612EW4364010KGFNJQI",
  "valid_until": "2016-05-07T00:00:00Z",
  "state": "ok",
  "payer_id": "user12345",
  "type": "visa",
  "number": "xxxxxxxxxxxx0331",
  "expire_month": "11",
  "expire_year": "2018",
  "first_name": "Betsy",
  "last_name": "Buyer",
  "links": [
    {
      "href": "https://api.sandbox.example.com/v1/vault/credit-cards/CARD-1MD19612EW4364010KGFNJQI",
      "rel": "self",
      "method": "GET"
    },
    {
      "href": "https://api.sandbox.example.com/v1/vault/credit-cards/CARD-1MD19612EW4364010KGFNJQI",
      "rel": "delete",
      "method": "DELETE"
    }
  ]
}
```

### Create New Resource - Consumer Supplied Identifier

When an API consumer provides the resource identifier, PUT method **SHOULD** be utilized, as the operation is idempotent, even during creation.
The same interaction as Create Resource is used here.
`201 Created` + response body on resource creation, and `204 No Content` + no response body when an existing resource is updated.

## Collection Resource

A collection resource should return a list of representation of all of the given resources (instances), including any related metadata.
An array of resources should be in the `items` field.
Consistent naming of collection resource fields allows API clients to create generic handling for using the provided data across various resource collections.

The GET verb should not affect the system, and should not change the response on subsequent requests (unless the underlying data changes), i.e. it should be idempotent.
Exceptions to 'changing the system' are typically instrumentation/logging-related.
The list of data is presumed to be filtered based on the privileges available to the API client.
In other words, it should not be a list of all resources in the domain.
It should only be resources for which the client has authorization to view within its current context.
Providing a summarized, or minimized version of the data representation can reduce the bandwidth footprint, in cases where individual resources contain a large object.

If the service allows partial retrieval of the set, the following patterns **MUST** be followed.

### Resource Filtering

Often it is desired to be able to filter the set of resources based on a resource property.
The filter is defined based on the following conventions and behaviors:

- filter query argument: `?filter=<filter-def>`
- filter-def: `<filter-spec>,...,<filter-spec>`
- filter-spec: `<property><operator><value>`
- property: the name of a property within the resource.
- value: the value to use in the comparison operation
- operator: a character which indicates the type of operations
    - equals: `:`
    - less than: `<`
    - less than or equal: `<:`
    - greater than: `>`
    - greater than or equal: `>:`
    - like: `~`  NOTE: there must be leading and/or trailing `*` character(s) in the value string
    - negation: `!` added before the operator
- Ensure that query definitions are URL-encoded properly
- Resources matching the filter **MUST** match all of the `<filter-spec>` definitions.
    - Except: specifying the same property to be equal to two values is an implicit 'IN' operation.
      For example: `GET /v1/movies?filter=genre:Comedy,genre:RomCom` will provide a list of all Comedy or RomCom movies.


Examples:

- `GET /v1/movies?filter=gross>=1000000` would get all movies grossing $1M or more
- `GET /v1/movies?filter=genre!~*edy` would get all movies not Comedy or Romantic Comedy or Dramedy
- `GET /v1/movies?filter=genre:Comedy,gross>=500000,origin!:us` would get all successful (over $500K) foreign comedies

This is not meant to be an exhaustive API, but rather a set of simple rules which are generally useful for all APIs.
APIs supporting any type of filtering on Collection resources **MUST** support the above conventions.

APIs which need additional capabilities **MAY** augment the above definitions provided the consumer expectations are not violated, and the meaning of the basic filter definition is not changed.
For example, an API may choose to support a more complicated method of filtering based on properties of related resources, as in the following example:

`GET /v1/movies?filter=actor.name:Kevin%20DBacon` might get all movies in which Kevin Bacon played a role.

### Time Selection

Query parameters with regard to time range could be used to select a subset of items in the following manner:

- `startTime` or `{propertyName}After`
A timestamp (in either Unix time or [ISO-8601](https://www.w3.org/TR/NOTE-datetime) format) indicating the non-inclusive start of a temporal range.
`startTime` may be used when there is only one unambiguous time dimension; otherwise, the property name should be used (e.g., processedAfter, updatedAfter).
The property **SHOULD** map to a time field in the representation.
- `endTime` or `{propertyName}Before`
A timestamp (in either Unix time or [ISO-8601](https://www.w3.org/TR/NOTE-datetime) format) indicating the non-inclusive end of a temporal range.
`endTime` may be used when there is only one unambiguous time dimension; otherwise, the property name should be used (e.g., processed_before, updated_before).
The property **SHOULD** map to a time field in the representation.

### Sorting

Results could be ordered according to sorting related instructions given by the client.
This includes sorting by a specific field's value and sorting order as described in the query parameters below.

- `sortBy`
A dimension by which items should be sorted; the dimensions **SHOULD** be an attribute in the item's representation; the default (ascending or descending) is left to the implementation and **MUST** be specified in the documentation.
- `sortOrder`
The order, one of `asc` or `desc`, indicating ascending or descending order.

### Pagination

Any resource that could return a large, potentially unbounded list of resources in its GET response **MUST** implement pagination using the patterns described here.

#### Sample URI path:

`/accounts?pageSize={pageSize}&page={page}`

Clients **MUST** assume no inherent ordering of results unless a default sort order has been specified for this collection.
It is RECOMMENDED that service implementers specify a default sort order whenever it would be useful.

### Query Parameters

- `pageSize`:
A non-negative, non-zero integer indicating the maximum number of results to return at one time.
This parameter:
    - **MUST** be optional for the client to provide.
    - **MUST** have a default value, for when the client does not provide a value.
- `page`:
A non-zero integer representing the page of the results.
This parameter:
    - **MUST** be optional for the client to provide.
    - **MUST** have a default value of 1 for when the client does not provide a value.
    - **MUST** respond to a semantically invalid page count, such as zero, with the HTTP status code `400 Bad Request`.
    - If a page number is too large -- for instance, if there are only 50 results, but the client requests `pageSize=100&page=3` -- the resource **MUST** respond with the HTTP status code `200 OK` and an empty result list.
- `pageToken`:
In certain cases such as querying on a large data set, in order to optimize the query execution while paginating, querying and retrieving the data based on result set of previous page migh be appropriate.
Such a `pageToken` could be an encrypted value of primary keys to navigate next and previous page along with the directions.
- `totalRequired`:
A boolean indicating total number of items (`totalItems`) and pages (`totalPages`) are expected to be returned in the response.
This parameter:
    - **SHOULD** be optional for the client to provide.
    - **SHOULD** have a default value of false.
    - **MAY** be used by the client in the very first request.
      The client **MAY** then cache the values returned in the response to help build subsequent requests.
    - **SHOULD** only be implemented when it will improve API performance and/or it is necessary for front-end pagination display.

### Response Properties

JSON response to a request of this type **SHOULD** be an object containing the following properties:

- `items` **MUST** be an array containing the current page of the result list.
- Unless there are performance or implementation limitations:
    - `totalItems` **SHOULD** be used to indicate the total number of items in the full result list, not just this page.
        - If `totalRequired` has been implemented by an API, then the value **SHOULD** only be returned when totalRequired is set to true.
        - If `totalRequired` has not been implemented by an API, then the value **MAY** be returned in every response if necessary, useful, and performant.
        - If present, this parameter **MUST** be a non-negative integer.
        - Clients **MUST NOT** assume that the value of `totalItems` is constant.
          The value **MAY** change from one request to the next.
    - `totalPages` **SHOULD** be used to indicate how many pages are available, in total.
        - If `totalRequired` has been implemented by an API, then the value **SHOULD** only be returned when totalRequired is set to true.
        - If `totalRequired` has not been implemented by an API, then the value **MAY** be returned in every response if necessary, useful, and performant.
        - If present, this parameter **MUST** be a non-negative, non-zero integer.
        - Clients **MUST NOT** assume that the value of `totalPages` is constant.
          The value **MAY** change from one request to the next.
- `links` **SHOULD** be an array containing one or more [HATEOAS](hypermedia.md) link relations that are relevant for traversing the result list.

### Page Navigation

|Relationship|Description |
|------------|------------|
|self|Refers to the current page of the result list.|
|first|Refers to the first page of the result list. If you are using `pageToken`, you may not return this link.|
|last|Refers to the last page of the result list. Returning of this link is optional. You need to return this link only if `totalRequired` is specified as a query parameter. If you are using `pageToken`, you may not return this link.|
|next|Refers to the next page of the result list.|
|prev|Refers to the previous page of the result list.|

This is a sample JSON schema that returns a collection of resources with pagination:

```json
{
  "id": "plan_list:v1",
  "$schema": "http://json-schema.org/draft-04/schema#",
  "description": "Resource representing a list of billing plans with basic information.",
  "name": "plan_list Resource",
  "type": "object",
  "required": true,
  "properties": {
    "plans": {
      "type": "array",
      "description": "Array of billing plans.",
      "items": {
        "type": "object",
        "description": "Billing plan details.",
        "$ref": "plan.json"
      }
    },
    "totalItems": {
      "type": "string",
      "readonly": true,
      "description": "Total number of items."
    },
    "totalPages": {
      "type": "string",
      "readonly": true,
      "description": "Total number of pages."
    },
    "links": {
      "type": "array",
      "items": {
        "$ref": "http://json-schema.org/draft-04/hyper-schema#"
      }
    }
  },
  "links": [
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize={pageSize}&page={page}&status={status}",
      "rel": "self"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize={pageSize}&page={page}&start={start_id}&status={status}",
      "rel": "first"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize={pageSize}&page={page+1}&status={status}",
      "rel": "next"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize={pageSize}&page={page-1}&status={status}",
      "rel": "prev"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize={pageSize}&page={last}&status={status}",
      "rel": "last"
    }
  ]
}
```

This is a sample JSON response that returns a collection of resources with pagination:

```json
{
  "totalItems": "166",
  "totalPages": "83",
  "plans": [
    {
      "id": "P-6EM196669U062173D7QCVDRA",
      "state": "ACTIVE",
      "name": "Testing1-Regular3",
      "description": "Create Plan for Regular",
      "type": "FIXED",
      "create_time": "2014-08-22T04:41:52.836Z",
      "update_time": "2014-08-22T04:41:53.169Z",
      "links": [
        {
          "href": "https://api.foo.com/v1/payments/billing-plans/P-6EM196669U062173D7QCVDRA",
          "rel": "self"
        }
      ]
    },
    {
      "id": "P-83567698LH138572V7QCVZJY",
      "state": "ACTIVE",
      "name": "Testing1-Regular4",
      "description": "Create Plan for Regular",
      "type": "INFINITE",
      "create_time": "2014-08-22T04:41:55.623Z",
      "update_time": "2014-08-22T04:41:56.055Z",
      "links": [
        {
          "href": "https://api.foo.com/v1/payments/billing-plans/P-83567698LH138572V7QCVZJY",
          "rel": "self"
        }
      ]
    }
  ],
  "links": [
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize=2&page=3&status=active",
      "rel": "self"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize=2&page=1&first=3&status=active",
      "rel": "first"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize=2&page=2&status=active",
      "rel": "prev"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize=2&page=4&status=active",
      "rel": "next"
    },
    {
      "href": "https://api.foo.com/v1/payments/billing-plans?pageSize=2&page=82&status=active",
      "rel": "last"
    }
  ]
}
```

## Read Single Resource

A single resource is typically derived from the parent collection of resources, often more detailed than an item in the representation of a collection resource.
Executing GET should never affect the system, and should not change response on subsequent requests, i.e. it should be idempotent.

All identifiers for sensitive data should be non-sequential, and preferably non-numeric.
In scenarios where this data might be used as a subordinate to other data, immutable string identifiers should be utilized for easier readability and debugging (i.e. `NAME_OF_VALUE` vs `1421321`).

### URI Template

`GET /{version}/{namespace}/{resource}/{resourceId}`

#### Example Request:

`GET /v1/vault/customers/CUSTOMER-66W27667YB813414MKQ4AKDY`

#### Example Response:

```json
{
  "merchant_customer_id": "merchant-1",
  "merchant_id": "target",
  "create_time": "2014-10-10T16:10:55Z",
  "update_time": "2014-10-10T16:10:55Z",
  "first_name": "Kartik",
  "last_name": "Hattangadi"
}
```

#### HTTP Status:

If the provided resource identifier is not found, the response `404 Not Found` HTTP status should be returned (even with ’soft deleted’ records in data sources).
Otherwise, `200 OK` HTTP status should be utilized when data is found.

## Delete Single Resource

In order to enable retries (e.g., poor connectivity), DELETE is treated as idempotent, so it should always respond with a `204 No Content` HTTP status.
`404 Not Found` HTTP status should not be utilized here, as on a second retry a client might mistakenly think the resource never existed at all.
GET can be utilized to verify the resources exists prior to DELETE.

For a number of reasons, some data exposed as a resource **MAY** disappear: because it has been specifically deleted, because it expired, because of a policy (e.g., only transactions less than 2 years old are available), etc.
Services **MAY** return a `410 Gone` error to a request related to a resource that no longer exists.
However, there may be significant costs associated with doing so.
Service designers are advised to weigh in those costs and ways to reduce them (e.g., using resource identifiers that can be validated without access to a data store), and **MAY** return a `404 Not Found` instead if those costs are prohibitive.

### URI Template

`DELETE /{version}/{namespace}/{resource}/{resourceId}`

#### Example Request:

`DELETE /v1/vault/customers/CUSTOMER-66W27667YB813414MKQ4AKDY`
`204 No Content`

## Update Single Resource

To perform an update to an entire resource, PUT method **MUST** be utilized.
The same response body supplied in the resource's GET should be provided in the resource's PUT request body.

If the update is successful, a `204 No Content` HTTP status code (with no response body) is appropriate.
Where there is a justifying use case (typically to optimize some client interaction), a `200 OK` HTTP status code with a response body can be utilized.
While the entire resource's representation must be supplied with the PUT method, the APIs validation logic can enforce constraints regarding fields that are allowed to be updated.
These fields can be specified as readOnly in the JSON schema.
Fields in the request body can be optional or ignored during deserialization, such as create_time or other system-calculated values.
Typical error handling, utilizing the `400 Bad Request` status code, should be applied in cases where the client attempts to update fields which are not allowed or if the resource is in a non-updateable state.

See Sample Input Validation Error Response for examples of error handling.

### URI Template
`PUT /{version}/{namespace}/{resource}/{resourceId}`

#### Example Request:
`PUT /v1/vault/customers/CUSTOMER-66W27667YB813414MKQ4AKDY`

```json
{
  "merchant_customer_id": "merchant-1",
  "merchant_id": "target",
  "create_time": "2014-10-10T16:10:55Z",
  "update_time": "2014-10-10T16:10:55Z",
  "first_name": "Kartik",
  "last_name": "Hattangadi"
}
```

#### HTTP Status:

Any failed request validation **MUST** respond with `400 Bad Request` HTTP status.
If clients attempt to modify read-only fields, this **MUST** also result in a `400 Bad Request`.
If there are business rules (more than simple data-type or length constraints), the system **SHOULD** provide a specific error code and message (in addition to the `400 Bad Request`) for that validation.

For situations which require interaction with APIs or processes outside of the current request, the `422 Unprocessable Entity` status code is appropriate.

After successful update, PUT operations **SHOULD** respond with `204 No Content` status, with no response body.

## Partially Update Single Resource

Often, previously created resources need to be updated based on customer or facilitator-initiated interactions (like adding items to a cart).
In such cases, APIs **SHOULD** provide an [RFC 6902](http://tools.ietf.org/html/rfc6902) JSON Patch compatible solution.
JSON patch uses the HTTP PATCH method defined in [RFC 5789](http://tools.ietf.org/html/rfc5789) to enable partial updates to resources.

A JSON patch expresses a sequence of operations to apply to a target JSON document.
The operations defined by the JSON patch specification include add, remove, replace, move, copy, and test.
To support partial updates to resources, APIs **SHOULD** support add, remove and replace operations.
Support for the other operations (move, copy, and test) is left to the individual API owner based on needs.

Below is a sample PATCH request to do partial updates to a resource:

```
PATCH /v1/namespace/resources/:id HTTP/1.1
Host: api.foo.com
Content-Length: 326
Content-Type: application/json-patch+json
If-Match: "etag-value"
```

```json
[
  {
    "op": "remove",
    "path": "/a/b/c"
  },
  {
    "op": "add",
    "path": "/a/b/c",
    "value": [ "foo", "bar" ]
  },
  {
    "op": "replace",
    "path": "/a/b/c",
    "value": 42
  }
]
```

The value of path is a string containing a [RFC 6901](https://tools.ietf.org/html/rfc6901) JSON Pointer that references a location within the target document where the operation is performed.
For example, the value /a/b/c refers to the element c in the sample JSON below:

```json
{
  "a": {
    "b": {
      "c": "",
      "d": ""
    },
    "e": ""
  }
}
```

#### path Parameter

When JSON Pointer is used with arrays, concurrency protection is best implemented with ETags.
In many cases, ETags are not an option:
It is expensive to calculate ETags because the API collates data from multiple data sources or has very large response objects.
The response data are frequently modified.

### JSON Pointer Expression

In cases where ETags are not available to provide concurrency protection when updating arrays, it is recommended to use an extension to RFC 6901 which provides expressions of the following form.

`"path": "/object-name/@filter-expression/attribute-name"`

- `object-name` is the name of the collection.The symbol “@” refers to the current object.
It also signals the beginning of a filter-expression.
- The filter-expression **SHOULD** only contain the following operators: a comparison operator (== for equality) or a Logical AND (&&) operator or both.
For example: `/address/@id==123/streetName`, `address/@id==123 && primary==true` are valid filter expressions.
- The right hand side operand for the operator “==” **MUST** have a value that matches the type of the left hand side operand.
For example: `addresss/@integer_id == 123`,`/address/@string_name == ‘james’`,`/address/@boolean_primary == true`,`/address/@decimal_number == 12.1` are valid expressions.
- If the right hand operand of "==" is a string then it **SHOULD NOT** contain any of the following escape sequences: a Line Continuation or a Unicode Escape Sequence.
- `attribute-name` is the name of the attribute to which a PATCH operation is applied if the filter condition is met.

### PATCH Array Examples

#### Example 1:

`"op": "replace","path": “/address/@id==12345/primary”,"value": true`

This would set the array element "primary" to true if the element "id" has a value "12345".

#### Example 2:

`"op": "replace","path": “/address/@countryCode==’GB’ && type==’office’/active”,"value": true`

This would set the array element "active" to true if the element "countryCode" equals to "GB" and type equals to "office".

#### Other Implementation Considerations For PATCH

It is not necessary that an API support the updating of all attributes via a PATCH operation.
An API implementer **SHOULD** make an informed decision to support PATCH updates only for a subset of attributes through a specific resource operation.

#### Responses to a PATCH request

- Note that the operations are applied sequentially in the order they appear in the payload.
If the update is successful, a `204 No Content` HTTP status code (with no response body) is appropriate.
Where there is a justifying use case (typically to optimize some client interaction) and the request has the header `Prefer:return=representation`, a `200 OK` HTTP status code with a response body can be utilized.
- Responses body with `200 OK` **SHOULD** return the entire resource representation unless the client uses the fields parameter to reduce the response size.
- If a PATCH request results in a new resource state that is invalid, the API **SHOULD** return a `400 Bad Request` or `422 Unprocessable` Entity.

See Sample Input Validation Error Response for examples of error handling.

#### PATCH Examples

PATCH examples for modifying objects can be found in [RFC 6902](http://tools.ietf.org/html/rfc6902).

## Projected Response

An API typically responds with full representation of a resource after processing requests for methods such as GET.
For efficiency, the client can ask the service to return partial representation using `Prefer: return=minimal` HTTP header.
Here, The determination of what constitutes an appropriate "minimal" response is solely at the discretion of the service.

To request partial representation with specific field(s), a client can use the fields query parameter.
For selecting multiple fields, a comma-separated list of fields **SHOULD** be used.

The following example shows the use of the fields parameter with users API.

#### Request:

HTTP GET without fields parameter

```
GET https://api.foo.com/v1/users/dbrown
Authorization: Bearer your_auth_token
```

#### Response:

The complete resource representation is returned in the response.

```json
{
  "uid": "dbrown",
  "given_name": "David",
  "sn": "Brown",
  "location": "Austin",
  "department": "RISK",
  "title": "Manager",
  "manager": "ipivin",
  "email": "dbrown@foo.com",
  "employeeId": "234167"
}
```

#### Request:

HTTP GET request specifies a subset of the fields.

```
GET https://api.foo.com/v1/users/dbrown?fields=department,title,location
Authorization: Bearer your_auth_token
```

#### Response:

The response has only fields specified by the fields query parameter as well as mandatory fields.

```json
200 OK
{
  "uid": "dbrown",
  "department": "RISK",
  "title": "Manager",
  "location": "Austin"
}
```

You could use the same pattern for Collection Resource as well as following.

`GET https://api.foo.com/v1/users?fields=department,title,location`

The response will have entries with the fields specified in request as well as mandatory fields.

## Sub-Resource Collection

Sometimes, multiple identifiers are required ('composite keys', in the database lexicon) to identify a given resource.
In these scenarios, all behaviors of a Collection Resource are implemented, as a subordinate of another resource.
It is always implied that the `resourceId` in the URL must be the parent of the sub-resources.

### Cautions

- The need to maintain multiple identifiers can create a burden on client developers.
    - Look for opportunities to promote resources with unique identifiers (i.e. there is no need to identify the parent resource) to a first-level resource.
- Caution should be used in identifying the name of the sub-resource, as to not interfere with the identifier naming conventions of the base resource.
In other words, `/{version}/{namespace}/{resource}/{resourceId}/{subResourceId}` is not appropriate, as the `subResourceId` has ambiguous meaning.
- Two levels is a practical limit for resource identifiers
- API client usability suffers, as the need for clients to maintain state about identifier hierarchy increases complexity.
- Server developers must validate each level of identifiers in order to verify that they are allowed access, and that they relate to each other, thus increasing risk and complexity.

Note these templates/examples are brief: for more detail on the Collection Resource style, see above.
Although this section explains the sub-resource collection, all interactions should be the same, simply with the addition of a parent identifier.

### URI Templates

```
POST /{version}/{namespace}/{resource}/{resourceId}/{sub-resource}
GET /{version}/{namespace}/{resource}/{resourceId}/{sub-resource}
GET /{version}/{namespace}/{resource}/{resourceId}/{sub-resource}/{subResourceId}
PUT /{version}/{namespace}/{resource}/{resourceId}/{sub-resource}/{subResourceId}
DELETE /{version}/{namespace}/{resource}/{resourceId}/{sub-resource}/{subResourceId}
```

#### Examples:

```
GET /v1/notifications/webhooks/{webhook-id}/event-types
POST /v1/factory/widgets/PART-4312/sub-assemblies
GET /v1/factory/widgets/PART-4312/sub-assemblies/INNER-COG
PUT /v1/factory/widgets/PART-4312/sub-assemblies/INNER-COG
DELETE /v1/factory/widgets/PART-4312/sub-assemblies/INNER-COG
```

## Sub-Resource Singleton

When a `sub-resource` has a one-to-one relationship with the parent resource, it could be modeled as a `singleton sub-resource`.
This approach is usually used as a means to reduce the size of a resource, when use cases support segmenting a large resource into smaller resources.

For a `singleton sub-resource`, the name should be a singular noun.
As often as possible, that single resource should always be present (i.e. does not respond with 404).

The `sub-resource` should be owned by the parent resource; otherwise this sub-resource should probably be promoted to its own collection resource, and relationships represented with `sub-resource` collections in the other direction.
Sub-resource singletons should not duplicate a resource from another collection.

If the `singleton sub-resource` needs to be created, PUT should be used, as the operation is idempotent, on creation or update.
PATCH can be used for partial updates, but should not be available on creation (in part because it is not idempotent).

This should not be used as a mechanism to update single or subsets of fields with PUT.
The resource should remain intact, and PATCH should be utilized for partial update.
Creating sub-resource singletons for each use case of updates is not a scalable design approach, as many endpoints could result long-term.

### URI Template

`GET/PUT /{version}/{namespace}/{resource}/{resourceId}/{sub-resource}`

#### Examples:

`GET /v1/customers/devices/DEV-FDU233FDSE213f)/vendor-information`

## Idempotency

Idempotency is an important aspect of building a fault-tolerant API.
Idempotent APIs enable clients to safely retry an operation without worrying about the side-effects that the operation can cause.
For example, a client can safely retry an idempotent request in the event of a request failing due to a network connection error.

Per [HTTP Specification](https://tools.ietf.org/html/rfc2616#section-9.1.2), a method is idempotent if the side-effects of more than one identical requests are the same as those for a single request.
Methods GET, HEAD, PUT and DELETE (additionally, TRACE and OPTIONS) are defined idempotent.

POST operations by definition are neither safe nor idempotent.

All service implementations **MUST** ensure that safe and idempotent behaviour of HTTP methods is implemented as per HTTP specifications.
Services that require idempotency for POST operations **MUST** be implemented as per the following guidelines.

### Idempotency For POST Requests

POST operations by definition are not idempotent which means that executing POST more than once with the same input creates as many resources.
To avoid creation of duplicate resources, an API **SHOULD** implement the protocol defined in the section below.
This guarantees that only one record is created for the same input payload.

For many use cases that require idempotency for POST requests, creation of a duplicate record is a severe problem.
For example, duplicate records for the use cases that create or execute a payment on an account are not allowed by definition.

To track an idempotent request, a unique idempotency key is used and sent in every request.
By convention, the API Styleguide defines a header `Idempotency-Key` for use as an idempotency key for any request that supports idempotency.

For the very first request from the client:

#### On the client side:

The API client sends a new POST request with the `Idempotency-Key` header that contains the idempotency key.

```json
POST /v1/payments/referenced-payouts-items HTTP/1.1
Host: api.foo.com
Content-Type: application/json
Authorization: Bearer oauth2_token
Idempotency-Key: 123e4567-e89b-12d3-a456-426655440000
{
  "reference_id": "4766687568468",
  "reference_type": "egflf465vbk7468mvnb"
}
```

#### On the server side:

If the call is successful and leads to a resource creation, the service **MUST** return a `201 Created` response to indicate both success and a change of state.

#### Sample response:

```json
HTTP/1.1 201 CREATED
Content-Type: application/json
{
  "item_id": "CDZEC5MJ8R5HY",
  "links": [{
    "href": "https://api.foo.com/v1/payments/referenced-payouts-items/CDZEC5MJ8R5HY",
    "rel": "self",
    "method": "GET"
  }]
}
```

The service **MAY** send back the idempotency key as part of `Idempotency-Key` header in the response.

For subsequent requests from the client with same input payload:

#### On the client side:

The API client sends a POST request with the same idempotency key and input body as before.

```json
POST /v1/payments/referenced-payouts-items HTTP/1.1
Host: api.foo.com
Content-Type: application/json
Authorization: Bearer oauth2_token
Idempotency-Key: 123e4567-e89b-12d3-a456-426655440000
{
  "reference_id": "4766687568468",
  "reference_type": "egflf465vbk7468mvnb"
}
```

#### On the server side:

The server, after checking that the call is identical to the first execution, **MUST** return a `200 OK` response with a representation of the resource to indicate that the request has already been processed successfully.

#### Sample response:

```json
HTTP/1.1 200 OK
Content-Type: application/json
{
  "item_id": "CDZEC5MJ8R5HY",
  "processing_state": {
    "status": "PROCESSING"
  },
  "reference_id": "4766687568468",
  "reference_type": "egflf465vbk7468mvnb",
  "payout_amount": {
    "currency_code": "USD",
    "value": "2.0"
  },
  "payout_destination": "9C8SEAESMWFKA",
  "payout_transaction_id": "35257aef-54f7-43cf-a258-3b45caf3293",
  "links": [{
    "href": "https://api.foo.com/v1/payments/referenced-payouts-items/CDZEC5MJ8R5HY",
    "rel": "self",
    "method": "GET"
  }]
}
```

### Uniqueness of Idempotency Key

The idempotency key that is supplied as part of every POST request **MUST** be unique and can not be reused with another request with a different input payload.
See error scenarios described below to understand the server behavior for repeating idempotency keys in requests.

How to make the key unique is up to the client and its agreed protocol with the server.
It is recommended that a [UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier) or a similar random identifier be used as the idempotency key.
It is also recommended that the server implements the idempotency keys to be time-based and, thus, be able to purge or delete a key upon its expiry.

### Error Scenarios

- If the `Idempotency-Key` header is missing for an idempotent request, the service **MUST** reply with a `400 Bad Request` error with a link pointing to the public documentation about this pattern.
- If there is an attempt to reuse an idempotency key with a different request payload, the service **MUST** reply with a `422 Unprocessable Entity` error with a link pointing to the public documentation about this pattern.
- For other errors, the service **MUST** return the appropriate error message.

## Asynchronous Operations

Certain types of operations might require processing of the request in an asynchronous manner (e.g. validating a bank account, processing an image, etc.) in order to avoid long delays on the client side and prevent long-standing open client connections waiting for the operations to complete.
For such use cases, APIs **MUST** employ the following pattern:

### For POST requests:

- Return the `202 Accepted` HTTP response code.
- In the response body, include one or more URIs as hypermedia links, which could include:
    - The final URI of the resource where it will be available in future if the ID and path are already known.

Clients can then make an HTTP GET request to that URI in order to obtain the completed resource.
Until the resource is ready, the final URI **SHOULD** return the HTTP status code `404 Not Found`.

```json
{
  "href": "/v1/namespace/resources/{resourceId}",
  "rel": "self",
  "method": "GET"
}
```

- A temporary request queue URI where the status of the operation may be obtained via some temporary identifier.
- Clients **SHOULD** make an HTTP GET request to obtain the status of the operation which **MAY** include such information as completion state, ETA, and final URI once it is completed.
- Implementations **MAY** provide additional functionality in the form of job control (via PUT / DELETE) if such capabilities are useful to consumers.

```json
{
  "href": "/v1/queue/requests/{requestId}",
  "rel": "self",
  "method": "GET"
}
```

#### For PUT/PATCH/DELETE/GET requests:

Like POST, you can support PUT/PATCH/DELETE/GET to be asynchronous.
The behaviour would be as follows:

- Return the `202 Accepted` HTTP response code.
- In the response body, include one or more URIs as hypermedia links, which could include:
    - A temporary request queue URI where the status of the operation may be obtained via some temporary identifier.
- Clients **SHOULD** make an HTTP GET request to obtain the status of the operation which **MAY** include such information as completion state, ETA, and final URI once it is completed.
- Implementations **MAY** provide additional functionality in the form of job control (via PUT / DELETE) if such capabilities are useful to consumers.

```json
{
  "href": "/v1/queue/requests/{requestId}",
  "rel": "self",
  "method": "GET"
}
```

APIs that support both synchronous and asynchronous operations for a particular URI and an HTTP method combination, **MUST** recognize the `Prefer` header and exhibit following behavior:

- If the request contains a `Prefer=respond-async` header, the service **MUST** switch the processing to asynchronous mode.
- If the request doesn't contain a `Prefer=respond-async` header, the service **MUST** process the request synchronously.

It is desirable that all APIs that implement asynchronous processing, also support [webhooks](https://en.wikipedia.org/wiki/Webhook) as a mechanism of pushing the processing status to the client.
