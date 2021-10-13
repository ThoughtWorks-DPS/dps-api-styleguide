# Naming Conventions

Naming conventions for URIs, query parameters, resources, fields and enums are described in this section.
Let us emphasize here that these guidelines are less about following the conventions exactly as described here but they are more about defining some naming conventions and sticking to them in a consistent manner while designing APIs.
Adhering to a defined convention across APIs provides the best consumer experience.

---

## Payload Naming Conventions

The data model for the representation **MUST** conform to JSON.
The values may themselves be objects, strings, numbers, booleans, or arrays of objects.

### Case Conventions

We have followed [camelCase](https://en.wikipedia.org/wiki/Camel_case) for field property names, based on [research](http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.158.9499).
We have followed [kebab-case](https://en.wikipedia.org/wiki/Letter_case#Special_case_styles) for components of the URL path as that seems to be the predominant style.
It is possible to use other forms such as [snake_case](https://en.wikipedia.org/wiki/Snake_case) or something else that you have devised yourself.
However, as noted above, any deviations from consistent API style erode the usability and effectiveness of the APIs as a whole.

|Use Case|Case Convention|
|--------|---------------|
|URI|kebab-case|
|Query parameters|camelCase|
|JSON properties|camelCase|
|Enumerated values|SNAKE_CASE_IN_CAPS|

### Field Names

- Key names **MUST** be lower-case words.
If compound words, **MUST** follow camelCase.
    - `foo`
    - `barBaz`
- Prefix such as is\* or has\_ **SHOULD NOT** be used for keys of type boolean.
- Fields that represent arrays **SHOULD** be named using plural nouns
    - `products` - contains one or more products.

### Enum Names

Entries (values) of an enum **SHOULD** be composed of only upper-case alphanumeric characters and the underscore character, ( \_ ).

- `FIELD_10`
- `NOT_EQUAL`

If there is an industry standard that requires us to do otherwise, enums **MAY** contain other characters.

### Link Relation Names

A link relation type represented by rel must be in lower-case.

#### Example:

```json
{
  "links": [
    {
      "href": "https://uri.example.com/v1/customer/partner-referrals/ALT-JFWXHGUV7VI/activate",
      "rel": "activate",
      "method": "POST"
    }
  ]
}
```

## File Names

JSON schema for various types used by API **SHOULD** each be contained in separate files, referenced using the `$ref` syntax (e.g. `"$ref":"object.json"`).
JSON Schema files **SHOULD** use underscore naming syntax, e.g. `transaction_history.json`.

## URI Naming Conventions

URIs follow [RFC 3986](https://tools.ietf.org/html/rfc3986) specification.
This specification simplifies REST API service development and consumption.
The guidelines in this section govern your URI structure and semantics following the RFC 3986 constraints.

### URI Components

According to [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986), the generic URI syntax consists of a hierarchical sequence of components referred to as the scheme, authority, path, query, and fragment as shown in example below.

An API’s resource path consists of URI’s path, query and fragment components.
It would include API’s major version followed by namespace, resource name and optionally one or more sub-resources.
For example, consider the following URI.

```
https://api.example.com/v1/vault/credit-cards/7LT50814996/charges?merchantId=8FW3C1AB
\___/\________________/\________________________________________/\__________________/
  |              |                        |                                |
scheme       authority                   path                            query
                       \_/\____/\___________/\__________/\______/\_________/\_______/
                        |    |        |             |        |        |         |
                     version |     resource        {id}      |    parameter   {value}
                         namespace                      subresource
```

Following table lists various pieces of the above URI:

|Component|Path Piece|Description|Definition|
|---------|----------|-----------|----------|
|scheme|https|Request protocol|The protocol defines how the client and server communicate the request / reply.|
|authority|api.example.com|Server|The domain name of the server offering the service.|
|path|v1/..../charges|Resource Path|The location of the resource being queried.|
|query|merchantId=8F33C1AB|Query filter|The filter criteria we wish to use as the criteria for filtering results from the collection.|

Following table lists various pieces of the above URI's resource path (including the query):

|Component|Path Piece|Description|Definition|
|---------|----------|-----------|----------|
|version|v1|Specifies major version 1 of the API|The API major version is used to distinguish between two backward-incompatible versions of the same API. The API major version is an integer value which **MUST** be included as part of the URI.|
|namespace|vault|Business Domain|Namespace identifiers are used to provide a context and scope for resources. They are determined by logical boundaries in the business capability model implemented by the API platform.|
|resource|credit-cards|Resource name|If the resource name represents a collection of resources, then the GET method on the resource should retrieve the list of resources. Query parameters should be used to specify the search criteria.|
|{id}|`7LT50814996`|Resource ID|To retrieve a particular resource out of the collection, a resource ID **MUST** be specified as part of the URI. Sub-resources are discussed below.|
|subresource|charges|Sub-Resource name|If the sub-resource name represents a collection of resources, then the GET method on the resource should retrieve the list of resources. Query parameters should be used to specify the search criteria.|
|parameter|merchantId|Property Name|The property we wish to use as the criteria for filtering results from the collection.|
|{value}|`8FW3C1AB`|Filter value|To retrieve a particular set of resources out of the collection, a filter value **MUST** be specified as part of the URI to restrict the data included in the collection.|

### Formal Definition

|Term|Definition|
|----|----------|
|URI|`[end-point] ‘/’ resource-path [’?'query]`|
|end-point|`[scheme “://”] host [’:’ port]]`|
|scheme|`http` or `https`|
|resource-path| `“/v” version ‘/’ namespace-name ‘/’ resource (’/’ resource)`|
|resource|`resource-name [’/’ resource-id]`|
|resource-name|`Alpha (Alpha | Digit | ‘-’)*`|
|resource-id|`value`|
|query|`name ‘=’ value (’&’ name = value)*`|
|name|`Alpha (Alpha | Digit | ‘_’)*`|
|value|URI Percent encoded value|

> Legend:
> 
> - ' Surround a special character with single quotes
> - " Surround strings with double quotes
> - () Use parentheses for grouping
> - [] Use brackets to specify optional expressions
> - * An expression can be repeated zero or more times

### URI Component Names

Following is a brief description of the URI specific naming convention guidelines for APIs.
This specification uses the following notation to denote special meaning:

- parentheses “( )” to group
- an asterisk " * " to specify zero or more occurrences
- brackets “[ ]” for optional fields.

`[scheme]://[host][':'port]]"v{major-version}/{namespace}/{resource}(/{sub-resource})* ?{query}`

- URIs **MUST** start with a letter and use only lower-case letters.
- Literals/expressions in URI paths **SHOULD** be separated using a hyphen ( - ).
- Literals/expressions in query strings **SHOULD** be expressed in camelCase.
- URI paths and query strings **MUST** percent encode data into UTF-8 octets.
- Plural nouns **SHOULD** be used in the URI where appropriate to identify collections of data resources.
    - `/invoices`
    - `/statements`
- An individual resource in a collection of resources **MAY** exist directly beneath the collection URI.
    - `/invoices/{invoiceId}`
- Sub-resource collections **MAY** exist directly beneath an individual resource.
  This should convey a relationship to another collection of resources (invoice-items, in this example).
    - `/invoices/{invoiceId}/items`
- Sub-resource individual resources **MAY** exist, but should be avoided in favor of top-level resources.
    - `/invoices/{invoiceId}/items/{itemId}`
    - Better: `/invoice-items/{invoiceItemId}`
- Resource identifiers **SHOULD** follow recommendations described in the subsequent section.

#### Examples:

```
https://api.example.com/v1/vault/credit-cards
https://api.example.com/v1/vault/credit-cards/CARD-7LT50814996943336KESEVWA
https://api.example.com/v1/payments/billing-agreements/I-V8SSE9WLJGY6/re-activate
```

### Resource Names

When modeling a service as a set of resources, developers **MUST** follow these principles:

- Nouns **MUST** be used, not verbs.
- Resource names **MUST** be singular for singletons; collections’ names **MUST** be plural.
    - Given a description of the automatic payments configuration on a user’s account
        - `GET /autopay` returns the full representation
    - Given a collection of hypothetical charges:
        - `GET /charges` returns a list of charges that have been made
        - `POST /charges` creates a new charge resource, /charges/1234
        - `GET /charges/1234` returns a full representation of a single charge
- Resource names **MUST** be lower-case and use only alphanumeric characters and hyphens.
- The hyphen character, ( - ), **MUST** be used as a word separator in URI path literals.
  Note that this is the only place where hyphens are used as a word separator.
  In nearly all other situations, camelCase formatting, **MUST** be used.


### Query Parameter Names

- Literals/expressions in query strings **SHOULD** be formatted using camelCase.
- Query parameters values **MUST** be percent-encoded.
- Query parameters **MUST** start with a letter.
  Only alpha characters and digits character **SHALL** be used.
- Query parameters **SHOULD** be optional.
- Some query parameter names are reserved, as indicated in Resource Collections.
  For more specific info on the query parameter usage, see URI Standards.

#### Sub-Resources

Sub-resources represent a relationship from one resource to another.
The sub-resource name provides a meaning for the relationship.

- If cardinality is 1:1, then no additional information is required.
Otherwise, the sub-resource **SHOULD** provide a sub-resource ID for unique identification.
- If cardinality is 1:many, then all the sub-resources will be returned.
- No more than two levels of sub-resources **SHOULD** be supported.

|Example|Description|
|-------|-----------|
|`GET https://api.example.com/v1/customer-support/disputes/ABCD1234/documents`|This call should return all the documents associated with dispute ABCD1234.|
|`GET https://api.example.com/v1/customer-support/disputes/ABCD1234/documents/102030`|This call should return only the details for a particular document associated with this dispute. Keep in mind that this is only an illustrative example to show how to use sub-resource IDs. In practice, two step invocations **SHOULD** be avoided. If the second identifier is unique, top-level resource (e.g. `/v1/customer-support/documents/102030`) is preferred.|
|`GET https://api.example.com/v1/customer-support/disputes/ABCD1234/transactions`|The following example should return all the transactions associated with this dispute and their details, so there **SHOULD NOT** be a need to specify a particular transaction ID. If specific transaction ID retrieval is needed, `/v1/customer-support/transactions/ABCD1234` is preferred (assuming IDs are unique).|

#### Resource Identifiers

Resource identifiers identify a resource or a sub-resource.
These **MUST** conform to the following guidelines.

- The lifecycle of a resource identifier **MUST** be owned by the resource’s domain model, where they can be guaranteed to uniquely identify a single resource.
- APIs **MUST NOT** use the database sequence number as the resource identifier.
- A UUID, Hashed Id (HMAC based) is preferred as a resource identifier.
- For security and data integrity reasons all sub-resource IDs **MUST** be scoped within the parent resource only.

##### Example:

`/users/1234/linked-accounts/ABCD`

- Even if account “ABCD” exists, it **MUST NOT** be returned unless it is linked to user: 1234.
- Enumeration values can be used as sub-resource IDs.
  String representation of the enumeration value **SHOULD** be used.
- There **MUST NOT** be two resource identifiers one after the other.
  Example: `https://api.example.com/v1/transactions/payments/12345/102030`
- Resource IDs **SHOULD** try to use either Resource Identifier Characters or ASCII characters.
  There **SHOULD NOT** be any ID using UTF-8 characters.
- Resource IDs and query parameter values **MUST** perform URI percent-encoding for any character other than URI unreserved characters.
  Query parameter values using UTF-8 characters **MUST** be encoded.

### Query Parameters

Query parameters are name/value pairs specified after the resource path, as prescribed in RFC 3986.

Naming Conventions should also be followed when applying the following section.

#### Filter a resource collection

- Query parameters **SHOULD** be used only for the purpose of restricting the resource collection or as search or filtering criteria.
- The resource identifier in a collection **SHOULD NOT** be used to filter collection results, resource identifier should be in the URI.
- Parameters for pagination **SHOULD** follow standard naming convention guidelines.
- Default sort order **SHOULD** be considered as undefined and non-deterministic.
  If an explicit sort order is desired, the query parameter sort **SHOULD** be used with the following general syntax: `{fieldName}|{asc|desc},{fieldName}|{asc|desc}`.
  For instance: `/accounts?sort=dateOfBirth|asc,zipCode|desc`

#### Query parameters on a single resource

In typical cases where one resource is utilized (e.g. `/v1/payments/billing-plans/P-94458432VR012762KRWBZEUA`), query parameters **SHOULD NOT** be used.

#### Cache-friendly APIs

In rare cases where a resource needs to be highly cacheable (usually data with minimal change), query parameters **MAY** be utilized as opposed to POST + request body.
As POST would make the response uncacheable, GET is preferred in these situations.
This is the only scenario in which query parameters **MAY** be required.

#### Query parameters with POST

When POST is utilized for an operation, query parameters are usually **NOT RECOMMENDED** in favor of request body fields.
In cases where POST provides paged results (typically in complex search APIs where GET is not appropriate), query parameters **MAY** be used in order to provide hypermedia links to the next page of results.

#### Passing multiple values for the same query parameter

When using query parameters for search functionality, it is often necessary to pass multiple values.
For instance, it might be the case that a resource could have many states, such as OPEN, CLOSED, and INVALID.
What if an API client wants to find all items that are either CLOSED or INVALID?

- It is **RECOMMENDED** that APIs implement this functionality by repeating the query parameter.
  This is inherently supported by HTTP standards and already built in to most client libraries.
- The query above would be implemented as `?status=CLOSED&status=INVALID`.
- The parameter **MUST** be marked as repeatable in API specifications using `"repeated": true` in the parameter’s definition section.
- The parameter’s name **SHOULD** be singular.

URIs have practical length limits that are quite low - most conservatively, about [2,000 characters](https://stackoverflow.com/questions/417142/what-is-the-maximum-length-of-a-url-in-different-browsers#417184).
Therefore, there are situations where API designers **MAY** choose to use a single query parameter that accepts comma-separated values in order to accommodate more values in the `query-string`.
Keep in mind that server and client libraries don’t consistently provide this functionality, which means that implementers will need to write additional string parsing code.
Due to the additional complexity and divergence from HTTP standards, this solution is NOT RECOMMENDED unless justified.

- The query above would be implemented as `?statuses=CLOSED,INVALID`.
- The parameter **MUST NOT** be marked as repeatable in API specifications.
- The parameter **MUST** be marked as `"type": "string"` in API specifications in order to accommodate comma-separated values.
  Any other type value **MUST NOT** be used.
- The parameter description **SHOULD** indicate that comma separated values are accepted.
- The `query-parameter` name **SHOULD** be plural, to provide a hint that this pattern is being employed.
- The comma character (Unicode U+002C) **SHOULD** be used as the separator between values.
- The API documentation **MUST** define how to escape the separator character, if necessary.

#### Complex Queries

The syntax defined above is sufficient to provide simple filter capabilities within the URL path.
At a certain point, the complexity of desired queries grows beyond our ability to reasonably express within the URL.
This complexity could be driven by a variety of domain, design, or organizational dynamics.

No matter the cause, re-examine your API before embarking on the creation of a complex query model to include as a request payload.
It may be possible to refactor the API, or provide more specialized endpoints suited to the use-case.
It may also be possible to refactor the domain context, either splitting the domain, or identifying a higher-level concept better suited to the use-case.

> NOTE: The one exception to this rule is when considering the inclusion of PII in query parameters.
> For these cases, it is recommended to provide a simple query payload for use in a POST request.
> This provides a mechanism to avoid including PII in the URL (and the associated dangers of logging or otherwise accidentally exposing PII).
