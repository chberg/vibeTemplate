# Example OPA policy. Replace once you have real product modules.
# Test with: opa test policy/
# Note: OPA <1.0 uses `allow { ... }`. OPA 1.0+ allows `allow if { ... }`.
# See ADR-0002 in projects derived from this template if you hit issues.

package vibe.example

default allow := false

# Allow read tools for any authenticated agent.
allow if {
    input.action == "read"
    input.agent_id != ""
}

# Allow write tools only with explicit human approval.
allow if {
    input.action == "write"
    input.human_approval == true
}
