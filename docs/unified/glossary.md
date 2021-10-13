# Glossary of REST Terms

---

## Capability:

Capability represents a business-oriented and customer-facing view of an organization’s business logic.
Capabilities can be used to organize a portfolio of APIs as a stable, business-driven view of its system..
Examples of capability are: customer enrollment, vendor managed inventory, pricing and service level offer management.

Capabilities drive the API interface, while domains are more coarse-grained and closer to the logical capability model.
Capability and Domain are seen as orthogonal concerns from a service perspective.

## Client / Consumer:
An entity that invokes an API request and consumes the API response.
[1]

## Domain:

A [domain model](https://en.wikipedia.org/wiki/Domain_model) is a system of abstractions that describes selected aspects of a sphere of knowledge, influence, or activity.
The concepts include the data involved in a business, and the rules that the business uses in relation to that data.
[4]

## Experiences:

"Experience" is a generic name for any of a variety of ways a consumer interacts with the business capabilities.
An Experience can be delivered to the consumer via a web-based UI, a mobile application, a CLI, or the API endpoints directly.

## Namespace:

Capabilities drive service modeling and namespace concerns in an API portfolio.
Namespaces are part of the Business Capability Model.
Examples of namespaces are: orders, contacts, customers, pricing.

Namespaces should reflect the domain that logically groups a set of business capabilities.
This lets consumers map API endpoints to domain concepts and enables a clearer understanding of the business capabilities which are offered by the API.

## Representation:

REST components perform actions on a resource by using a representation to capture the current or intended state of that resource and by transferring that representation between components.
A representation is a sequence of bytes, plus representation metadata to describe those bytes.
[3]

## Resource:

The key abstraction of information in REST is a resource.
According to [Fielding's dissertation section 5.2](https://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm#sec_5_2), any information that can be named can be a resource: a document or image, a temporal service (e.g. "today's weather forecast in Los Angeles"), a collection of other resources, a non-virtual object (e.g. a person), and so on.
A resource is a conceptual mapping to a set of entities, not the entity that corresponds to the mapping at any particular point in time.

More precisely, a resource R is a temporally varying membership function MR(t), that for time t maps to a set of entities, or values, that are equivalent.
The values in the set may be resource representations and/or resource identifiers.

A resource can also map to the empty set, which allows references to be made to a concept before any realization of that concept exists.

As an example, the resource "today's weather forecast in Los Angeles" does not imply that there is a specific `forecastInLA` entity in our database that continually gets updated.
Instead, the resource maps to the latest in a series of weather model predictions, and that mapping will change tomorrow when data from the next run of the prediction model is received.
Historical data related to past actual weather would be a different resource "weather observations in Los Angeles" that maps to a different set of data.
It would also be natural to include the "observations" resource in the "forecast" resource results, if that is useful data for consumers of the forecast.

## Resource Identifier:

An identifier used to identify the particular resource instance involved in a RESTful interaction between components.
According to Fielding's dissertation section 5.2, the naming authority (an organization providing APIs, for example) that assigned the resource identifier making it possible to reference the resource, is responsible for maintaining the semantic validity of the mapping over time (ensuring that the membership function does not change).
