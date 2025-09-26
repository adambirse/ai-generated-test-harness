# Use Alpine Linux for smaller image size
FROM alpine:3.18

# Install required tools and AWS CLI
RUN apk add --no-cache redis curl bash aws-cli

# Copy and prepare the test harness script
COPY test-harness.sh /usr/local/bin/test-harness.sh
RUN sed -i 's/\r$//' /usr/local/bin/test-harness.sh && \
    chmod +x /usr/local/bin/test-harness.sh

# Entry point
ENTRYPOINT ["/usr/local/bin/test-harness.sh"]
