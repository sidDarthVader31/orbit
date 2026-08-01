# Synthetic ticket (public fixture)

**Key:** `ORB-1`  
**Summary:** Add healthcheck endpoint to sample service  

## Description

Add a `/healthz` endpoint that returns 200 OK.

## Acceptance criteria

- GET `/healthz` returns 200
- Unit test covers the handler
- Docs mention the endpoint

## Links

- Runbook: see `runbook.md` in this fixture folder

## Repos

- `example/sample-service` (synthetic — do not clone; for schema/docs only)
