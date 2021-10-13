# Resource Identifiers

Oversimplifying a bit, there are four types of resource endpoints: Collections, Individual Resources, Reified Resources, and Non-resourceful endpoints.
In RESTful APIs, the URL path (e.g.without the querystring) acts as an identifier for the resource.
As a general principle, all resource URL paths should avoid the use of verbs in the resource name.

---

## Collection resources

These represent a collection of resources.
Prefer plural nouns with no identifier in the URL path.
List resources can be filtered, sorted, paged, etc using query parameters.

Example: `/orders?page=2&size=25&line_items=1`

## Singular resources

These represent a single instance of a resource in a collection.
They should be completely and uniquely identified on the URL path.
A resource identifier (id) can be a made up composite key when we have no valid shadow key.
IDs should be treated as opaque by clients.

Example: `/orders/12345`

## Reified resources

*Reification* is the act of naming an abstract concept, which is sometimes useful in RESTful modeling.
Reified resources generally represent the intent of a change, as opposed to a simple CRUD operation.
As such, they tend to avoid PUTs in favor of immutable resources modeling some user action or workflow.

Example: `/registrationRequest`

## Non-resourceful endpoints

There may be considerations that force us into an intentionally non-resourceful endpoint.
For example, you may decide to support searching by credit cards as a POST instead of a GET because we want to keep the credit card number off of the URL.
In this case, we are clearly and intentionally breaking the Uniform Interface architectural constraint of REST.
To indicate this as intentional, we should put a verb on the path to label this as RPC instead of RESTful.
See the next section on [Controller Resources](controller-resources.md) for a more in-depth discussion.

Example: `/orders/search`
