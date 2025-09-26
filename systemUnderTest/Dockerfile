# Use Alpine Linux for smaller image size
FROM alpine:3.18

# Install required tools and AWS CLI
RUN apk add --no-cache redis curl bash aws-cli

# Copy and prepare the test-consumer script
COPY test-consumer.sh /usr/local/bin/test-consumer.sh
RUN sed -i 's/\r$//' /usr/local/bin/test-consumer.sh && \
    chmod +x /usr/local/bin/test-consumer.sh

# Set entrypoint to the script
ENTRYPOINT ["/usr/local/bin/test-consumer.sh"]
