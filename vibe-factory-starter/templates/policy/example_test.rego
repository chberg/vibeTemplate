package vibe.example_test

import data.vibe.example

test_read_allowed_for_authenticated_agent if {
    example.allow with input as {"action": "read", "agent_id": "agent-1"}
}

test_read_denied_for_unauthenticated if {
    not example.allow with input as {"action": "read", "agent_id": ""}
}

test_write_requires_human_approval if {
    not example.allow with input as {"action": "write", "agent_id": "agent-1", "human_approval": false}
}

test_write_allowed_with_approval if {
    example.allow with input as {"action": "write", "agent_id": "agent-1", "human_approval": true}
}
