# Security Policy

## 1. Supported Versions

Auxilia is currently under active development. Security fixes will be applied to the latest development version where reasonably possible.

| Version | Supported |
|---|---|
| Latest development version | Yes |
| Older versions | No guarantee of security updates |

## 2. Reporting a Vulnerability

If you discover a potential security vulnerability in Auxilia, please report it responsibly.

**Please do not disclose security vulnerabilities publicly through GitHub Issues or public pull requests before they have been assessed.**

When reporting a vulnerability, include:

- A description of the vulnerability.
- The steps required to reproduce the issue.
- The potential impact and affected components.
- Any relevant logs or screenshots, with sensitive information removed.
- Suggested mitigation, if known.

### Reporting Channel

Please use GitHub's private vulnerability reporting feature if it is enabled for this repository.

Alternatively, contact the repository maintainer privately through an appropriate channel. Do not include passwords, access tokens, database credentials, personal data, or other secrets in a public report.

## 3. Scope

Security reports may cover the following components:

- **Frontend:** Flutter application, local data handling, and API communication.
- **Backend:** Express.js and TypeScript APIs, request validation, authentication, authorization, and error handling.
- **Database:** Database access controls, configuration, and protection of stored information.
- **CI/CD:** GitHub repository permissions, Jenkins pipelines, build processes, and secret management.
- **Dependencies and deployment:** Vulnerable packages, environment configuration, and deployment security.

## 4. Security Practices

The project aims to follow these practices as development progresses:

- **Secrets management:** Keep passwords, API keys, database credentials, signing keys, and access tokens out of source control.
- **Input validation:** Validate incoming API requests and reject invalid or unexpected input.
- **Authentication and authorization:** Protect restricted endpoints and ensure users can only access resources they are authorized to use, where applicable.
- **Data protection:** Avoid exposing sensitive information in API responses, logs, or error messages.
- **Secure communication:** Use HTTPS for production API communication.
- **Dependency management:** Review and update dependencies to address known vulnerabilities.
- **Error handling:** Return appropriate error responses without exposing internal implementation details.
- **CI/CD security:** Restrict access to deployment credentials and avoid exposing secrets in pipeline logs.
- **Testing:** Add security-related tests as relevant features are implemented.

These are development goals and do not imply that every control has already been implemented.

## 5. Responsible Disclosure

Please give the maintainer a reasonable opportunity to investigate and address a reported vulnerability before publicly disclosing it.

Do not exploit a vulnerability to access, modify, or delete other people's data, disrupt services, or compromise systems beyond what is necessary to demonstrate the issue safely.

## 6. Response and Remediation

Reports will be reviewed as project resources allow. The maintainer will assess the severity, investigate the issue, and determine appropriate remediation.

Response and resolution timelines are not guaranteed while Auxilia remains a development project.

## 7. Acknowledgements

We appreciate responsible security research and reports that help improve Auxilia's security and reliability.

Thank you for helping make Auxilia safer for its users.
