# Introduction

---

## Abstract

The typical microservices platform is a collection of reusable services that encapsulate well-defined business capabilities.
Developers are encouraged to access these capabilities through Application Programming Interfaces (APIs) that enable consistent design patterns and principles.
This facilitates a great developer experience and the ability to quickly compose complex business processes by combining multiple, complementary capabilities as building blocks

## Purpose

APIs follow the RESTful architectural style wherever possible.
This is largely driven by the API readability and mature tooling available for REST API development.
Some APIs will benefit from the advantages of an RPC-style interface, such as gRPC.
To support our objectives, we have developed a set of rules, standards, and conventions that apply to the design of RESTful APIs.
These have been used to help design and maintain hundreds of APIs and have evolved over several years to meet the needs of a wide variety of use cases.

This document is based on the incredible work done at PayPal and Zalando on their API style guide.

## Document Semantics, Formatting, and Naming

The keywords “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt).

The words “REST” and “RESTful” **MUST** be written as presented here, representing the acronym as all upper-case letters.
This is also true of “JSON,” “XML,” and other acronyms.

Machine-readable text, such as URLs, HTTP verbs, and source code, are represented using a fixed-width font.
URIs containing variable blocks are specified according to [URI Template RFC 6570](https://tools.ietf.org/html/rfc6570).
For example, a URL containing a variable called `accountId` would be shown as `https://api.example.com/v1/accounts/{accountId}/`.

HTTP headers are written in PascalCase + hyphenated syntax, e.g. `Idempotency-Key`.

## Interpreting The Guidelines

To aid understanding, we define key terms used within this standards document:

### Resource

The key abstraction of information in REST is a resource.
According to [Fielding’s dissertation section 5.2](https://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm#sec_5_2), any information that can be named can be a resource: a document or image, a temporal service (e.g. “today’s weather in Los Angeles”), a collection of other resources, a non-virtual object (e.g. a person), and so on.
A resource is a conceptual mapping to a set of entities, not the entity that corresponds to the mapping at any particular point in time.
The values in the set may be resource representations and/or resource identifiers.

A resource can also map to the empty set, which allows references to be made to a concept before any realization of that concept exists.

### Resource Identifier

REST uses a resource identifier to identify the particular resource instance involved in an interaction between components.
The naming authority (an organization providing APIs, for example) that assigned the resource identifier making it possible to reference the resource, is responsible for maintaining the semantic validity of the mapping over time (ensuring that the membership function does not change).

### Representation

REST components perform actions on a resource by using a representation to capture the current or intended state of that resource and by transferring that representation between components.
A representation is a sequence of bytes, plus representation metadata to describe those bytes.

### Domain

According to Wikipedia, a domain model is a system of abstractions that describes selected aspects of a sphere of knowledge, influence, or activity.
The concepts include the data involved in a business, and the rules that the business uses in relation to that data.

Domain definition should reflect the customer’s perspective on how platform capabilities are organized.
Note that these may not necessarily reflect the company’s hierarchy, organization, or (existing) code structure.
In some cases, domain definitions are aspirational, in the sense that these reflect the target, customer-oriented platform organization model.
Underlying service implementations and organization structures may need to migrate to reflect these boundaries over time.

As an example, a domain model may include domains such as Customer, Order, Invoice, Payment, Customer Support, etc.

### Capability

Capability represents a business-oriented and customer-facing view of an organization’s business logic.
Capabilities can be used to organize a portfolio of APIs as a stable, business-driven view of its system..
Examples of capability are: customer enrollment, vendor managed inventory, pricing and service level offer management.

Capabilities drive the API interface, while domains are more coarse-grained and closer to the logical capability model.
Capability and Domain are seen as orthogonal concerns from a service perspective.

### Experiences

"Experience" is a generic name for any of a variety of ways a consumer interacts with the business capabilities.
An Experience can be delivered to the consumer via a web-based UI, a mobile application, a CLI, or the API endpoints directly.

### Namespace

Capabilities drive service modeling and namespace concerns in an API portfolio.
Namespaces are part of the Business Capability Model.
Examples of namespaces are: orders, contacts, customers, pricing.

Namespaces should reflect the domain that logically groups a set of business capabilities.
This lets consumers map API endpoints to domain concepts and enables a clearer understanding of the business capabilities which are offered by the API.

### Service

Services provide a generic API for accessing and manipulating the value set of a resource, regardless of how the membership function is defined or the type of software that is handling the request.
Services are generic pieces of software that can perform any number of functions.
It is, therefore, instructive to think about the different types of services that exist.

Logically, we can segment the services and the APIs that they expose into two categories:

1. Capability APIs
2. Experience-specific APIs

#### Capability Services and APIs

Capability APIs are public APIs exposed by services implementing generic, reusable business capabilities.
Public implies that these APIs are limited only to the interfaces meant for consumption by front-end experiences, external consumers, or internal consumers from a different domain.

#### Experience-specific Services and APIs

Experience-specific APIs are built on top of capability APIs.
They expose functionality which may be either specific to an interaction mode, or optimized for a context-specific specialization of a generic capability.
Contextual information could be related to time, location, device, channel, identity, user, role, or privilege level among other things.

Experience-specific services provide minimal additional business logic over core capabilities, and mainly provide transformation and lightweight orchestration to tailor an interaction to the needs of a specific experience, channel or device.
Their input/output functionality is limited to service calls.

### Client, API Client, API Consumer

An entity that invokes an API request and consumes the API response.
