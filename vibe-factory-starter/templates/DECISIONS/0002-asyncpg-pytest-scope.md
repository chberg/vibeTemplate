# ADR 0002: Pytest Asyncio Loop Scope for Asyncpg

## Status
Accepted

## Context
When writing integration tests using `pytest-asyncio` and `asyncpg` (often via SQLAlchemy async engine), we spin up session-scoped database connection pools (and testcontainers) to avoid the overhead of recreating them per test. 
However, `asyncpg` strictness requires that futures and tasks be attached to the same event loop that created the connection pool. If tests run in a default `function`-scoped event loop while the connection pool is in a `session`-scoped loop, `asyncpg` raises `RuntimeError: Future attached to a different loop`.

## Decision

1. **Global Pytest Config**: We explicitly set the default loop scope to `session` in `pyproject.toml`:
   ```toml
   [tool.pytest.ini_options]
   asyncio_mode = "auto"
   asyncio_default_fixture_loop_scope = "session"
   ```
2. **Explicit Module Markers**: Even with the global default, any test file using session-scoped async fixtures (like a database engine) should explicitly declare the session loop scope to prevent unexpected loop generation:
   ```python
   import pytest
   pytestmark = pytest.mark.asyncio(loop_scope="session")
   ```

## Rationale
This configuration completely eliminates the "Future attached to a different loop" class of bugs. It ensures all tests within a session use the same event loop, matching the lifespan of our most expensive fixtures (the database pool and testcontainer).

## Consequences
- All async tests share a single event loop per session.
- Tests cannot rely on loop isolation (e.g., test A leaving a dirty task on the loop might affect test B if they aren't cleaned up, though standard garbage collection usually mitigates this).
- Developers don't have to guess why their database connections are failing in tests.

## Out of scope
- Per-function database transaction isolation (this is handled via savepoints or table truncation, not loop scope).
