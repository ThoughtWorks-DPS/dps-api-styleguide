# API Design Principles

---

## Consistency

_Promote usage by consistent language wherever possible._

- Consider using names provided by schemas in [schema.org](https://schema.org).
They’ve thought through conceptual pitfalls you may not have (e.g. firstName becomes inaccurate outside of Western culture; givenName is better).
- Use standard names for common operations like sorting, filtering, searching, paging, and projecting.
- Use ISO formats for dates, currencies, country codes, and standard representations for types like Money.

> Note: referring to schema.org for naming guidance does not imply following schema.org naming conventions (e.g. camelCase vs snake_case) which are defined elsewhere in this document

## Usability

_Build design affordances into your API._

- Aspire to make it so developers “don’t have to think” by making the API as easy as possible to consume, even if that makes the implementation harder.
- Always send JSON keys back for null values rather than stripping the key out of the payload (avoids existence checks by clients).
- Always send a response body on create and delete operations so that the developers can see the full resource representation after creation and after deletion.
- Use a standard error convention, and be as specific as possible when reporting the error.
- Define the HTTP Response Codes used and the purpose/meaning behind each one.
- Don’t mutate the meaning of standard error codes.
- Don’t return 200-with-an-error-payload.

## Evolution

_APIs should be built with an eye towards future evolution, without forced upgrades of clients._

- Avoid returning top-level raw arrays, which don't allow non-breaking evolution to add metadata (like paging).
- Implement pagination for all result-sets that may grow without bound (i.e. search results).
- Turn off all strict deserialization.
- Adding fields is a non-breaking change (Postel’s Law - be liberal in what you accept, and conservative in what you produce).
- It’s better for the contract to be incomplete than inaccurate.

## Encapsulation

_Use the API to hide dependency complexity._

- All ids are global, even if the System(s) of Record are federated.
  The client should not have to care about the origin of the id.
- Treat ids as opaque.
  There should be no intrinsic meaning in the value of the id.
- Avoid leaky abstractions by mapping System of Record field names and values to meaningful values.

## Externalization

_Build the API with the expectation that it will be consumed externally._

- API must be derived from the domain model and the intended use-cases it is meant to support.
- API contract must meet the need of the customer.
- Externalization of the contract must not require reimplementation, or a change in service contract.

