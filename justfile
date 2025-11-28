# Kyuubi with Delta and Iceberg - Local Development Setup
# This Justfile provides convenient commands for managing the development environment
#
# NOTE: This setup uses a custom Docker image (regv2.gsingh.io/core/kyuubi:latest)
# that is built from the Dockerfile with Spark 3.5.2 and all required extensions.
# The 'start' command automatically builds the image before starting services.

# Default recipe
default:
    @just --list

# Environment variables
export MINIO_ACCESS_KEY := env_var_or_default("MINIO_ACCESS_KEY", "minioadmin")
export MINIO_SECRET_KEY := env_var_or_default("MINIO_SECRET_KEY", "minioadmin")
export AWS_REGION := env_var_or_default("AWS_REGION", "us-east-1")
export HIVE_METASTORE_DB := env_var_or_default("HIVE_METASTORE_DB", "hive_metastore")
export HIVE_METASTORE_USER := env_var_or_default("HIVE_METASTORE_USER", "hive")
export HIVE_METASTORE_PASSWORD := env_var_or_default("HIVE_METASTORE_PASSWORD", "hive")

# Initial setup
setup:
    mkdir -p config/kyuubi config/spark config/hive scripts jars data/warehouse data/minio data/postgres logs
    @echo "📦 Downloading required JARs..."
    just _download-jars
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x config/spark/spark-env.sh
    @echo "✅ Setup complete!"

# Download required JARs for Delta and Iceberg
_download-jars:
    #!/usr/bin/env bash
    set -e
    
    JARS_DIR="jars"
    DELTA_VERSION="3.2.1"
    ICEBERG_VERSION="1.7.1"
    SCALA_VERSION="2.13"
    POSTGRES_VERSION="42.7.3"
    HADOOP_AWS_VERSION="3.3.6"
    
    # Create jars directory
    mkdir -p "$JARS_DIR"
    
    echo "Downloading Delta Lake JARs..."
    cd "$JARS_DIR"
    
    # Delta Lake Spark Runtime
    if [ ! -f "delta-spark_${SCALA_VERSION}-${DELTA_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/io/delta/delta-spark_${SCALA_VERSION}/${DELTA_VERSION}/delta-spark_${SCALA_VERSION}-${DELTA_VERSION}.jar"
    fi
    
    # Delta Storage
    if [ ! -f "delta-storage-${DELTA_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar"
    fi
    
    # Iceberg JARs
    echo "Downloading Iceberg JARs..."
    if [ ! -f "iceberg-spark-runtime-3.5_${SCALA_VERSION}-${ICEBERG_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_${SCALA_VERSION}/${ICEBERG_VERSION}/iceberg-spark-runtime-3.5_${SCALA_VERSION}-${ICEBERG_VERSION}.jar"
    fi
    
    if [ ! -f "iceberg-aws-bundle-${ICEBERG_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar"
    fi
    
    # PostgreSQL Driver
    echo "Downloading PostgreSQL driver..."
    if [ ! -f "postgresql-${POSTGRES_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.jar"
    fi
    
    # Hadoop AWS
    echo "Downloading Hadoop AWS JAR..."
    if [ ! -f "hadoop-aws-${HADOOP_AWS_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar"
    fi
    
    cd ..
    echo "✅ JARs downloaded successfully!"

# Start all services
start:
    @echo "🔨 Building custom Kyuubi image..."
    just docker-build latest
    @echo "🚀 Starting Kyuubi services..."
    docker compose up -d
    @echo "⏳ Waiting for services to be ready..."
    sleep 30
    just status
    @echo "✅ Services started!"
    @echo "📊 Spark UI: http://localhost:4040"
    @echo "🗄️  MinIO Console: http://localhost:9001"
    @echo "🔌 Kyuubi Server: localhost:10009"

# Stop all services
stop:
    @echo "🛑 Stopping Kyuubi services..."
    docker compose down
    @echo "✅ Services stopped!"

# Start services without rebuilding (faster for restarts)
start-quick:
    @echo "🚀 Starting Kyuubi services (without rebuild)..."
    docker compose up -d
    @echo "⏳ Waiting for services to be ready..."
    sleep 30
    just status
    @echo "✅ Services started!"
    @echo "📊 Spark UI: http://localhost:4040"
    @echo "🗄️  MinIO Console: http://localhost:9001"
    @echo "🔌 Kyuubi Server: localhost:10009"

# Restart all services
restart:
    @echo "🔄 Restarting Kyuubi services..."
    just stop
    just start-quick

# Show logs
logs service="":
    #!/usr/bin/env bash
    if [ -z "$service" ]; then
        echo "📋 Showing logs for all services..."
        docker compose logs -f
    else
        echo "📋 Showing logs for $service..."
        docker compose logs -f "$service"
    fi

# Show status
status:
    @echo "📊 Service Status:"
    @docker compose ps

# Open shell in Kyuubi container
shell:
    @echo "🐚 Opening shell in Kyuubi container..."
    docker compose exec kyuubi bash

# Connect to Kyuubi using Beeline
beeline:
    @echo "🔌 Connecting to Kyuubi using Beeline..."
    docker compose exec kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default"

# Open MinIO console
minio:
    @echo "MinIO Console: http://localhost:9001"

# Open Spark UI
spark-ui:
    @echo "Spark UI: http://localhost:4040"

# Clean up everything
clean:
    @echo "🧹 Cleaning up containers and data..."
    docker compose down -v --remove-orphans
    docker system prune -f
    sudo rm -rf data/* logs/*
    @echo "✅ Cleanup complete!"

# Clean only data directories
clean-data:
    @echo "🧹 Cleaning data directories..."
    docker compose down
    sudo rm -rf data/warehouse/* data/minio/* data/postgres/*
    @echo "✅ Data cleaned!"

# Test Delta Lake functionality
test-delta:
    #!/usr/bin/env bash
    set -e
    echo "🧪 Testing Delta Lake functionality..."
    docker compose exec -T kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" <<'EOF'
    CREATE TABLE delta_test (id INT, name STRING, value DOUBLE) USING DELTA LOCATION 's3a://kyuubi-warehouse/delta_test';
    INSERT INTO delta_test VALUES (1, 'Alice', 100.5), (2, 'Bob', 200.3);
    SELECT * FROM delta_test;
    UPDATE delta_test SET value = value * 1.1 WHERE id = 1;
    DESCRIBE HISTORY delta_test;
    EOF

# Test Iceberg functionality
test-iceberg:
    #!/usr/bin/env bash
    set -e
    echo "🧪 Testing Iceberg functionality..."
    docker compose exec -T kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" <<'EOF'
    USE s3;
    CREATE TABLE iceberg_test (id INT, name STRING, value DOUBLE) USING iceberg;
    INSERT INTO iceberg_test VALUES (1, 'Charlie', 300.7), (2, 'Diana', 400.2);
    SELECT * FROM iceberg_test;
    SELECT * FROM iceberg_test.snapshots;
    EOF

# Test S3/MinIO functionality
test-s3:
    #!/usr/bin/env bash
    set -e
    echo "🧪 Testing S3/MinIO functionality..."
    docker compose exec -T kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" <<'EOF'
    CREATE TABLE s3_test (id INT, data STRING) LOCATION 's3a://kyuubi-warehouse/s3_test';
    INSERT INTO s3_test VALUES (1, 'test_data_1'), (2, 'test_data_2');
    SELECT * FROM s3_test;
    SHOW TABLES LIKE '*s3*';
    EOF

# Run all tests
test-all: test-delta test-iceberg test-s3
    @echo "✅ All tests completed!"

# Show help
help:
    @just --list

# Create sample data
create-sample-data:
    @echo "📊 Creating sample data..."
    docker compose exec kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" -e "CREATE TABLE sales_delta (order_id INT, customer_id INT, product_id INT, quantity INT, price DECIMAL(10,2), order_date DATE) USING DELTA PARTITIONED BY (order_date);"
    docker compose exec kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" -e "INSERT INTO sales_delta VALUES (1, 101, 1001, 2, 29.99, DATE('2024-01-15')), (2, 102, 1002, 1, 49.99, DATE('2024-01-15')), (3, 101, 1003, 3, 19.99, DATE('2024-01-16')), (4, 103, 1001, 1, 29.99, DATE('2024-01-16'));"
    docker compose exec kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" -e "USE s3; CREATE TABLE customers_iceberg (customer_id INT, name STRING, email STRING, registration_date DATE) USING iceberg;"
    docker compose exec kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" -e "USE s3; INSERT INTO customers_iceberg VALUES (101, 'Alice Johnson', 'alice@example.com', DATE('2023-06-01')), (102, 'Bob Smith', 'bob@example.com', DATE('2023-07-15')), (103, 'Charlie Brown', 'charlie@example.com', DATE('2023-08-20'));"
    docker compose exec kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" -e "USE default; SHOW TABLES;"
    docker compose exec kyuubi /opt/kyuubi/bin/beeline -u "jdbc:hive2://localhost:10009/default" -e "USE s3; SHOW TABLES;"
    @echo "✅ Sample data created!"

# Backup configurations
backup-config:
    @echo "💾 Backing up configurations..."
    tar -czf "kyuubi-config-backup-$(date +%Y%m%d-%H%M%S).tar.gz" config/ justfile docker-compose.yml .env 2>/dev/null || true
    @echo "✅ Configuration backed up!"

# Health check
health:
    @echo "🏥 Checking service health..."
    @echo "Kyuubi Server:"; curl -s http://localhost:10009/ >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
    @echo "MinIO:"; curl -s http://localhost:9000/minio/health/live >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
    @echo "PostgreSQL:"; docker compose exec -T postgres pg_isready -U hive >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
    @echo "Hive Metastore:"; docker compose exec -T hive-metastore netstat -tlnp | grep :9083 >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"

# Docker image management
# Build custom Kyuubi image with Delta and Iceberg extensions
docker-build tag="latest":
    @echo "🔨 Building custom Kyuubi image with Delta and Iceberg extensions..."
    @echo "Building image: regv2.gsingh.io/core/kyuubi:{{tag}}"
    docker build -t "regv2.gsingh.io/core/kyuubi:{{tag}}" .
    @echo "✅ Image built successfully: regv2.gsingh.io/core/kyuubi:{{tag}}"

# Publish Docker image to registry
docker-publish tag="latest":
    @echo "📤 Publishing Kyuubi image to registry..."
    @echo "Publishing: regv2.gsingh.io/core/kyuubi:{{tag}}"
    docker push "regv2.gsingh.io/core/kyuubi:{{tag}}"
    @echo "✅ Image published successfully: regv2.gsingh.io/core/kyuubi:{{tag}}"

# Build and publish Docker image with version tagging
docker-release version="":
    #!/usr/bin/env bash
    set -e
    
    if [ -z "{{version}}" ]; then
        echo "❌ Error: Version is required"
        echo "Usage: just docker-release <version>"
        echo "Example: just docker-release 1.10.2-delta-iceberg"
        exit 1
    fi
    
    echo "🚀 Releasing Kyuubi image version {{version}}..."
    
    # Build with version tag
    echo "Building image with version tag..."
    just docker-build "{{version}}"
    
    # Also tag as latest
    echo "Tagging as latest..."
    docker tag "regv2.gsingh.io/core/kyuubi:{{version}}" "regv2.gsingh.io/core/kyuubi:latest"
    
    # Publish both tags
    echo "Publishing versioned image..."
    just docker-publish "{{version}}"
    
    echo "Publishing latest image..."
    just docker-publish "latest"
    
    echo "✅ Release complete!"
    echo "📦 Published images:"
    echo "   - regv2.gsingh.io/core/kyuubi:{{version}}"
    echo "   - regv2.gsingh.io/core/kyuubi:latest"

# Update docker-compose.yml to use custom image
docker-use-custom tag="latest":
    #!/usr/bin/env bash
    set -e
    
    echo "🔄 Updating docker-compose.yml to use custom image..."
    IMAGE_NAME="regv2.gsingh.io/core/kyuubi:{{tag}}"
    
    # Update the image in docker-compose.yml
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|image: apache/kyuubi:1.10.2-spark|image: ${IMAGE_NAME}|g" docker-compose.yml
    else
        # Linux
        sed -i "s|image: apache/kyuubi:1.10.2-spark|image: ${IMAGE_NAME}|g" docker-compose.yml
    fi
    
    echo "✅ Updated docker-compose.yml to use ${IMAGE_NAME}"
    echo "💡 Run 'just restart' to use the new image"

# Restore docker-compose.yml to use official image
docker-use-official:
    #!/usr/bin/env bash
    set -e
    
    echo "🔄 Restoring docker-compose.yml to use official image..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|image: regv2.gsingh.io/core/kyuubi:.*|image: apache/kyuubi:1.10.2-spark|g" docker-compose.yml
    else
        # Linux
        sed -i "s|image: regv2.gsingh.io/core/kyuubi:.*|image: apache/kyuubi:1.10.2-spark|g" docker-compose.yml
    fi
    
    echo "✅ Restored docker-compose.yml to use official image"
    echo "💡 Run 'just restart' to use the official image"

# Show Docker image information
docker-info:
    @echo "📋 Docker Image Information:"
    @echo "Custom Image: regv2.gsingh.io/core/kyuubi"
    @echo "Base Image: apache/kyuubi:1.10.2-spark"
    @echo "Extensions: Delta Lake 3.2.1, Iceberg 1.7.1"
    @echo ""
    @echo "📦 Available local images:"
    @docker images | grep kyuubi || echo "No Kyuubi images found locally"
    @echo ""
    @echo "🔧 Available commands:"
    @echo "  just docker-build [tag]     - Build custom image"
    @echo "  just docker-publish [tag]   - Publish image to registry"
    @echo "  just docker-release <ver>  - Build and publish with versioning"
    @echo "  just docker-use-custom [tag] - Update compose to use custom image"
    @echo "  just docker-use-official    - Restore official image in compose"
    @echo "  just docker-info            - Show this information"