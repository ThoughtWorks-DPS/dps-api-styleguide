# Controller Resources

---

Controller (aka Procedural) resources challenge the fundamental notion or concept of resource orientation where resources usually represent mapping to a conceptual set of entities or things in a domain system.
However, often API developers come across a situation where they are unable to model a service executing (part of) a business process as a pure RESTful service.
Some examples of use cases for controller resources are:

- When it is required to execute a processing function on the server from a set of inputs (client provided input or based on data from the server's information store or from an external information store).
- When it is required to combine one or more operations and execute them in an [atomic](https://en.wikipedia.org/wiki/Atomicity_(database_systems)) fashion (aka a composite controller operation).
- When you want to hide a multi-step business process operation from a client to avoid unnecessary coupling between a client and server.

## Risks

- Design scalability
    - When overused, the number of URIs can grow very quickly, as all permutations of root-level action can increase rapidly over time.
      This can also produce configuration complexity for routing/externalization.
    - The URI cannot be extended past the action, which precludes any possibility of sub-resources.
- Testability: highly compromised in comparison to Collection Resource oriented designs (due the lack of corresponding GET/read operations).
- History: the ability to retrieve history for the given actions is forced to live in another resource (e.g. `/action-resource-history`), or not at all.

## Benefits

- Avoids corrupting collection resource model with transient data (e.g. comments on state changes etc).
- Usability improvement: there are cases where a complex operation simplifies client interaction, where the client does not benefit from resource retrieval.

For further reading on controller concepts, please refer to section 2.6 of the [RESTful Web Services Cookbook](http://techbus.safaribooksonline.com/book/web-development/web-services/9780596809140).
Below are the set of guidelines for modelling controller resources.

## Naming Of A Controller Resource

Because a controller operation represents an action or a processing function in the server, it is more intuitive to express it using an English verb, i.e. the action itself as the resource name.

Verbs such as 'activate', 'cancel', 'validate', 'accept', and 'deny' are usual suspects.
There are many style options from which you can choose to define a controller resource.

- If the controller action is not associated with any resource context, you can express it as an independent resource at the namespace level (`/v1/credit/assess-eligibility`).
This is typically only applicable for creating a variety of resources in an optimized operation.
However, this is usually an anti-pattern.
- If the controller action is always in the context of a parent resource, then it should be expressed as a sub-resource (using a /) of the parent resource (e.g. `v1/identity/external-profiles/{id}/confirm`).
- When an action is in the context of a collection resource, express it as an independent resource at the namespace level.
The controller resource name in such cases **SHOULD** be composed of the action (an English verb) that the controller represent and the name of the collection resource.
For example, if you want to express a search operation for deposits, the controller resource **SHOULD** read as `v1/customer/search-deposits`.

> NOTE: A controller action is a terminal resource.
A sub-resource for a controller resource is thus invalid.
For this reason, you **SHOULD NOT** define a sub-resource to a controller resource.
It is also important to scope a controller to the minimum possible level of nesting in order to avoid resource pollution as such resources are use-case or action centric.

## HTTP Methods For Controller Resources

In general, for most cases the HTTP POST method **SHOULD** be used as the default method for executing a controller operation.

In scenarios where it is desired that the response of a controller operation be cache-able, GET **SHOULD** be used to execute the controller.
For example, you can use a GET operation (`GET /calculate-shortest-path?from=x &to=y`) to calculate the shortest path between two nodes (origin and destination).
The result of the GET operation is a collection of routes and their maps, and ideally you would like to cache the map for future use (`GET /retrieve`).

## HTTP Status Codes For Controller Resources

In general, the following response codes can be used for a controller operation.

### `200 OK`

This is the default status code for any controller operation.
The response **MUST** contain a body that describes the result of a controller operation.

### `201 Created`

Use `201 Created` if the controller operation leads to creation of a resource.
If a composite controller is used to create one or more resources and it is not possible to expresss them as a composite record, you **MAY** instead use `200 OK` as response code.

### `204 No Content`

Use `204 No Content` if the server declines to return anything as part of a controller action.
Most of the out-of-band actions fall in this category. (e.g. `v1/users/{id}/notify`).

For errors, appropriate `4XX` or `5XX` error codes **MAY** be returned.

Following sections provide some examples for modeling controller resources to carry out various kinds of complex operations.

## Complex Operation - Sub-Resource

> NOTE: Use with caution

For associated risks, see Controller Resource above.
There are often situations in which a canonical resource needs to impart certain actions or state changes which are not appropriate in a PUT or PATCH.
These URIs look like other `Sub-Resources`, but imply action.

A good use for this pattern is when a particular state change requires a "comment" (e.g. cancellation "reason").
Adding this comment, or other data such as location, would make the GET/PUT unnecessarily include those extra fields on every request/response.
This action may change the status of the given resource implicitly.

Additionally, when a resource identifier is required for an action, it's best to keep it in the URL.
Some actions are business processes which are not innately a resource (and in some cases might not even change resource state).

The response is typically `200 OK` and the resource itself, if there are changes expected in the resource the consumer needs to capture.
However, if no resource state change occurs, `204 No Content` and no response body could also be considered appropriate.

### URI Template

`POST /{version}/{namespace}/{resource}/{resource-id}/{complex-operation}`

#### Example Request:

```json
POST /v1/payments/billing-agreements/I-0LN988D3JACS/suspend
{
  "note": "Suspending the agreement."
}
```

#### Example Response:

`204 No Content`

However, when state changes are imparted in this manner, it does not mean that all state changes for the given resource should use a complex operation.
Simple state transitions (i.e. changes to a status field) should still utilize PUT/PATCH.
It is completely appropriate to mix patterns using PUT/PATCH on a Collection Resource + Complex Operation, in order to minimize the number of operations.

### Example Request (for mixed use of PUT):

```json
PATCH /v1/payments/billing-agreements/I-0LN988D3JACS
[
  {
    "op": "replace",
    "path": "/",
    "value": {
      "description": "New Description",
      "shipping_address": {
        "line1": "2065 Hamilton Ave",
        "city": "San Jose",
        "state": "CA",
        "postal_code": "95125",
        "country_code": "US"
      }
    }
  }
]
```

Keep in mind that if there is any need to see the history of these actions, a Sub-resource Collection is appropriate to show all of the prior executions of this action.
In that case, the verb should be [reified](http://en.wikipedia.org/wiki/Reification_(computer_science)'), or changed to a plural noun (e.g. 'execute' would become 'executions').

## Complex Operation - Composite

This type of complex operation creates/updates/deletes multiple resources in one operation.
This serves as both a performance and usability optimization, as well as adding better atomicity when values in the request might affect multiple resources at the same time.

Note in the sample below, the capture and the payment are both potentially affected by refund.
A PUT or PATCH operation on the capture resource would have unintended side effects on the payment resource.
To encapsulate both of these changes, the 'refund' action is used.

### URI Template

`POST /{version}/{namespace}/{action}`

#### Example Request:

`POST /v1/payments/captures/{capture-id}/refund`

#### Example Response:

```json
{
  "id": "REF-0P209507D6694645N",
  "create_time": "2013-05-06T22:11:51Z",
  "update_time": "2013-05-06T22:11:51Z",
  "state": "completed",
  "amount": {
    "total": "110.54",
    "currency": "USD"
  },
  "capture_id": "8F148933LY9388354",
  "parent_payment": "PAY-8PT597110X687430LKGECATA",
  "links": [
    {
      "href": "https://api.foo.com/v1/payments/refund/REF-0P209507D6694645N",
      "rel": "self",
      "method": "GET"
    },
    {
      "href": "https://api.foo.com/v1/payments/payment/PAY-8PT597110X687430LKGECATA",
      "rel": "parent_payment",
      "method": "GET"
    },
    {
      "href": "https://api.foo.com/v1/payments/capture/8F148933LY9388354",
      "rel": "capture",
      "method": "GET"
    }
  ]
}
```

## Complex Operation - Transient

This type of complex operation does not maintain state for the client, and creates no resources.
This is about as RPC as it gets; other alternatives should be considered first.

This is not usually utilized in sub-resources, as a sub-resource action would typically affect the parent resource.

HTTP status `200 OK` is always appropriate.
Response body contains calculated values, which could potentially change if run again.

As with all actions, resource-oriented alternatives should be considered first.

### URI Template

`POST /{version}/{namespace}/{action}`

### Example Request:

```json
POST /v1/risk/evaluate-payment
{
  "code": "h43j5k6iop"
}
```

### Example Response

```json
200 OK
{
  "status": "VALID"
}
```

## Complex Operation - Search

When Collection Resources are used, it is best to use query parameters on the collection to filter the set.
However, there are some situations that demand a very complex search syntax, where query parameter filtering on a collection might present usability problems, security / privacy issues, or run up against theoretical query parameter length limitations.

In these situations, POST can be utilized with a request object to specify the search parameters.

### Pagination

Assuming pagination will be required with large response quantities, it is important to remember that the consumer will need to use POST on each subsequent page.
As such, it's important to maintain paging in the query parameters (one of the rare exceptions where POST body + query parameters are utilized).

Paging query parameters should follow the same conventions as in Collection Resources.
This allows for hypermedia links to provide next, previous, first, last page relationships with paging specified in the URL.

### URI Template

`POST /{version}/{namespace}/{search-resource}`

#### Example Request:

```json
POST /v1/factory/widgets-search
{
  "created_before":"1975-05-13",
  "status": "ACTIVE",
  "vendor": "Parts Inc."
}
```

#### Example Response:

```json
200 OK
{
  "items": [
    <<lots of part objects here>>
  ],
  "links": [
    {
      "href": "https://api.sandbox.factory.io/v1/factory/widgets-search?page=2&page_size=10",
      "rel": "next",
      "method": "POST"
    },
    {
      "href": "https://api.sandbox.factory.io/v1/factory/widgets-search?page=124&page_size=10",
      "rel": "last",
      "method": "POST"
    },
  ]
}
```

## Resource-Oriented Alternative

A better pattern is to create a Collection Resource of actions and provide a history of those actions taken in `GET /{actions}`.
This allows for future expansion of use cases around a resource model, instead of a single action-oriented, RPC-style URL.

Additionally, for various use cases, filtering the resource collection of historical actions is usually desirable.
This also feeds well into [event sourcing](http://martinfowler.com/eaaDev/EventSourcing.html) concepts, where the history of a given event can drive further functionality.

## File Upload

Certains types of API operations require uploading a file (e.g. jpeg, png, pdf) as part of the API call.
Services for such use cases, **MUST NOT** support or allow encoding the file content within a JSON body using Base64 encoding.

For uploading a file, one of the following options **SHOULD** be used.

### Standalone Operation

Services supporting such an operation **SHOULD** provide a separate dedicated URI for uploading and retrieving the files.
Clients of such services upload the files using the file upload URI and retrieve the file metadata as part of the response to an upload operation.

Format of the file upload request **SHOULD** conform to multipart/form-data content type ([RFC 2388](https://www.ietf.org/rfc/rfc2388.txt)).
Example of a multipart/form-data request:

The client first uploads the file using a file-upload URI provided by the service.

```
POST /v1/identity/limit-resolution-files

Content-Type: multipart/form-data; boundary=--foo_bar_baz
Authorization: Bearer YOUR_ACCESS_TOKEN_HERE
MIME-Version: 1.0

--foo_bar_baz
Content-Type: text/plain
Content-Disposition: form-data; name="title"

Identity Document
--foo_bar_baz
Content-Type: image/jpeg
Content-Disposition: form-data; name="artifact"; filename="passport.jpg"

...(binary bytes of the image)...
--foo_bar_baz--
```

#### Sample file upload response:

If the file upload is successful, the server responds with the metadata of the uploaded file.

```json
{
  "id": "file_egflf465vbk7468mvnb",
  "created_at": 748557607545,
  "size" : 3457689458369,
  "url" : "https://api.foo.com/v1/files/file_egflf465vbk7468mvnb",
  "type" : "image/jpeg"
}
```

The client can use the uploaded file's URI (received in the above response) for any subsequent operation that requires the uploaded file as shown below.

#### Example Request:

```json
POST /v1/identity/limits-resolutions
Host: api.foo.com
Content-Type: application/json
Authorization: Bearer oauth2_token

{
  ...
  "identity_document_reference" : "https://api.foo.com/v1/files/file_egflf465vbk7468mvnb"
}
```

### As Attachment

This option **SHOULD** be used if you have to combine the uploading of a file with an API request body or parameters in one API request.
For example, for the purpose of optimization or to process both the file upload and request data in an atomic manner.

For such use cases, the request **SHOULD** either use content-type multipart/mixed or multipart/related ([RFC 2387](https://tools.ietf.org/html/rfc2387)).
Following is an example of such a request.

#### Example of a multipart/related request:

The first part in the below multipart request is the request metadata, while the second part contains the binary file content

```
POST /v1/identity/limits-resolutions
Host: api.foo.com
Content-Type: multipart/related; boundary=--foo_bar_baz
Authorization: Bearer oauth2_token

--foo_bar_baz
Content-Type: application/json; charset=UTF-8

{
...
}

--foo_bar_baz
Content-Type: image/jpeg

[JPEG_DATA]
--foo_bar_baz--
```

## HATEOAS Use Cases

This section describes various use cases where HATEOAS could be used.
See the [Hypermedia](hypermedia.md) section for more detailed guidelines when implementing HATEOAS-style APIs.

As a guiding principle, when adopting HATEOAS, every API **SHOULD** strive for a single entry point.
Any response from this entry point will have [HATEOAS](https://en.wikipedia.org/wiki/HATEOAS) links using which the client can navigate to all other methods on the same resource or related resources and sub-resources.

### Patterns

Following are different patterns for defining such an API entry point.

#### Pattern 1: API with a top level entry point

For most APIs, there's a natural top level object or a collection which can be the resources addressed by the entry point.
For example, the API defined in the previous section has a collection resource /users which can be the entry point URI.

#### Pattern 2: Entry point for complex controller style operations

A complex multi step operation always has a logical entry point.
For example, you want to build an API for a credit application process that involves multiple steps- a create application step, consumer consent step (to sign, agree to terms and conditions), an approval step- the last step of a successful credit application.

- `/apply-credit` is the API's entry point.

All other steps would be guided by the "application create" step in the `from` of links based on the captured data.
For example a successful "create application" step would return the link to the next state of the application process `apply-sign`.

- An unsuccessful (application with incorrect data) **MAY** return only a link to send only the incorrect/missing data (e.g PATCH link).

#### Pattern 3: API without a top level entry point

Consider an API that provides a set of independent controller style utility methods.
For example, you want to build an identity API that provides the following utility methods.

- generate OTP (one time password)
- encrypt payload using a particular algorithm
- decrypt the payload, link tokens

For such cases, the API **MAY** provide a separate resource /actions to return links to all resources that can be served by this API.
`GET /actions` in the above example would return links to other api methods (`/generate-otp`,`/encrypt`,`/decrypt`,`/link-tokens`).

### Navigating A Collection

For collection resources, a service **MAY** automatically provide a paginated collection.
The Client can also specify its pagination preferences, if the query resultset is quite large.
In such cases, the resultset is returned as a paginated collection with appropriate pagination related links.
The Client utilizes these links to navigate through the resultset back-and-forth.
For more details on this linking pattern, please refer to Pagination and HATEOAS links.

### Error Resolution

There are often use cases where an API wants to provide additional context in case of error along with other error details beyond simple HTTP status codes.
(See Error Standards for more).
An API could return additional resource links to provide more hints on the error in order to resolve it.
Consider an example from the `/users` API where the user wants to update his address details.

#### Request:

```json
PATCH /v1/users/ALT-JFWXHGUV7VI
{
  "address": {
    ...
  }
}
```

The service, however, finds that the user account is currently not active.
It responds with an error explaining that an update of this account is not possible given the current state.
It also returns an HATEOAS link in the response to activate the user account.

#### Response:

```json
HTTP/1.1 422 Unprocessable Entity
{
  "name":"INVALID_OPERATION",
  "debug_id":"123456789",
  "message":"An update to an inactive account is not supported.",
  "links": [
    {
      "href": "https://api.foo.com/v1/customer/partner-referrals/ALT-JFWXHGUV7VI/activate",
      "rel": "activate",
      "method": "POST"
    }
  ]
}
```

The client can now prompt the user to first activate his account and then change his address details.

### Service-controlled Flow

In a complex business operation that has one or more sub-business operations and business rules govern the state transitions at run-time, using HATEOAS links to describe or emit the allowed state transitions prevents clients from embedding the service-specific business logic into their code.
Loose coupling or no coupling with server's business logic enables better evolution for both client and server.

For example, an order can be cancelled when it is in a PENDING state.
The order cannot be cancelled once it moves to a COMPLETED state.
Following example shows how a service can use HATEOAS links to guide clients about next possible step(s) in business process.

#### Example: Pending Order

Order is in PENDING state, so the service returns the cancel HATEOAS link.

##### Request:

```
GET v1/checkout/orders/52181732T9513405D HTTP/1.1
Host: api.foo.com
Content-Type: application/json
Authorization: Bearer oauth2_token
```

##### Response:

```json
HTTP/1.1 200 OK
Content-Type: application/json
{
  "payment_details":{
    ...
  },
  "status":"PENDING",
  "links":[
    {
      "href": "https://api.foo.com/v1/checkout/orders/19S86694A9334040A",
      "rel": "self",
      "method": "GET"
    },
    {
      "href": "https://api.foo.com/v1/checkout/orders/19S86694A9334040A/cancel",
      "rel": "cancel",
      "method": "POST"
    }
  ]
}
```

#### Example: Completed Order

Order is in COMPLETED state so the services does not return the cancel link anymore.

##### Request:

```
GET v1/checkout/orders/52181732T9513405D HTTP/1.1
Host: api.foo.com
Content-Type: application/json
Authorization: Bearer oauth2_token
```

##### Response:

```json
HTTP/1.1 200 OK
Content-Type: application/json
{
  "payment_details":{
    ...
  },
  "status":"COMPLETED",
  "links":[
    {
      "href": "https://api.foo.com/v1/checkout/orders/19S86694A9334040A",
      "rel": "self",
      "method": "GET"
    }
  ]
}
```

> NOTE: The service **MAY** decide to support cancellation of orders (for orders with COMPLETED status) in some countries in future but that does not require the client to change anything in its code.
All that a client knows or has coded when it first integrated with the service is the request body that is required to cancel an order.

### Asynchronous Operations

When an operation is carried out asynchronously, it is important to provide relevant links to client so that the client can find out more details about the operation such as finding out status or perform get, update and delete operations.
Please refer to Asynchronous Operations to find how the HATEOAS links could be used in response of an asynchronous operation.

### Saving Bandwidth

Some services always return very large response because of the nature of the domain they address.
APIs of such services are sometimes referred as Composite APIs (they accumulate data from various sources or an aggregate of more than one services).
For such APIs, sending the entire response drastically impacts performance of the API consumer, API server and the underlying network.
In such cases, the client can ask the service to return partial representation using `Prefer: return=minimal` HTTP header.
A service could send response with relevant HATEOAS links with minimal data to improve the performance.

