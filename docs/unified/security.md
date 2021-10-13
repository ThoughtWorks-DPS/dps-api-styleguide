# Security

---

## Authentication & Authorization

[OAuth 2.0](https://tools.ietf.org/html/rfc6749) has become the de-facto standard for API security.
OpenId Connect (OIDC) is a simple identity layer on top of the OAuth 2.0 that enables clients to verify the identity of the end-user.
Every authenticated API endpoint must be secured using OAuth 2.0/OpenId Connect.
Please refer to the [Authentication section](https://swagger.io/docs/specification/authentication/) of the official OpenAPI Specification on how to specify security definitions in your API.
For OpenID Connect, use a bearer HTTP authentication scheme with a JSON Web Token (JWT) format.
We recommend using appropriate OAuth2.0 flows when Authenticating and Authorizing different kinds of API consumers.

### Machine to Machine communication

For situations involving communication between two systems that trust each other.
For example; Batch jobs or system jobs running in the background.
Or, if a user identity (authentication) and role (authorization) has already been established, and the participating systems trust each other to have established this beforehand.

Use the OAuth2.0 Client Credentials Flow, where client credentials (client ID and client Secret) are exchanged for an access token.

### API Usage with an end user context accessed

In many cases you need to get a user context into the API call, i.e. the backend service needs to know on behalf of which actual user an API call is done.

*Confidential Clients* (clients that are able to keep secret/credentials confidential, i.e. server side) should use the OAuth2.0 Authorization Code grant to get access to APIs (in case the API supports this flow).

*Non-confidential clients*, such as Single Page Application (aka Public clients) must now use the OAuth2.0 Authorization Code grant with flow with the PKCE extension.

### APIs without end user context

Clients who want to use an API without actually having an end user context can still make use of a similar approach to getting access tokens to the API.
By using a device ID or even a random number as client credentials, rate limiting and such can be applied to a specific client.
The Authorization Server would then usually unconditionally accept the client’s credentials and issue tokens.
You would then still have the possibility to revoke or at least limit access to specific devices/IDs in your Authorization Server implementation.

*Confidential Clients* should use the OAuth2.0 Authorization Code grant to get access to APIs (in case the API supports this flow).

*Non-confidential clients*, such as Single Page Application (aka Public clients) must now use the OAuth2.0 Authorization Code grant with flow with the PKCE extension

## Defining OAuth 2.0 Scopes

Scopes are a mechanism to restrict API consumers access to an API.
APIs must define scopes to protect their resources.
Thus, at least one scope must be assigned to each endpoint.
The challenge when defining scopes for an API is to not get carried away with defining too many scopes.
Users need to be able to understand the scope of the authorization they are granting, and this will be presented to the user in a list.

Points to consider when defining scopes;

- *Read vs. Write* – Typically API consumers that need to be able to create content on behalf of a user need a different level of access from API consumers that only need to read a user’s public data.
For the majority of use cases, restricting access to specific API endpoints using read and write is sufficient for controlling access for API consumers
- *Restricting access to sensitive information* – Sensitive information such as PII and PHI need to be restricted and should therefore require a different scope
- *Selectively enabling access to functionality* – A great use of scope is to selectively enable access to a user’s account based on the functionality needed.
For example, Google offers a set of scopes for their various services such as Google Drive, Gmail, YouTube, etc.
- *Limiting Access to Billable Resources* – If a service provides an API that may cause the user to incur charges, scope is a great way to protect against applications abusing this.

> NOTE: All OAuth 2.0 claims for APIs must be part of a common scope to avoid confusion across API providers

### Scope Naming Convention

The naming convention for scopes **MUST** identify the name of the scope and the admissible action for the scope.
The name of the scope **SHOULD** be a dot-separated tuple containing the namespace, an optional resource name, and an optional category name.
The namespace **SHOULD** match the API URL namespace component, as **SHOULD** the resource scope (if necessary).
Scopes **MUST** use `:` to separate the name of the scope from the permissible action.
The full scope name **MUST** be formed as a URI namespacing the scopes to the Organization.

`https://api.example.com/auth/<namespace>[.<resource>][.<category>]:<action>`

where `[]`s indicate optional parts of the scope name.

For example, `https://api.example.com/auth/platform.teams:register` allows a user with this scope to register a new team with the DI platform.

This also allows for an API endpoint to share a more generic namespace-level scope when appropriate.
For example, instead of defining a specific scope for each resource, the namespace-level scope `https://api.example.com/auth/platform:write` can be shared across multiple resources within the `platform` namespace. 

#### Generic Read Scope

For endpoints which do not have security implications, a generic `https://api.example.com/auth/public:read` scope can be used to allow generic access to endpoints.

#### Resolvable Scope URI

The URI **SHOULD** be resolvable to provide additional information pertaining to the capabilities enabled by the scope.
If the query uses `Accept: application/json`, then a machine-readable form of the documentation **MUST** be returned.
If the query uses `Accept: text/html`, then human-formatted HTML or a redirect to appropriate documentation pages **MAY** be returned.
Otherwise, the machine-readable format **MAY** be returned in all cases.

## Secure transport everywhere

All API resources (internal and external) must be accessed via a secure communication channel using Transport Layer Security (TLS).
Another advantage of always using TLS is that guaranteed encrypted communications simplifies authentication efforts - you can secure the communication with simple access tokens instead of having to sign each API request.

## Personally Identifiable Information

Personally Identifiable Information (PII) is any sensitive information that a third-party could use to identify an entity, such as a veteran, patient, or client.
PII should remain private and secure from any party except the owner of that information.

To avoid making PII vulnerable, the following practices are required:

- Avoid directly logging PII for monitoring usage. 
If an API needs to log metadata pertaining to a request, obfuscate the data or use a request identifier not derived from PII.
- The presence of PII as a query parameter requires the use of the complex query payload.
This avoids the use of PII in query params, path params, a URL, or HTTP headers.
- Clearly define which PII is accessible via a given set of endpoints, and define permissions/scopes based on that access.

> Note: As mentioned above <<Non-resourceful endpoints>>, when supporting query parameters with PII, we create a non-RESTful endpoint as follows:
>
> `/<collection>/search` with a payload body containing the search query parameters:
>
> ```json
> {
>   "query": {
>     "relations": [
>       {
>         "type": "conjunction",
>         "operator": "and",
>         "relations": [
>           {
>             "type": "criteria",
>             "propertyName": "name",
>             "operator": "equals",
>             "value": "something"
>           },
>           {
>             "type": "conjunction",
>             "operator": "or",
>             "relations": [
>               {
>                 "type": "criteria",
>                 "propertyName": "age",
>                 "operator": "lt",
>                 "value": "18"
>               },
>               {
>                 "type": "criteria",
>                 "propertyName": "age",
>                 "operator": "gt",
>                 "value": "65"
>               }
>             ]
>           }
>         ]
>       }
>     ]
>   }
> }
> ```

