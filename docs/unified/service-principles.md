# Service Design Principles

---

This section captures the principles guiding the design of the services that expose APIs to internal and external developers, agencies, partners and affiliates.
A service refers to functionality pertaining to a particular capability, exposed as an API.
Following are the core design principles for a service.

## Loose Coupling

Services and consumers must be loosely coupled to each other.

Coupling refers to a connection or relationship between two things.
A measure of coupling is comparable to a level of dependency.
This principle advocates the design of service contracts, with a constant emphasis on reducing (loosening) dependencies between the service contract, its implementation, and service consumers.

The principle of Loose Coupling promotes the independent design and evolution of a service’s logic and implementation while still emphasizing baseline interoperability with consumers that have come to rely on the service’s capabilities.

This principle implies the following:

- A service contract should not expose implementation details.
- A service contract can evolve without impacting existing consumers.
- A service in a particular domain can evolve independently of other domains.

## Encapsulation

A domain service can access data and functionality it does not own only through other service contracts.

A service exposes functionality that comprises the capability and data it owns and implements, as well as the capability and data it depends upon which it does not own.
This principle advocates that any capability or data that a service depends on and which it does not own must only be accessed through service contracts.

This principle implies the following:

- A service has a clear isolation boundary - a clear scope of ownership in terms of functionality and data.
- A service cannot expose the data it does not own directly.

## Stability

Service contracts must be stable.

Services must be designed in such a way that the contract they expose remains valid for existing customers.
Should the service contract need to evolve in an incompatible fashion for the consumer, this should be communicated clearly.

This principle implies the following:

- Existing clients of a service must be supported for a documented period of time.
- Additional functionality must be introduced in a way that does not impact existing consumers.
Deprecation and migration policies must be clearly stated to set consumers’ expectations.
  
Results of applying this principle can be seen in the sections on API Versioning. 

## Reusable

Services must be developed to be reusable across multiple contexts and by multiple consumers.

The main goal of an API platform is to enable applications to be developed quickly and cost effectively by using and combining services.
This principle advocates that services be developed in a manner that enables them to be used by multiple consumers and in multiple contexts, some of which may evolve over time.

This principle implies the following:

- A service contract should be designed for not just the immediate context, but with support and/or extensibility to be used by multiple consumers in different contexts.
- A service contract may need to incrementally evolve to support multiple contexts and consumers over time.

## Contract-based

Functionality and data must only be exposed through standardized service contracts.

A service exposes its purpose and capabilities via a service contract.
A service contract is comprised of functional aspects, non-functional aspects (such as availability, response-time), and business aspects (such as cost-per-call, terms and conditions).
Standardized means that the service contracts must be compliant with the contract design standards.

This principle advocates that all functionality and data must only be exposed through standardized service contracts.
Consumers of services can, therefore, understand and access functionality and data only through service contracts.

This principle implies the following:

- Functionality and data cannot be understood or accessed outside of service contracts.
- Each piece of data (such as that managed in a datastore) is owned by only one service.

## Consistency

Services must follow a common set of rules, interaction styles, vocabulary and shared types.

A set of rules prescribes the definition of services in order to expose those in a consistent manner.
This principle increases the ease of use of the API platform by reducing the learning curve for consumers of new services.

This principle implies the following:

- A set of standards is defined for services with which to comply.
- A service should use vocabulary from common and shared dictionaries.
- Compatible interaction styles, service granularity and shared types are key for full interoperability and ease of service compositions.

## Ease Of Use

Services must be easy to use and compose in consumers (and applications).

A service that is difficult and time consuming to use reduces the benefits of a microservices architecture by encouraging consumers to find alternate mechanisms to access the same functionality.
Composability means that services can be combined easily because the service contracts and access protocols are consistent, and each service contract does not have to be understood independently.

This principle implies the following:

- A service contract is easily discoverable and understandable.
Service contracts and protocols are consistent in all aspects that they can be - e.g. identification and authentication mechanisms, error semantics, common type usage, pagination, etc.
- A service has clear ownership, so that consumer providers can reach service owners regarding SLAs, requirements, and issues.
- A consumer provider can easily integrate, test, and deploy a consumer that uses this service.
- A consumer provider can easily understand the non-functional guarantees provided by a service.

## Externalizable

A service must be designed so that the functionality it provides is easily accessible to consumers outside the team.

A service is developed for use by consumers that may be from another domain or team, another business unit or another company.
In all of these cases, the functionality exposed is the same; what changes is the access mechanism or the policies enforced by a service, like authentication, authorization and rate-limiting.
Since the functionality exposed is the same, the service should be designed once and then externalized based on business needs through appropriate policies.

This principle implies the following:

- The service interface must be derived from the domain model and the intended use-cases it is meant to support.
- The service contract and access (binding) protocols supported must meet the consumer’s needs.
- The externalization of a service must not require reimplementation, or a change in service contract.

## Observability

A service must provide a way for consumers to understand its operational characteristics.

Consumers need a way to understand the operational properties of a system in a (near) real-time manner.
This is critical to a consumer's ability to support their own systems which are dependent upon the service.

This principle implies the following:

- The service should provide a method for a consumer to view its health status.
- The service should provide access to metrics related to SLAs/SLOs.
- The consumer should be able to access some level of logging or response information related to their own specific queries.
