# Kyuubi with Delta and Iceberg - Local Development Setup
# This Justfile provides convenient commands for managing the development environment

# Default recipe
default:
    @echo "Kyuubi with Delta and Iceberg - Local Development Setup"
    @echo ""
    @echo "Available commands:"
    @echo "  just setup          - Initial setup and download dependencies"
    @echo "  just start          - Start all services"
    @echo "  just stop           - Stop all services"
    @echo "  just restart        - Restart all services"
    @echo "  just logs [service] - Show logs for all or specific service"
    @echo "  just status         - Show status of all services"
    @echo "  just shell          - Open shell in Kyuubi container"
    @echo "  just beeline        - Connect to Kyuubi using Beeline"
    @echo "  just minio          - Open MinIO console in browser"
    @echo "  just spark-ui       - Open Spark UI in browser"
    @echo "  just clean          - Clean up containers and data"
    @echo "  just clean-data     - Clean only data directories"
    @echo "  just test-delta     - Test Delta Lake functionality"
    @echo "  just test-iceberg   - Test Iceberg functionality"
    @echo "  just test-s3        - Test S3/MinIO functionality"
    @echo "  just help           - Show this help message"

# Environment variables
export MINIO_ACCESS_KEY := env_var_or_default("MINIO_ACCESS_KEY", "minioadmin")
export MINIO_SECRET_KEY := env_var_or_default("MINIO_SECRET_KEY", "minioadmin")
export AWS_REGION := env_var_or_default("AWS_REGION", "us-east-1")
export HIVE_METASTORE_DB := env_var_or_default("HIVE_METASTORE_DB", "hive_metastore")
export HIVE_METASTORE_USER := env_var_or_default("HIVE_METASTORE_USER", "hive")
export HIVE_METASTORE_PASSWORD := env_var_or_default("HIVE_METASTORE_PASSWORD", "hive")

# Initial setup
setup:
    @echo "🚀 Setting up Kyuubi development environment..."
    
    # Create necessary directories
    mkdir -p config/kyuubi config/spark config/hive scripts jars data/warehouse data/minio data/postgres logs
    
    # Download required JARs if not present
    @echo "📦 Downloading required JARs..."
    just _download-jars
    
    # Set proper permissions
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod +x config/spark/spark-env.sh
    
    @echo "✅ Setup complete! Run 'just start' to begin."

# Download required JARs for Delta and Iceberg
_download-jars:
    #!/usr/bin/env bash
    set -e
    
    JARS_DIR="jars"
    DELTA_VERSION="2.4.0"
    ICEBERG_VERSION="1.5.0"
    SPARK_VERSION="3.5"
    POSTGRES_VERSION="42.7.3"
    AWS_SDK_VERSION="2.25.69"
    HADOOP_AWS_VERSION="3.3.6"
    
    # Create jars directory
    mkdir -p "$JARS_DIR"
    
    echo "Downloading Delta Lake JARs..."
    cd "$JARS_DIR"
    
    # Delta Lake Core
    if [ ! -f "delta-core_${SPARK_VERSION}-${DELTA_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/io/delta/delta-core_${SPARK_VERSION}/${DELTA_VERSION}/delta-core_${SPARK_VERSION}-${DELTA_VERSION}.jar"
    fi
    
    # Delta Storage
    if [ ! -f "delta-storage-${DELTA_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar"
    fi
    
    # Iceberg JARs
    echo "Downloading Iceberg JARs..."
    if [ ! -f "iceberg-spark-runtime-${SPARK_VERSION}_${ICEBERG_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_VERSION}_${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_VERSION}_${ICEBERG_VERSION}.jar"
    fi
    
    if [ ! -f "iceberg-aws-bundle-${ICEBERG_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar"
    fi
    
    # PostgreSQL Driver
    echo "Downloading PostgreSQL driver..."
    if [ ! -f "postgresql-${POSTGRES_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.jar"
    fi
    
    # AWS SDK and Hadoop AWS
    echo "Downloading AWS SDK JARs..."
    if [ ! -f "hadoop-aws-${HADOOP_AWS_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar"
    fi
    
    # AWS SDK bundles
    if [ ! -f "aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar" ]; then
        wget -q "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_SDK_VERSION}/aws-java-sdk-bundle-${AWS_SDK_VERSION}.jar"
    fi
    
    cd ..
    echo "✅ JARs downloaded successfully!"

# Start all services
start:
    @echo "🚀 Starting Kyuubi services..."
    docker-compose up -d
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
    docker-compose down
    @echo "✅ Services stopped!"

# Restart all services
restart:
    @echo "🔄 Restarting Kyuubi services..."
    just stop
    just start

# Show logs
logs service="":
    #!/usr/bin/env bash
    if [ -z "$service" ]; then
        echo "📋 Showing logs for all services..."
        docker-compose logs -f
    else
        echo "📋 Showing logs for $service..."
        docker-compose logs -f "$service"
    fi

# Show status
status:
    @echo "📊 Service Status:"
    @docker-compose ps

# Open shell in Kyuubi container
shell:
    @echo "🐚 Opening shell in Kyuubi container..."
    docker-compose exec kyuubi bash

# Connect to Kyuubi using Beeline
beeline:
    @echo "🔌 Connecting to Kyuubi using Beeline..."
    docker-compose exec kyuubi /opt/spark/bin/beeline -u "jdbc:hive2://localhost:10009/default"

# Open MinIO console
minio:
    @echo "🗄️ Opening MinIO console..."
    @if command -v xdg-open >/dev/null 2>&1; then
        xdg-open http://localhost:9001
    elif command -v open >/dev/null 2>&1; then
        open http://localhost:9001
    else
        echo "Please open http://localhost:9001 in your browser"
    fi

# Open Spark UI
spark-ui:
    @echo "📊 Opening Spark UI..."
    @if command -v xdg-open >/dev/null 2>&1; then
        xdg-open http://localhost:4040
    elif command -v open >/dev/null 2>&1; then
        open http://localhost:4040
    else
        echo "Please open http://localhost:4040 in your browser"
    fi

# Clean up everything
clean:
    @echo "🧹 Cleaning up containers and data..."
    docker-compose down -v --remove-orphans
    docker system prune -f
    sudo rm -rf data/* logs/*
    @echo "✅ Cleanup complete!"

# Clean only data directories
clean-data:
    @echo "🧹 Cleaning data directories..."
    docker-compose down
    sudo rm -rf data/warehouse/* data/minio/* data/postgres/*
    @echo "✅ Data cleaned!"

# Test Delta Lake functionality
test-delta:
    @echo "🧪 Testing Delta Lake functionality..."
    docker-compose exec kyuubi /opt/spark/bin/beeline -u "jdbc:hive2://localhost:10009/default" --script=<(echo "
    -- Create Delta table
    CREATE TABLE delta_test (id INT, name STRING, value DOUBLE) USING DELTA LOCATION 's3a://kyuubi-warehouse/delta_test';
    
    -- Insert data
    INSERT INTO delta_test VALUES (1, 'Alice', 100.5), (2, 'Bob', 200.3);
    
    -- Query data
    SELECT * FROM delta_test;
    
    -- Update data
    UPDATE delta_test SET value = value * 1.1 WHERE id = 1;
    
    -- Show history
    DESCRIBE HISTORY delta_test;
    ")

# Test Iceberg functionality
test-iceberg:
    @echo "🧪 Testing Iceberg functionality..."
    docker-compose exec kyuubi /opt/spark/bin/beeline -u "jdbc:hive2://localhost:10009/default" --script=<(echo "
    -- Use Iceberg catalog
    USE s3;
    
    -- Create Iceberg table
    CREATE TABLE iceberg_test (id INT, name STRING, value DOUBLE) USING iceberg;
    
    -- Insert data
    INSERT INTO iceberg_test VALUES (1, 'Charlie', 300.7), (2, 'Diana', 400.2);
    
    -- Query data
    SELECT * FROM iceberg_test;
    
    -- Show snapshots
    SELECT * FROM iceberg_test.snapshots;
    ")

# Test S3/MinIO functionality
test-s3:
    @echo "🧪 Testing S3/MinIO functionality..."
    docker-compose exec kyuubi /opt/spark/bin/beeline -u "jdbc:hive2://localhost:10009/default" --script=<(echo "
    -- Create table in S3
    CREATE TABLE s3_test (id INT, data STRING) LOCATION 's3a://kyuubi-warehouse/s3_test';
    
    -- Insert data
    INSERT INTO s3_test VALUES (1, 'test_data_1'), (2, 'test_data_2');
    
    -- Query data
    SELECT * FROM s3_test;
    
    -- List S3 files (using Spark)
    SHOW TABLES LIKE '*s3*';
    ")

# Run all tests
test-all: test-delta test-iceberg test-s3
    @echo "✅ All tests completed!"

# Show help
help:
    @just --list

# Create sample data
create-sample-data:
    @echo "📊 Creating sample data..."
    docker-compose exec kyuubi /opt/spark/bin/beeline -u "jdbc:hive2://localhost:10009/default" --script=<(echo "
    -- Create Delta sample table
    CREATE TABLE sales_delta (
        order_id INT,
        customer_id INT,
        product_id INT,
        quantity INT,
        price DECIMAL(10,2),
        order_date DATE
    ) USING DELTA PARTITIONED BY (order_date);
    
    -- Insert sample data
    INSERT INTO sales_delta VALUES
        (1, 101, 1001, 2, 29.99, DATE('2024-01-15')),
        (2, 102, 1002, 1, 49.99, DATE('2024-01-15')),
        (3, 101, 1003, 3, 19.99, DATE('2024-01-16')),
        (4, 103, 1001, 1, 29.99, DATE('2024-01-16'));
    
    -- Create Iceberg sample table
    USE s3;
    CREATE TABLE customers_iceberg (
        customer_id INT,
        name STRING,
        email STRING,
        registration_date DATE
    ) USING iceberg;
    
    -- Insert sample data
    INSERT INTO customers_iceberg VALUES
        (101, 'Alice Johnson', 'alice@example.com', DATE('2023-06-01')),
        (102, 'Bob Smith', 'bob@example.com', DATE('2023-07-15')),
        (103, 'Charlie Brown', 'charlie@example.com', DATE('2023-08-20'));
    
    -- Show created tables
    USE default;
    SHOW TABLES;
    USE s3;
    SHOW TABLES;
    ")
    @echo "✅ Sample data created!"

# Backup configurations
backup-config:
    @echo "💾 Backing up configurations..."
    tar -czf "kyuubi-config-backup-$(date +%Y%m%d-%H%M%S).tar.gz" config/ justfile docker-compose.yml .env 2>/dev/null || true
    @echo "✅ Configuration backed up!"

# Health check
health:
    @echo "🏥 Checking service health..."
    @echo "Kyuubi Server:"
    @curl -s http://localhost:10009/ >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
    @echo "MinIO:"
    @curl -s http://localhost:9000/minio/health/live >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
    @echo "PostgreSQL:"
    @docker-compose exec -T postgres pg_isready -U hive >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"
    @echo "Hive Metastore:"
    @docker-compose exec -T hive-metastore netstat -tlnp | grep :9083 >/dev/null && echo "✅ Healthy" || echo "❌ Unhealthy"