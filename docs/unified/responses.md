# HTTP Response Standards

---

## HTTP Status Codes

RESTful services use HTTP status codes to specify the outcomes of HTTP method execution.
HTTP protocol specifies the outcome of a request execution using an integer and a message.
The number is known as the status code and the message as the reason phrase.
The reason phrase is a human readable message used to clarify the outcome of the response.
HTTP protocol categorizes status codes in ranges.

### Status Code Ranges

When responding to API requests, the following status code ranges **MUST** be used.

|Range|Meaning|
|-----|-------|
|2xx|Successful execution. It is possible for a method execution to succeed in several ways. This status code specifies which way it succeeded.|
|3xx|Indicates that further action needs to be taken by the user agent in order to fulfill a request. The required action may be carried out by the user agent without interaction with the user, if and only if, the method used in the second request is GET or HEAD.|
|4xx|Usually these are problems with the request, the data in the request, invalid authentication or authorization, etc. In most cases the client can modify their request and resubmit.|
|5xx|Server error: The server was not able to execute the method due to site outage or software defect. 5xx range status codes **SHOULD** NOT be utilized for validation or logical error handling.|

### Status Reporting

Success and failure apply to the whole operation not just to the SOA framework portion or to the business logic portion of code execution.

Following are the guidelines for status codes and reason phrases.

- Success **MUST** be reported with a status code in the 2xx range.
- HTTP status codes in the 2xx range **MUST** be returned only if the complete code execution path is successful.
  This includes any container/SOA framework code as well as the business logic code execution of the method.
- A server returning a status code in the 2xx or 3xx range **MUST NOT** return a response following `error.json`, or any kind of error code, as the response body.
- Failures **MUST** be reported in the 4xx or 5xx range for both system and application errors.
- There **MUST** be a consistent, JSON-formatted error response in the body as defined by the `error.json` schema.
  This schema is used to qualify the kind of error.
  Please refer to Error Handling guidelines for more details.
- A server returning a status code in the 4xx or 5xx range **MUST** return the `error.json` response body.
- For client errors in the 4xx code range, the reason phrase **SHOULD** provide enough information for the client to be able to determine what caused the error and how to fix it.
- For server errors in the 5xx code range, the reason phrase and an error response following `error.json` **SHOULD** limit the amount of information to avoid exposing internal service implementation details to clients.
  This is true for both external facing and internal APIs.
  Service developers should use logging and tracking utilities to provide additional information.

### Allowed Status Codes List

All REST APIs **MUST** use only the following [status codes](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes).

The rest are primarily intended for web-services framework developers reporting framework-level errors related to security, content negotiation, etc.

- APIs **MUST** NOT return a status code that is not defined in this table.
- APIs **MAY** return only some of status codes defined in this table

|Status Code|Description|
|-----------|-----------|
|200 OK|General success message.|
|201 Created|Used as a response to POST method execution to indicate successful creation of a resource. If the resource was already created (by a previous execution of the same method, for example), then the server should return status code 200 OK.|
|202 Accepted|Used for asynchronous method execution to specify the server has accepted the request and will execute it at a later time. For more details, please refer Asynchronous Operations.|
|204 No Content|The server has successfully executed the method, but there is no entity body to return.|
|301 Moved Permanently|Used to indicate that the resource is located at a different path.  This is typically implemented at the Gateway or Service Mesh level.|
|302 Found|Used to indicate that the resource is temporarily located at a different path.  This is typically implemented at the Gateway or Service Mesh level.|
|304 Not Modified|Used in conditional GET operations as part of a caching strategy.|
|400 Bad Request|The request could not be understood by the server. Use this status code to specify if either a) The data as part of the payload cannot be converted to the underlying data type, b) The data is not in the expected data format, c) Required field is not available, or d) Simple data validation type of error.|
|401 Unauthorized|The request requires authentication and none was provided. Note the difference between this and `403 Forbidden`.|
|403 Forbidden|The client is not authorized to access the resource, although it may have valid credentials. API could use this code in case business level authorization fails.|
|404 Not Found|The server has not found anything matching the request URI. This either means that the URI is incorrect or the resource is not available. For example, it may be that no data exists in the database at that key.|
|405 Method Not Allowed|The server has not implemented the requested HTTP method. This is typically default behavior for API frameworks.|
|406 Not Acceptable|The server **MUST** return this status code when it cannot return the payload of the response using the media type requested by the client. For example, if the client sends an `Accept: application/xml` header, and the API can only generate `application/json`, the server **MUST** return 406.|
|409 Conflict|Indicates that the request could not be processed because of conflict in the current state of the resource, such as an edit conflict between multiple simultaneous updates.|
|415 Unsupported Media Type|The server **MUST** return this status code when the media type of the request’s payload cannot be processed. For example, if the client sends a `Content-Type: application/xml` header, but the API can only accept `application/json`, the server **MUST** return 415.|
|422 Unprocessable Entity|The requested action cannot be performed and may require interaction with APIs or processes outside of the current request. This is distinct from a 500 response in that there are no systemic problems limiting the API from performing the request.|
|429 Too Many Requests|The server must return this status code if the rate limit for the user, the application, or the token has exceeded a predefined value. Defined in Additional HTTP Status Codes [RFC 6585](https://tools.ietf.org/html/rfc6585).|
|500 Internal Server Error|This is either a system or application error, and generally indicates that although the client appeared to provide a correct request, something unexpected has gone wrong on the server. A 500 response indicates a server-side software defect or site outage. 500 **SHOULD** NOT be utilized for client validation or logic error handling.|
|501 Not Implemented|The client made a request for functionality that is currently unsupported.|
|503 Service Unavailable|The server is unable to handle the request for a service due to temporary maintenance.|
|504 Gateway Timeout|A dependency failed to respond within a reasonable timeframe.|

> NOTE: For `202 Accepted` response, the response body returned should include one or more URIs as hypermedia links, which could include:
>
> - The final URI of the resource where it will be available in future if the ID and path are already known.
>   Clients can then make an HTTP GET request to that URI in order to obtain the completed resource.
>   Until the resource is ready, the final URI SHOULD return the HTTP status code 404 Not Found.
>     - { "rel": "self", "href": "/v1/namespace/resources/{resource_id}", "method": "GET" }
> - A temporary request queue URI where the status of the operation may be obtained via some temporary identifier.
>   Clients should make an HTTP GET request to obtain the status of the operation which MAY include such information as completion state, ETA, and final URI once it is completed.
>     - { "rel": "self", "href": "/v1/queue/requests/{request_id}, "method": "GET" }"

### HTTP Method to Status Code Mapping

For each HTTP method, API developers **SHOULD** use only status codes marked as “X” in this table.
If an API needs to return any of the status codes marked with an X, then the use case **SHOULD** be reviewed as part of API design review process and maturity level assessment.
Most of these status codes are used to support very rare use cases.

|Status Code|GET|POST|PUT|PATCH|DELETE|
|---|---|---|---|---|---|
|200 – Success|X|X|X|X|X|
|201 – Created| |X| | | |
|202 – Accepted| |X|X| | |
|204 – No Content| | |X|X|X|
|301 – Moved Permanently| | | | | |
|302 – Found| | | | | |
|304 – Not Modified|X| | | | |
|400 – Bad Request|X|X|X|X|X|
|401 – Unauthorized|X|X|X|X|X|
|403 – Forbidden|X|X|X|X|X|
|404 – Not found|X| |X|X|X|
|405 – Method Not Allowed|X|X|X|X|X|
|406 – Not Acceptable|X|X|X|X|X|
|409 – Conflict| |X|X|X|X|
|415 – Unsupported Media Type| |X|X|X| |
|422 – Unprocessable Entity|X|X|X|X|X|
|429 – Too Many Requests|X|X|X|X|X|
|500 – Internal server Error|X|X|X|X|X|
|503 – Service Unavailable|X|X|X|X|X|

### GET

The purpose of the GET method is to retrieve a resource.
On success, a status code `200 OK` and a response with the content of the resource is expected.
In cases where resource collections are empty (0 items in /v1/namespace/resources), `200 OK` is the appropriate status (resource will contain an empty items array).
If a resource item is ‘soft deleted’ in the underlying data, `200 OK` is not appropriate (`404 Not Found` is correct) unless the ‘DELETED’ status is intended to be exposed.

### POST

The primary purpose of POST is to create a resource.
If the resource did not exist and was created as part of the execution, then a status code `201 Created` **SHOULD** be returned.
It is expected that on a successful execution, a reference to the resource created (in the form of a link or resource identifier) is returned in the response body.

Idempotency semantics: If this is a subsequent execution of the same invocation (including the `Idempotency-Key` header) and the resource was already created, then a status code of `200 OK` **SHOULD** be returned.
For more details on idempotency in APIs, refer to idempotency.

If a sub-resource is utilized (‘controller’ or data resource), and the primary resource identifier is non-existent, `404 Not Found` is an appropriate response.
POST can also be used while utilizing the controller pattern, `200 OK` is the appropriate status code.
In rare cases, server generated values may need to be provided in the response, to optimize client flow (if the client necessarily has to perform a GET after PUT).
In these cases, `200 OK` and a response body are appropriate.

### PUT

Since a `PUT` request is a wholesale replacement, the client already has the full content of the entity, so `204 No Content` + no response body is appropriate in this context.
`200 OK` + response body should be avoided, since responding with the entire resource can result in large bandwidth usage, especially for bandwidth-sensitive mobile clients.

In rare cases, server generated values may need to be provided in the response, to optimize client flow (if the client necessarily has to perform a GET after PUT).
In these cases, `200 OK` + response body are appropriate.

### DELETE

This method **SHOULD** return status code 204 as there is no need to return any content in most cases as the request is to delete a resource and it was successfully deleted.

As the DELETE method **MUST** be idempotent as well, it **SHOULD** still return `204 No Content`, even if the resource was already deleted.
Usually the API consumer does not care if the resource was deleted as part of this operation, or before.
This is also the reason why `204 No Content` instead of `404 Not Found` should be returned.

### PATCH

This method should follow the same status/response semantics as PUT, `204 No Content` status and no response body.

### POST-as-GET

There may be considerations that force us into an intentionally non-resourceful endpoint.
This is particularly true when using PII as query parameters / filters.
For example, you may decide to support searching by credit cards as a POST instead of a GET because we want to keep the credit card number off of the URL.
In this case, we are clearly and intentionally breaking the Uniform Interface architectural constraint of REST.
To indicate this as intentional, we should put a verb on the path to label this as RPC instead of RESTful.
