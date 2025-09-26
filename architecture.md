# Architecture Diagram

## System Overview

```mermaid
graph TB
    subgraph "Docker Compose Environment"
        subgraph "Infrastructure Services"
            Redis[Redis<br/>Message Queue<br/>Port: 6379]
            LocalStack[LocalStack<br/>Mock S3<br/>Port: 4566]
            RedisInsight[RedisInsight<br/>Redis GUI<br/>Port: 5540]
        end

        subgraph "Application Services"
            TestHarness[Test Harness<br/>Message Producer & Validator]
            TestConsumer[Test Consumer<br/>Message Processor]
        end
    end

    subgraph "GitHub Actions CI/CD"
        BuildJob[Build Containers Job]
        IntegrationJob[Integration Test Job]
    end

    %% Data Flow
    TestHarness -->|1. LPUSH message| Redis
    TestConsumer -->|2. RPOP message| Redis
    TestConsumer -->|3. Upload file| LocalStack
    TestHarness -->|4. Verify file exists| LocalStack

    %% CI/CD Flow
    BuildJob -->|builds| TestHarness
    BuildJob -->|builds| TestConsumer
    IntegrationJob -->|orchestrates| TestHarness
    IntegrationJob -->|orchestrates| TestConsumer

    %% Optional monitoring
    RedisInsight -.->|monitors| Redis

    classDef infrastructure fill:#e1f5fe
    classDef application fill:#f3e5f5
    classDef cicd fill:#e8f5e8

    class Redis,LocalStack,RedisInsight infrastructure
    class TestHarness,TestConsumer application
    class BuildJob,IntegrationJob cicd
```

## Component Details

### Infrastructure Services

| Component | Purpose | Port | Technology |
|-----------|---------|------|------------|
| **Redis** | Message queue storage | 6379 | Redis 7 |
| **LocalStack** | Mock AWS S3 service | 4566 | LocalStack |
| **RedisInsight** | Redis monitoring GUI | 5540 | RedisInsight |

### Application Services

| Component | Purpose | Dependencies | Technology |
|-----------|---------|--------------|------------|
| **Test Harness** | Generates messages, validates results | Redis, LocalStack | Alpine + Bash |
| **Test Consumer** | Processes messages, uploads files | Redis, LocalStack | Alpine + Bash |

## Message Flow

```mermaid
sequenceDiagram
    participant TH as Test Harness
    participant R as Redis Queue
    participant TC as Test Consumer
    participant S3 as LocalStack S3

    Note over TH,S3: Integration Test Flow

    TH->>R: 1. Clear queue (DEL)
    TH->>R: 2. Push message (LPUSH)
    Note over TH: Wait for consumption

    loop Poll for messages
        TC->>R: 3. Pop message (RPOP)
        alt Message found
            TC->>TC: 4. Create file with message
            TC->>S3: 5. Upload file to S3
            Note over TC: Exit success
        else No message
            Note over TC: Continue polling
        end
    end

    loop Verify completion
        TH->>R: 6. Check queue empty (LLEN)
        TH->>S3: 7. Verify file exists (HTTP GET)
        alt All checks pass
            Note over TH: Exit "Test Success"
        else Timeout reached
            Note over TH: Exit "Test Failure"
        end
    end
```

## Network Architecture

```mermaid
graph LR
    subgraph "Docker Network"
        TH[test-harness]
        TC[test-consumer]
        R[redis:6379]
        LS[localstack:4566]
        RI[redisinsight:5540]
    end

    subgraph "Host Machine"
        H[Host Ports<br/>6379, 4566, 5540]
    end

    TH -.->|redis-cli| R
    TH -.->|curl S3 API| LS
    TC -.->|redis-cli| R
    TC -.->|aws cli| LS
    RI -.->|monitor| R

    R -.->|expose| H
    LS -.->|expose| H
    RI -.->|expose| H
```

## CI/CD Pipeline Architecture

```mermaid
flowchart TD
    A[Git Push/PR] --> B[GitHub Actions Trigger]

    subgraph "Build Job (Matrix)"
        B --> C1[Build test-consumer]
        B --> C2[Build test-harness]
    end

    subgraph "Integration Test Job"
        C1 --> D[Install docker-compose]
        C2 --> D
        D --> E[Start Infrastructure]
        E --> F[Start Test Consumer]
        F --> G[Run Test Harness]
        G --> H{Check Output}
        H -->|"Test Success"| I[✅ Pass]
        H -->|"Test Failure"| J[❌ Fail + Logs]
        H -->|No clear result| J
    end

    subgraph "Cleanup"
        I --> K[docker-compose down]
        J --> K
    end
```

## File Structure

```
redis_test/
├── docker-compose.yml          # Service orchestration
├── .github/workflows/          # CI/CD pipeline
│   └── build-containers.yml
├── systemUnderTest/            # Test consumer
│   ├── Dockerfile             # Alpine-based image
│   └── test-consumer.sh       # Message processor
├── testHarness/               # Test harness
│   ├── Dockerfile             # Alpine-based image
│   └── test-harness.sh        # Test orchestrator
└── architecture.md           # This documentation
```

## Environment Variables

| Variable | Purpose | Default | Used By |
|----------|---------|---------|---------|
| `REDIS_HOST` | Redis hostname | `redis` | Both |
| `REDIS_PORT` | Redis port | `6379` | Both |
| `S3_BUCKET` | S3 bucket name | `test-bucket` | Both |
| `S3_ENDPOINT_URL` | LocalStack S3 URL | `http://localstack:4566` | Both |
| `AWS_ACCESS_KEY_ID` | Mock AWS key | `test` | Both |
| `AWS_SECRET_ACCESS_KEY` | Mock AWS secret | `test` | Both |
| `AWS_REGION` | AWS region | `us-east-1` | Both |