# Use a slim Debian base
FROM debian:bullseye-slim

# Install required tools
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    curl \
    unzip \
    less \
    groff \
    redis-tools \
    && pip3 install --no-cache-dir awscli \
    && rm -rf /var/lib/apt/lists/*

# Copy the test-consumer script
COPY test-consumer.sh /usr/local/bin/test-consumer.sh

# Convert Windows line endings + make executable
RUN sed -i 's/\r$//' /usr/local/bin/test-consumer.sh && \
    chmod +x /usr/local/bin/test-consumer.sh

# Set entrypoint to the script
ENTRYPOINT ["/usr/local/bin/test-consumer.sh"]
