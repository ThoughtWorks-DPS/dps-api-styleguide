# General Guidelines

---

## Think of the API as a Product

The design of the API should be based on the “API as a Product” principle.
This means that the API Provider should:

- Act like a product owner
- Design the API based on the needs of the customer
- Focus on customer experience by emphasizing simplicity, comprehensibility and usage of the API
- Provide a self-service experience (i.e. full documentation, examples, how-to/quick start guides, etc.)
- Provide service level support to the customer
- Collect and react to customer feedback

## Define and Design the API First

An API first approach means that the design and development of the API comes first before the implementation.
In practice this means:

- Define the API first, before coding its implementation using a standard specification language such as OpenAPI Specification
- Collect early review feedback from peers and customers
- Services interact with each other solely through their exposed APIs

Taking an API first approach ensures that the API design is:

- Focused on the needs of the consumers as opposed to how the underlying service is implemented
- Focused on generalized business capabilities as opposed to specific use-cases
- Not just a CRUD-style interface on top of persistence entities, i.e. matches usage patterns and provides business capabilities rather than implementation details

## Describe the API using an API Specification

An API Specification is a formal API description language that standardizes how the API is documented and consumed by the clients.
Whereas there are various API specification standards such as RAML and API BluePrint, it is recommended to use [OpenAPI Specification](https://www.openapis.org/) ([OAS](https://www.openapis.org/)) since it’s more widely supported and adopted.
We strive to be compliant with the latest released version, which at this moment is [OASv3.1](https://spec.openapis.org/oas/latest.html).
Previous versions can be found on Github in the [OpenAPI Specification](https://github.com/OAI/OpenAPI-Specification/) project.
