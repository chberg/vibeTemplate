# Sandbox image for the AFK loop.
# Build: docker build -t vibe-sandbox -f docker/sandbox.Dockerfile .
# Use:   docker run --rm -v "$(pwd)":/workspace -w /workspace vibe-sandbox ./scripts/agentctl/once.sh

FROM node:20-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    ca-certificates \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

# Codex CLI
RUN npm install -g @openai/codex

# Optional: Claude CLI
# RUN npm install -g @anthropic-ai/claude-code

# Python tooling for verify.sh
RUN pip3 install --break-system-packages ruff mypy pytest

# OPA
RUN curl -L -o /usr/local/bin/opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64_static \
  && chmod +x /usr/local/bin/opa

WORKDIR /workspace
