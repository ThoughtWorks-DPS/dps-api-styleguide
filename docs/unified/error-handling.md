# Error Handling

---

As per HTTP specifications, the outcome of a request execution could be specified using an integer and a message.
The number is known as the status code and the message as the reason phrase.
The reason phrase is a human-readable message used to clarify the outcome of the response.
The HTTP status codes in the 4xx range indicate client-side errors (validation or logic errors), while those in the 5xx range indicate server-side errors (usually defect or outage).
However, these status codes and human-readable reason phrases are not sufficient to convey enough information about an error in a machine-readable manner.
To resolve an error, non-human consumers of RESTful APIs need additional help.

Therefore, APIs **MUST** return a JSON error representation that conforms to the schema defined in [RFC 7807](https://tools.ietf.org/html/rfc7807).
Zalando have implemented a [JSON Schema definition of the RFC 7807 spec](https://opensource.zalando.com/problem/schema.yaml#/Problem) which we use by reference. 

## Error Schema

An error response following RFC 7807 schema **MUST** conform to the following structure:

```json
{
  "type": "https://api.example.com/types/<namespace>/errors/<category>/<error>",
  "title": "Request data validation error",
  "status": 400,
  "detail": "One or more fields failed validation",
  "instance": "UUID",
  "invalidParams": [{
    "field": "nickname",
    "code": "https://api.example.com/types/<namespace>/errors/validations/missing",
    "message": "The value for this field needs to be present."
  }]
}
```

The error response structure includes the following fields:

|Field|Description|
|-----|-----------|
|type|A human-readable, unique URI for the error. The URI **MAY** be an endpoint which provides more information about the type of error.|
|title|A human-readable message, describing the error. This message **MUST** be a description of the problem NOT a suggestion about how to fix it.|
|status|The HTTP Error Code response of this error.|
|detail|If present, the detail field **SHOULD** focus on helping the client correct the problem, rather than giving debugging information.|
|instance|A unique error identifier generated on the server-side and logged for correlation purposes. This could be trace / span identifiers.|
|invalidParams|An extension to the error payload.  An array that contains individual instance(s) of the error with specifics such as the following. This field is required for client side errors (4xx).|
|field|JSON Pointer to the field in error if in body, else name of the path parameter or query parameter.|
|code|A human-readable, unique name for the error.|
|message|A human-readable message, describing the error. This message **MUST** be a description of the problem NOT a suggestion about how to fix it.|
|errors|An array of individual request errors (or successes) when a bulk request fails.|

> NOTE: The domain name for the error types should be reflective of your organization, not `example.com`.
> In this instance, it should be `twdps.io`.

## Use of JSON Pointer

If you have used some other means to identify the field in an already released API, you could continue using your existing approach.
However, if you plan to migrate to the approach suggested, you would want to bump up the major version of your API and provide migration assistance to your clients as this could be a potential breaking change for them.
The JSON Pointer for the field **SHOULD** be a JSON string value.

### Input Validation Errors

In validating requests, there are a variety of concerns that should be addressed in the following order:

|Problem|Code|
|-------|----|
|Not well-formed JSON|`400 Bad Request`|
|Contains validation errors that the client can change.|`400 Bad Request`|
|Cannot be executed due to factors outside of the request body.|`422 Unprocessable Entity`|
|The request was well-formed but was unable to be followed due to semantic errors.|`409 Conflict`|

### Error Samples

This section provides some samples to describe usage of RFC 7807 in various scenarios.

#### Validation Error Response - Single Field

The following sample shows a validation error in one field.
Because this is a client error, a `400 Bad Request` HTTP status code should be returned.

```json
{
  "type": "https://api.example.com/types/profile/errors/validations/invalid-user",
  "title": "Invalid data provided",
  "status": 400,
  "detail": "One or more fields failed validation",
  "instance": "123456789",
  "invalidParams": [
    {
      "field": "customerId",
      "message": "Required field is missing",
      "code": "https://api.example.com/types/profile/errors/validations/too-long"
    }
  ]
}
```

#### Validation Error Response - Multiple Fields

The following sample shows a validation error of the same type in two fields.
Note that `invalidParams` is an array listing all the instances in the error.
Because both these are a client errors, a `400 Bad Request` HTTP status code should be returned.

```json
{
  "type": "https://api.example.com/types/profile/errors/validations/invalid-user",
  "title": "Invalid data provided",
  "status": 400,
  "detail": "One or more fields failed validation",
  "instance": "123456789",
  "invalidParams": [
    {
      "field": "customerId",
      "message": "Required field is missing",
      "code": "https://api.example.com/types/profile/errors/validations/too-long"
    },
    {
      "field":"name",
      "message":"Name must be < 20 chars",
      "code": "https://api.example.com/types/profile/errors/validations/too-long"
    }
  ]
}
```

#### Validation Error Response - Bulk

For heterogeneous types of client-side errors shown below resulting from a bulk request, the error payload includes an array named `errors`.
Each error instance is represented as an item in this array.
Because these are client validation errors, a `400 Bad Request` HTTP status code should be returned.

```json
{
  "type": "https://api.example.com/types/profile/errors/bulk/failed",
  "title": "Invalid data provided",
  "status": 400,
  "detail": "One or more of the bulk requests failed.",
  "instance": "123456789",
  "errors": [
    {
      "type": "error://api.example.com/types/profile/errors/validations/invalid-user",
      "title": "Invalid data provided",
      "detail": "One or more fields failed validation",
      "status": 400,
      "instance": "123456789",
      "invalidParams": [
        {
          "field": "customerId",
          "message": "Required field is missing",
          "code": "error://api.example.com/types/profile/errors/validations/missing"
        },
        {
          "field": "name",
          "message": "Name must be < 20 chars",
          "code": "error://api.example.com/types/profile/errors/validations/too-long"
        }
      ]
    },
    {
      "type": "error://api.example.com/types/profile/errors/bulk/success",
      "title": "Individual request within bulk request succeeded",
      "detail": "Request succeeded",
      "status": 200,
      "instance": "123456789"
    },
    { ... }
  ]
}
```

#### Semantic Validation Error Response

In cases where client input is well-formed and valid but the request action may require interaction with APIs or processes outside of this URI, an HTTP status code `422 Unprocessable Entity` should be returned.

```json
{
  "type": "error://api.example.com/types/profile/errors/account/balance-error",
  "title": "Insufficient balance.",
  "status": 409,
  "detail": "The account balance is too low. Add balance to your account to proceed.",
  "instance": "123456789"
}
```

#### Error Declaration In API Specification

It is important that documentation generation tools and client/server-side binding generation tools recognize RFC 7807.
Following section shows how you could refer to the Zalando definition in an API specification confirming to OpenAPI.

```json
{
  "responses": {
    "200": {
      "title": "Address successfully found and returned.",
      "schema": {
        "$ref": "address.json"
      }
    },
    "403": {
      "title": "Unauthorized request. This error will occur if the SecurityContext header is not provided or does not include a party_id.",
      "schema": {
        "$ref": "https://opensource.zalando.com/problem/schema.yaml#/Problem"
      }
    },
    "404": {
      "title": "Address does not exist.",
      "schema": {
        "$ref": "https://opensource.zalando.com/problem/schema.yaml#/Problem"
      }
    },
    "default": {
      "title": "Unexpected error response.",
      "schema": {
        "$ref": "https://opensource.zalando.com/problem/schema.yaml#/Problem"
      }
    }
  }
}
```

## Documentation Standards

Documentation of error conditions is just as important as the documentation of intended use.
Since the range of failure modes is typically larger than success, efforts to provide comprehensive error documentation will  

### Samples with Error Scenarios in Documentation

The User Guide of an API is a document that is exposed to API consumers.
In addition to linking to samples showing successful execution for invocation on various methods exposed by the API, the API developer should also provide links to samples showing error scenarios.
It is equally, or perhaps more, important to show the API consumers how an API would propagate errors in a machine-readable form in order to build applications that take necessary actions to handle errors gracefully and in a meaningful manner.
In conclusion, we reiterate the message we started with that non-human consumers of RESTful APIs need more help to take necessary actions to resolve an error in a machine-readable manner.
Therefore, a representation of errors following the schema described here **MUST** be returned by APIs for any HTTP status code that falls into the ranges of 4xx and 5xx.

