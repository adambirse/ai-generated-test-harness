# Use Debian slim
FROM debian:bullseye-slim

# Install required tools
RUN apt-get update && apt-get install -y \
    redis-tools \
    bash \
    curl \
    unzip \
    less \
    groff \
    python3 \
    python3-pip \
    && pip3 install --no-cache-dir awscli \
    && rm -rf /var/lib/apt/lists/*

# Copy the test harness script
COPY test-harness.sh /usr/local/bin/test-harness.sh

# Fix Windows line endings + make executable
RUN sed -i 's/\r$//' /usr/local/bin/test-harness.sh && \
    chmod +x /usr/local/bin/test-harness.sh

# Entry point
ENTRYPOINT ["/usr/local/bin/test-harness.sh"]
