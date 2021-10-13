# Bulk Operations

This section describes guidelines for handling bulk calls in APIs.

---

## Methodology

There are two different methods that one could use for bulk processing.

- Homogeneous:
Operation involves request and response payload representing collection of resources of the same type.
Same operation is applied on all items in the collection.
- Heterogeneous:
Operation involves a request and response payload that contains one or more requests and response payloads respectively.
Each nested request and response represents an operation on a specific type of resource.
However, the container request and response have one or more operations operating on one or more types of resources.
It is **RECOMMENDED** to use a public domain standard such as OData Batch Specification in such cases.

This section only addresses bulk processing of payloads using the homogenous method.

## Request Format

Each bulk request is a single HTTP request to one target API endpoint.
This example illustrates a bulk add operation.

### Example Request:

```json
POST /v1/devices/cards HTTP/1.1
Host: api.foo.com
Content-Length: total_content_length
{
  ...
  "items": [
    {
      "account_number": "2097094104180012037",
      "address_id": "466354",
      "phone_id": "0",
      "first_name": "M",
      "last_name": "Shriver",
      "primary_card_holder": false
    },
    {
      "account_number": "2097094104180012047",
      "address_id": "466354",
      "phone_id": "0",
      "first_name": "M",
      "last_name": "Shriver",
      "primary_card_holder": false
    },
    {
      "account_number": "2097094104180012023",
      "address_id": "466354",
      "phone_id": "0",
      "first_name": "M",
      "last_name": "Shriver",
      "primary_card_holder": false
    }
  ]
}
```

## Response Format

The response usually contains the status of each item.
Failure of an individual item is described using Error Handling Guidelines for an individual item.
Given below is such an example.

#### Example Response:

```json
HTTP/1.1 200 OK

{
  ...
  "batch_result":[
    {
      … <Success_body>
    },
    {
      "name": "VALIDATION_ERROR",
      "details": [
        {
          "field": "#/credit_card/expire_month",
          "issue": "Required field is missing",
          "location": "body"
        }
      ],
      "debug_id": "123456789",
      "message": "Invalid data provided",
      "information_link": "http://developer.foo.com/apidoc/blah#VALIDATION_ERROR"
    },
    {
      "name": "VALIDATION_ERROR",
      "details": [
        {
          "field":"#/credit_card/currency",
          "value":"XYZ",
          "issue":"Currency code is invalid",
          "location":"body"
        }
      ],
      "debug_id": "123456789",
      "message": "Invalid data provided",
      "information_link": "http://developer.foo.com/apidoc/blah#VALIDATION_ERROR"
    }
  ]
}
```

If the API supports atomic semantics to processing requests, there would be a single response code for the entire request with one or more errors as applicable.

#### Example Response:

```json
HTTP/1.1 400 Bad Request
{
  "name": "VALIDATION_ERROR",
  "details": [
    {
      "field": "#/credit_card/currency",
      "value": "XYZ",
      "issue": "Currency code is invalid",
      "location": "body"
    }
  ],
  "debug_id": "123456789",
  "message": "Invalid data provided"
}
```

## Replace And Update

Similar to bulk add, a service can support bulk update operation (replace using HTTP PUT or partial update using PATCH).
This is possible provided the bulk add request also creates a first-class resource (e.g. a batch resource) that is uniquely identifiable using an id and returned to the client.
The subsequent update operations could then use this id and perform updates on constituent elements of the batch as if an update is performed on a single resource.

For bulk replace and update operations, every effort should be made to make the execution atomic (all or nothing semantics).
When it is not possible to make it so, the response should be similar to the partial response of bulk add operation described in the previous section.

## HTTP Status Codes And Error Handling

The following guidelines describe HTTP status code and error handling for bulk operations.

- If atomicity is supported (all or nothing), use the regular REST API standards for error handling as there would be only one response code.
- To support partial failures, you **MUST** return `200 OK` as the overall bulk processing status with individual status of each bulk item.
    - In case of an error while processing a bulk item, the error description **MUST** follow the Error Handling Guidelines.
- If asynchronous processing is supported, the API **MUST** return `202 Accepted` with a status URI for the client to monitor the request.
    - The client may choose to ignore the status URI if it has registered itself with the API server for notification via webhooks.

### Response-Request Correlation in Error Scenarios

For a failed item, you **MAY** use the [JSON Pointer Expressions](https://github.com/paypal/api-standards/blob/master/patterns.md#json-pointer-expression) in the error response for that item using the field attribute of [`error.json`](https://github.com/paypal/api-standards/blob/master/v1/schema/json/draft-04/error.json).
The caller can then map a response item's processing state to the exact request item in the original bulk request.
Given below is an error response sample using the JSON Pointer Expressions.

### Error Response Sample:
```json
HTTP/1.1 200 OK
{
  ...
  "batch_result": [
    {
      "name": "VALIDATION_ERROR",
      "details": [
        {
          "field": "/items/@account_number=='2097094104180012047'/address_id",
          "issue": "Invalid Address Id for the account",
          "location": "body"
        }
      ],
      "debug_id": "123456789",
      "message": "Invalid data provided"
    },
    {
      "name": "VALIDATION_ERROR",
      "details": [
        {
          "field": "/items/@account_number=='2097094104180012023'/phone_id",
          "value": "XYZ",
          "issue": "Phone Id is invalid",
          "location": "body"
        }
      ],
      "debug_id": "123456789",
      "message": "Invalid data provided"
    }
  ]
}
```

The alternative is to create a response that contains the processing status of each item in the same order as it was received in the original request.
The failed item would be represented using `error.json` with appropriate value in the field attribute.

### Error Response Sample:

```json
HTTP/1.1 200 OK
{
  ...
  "batch_result": [
    {
      "name": "VALIDATION_ERROR",
      "details": [
        {
          "field": "/items/0/address_id",
          "issue": "Invalid Address Id for the account",
          "location": "body"
        }
      ],
      "debug_id": "123456789",
      "message": "Invalid data provided"
    },
    {
      "name": "VALIDATION_ERROR",
      "details": [
        {
          "field": "/items/2/phone_id",
          "value": "XYZ",
          "issue": "Phone Id is invalid",
          "location": "body"
        }
      ],
      "debug_id": "123456789",
      "message": "Invalid data provided"
    }
  ]
}
```
