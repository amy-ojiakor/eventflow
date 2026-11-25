# EventFlow — Event Booking and Notification Platform

EventFlow is a backend-focused event booking and notification platform built with Java and Spring Boot.

The project explores the design and implementation of a reliable, scalable backend system that supports event management, ticket inventory, reservations, payments, asynchronous notifications and distributed event processing.

It is being developed as a practical portfolio project to demonstrate backend engineering, database design, transactional processing, messaging, cloud infrastructure and production-oriented software development.

---

## 1. Project Vision

The goal of EventFlow is to build a realistic event booking platform that goes beyond basic CRUD operations.

The system should support the complete booking lifecycle, from event creation and ticket selection to reservation, payment processing and customer notifications.

Particular attention will be given to:

- Data consistency and transactional integrity.
- Ticket inventory management and prevention of overselling.
- Reliable booking and payment workflows.
- Idempotent payment processing.
- Asynchronous communication using event-driven architecture.
- Notification retries and failure handling.
- Maintainable application architecture.
- Cloud deployment and operational reliability.

## 2. Technology Stack

| Area | Technology |
|---|---|
| Programming language | Java 21 |
| Backend framework | Spring Boot 4.2 |
| API architecture | REST |
| Database | PostgreSQL 17 |
| ORM | Spring Data JPA / Hibernate |
| Database migrations | Liquibase |
| Messaging | Apache Kafka |
| Containerization | Docker |
| Cloud infrastructure | AWS |
| Testing | JUnit 5, Mockito |
| API documentation | OpenAPI / Swagger |
| Build tool | Maven |
| Version control | Git / GitHub |

The stack may be extended as the project evolves, but new dependencies should be introduced for a clear architectural or functional reason.

## 3. Core Features

### Event Management

Users should be able to:

- Create events.
- Associate events with venues.
- Update event details.
- Retrieve individual events.
- Browse available events.
- Manage event publication and lifecycle status.

### Ticket Management

Event organizers should be able to:

- Define multiple ticket types for an event.
- Set ticket prices and currencies.
- Configure ticket inventory.
- Define ticket sales periods.
- Monitor available ticket quantities.

### Checkout and Reservations

Customers should be able to:

- Select ticket types and quantities.
- Initiate checkout.
- Temporarily hold selected inventory.
- Complete the required deposit payment.
- Secure a reservation.
- Pay the outstanding balance before the payment deadline.

### Payment Processing

The payment subsystem should support:

- Payment initiation.
- Payment provider integration.
- Payment reference tracking.
- Idempotency protection.
- Server-side payment verification.
- Partial payments and outstanding balances.
- Payment status tracking.

Payment success must never be determined solely by a client-side request or redirect.

### Notifications

The notification subsystem should support:

- Booking-related notifications.
- Email and other supported delivery channels.
- Asynchronous processing.
- Delivery attempt tracking.
- Retry mechanisms.
- Failure recording and recovery.

### Event-Driven Processing

Kafka will be used to support asynchronous communication between application components.

The transactional outbox pattern will help ensure that important application events are not lost between database transactions and message publication.

## 4. System Architecture

The application will initially follow a modular layered architecture within a Spring Boot application.

The major architectural layers are:

1. **Controller layer:** Exposes REST endpoints and handles HTTP requests.
2. **DTO layer:** Defines API request and response contracts.
3. **Service layer:** Contains business rules and application workflows.
4. **Repository layer:** Handles database access.
5. **Entity layer:** Represents persisted domain data.
6. **Messaging layer:** Handles asynchronous event publication and consumption.
7. **Notification layer:** Coordinates notification generation and delivery.

The architecture should keep business logic out of controllers and avoid exposing JPA entities directly through REST endpoints.

### High-level workflow

A typical booking workflow will look like this:

1. A customer selects an event and ticket types.
2. The application validates availability.
3. A temporary checkout hold is created.
4. The customer initiates payment.
5. The payment provider processes the transaction.
6. The backend verifies the payment.
7. Once the required deposit is received, the booking becomes reserved.
8. A booking event is recorded in the outbox.
9. The event is published to Kafka.
10. Notification processing consumes the event and sends the appropriate notification.
11. The customer pays the outstanding balance before the deadline.
12. The booking becomes confirmed after full payment.

## 5. Database Design

The initial database schema is managed using Liquibase.

The database currently contains 11 principal tables.

| Table | Responsibility |
|---|---|
| `venues` | Stores event venue information. |
| `users` | Stores application user information. |
| `events` | Stores event details and ownership. |
| `ticket_types` | Defines ticket categories, pricing and inventory. |
| `checkout_holds` | Tracks temporary checkout reservations. |
| `checkout_hold_items` | Stores ticket selections within checkout holds. |
| `bookings` | Stores customer bookings and their lifecycle. |
| `booking_items` | Stores ticket quantities and prices associated with bookings. |
| `payments` | Tracks payment transactions. |
| `notifications` | Tracks customer notification delivery. |
| `outbox_events` | Stores application events awaiting publication. |

### Important database principles

- Liquibase is the source of truth for schema changes.
- Hibernate schema generation is disabled in favour of schema validation.
- Database changes should be introduced through new migrations.
- Currency columns use `VARCHAR(3)` to represent ISO-style three-letter currency codes.
- Monetary values use appropriate decimal types rather than floating-point types.
- Foreign keys and database constraints protect relational integrity.
- Indexes support commonly used lookup and filtering operations.

### Database relationship diagram

See the Mermaid ER diagram in this README's database documentation section. It should be maintained whenever the database relationships change.

## 6. Important Business Rules

These rules are fundamental to the application's design and must be preserved during implementation.

### 6.1 Checkout Holds vs. Bookings

A checkout hold and a booking are two different concepts.

**Checkout hold:**

- Temporarily holds selected ticket inventory.
- Has an expiration time.
- Exists while the customer completes checkout.
- Does not constitute a confirmed or deposit-backed reservation.

**Booking:**

- Represents the customer's actual booking.
- Begins in the `PENDING_DEPOSIT` state.
- Becomes a deposit-backed reservation only after the required deposit is successfully verified.
- Has a payment deadline for the outstanding balance.

### 6.2 Deposit Policy

The minimum deposit percentage is configurable per event.

The default is 30%.

The deposit is calculated against the entire booking total.

The percentage used for a booking is copied into the booking record so that subsequent changes to an event's deposit policy do not alter existing bookings.

A booking becomes `RESERVED` only after the backend verifies that the successful payments meet the required minimum deposit.

### 6.3 Booking Lifecycle

The intended booking lifecycle is:

`PENDING_DEPOSIT` → `RESERVED` → `CONFIRMED`

If the required deposit is not received, the booking must not become a reserved booking.

If the remaining balance is not paid before the deadline, the booking may transition to an expired state according to the cancellation policy, and its reserved inventory must be released.

### 6.4 Inventory Management

Inventory must be protected against overselling.

The application must not rely exclusively on database check constraints to prevent concurrent booking conflicts.

Transactional operations and appropriate row-level locking will be required when reserving or releasing inventory.

Inventory transitions should be controlled by business services rather than arbitrary entity setters.

### 6.5 Payment Idempotency

Payment callbacks may be delivered more than once.

The application must prevent duplicate processing through payment references, idempotency keys and appropriate database constraints.

The same successful payment must never be applied to a booking more than once.

### 6.6 Transactional Outbox

Important application events should be persisted in the same database transaction as the business operation that creates them.

A background publisher will retrieve pending outbox events and publish them to Kafka.

Failed publications should be retried according to a controlled retry policy.

## 7. Development Standards

The project will follow these conventions:

- Use Java 21 language features where appropriate.
- Keep controllers thin.
- Put business logic in services.
- Use DTOs for external API contracts.
- Use Bean Validation for incoming requests.
- Use global exception handling for consistent API errors.
- Keep database migrations version-controlled.
- Avoid unnecessary dependencies.
- Write unit and integration tests for important business workflows.
- Use meaningful commit messages following Conventional Commits.
- Do not expose secrets or credentials in source control.

### JPA Entity Conventions

Entities should:

- Have protected no-argument constructors for JPA.
- Use explicit constructors for domain creation where appropriate.
- Expose getters.
- Use selective setters rather than unrestricted mutation.
- Avoid Lombok `@Data`.
- Keep important state transitions under service-layer control.

## 8. Project Progress

### Completed

- [x] Spring Boot project initialization.
- [x] Maven configuration.
- [x] GitHub repository setup.
- [x] Git branching workflow.
- [x] PostgreSQL development database setup.
- [x] Application database user configuration.
- [x] Liquibase integration.
- [x] Initial database schema migrations.
- [x] JPA entity classes.
- [x] Hibernate schema validation.

### In Progress / Next

- [ ] Implement Spring Data JPA repositories.
- [ ] Define DTOs and request validation.
- [ ] Implement event management services.
- [ ] Implement event management REST APIs.
- [ ] Implement global exception handling.
- [ ] Add API documentation.
- [ ] Add unit and integration tests.

### Planned

- [ ] Implement ticket management.
- [ ] Implement checkout holds and inventory management.
- [ ] Implement booking workflows.
- [ ] Implement deposit and balance payment processing.
- [ ] Integrate a payment provider or suitable payment simulation.
- [ ] Implement transactional outbox processing.
- [ ] Integrate Apache Kafka.
- [ ] Implement asynchronous notifications.
- [ ] Implement retries and dead-letter handling.
- [ ] Add Docker support.
- [ ] Implement CI/CD.
- [ ] Deploy to AWS.
- [ ] Add monitoring, logging and operational documentation.

## 9. Git Workflow

The project uses the following branching strategy:

| Branch | Purpose |
|---|---|
| `master` | Stable release branch |
| `develop` | Integration branch |
| `feature/*` | Individual feature development |

Typical workflow:

1. Create a feature branch from `develop`.
2. Implement and test the feature.
3. Open a pull request into `develop`.
4. Merge tested and reviewed changes.
5. Merge stable milestones into `master`.

### Commit message convention

Use Conventional Commits:

- `feat:` New functionality.
- `fix:` Bug fixes.
- `refactor:` Code restructuring without functional changes.
- `test:` Tests.
- `docs:` Documentation.
- `chore:` Maintenance and configuration.

Example:

`feat: add database migrations and JPA entities`

## 10. Running the Application Locally

### Prerequisites

- Java 21
- Maven
- PostgreSQL 17
- Git

### Database configuration

The development profile expects a PostgreSQL database named:

`eventflow_db`

The application connects using the `eventflow_user` database role.

Configure the following environment variables:

| Variable | Purpose |
|---|---|
| `DB_URL` | PostgreSQL JDBC connection URL |
| `DB_USERNAME` | Application database username |
| `DB_PASSWORD` | Application database password |

The development profile provides a default JDBC URL and username. The password should be supplied through the environment rather than committed to Git.

### Start the application

Run the application from IntelliJ IDEA or execute:

`./mvnw spring-boot:run`

Liquibase applies the database migrations during application startup, and Hibernate validates the entity mappings against the resulting schema.

The development application is configured to use port `8089`.

## 11. Project Structure

The Java root package is:

`com.amyojiakor.eventflow`

The application should be organized by business domain as it grows, with packages for areas such as:

- `event`
- `venue`
- `user`
- `ticket`
- `checkout`
- `booking`
- `payment`
- `notification`
- `outbox`
- `common`

Each domain can contain its own controller, service, repository, entity and DTO packages where appropriate.

## 12. Long-Term Engineering Objectives

EventFlow is intended to demonstrate the ability to design and build backend systems that address real engineering problems.

By completion, the project should demonstrate:

- REST API design and implementation.
- Relational database modelling.
- Transaction management.
- Concurrency control.
- Payment processing and idempotency.
- Event-driven architecture.
- Kafka integration.
- Transactional outbox implementation.
- Reliable asynchronous processing.
- Docker-based deployment.
- AWS infrastructure and deployment.
- Automated testing and CI/CD.
- Production-oriented logging and monitoring.

The emphasis is on understanding the engineering decisions behind the implementation, not merely assembling technologies.

---

**Project:** EventFlow

**Repository:** https://github.com/amy-ojiakor/eventflow

**Java package:** `com.amyojiakor.eventflow`

**Current milestone:** Database foundation completed; moving into repository, service and REST API implementation.