# HTTP Payload Standards

---

## Request / Response Body

All request and response bodies across any REST resource operation are expected to serialize data according to the JSON Data Interchange Format described in [RFC 7159](https://tools.ietf.org/html/rfc7159) and [JavaScript Object Notation (JSON)](http://json.org/).
JSON is built upon four primitive types (`string`, `number`, `boolean`, and `null`) and on two structures [5]:

1. *Object* - A collection of name/value pairs.
   In various languages, this is realized as an object, record, struct, dictionary, hash table, keyed list, or associative array.
2. *Array* - An ordered list of values.
   In most languages, this is realized as an array, vector, list, or sequence.
   JSON responses must always return a JSON object (and not e.g. an array) as a top level data structure to support future extensibility [2].
   Potential extensibility might include metadata such as paging, as an example.

## JSON Schema

[JSON Schema](http://json-schema.org/) is a vocabulary that allows you to annotate and validate JSON documents.
As of the writing of this style guide, the latest JSON Schema is version [2020-12](http://json-schema.org/draft/2020-12/json-schema-core.html).
OpenAPI spec defines an API’s contract interface and the [OpenAPI Schema Object](https://swagger.io/specification/) is based on the JSON Schema.
This enables the API provider to communicate JSON schema validation rules via OpenAPI spec.
Refer to both of these specifications when documenting the contract interface for consumers.

> NOTE: json-schema.org seems to have dropped the Hypermedia specification from the 2012-12 version of the spec.
> This document continues to refer to the [2019-09 version](http://json-schema.org/draft/2019-09/json-schema-hypermedia.html).
> YMMV.

### API Contract Description

There are various options available to define the API’s contract interface (API specification or API description).
Examples are: [OpenAPI](http://swagger.io/specification) (fka Swagger), [Google Discovery Document](https://developers.google.com/discovery/v1/reference/apis#method_discovery_apis_getRest), [RAML](http://raml.org/), [API BluePrint](https://apiblueprint.org/) and so on.
OpenAPI is a vendor neutral API description format.
The OpenAPI [Schema Object](http://swagger.io/specification/#schemaObject) (or OpenAPI JSON) is an extended subset of the [JSON Schema Specification](https://json-schema.org/).
In addition, there are extensions provided by the specification to allow for more complete documentation.

It is **RECOMMENDED** to use the latest version of the OpenAPI specification.
At the time of this writing, the latest version is v3.1.

We have used OpenAPI to describe the API specification throughout this document.

### $schema

Use `$schema` to indicate the version of JSON schema used by each JSON type you define as shown below.

```json
{
  "type": "object",
  "$schema": "https://json-schema.org/draft/2020-12/schema#",
  "name": "Order",
  "description": "An order transaction.",
  "properties": {
     ...
  }
}
```

In case your JSON type uses links, media and other such keywords or schemas such as for linkDescription that are defined in [http://json-schema.org/draft/2019-09/json-schema-hypermedia.html](http://json-schema.org/draft/2019-09/json-schema-hypermedia.html), you should provide the value for `$schema` accordingly as shown below.

```json
{
  "type": "object",
  "$schema": "https://json-schema.org/draft/2019-09/hyper-schema#",
  "name": "Linked-Order",
  "description": "An order transaction using HATEOAS links.",
  "properties": {
    ...
  }
}
```

If you are unsure about the specific schema version to refer to, it would be safe to refer [https://json-schema.org/draft/2019-09/hyper-schema#](https://json-schema.org/draft/2019-09/hyper-schema#) schema since it would cover the hypermedia aspects of any JSON schema.

#### readOnly:

When resources contain immutable fields, PUT/PATCH operations can still be utilized to update that resource.
To indicate immutable fields in the resource, the readOnly field can be specified on the immutable fields.

##### Example:

```json
"properties": {
  "id": {
    "type": "string",
    "description": "Identifier of the resource.",
    "readOnly": true
  }
}
```

### Advanced Syntax Guidance

Be aware that anyOf/allOf/oneOf syntax can cause issues with tooling, as code generators, documentation tools and validation of these keywords is often not implemented.

#### allOf

The allOf keyword **MUST** only be used for the purposes listed here.

##### Extend object

The allOf keyword in JSON Schema **SHOULD** be used for extending objects.
In draft-03, this was implemented with the extends keyword, which has been deprecated in draft-04.

Example:

A common need is to extend a common type with additional fields.
In this example, we will extend the [address](https://schema.org/address) with a typefield.

```json
"shipping_address": { 
  "\$ref": "v1/schema/address.json" 
}
```

Using the allOf keyword, we can combine both the common type address schema and an extra schema snippet for the address type:

```json
"shipping_address": {
  "allOf": [
  // Here, we include our "core" address schema...

    { "\$ref": "v1/schema/address.json" },
    // ...and then extend it with stuff specific to a shipping
    // address
    {
      "properties": {
        "type": { "enum": [ "residential", "business" ] }
      },
      "required": ["type"]
    }
  ]
}
```

#### anyOf/oneOf

The anyOf and oneOf keywords **SHOULD NOT** be used to design APIs.
A variety of problems occur from these keywords:

- Codegen tools do not have an accurate way to generate models/objects from these definitions.
- Developer portals would have significant difficulty in clearly explaining to API consumers the meaning of these relationships.
- Consumers using statically typed languages (e.g. C#, Java) have a more complex experience trying to conditionally deserialize objects which change based on some element.
- Custom deserialization code is required to represent objects based on the response, standard libraries do not accommodate this out of the box.
- Flat structures which combine all possible fields in an object are automatically deserialized properly.

##### anyOf/oneOf Problems: Example:

```json
{
  "activityType": {
    "description": "The entity type of the item. One of 'PAYMENT', 'MONEY-REQUEST', 'RECURRING-PAYMENT-PROFILE', 'ORDER', 'PAYOUT', 'SUBSCRIPTION', 'INVOICE'",
    "type": "string",
    "enum": [
      "PAYMENT",
      "MONEY-REQUEST"
    ]
  },
  "extensions": {
    "type": "object",
    "description": "Extension to core activity fields",
    "oneOf": [
      { "$ref": "v1/schema/extended_properties.json#/definitions/payment_properties" },
      { "$ref": "v1/schema/extended_properties.json#/definitions/money_request_properties" }
    ]
  }
}
```

In order for an API consumer to deserialize this response (where POJO/POCO objects are used), standard mechanisms would not work.
Because the extensions field can change on any given response, the consumer is forced to create a composite object to represent both `payment_properties.json` and `money_request_properties.json`.

A better approach:

```json
{
  "activityType": {
    "description": "The entity type of the item. One of 'PAYMENT', 'MONEY-REQUEST', 'RECURRING-PAYMENT-PROFILE', 'ORDER', 'PAYOUT', 'SUBSCRIPTION', 'INVOICE'",
    "type": "string",
    "enum": [
      "PAYMENT",
      "MONEY-REQUEST"
    ]
  },
  "payment": {
    "type": "object",
    "description": "Payment-specific activity.",
    "$ref": "v1/schema/payment.json"
  },
  "moneyRequest": {
    "type": "object",
    "description": "Money request-specific activity.",
    "$ref": "v1/schema/money_request.json"
  }
}
```

In this scenario, both `payment` and `moneyRequest` are in the definition.
However, in practice, only one field would be serialized based on the `activityType`.

For API consumers, this is a very predictable response, and allows for easy deserialization through standard libraries, without writing custom deserializers.

## JSON Types

This section provides guidelines related to usage of [JSON primitive types](https://docs.google.com/document/d/1hOkwz-fboULkiPOHPfvR8w3YvQTyQDhW9Lp-NJ7JzNE/edit#heading=h.7twav2snr1s2) as well as commonly useful JSON types for address, name, currency, money, country, phone, among other things.

### JSON Primitive Types

JSON Schema 2020-12 **SHOULD** be used to define all fields in APIs.
As such, the following notes about the JSON Schema primitive types **SHOULD** be respected.
Following are the guidelines governing use of JSON primitive type representations.

#### String

At a minimum, strings **SHOULD** always explicitly define a `minLength` and `maxLength`.
There are several reasons for doing so.

- Without a maximum length, it is impossible to reliably define a database column to store a given string.
- Without a maximum and minimum, it is also impossible to predict whether a change in length will break backwards-compatibility with existing clients.
- Finally, without a minimum length, it is often possible for clients to send an empty string when they should not be allowed to do so.

APIs **MAY** avoid defining `minLength` and `maxLength` only if the string value is from another system of record that has refused to provide any information on these values.
This decision must be documented in the schema.

API authors **SHOULD** consider practical limitations when defining `maxLength`.
For example, when using the `VARCHAR2` type, modern versions of Oracle can safely store a Unicode string of no more than 1,000 characters.
(The size limit is [4,000](https://docs.oracle.com/cd/B28359_01/server.111/b28320/limits001.htm) bytes and each Unicode character may take up to four bytes for storage).

`string` **SHOULD** utilize the pattern property as appropriate, especially when defining enumerated values or numbers.
However, it is **RECOMMENDED** not to overly constrain fields without a valid technical reason.

#### Enumeration

The JSON Schema enum keyword is difficult to use safely.
It is not possible to add new values to an enum in a schema that describes a service response without breaking backwards compatibility.
In that scenario, clients will often reject responses with values that are not in the older copy of the schema that they possess.
This is usually not the desired behavior.
Clients should usually handle unknown values more gracefully, but since you can’t control nor verify their behavior, it is not safe to add new enum values.

For the reasons stated above, the schema author **MUST** comply with the following guidelines while using an enum with the JSON type string.

- The keyword enum **SHOULD** be used only when the set of values are fixed and would never change in future.
- If you anticipate adding new values to the enum array in future, avoid using the keyword enum.
  You **SHOULD** instead use a string type and document all acceptable values for the string.
  When using a string type to express enumerated values, you **SHOULD** enforce naming conventions through a pattern field.
- If there is no technical reason to do otherwise – for instance, a pre-existing database column of smaller size – `maxLength` should be set to 255.
  `minLength` should be set to 1 to prevent clients sending the empty string.
- All possible values of an enum field **SHOULD** be precisely defined in the documentation.
  If there is not enough space in the description field to do so, you **SHOULD** use the API’s user guide to define them.

Given below is the JSON snippet for enforcing naming conventions and length constraints.

```json
{
  "type": "string",
  "minLength": 1,
  "maxLength": 255,
  "pattern": "^[0-9A-Z_]+\$",
  "description": "A description of the field. The possible values are OPTION_ONE and OPTION_TWO."
}
```

#### Number

There are a number of difficulties associated with number type in JSON.

JSON itself defines a number very simply: it is an unbounded, fixed-point value.
This is illustrated well by the railroad diagram for number at [JSON](http://json.org/).
There is only one number type in JSON; there is no separate integer type.

JSON Schema diverges from JSON and defines two number types: number and integer.
This is purely a convenience for schema validation; the JSON number type is used to implement both.
Just as in JSON, both types are unbounded unless the schema author provides explicit minimum and maximum values.

Many programming languages do not safely handle unbounded values in JSON.
JavaScript is an excellent example.
A JSON deserializer is provided as part of the [ECMAScript](http://www.ecma-international.org/publications/standards/Ecma-262.htm) specification.
However, it requires that all JSON numbers are deserialized into the only number type supported by JavaScript – 64-bit floating point.
This means that attempting to deserialize any JSON number larger than about 2<sup>53</sup> in a JavaScript client will result in an exception.

To ensure the greatest degree of cross-client compatibility possible, schema authors **SHOULD**:

- Never use the JSON Schema number type.
  Some languages may interpret it as a fixed-point value, and some as floating-point.
  Always use string to represent a decimal value.
- Only define integer types for values that can be represented in a 32-bit signed integer, that is to say, values between ((2<sup>31</sup>) - 1) and -(2<sup>31</sup>).
  This ensures compatibility across a wide range of programming languages and circumstances.
  For example, array indices in JavaScript are signed 32-bit integers.
- When using an integer type, always provide an explicit minimum and a maximum.
  This not only allows backwards-incompatible changes to be detected, it also guarantees that all values can fit in a 32-bit signed integer.
  If there are no technical reasons to do otherwise, the maximum and minimum should be defined as 2147483647 (((2<sup>31</sup>) - 1)) and -2147483648 (-(2<sup>31</sup>)) or 0 respectively.
  Common sense should be used to determine whether to allow negative values.
- Business logic that could change in the future generally **SHOULD NOT** be used to determine boundaries; business rules can easily change and break backwards compatibility.

If there is any possibility that the value could not be represented by a signed 32-bit integer, now or in the future, not use the JSON Schema integer type.
Use a string instead.

##### Examples:

This integer type might be used to define an array index or page count, or perhaps the number of months an account has been open.

```json
{
  "type": "integer",
  "minimum": 0,
  "maximum": 2147483647
}
```

When using a string type to represent a number, authors **MUST** provide boundaries on size using `minLength` and `maxLength`, and constrain the definition of the string to only represent numbers using pattern.

For example, this definition only allows positive integers and zero, with a maximum value of 999999:

```json
{
  "type": "string",
  "pattern": "^[0-9]+\$",
  "minLength": 1,
  "maxLength": 6
}
```

The following definition allows the representation of fixed-point decimal values both positive or negative, with a maximum length of 32 and no requirements on scale:

```json
{
  "type": "string",
  "pattern": "^(-?[0-9]+|-?([0-9]+)?[.][0-9]+)$",
  "maxLength": 32,
  "minLength": 1,
}
```

#### Array

JSON defines an array as unbounded.
Although practical limits are often much lower due to memory constraints, many programming languages do place maximum theoretical limits on the size of arrays.
For example, JavaScript is limited to the length of a 32-bit unsigned integer by the ECMA-262 specification.
Java is [limited to about Integer.MAX_VALUE - 8](https://stackoverflow.com/questions/3038392/do-java-arrays-have-a-maximum-size#3039805), which is less than half of JavaScript.

To ensure maximum compatibility across languages and encourage paginated APIs, `maxItems` **SHOULD** always be defined by schema authors.
`maxItems` **SHOULD NOT** have a value greater than can be represented by a 16-bit signed integer, in other words, 32767 or (2<sup>15</sup>) - 1).

Note that developers **MAY** choose to set a smaller value; the value 32767 is a default choice to be used when no better choice is available.
However, developers **SHOULD** design their API for growth.

For example, although a paginated API may only support a maximum of 100 results per page today, performance improvements may allow developers to improve that to 1,000 results next year.
Therefore, `maxItems` **SHOULD NOT** be used to communicate maximum page size.
`minItems` **SHOULD** also be defined.
In most situations, its value will be either 0 or 1.

#### Null

APIs **MUST NOT** produce or consume null values.

`null` is a primitive type in JSON.
When validating a JSON document against JSON Schema, a property’s value can be nullonly when it is explicitly allowed by the schema, using the type keyword (e.g. `{"type": "null"}`).
Since in an API type will always need to be defined to some other value such as object or string, and these standards prohibit using schema composition keywords such as anyOf or oneOf that allow multiple types, if an API produces or consumes null values, it is unlikely that, according to the API’s own schemas, this is actually valid data.

In addition, in JSON, a property that doesn’t exist or is missing in the object is considered to be undefined; this is conceptually separate from a property that is defined with a value of null, but many programming languages have difficulty drawing this distinction.
For example, a property my_property defined as `{"type": "null"}` is represented as

```json
{
  "myProperty": null
}
```

While a property that is undefined would not be present in the object:

```json
{ }
```

In most strongly typed languages, such as Java, there is no concept of an undefined type, which means that for all undefined fields in a JSON object, a deserializer would return the value of such types as null when you try to retrieve them.
Similarly, some Java-based JSON serializers serialize fields to JSON null by default, even though it is not possible for the serializer to determine whether the author of the Java object intended for that property to be defined with a value of null, or simply undefined.
In Jackson, for example, this behavior is moderated through use of the [JsonInclude](https://fasterxml.github.io/jackson-annotations/javadoc/2.8/com/fasterxml/jackson/annotation/JsonInclude.html) annotation.

On the other hand, the `org.json` library defines an object called NULL to distinguish between null and undefined.

Eschewing JSON null completely helps avoid many of these subtle cross-language compatibility traps.

#### Additional Properties

Setting of [additionalProperties](http://json-schema.org/latest/json-schema-validation.html#anchor134) to false in schema objects breaks backward compatibility in those clients that use an API’s JSON schemas (defined by its contract) to validate the API requests and responses.
For the same reason, the schema author **MUST** not explicitly set the `additionalProperties` to false.

The API implementation **SHOULD** instead enforce the conformance of requests and responses to an API contract by hard validating the requests and responses against the defined API contract at run-time.

### Common Types

Resource representations in API **MUST** reuse the [common data type](http://json-schema.org/draft/2020-12/json-schema-core.html) definitions where possible.
The following sections provide some details about some of these common types.

#### Quantity

Future-proof quantities by including a unit-of-measure (UOM).
It is recommended to adopt a standard set of measurement unit representations, for example [UCUM](https://ucum.org).

```json
{
  "amount": "4.093",
  "uom": "lbs"
}
```

#### Address

We recommend using [address](https://schema.org/address) for all requirements related to address.
The `address` is

- backward compatible with [hCard](http://www.htmlandcssbook.com/extras/introduction-to-hcard/) address microformats,
- forward compatible with Google open-source address validation metadata (i18n-api) and W3 HTML5.1 autofill fields,
- allows mapping to and from many address normalization services (ANS) such as AddressDoctor.

Please refer to [README for Address](http://swagger.io/specification/#schemaObject) for more details about the address type, guidance on how to map it to i18n-api’s address and W3 HTML5.1’s autofill fields.

#### Money

Money is a standard type to represent amounts.
The Common Type [MonetaryAmount](https://schema.org/MonetaryAmount) provides common definition of money.

Data-type integrity rules:

- Both `currency` and `value` **MUST** exist for this type to be valid.
- Some currencies such as “JPY” do not have sub-currency, which means the decimal portion of the value should be “.0”.
- An amount **MUST NOT** be negative.
  For example a $5 bill is never negative.
  Negative or positive is an internal notion in association with a particular account/transaction and in respect of the type of the transaction performed.

```json
{
  "value": "210.93",
  "currency": "USD"
}
```

#### Percentage, Interest rate, or APR

Percentages and interest rates are very common when dealing with money.
One of the most common examples is annual percentage rate, or APR.
These interest rates **SHOULD** always be represented according to the following rules:

- The Common Type [annualPercentageRate](https://schema.org/annualPercentageRate) **MUST** be used.
  This ensures that the rate is represented as a fixed-point decimal.
- All validation rules defined in the type **MUST** be followed.
- The value **MUST** be represented as a percentage.
- Example: if the interest rate is 19.99%, the value returned by the API **MUST** be 19.99.
- The field’s JSON schema description field **SHOULD** inform clients how the representation works.
- Example: “The interest rate is represented as a percentage.
  For example, an interest rate of 19.99% would be serialized as 19.99.”
- It is the responsibility of the client to transform this value into a format suitable for display to the end-user.
  For example, some countries use the comma ( , ) as a decimal separator instead of the period ( . ).
  Services **MUST NOT** vary the format of values passed to or from a service based on end-user display concerns.

#### Internationalization

The following common types **MUST** be used with regard to global country, currency, language and locale.

- Country code - All APIs and services **MUST** use the [ISO 3166-1 alpha-2](http://www.iso.org/iso/country_codes.htm) two letter country code standard.
- Currency code - Currency type **MUST** use the three letter currency code as defined in [ISO 4217](http://www.currency-iso.org/).
  For quick reference on currency codes, see http://en.wikipedia.org/wiki/ISO_4217.
- Language code - Language type uses [BCP-47](https://tools.ietf.org/html/bcp47) language tag.
- Locale code - Locale type defines the concept of locale, which is composed of country_code and language.
  Optionally, IANA timezone can be included to further define the locale.
- Province code - Province type provides detailed definition of province or state, based on [ISO-3166-2](https://en.wikipedia.org/wiki/ISO_3166-2) country subdivisions, with room for variant local, international, and abbreviated representations of province names.
  Useful for logistics, statistics, and building state pull-downs for on-boarding.

#### Date, Time and Timezone

When dealing with date and time, all APIs **MUST** conform to the following guidelines.

- The date and time string **MUST** conform to the date-time universal format defined in section 5.6 of [RFC3339](https://www.ietf.org/rfc/rfc3339.txt).
  In use cases where you would require only a subset of the fields (e.g full-date or full-time) from the RFC3339 date-timeformat, you **SHOULD** use the Date Time Common Types to express these.
- All APIs **MUST** only emit [UTC](https://en.wikipedia.org/wiki/Coordinated_Universal_Time) time (aka [Zulu time](https://en.wikipedia.org/wiki/List_of_military_time_zones) or [GMT](https://en.wikipedia.org/wiki/Greenwich_Mean_Time)) in the responses.
- When processing requests, an API **SHOULD** accept date-time or time fields that contain an offset from UTC.
  For example, 2016-09-28T18:30:41.000+05:00 **SHOULD** be accepted as equivalent to 2016-09-28T13:30:41.000Z.
  This helps ensure compatibility with third parties who may not be capable of normalizing values to UTC before sending requests.
  In such cases the offset **SHOULD** only be used to calculate the equivalent UTC time before it is persisted in the system (because of known platform/language/DB interoperability issues).
  A UTC offset **MUST NOT** be used to derive anything else.
- If the business logic requires expressing the timezone of an event, it is **RECOMMENDED** that you capture the timezone explicitly by using a separate request/response field.
  You **SHOULD NOT** use offset to derive the timezone information.
  The offset alone is insufficient to accurately transform the stored UTC time back to a local time later.
  The reason is that a UTC offset might be same for many geographical regions and based on the time of the year there may be additional factors such as daylight savings.
  For example, an offset UTC-05:00 represents Eastern Standard Time during winter, Central Dayight Time during summer, and year-round offset for Panama, Columbia, and Peru.
- The timezone string **MUST** be per [IANA timezone database](https://www.iana.org/time-zones) (aka Olson database or tzdata or zoneinfo database), for example America/Los_Angeles for Pacific Time, or Europe/Berlin for Central European Time.
- When expressing [floating](https://www.w3.org/International/wiki/FloatingTime) time values that are not tied to specific time zones such as user’s date of birth, expiry date, publication date etc.
  in requests or responses, an API **SHOULD NOT** associate it with a timezone.
  The reason is that a UTC offset changes the meaning of a floating time value.
  For example, all countries with timezones west of prime meridian would consider a floating time value to be the previous day.

#### Date Time Common Types

The following common formats **MUST** be used to express various date-time formats in [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) standard formats:

- `YYYY-MM-DD'T'hh:mm:ss.nnnZ` **SHOULD** be used to express an RFC3339 date-time.
- `YYYY-MM-DD` **SHOULD** be used to express full-date from RFC 3339.
- `hh:mm:ss.nnnZ` **SHOULD** be used to express full-time from RFC3339.
- `YYYY-MM` **SHOULD** be used to express a floating date that contains only the month and year.
  For example, card expiry date (2016-09).
- Time zone code **MUST** be used for expressing timezone of a RFC3339 date-time or a full-time field.

### Enumerated Codes

Provide human-readable descriptions, as well as machine-readable codes.

```json
{
  "shippingMethod": {
    "code": "02",
    "description": "Road Del Unmtr/Pkg 送货"
  }
}
```

### I18n Enumerated Codes

Provide internationalized human-readable descriptions, as well as machine-readable codes

```json
{
  "shippingMethod": {
    "code": "02",
    "description": {
      "en": "Road Del Unmtr/Pkg",
      "jp": "送货"
    }
  }
}
```

