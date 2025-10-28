# Kyuubi with Delta Lake and Iceberg - Local Development Setup

A comprehensive Docker-based setup for running Apache Kyuubi with Delta Lake and Apache Iceberg extensions, featuring MinIO for S3-compatible storage and optional Hive Metastore support.

## 🚀 Features

- **Apache Kyuubi**: Multi-tenant JDBC interface for big data processing
- **Delta Lake**: ACID transactions and time travel for data lakes
- **Apache Iceberg**: Table format for huge analytic datasets
- **MinIO**: S3-compatible object storage
- **Hive Metastore**: Centralized metadata management (optional)
- **PostgreSQL**: Backend for Hive Metastore
- **Justfile**: Convenient task automation
- **Multiple Storage Options**: Local filesystem and S3/MinIO

## 📋 Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- [Just](https://github.com/casey/just) (task runner)
- 8GB+ RAM recommended
- 10GB+ free disk space

## 🛠️ Quick Start

1. **Clone or download this setup**
   ```bash
   # If you have this code in a directory, navigate to it
   cd /path/to/kyuubi-setup
   ```

2. **Initial setup**
   ```bash
   just setup
   ```
   This will:
   - Create necessary directories
   - Download required JARs for Delta Lake and Iceberg
   - Set up permissions

3. **Start all services**
   ```bash
   just start
   ```

4. **Verify everything is working**
   ```bash
   just status
   just health
   ```

## 🌐 Access Points

Once started, you can access:

- **Kyuubi Server**: `localhost:10009` (JDBC connection)
- **Spark UI**: http://localhost:4040
- **MinIO Console**: http://localhost:9001
  - Username: `minioadmin`
  - Password: `minioadmin`

## 📖 Usage Examples

### Connecting with Beeline

```bash
just beeline
```

Or manually:
```bash
docker-compose exec kyuubi /opt/spark/bin/beeline -u "jdbc:hive2://localhost:10009/default"
```

### Working with Delta Lake

```sql
-- Create a Delta table
CREATE TABLE sales (
    order_id INT,
    customer_id INT,
    amount DECIMAL(10,2),
    order_date DATE
) USING DELTA
PARTITIONED BY (order_date)
LOCATION 's3a://kyuubi-warehouse/sales';

-- Insert data
INSERT INTO sales VALUES 
    (1, 101, 100.50, DATE('2024-01-15')),
    (2, 102, 200.75, DATE('2024-01-15'));

-- Query data
SELECT * FROM sales WHERE order_date = DATE('2024-01-15');

-- Update data (ACID transaction)
UPDATE sales SET amount = amount * 1.1 WHERE customer_id = 101;

-- Time travel - see previous versions
SELECT * FROM sales VERSION AS OF 0;

-- Show history
DESCRIBE HISTORY sales;
```

### Working with Iceberg

```sql
-- Switch to S3 catalog
USE s3;

-- Create an Iceberg table
CREATE TABLE customers (
    customer_id INT,
    name STRING,
    email STRING,
    registration_date DATE
) USING iceberg;

-- Insert data
INSERT INTO customers VALUES
    (101, 'Alice Johnson', 'alice@example.com', DATE('2023-06-01')),
    (102, 'Bob Smith', 'bob@example.com', DATE('2023-07-15'));

-- Query data
SELECT * FROM customers;

-- Show snapshots
SELECT * FROM customers.snapshots;

-- Rollback to previous snapshot
ALTER TABLE customers ROLLBACK TO SNAPSHOT 1;
```

### Using Local Storage

```sql
-- Use local catalog
USE local;

-- Create table in local storage
CREATE TABLE local_test (
    id INT,
    data STRING
) USING iceberg;

-- Insert and query
INSERT INTO local_test VALUES (1, 'local data');
SELECT * FROM local_test;
```

## 🎯 Just Commands

The `just` command provides convenient shortcuts:

### Basic Operations
```bash
just setup          # Initial setup and download dependencies
just start          # Start all services
just stop           # Stop all services
just restart        # Restart all services
just status         # Show service status
just health         # Check service health
```

### Development Tools
```bash
just logs [service] # Show logs (all or specific service)
just shell          # Open shell in Kyuubi container
just beeline        # Connect to Kyuubi using Beeline
just minio          # Open MinIO console in browser
just spark-ui       # Open Spark UI in browser
```

### Testing
```bash
just test-delta     # Test Delta Lake functionality
just test-iceberg   # Test Iceberg functionality
just test-s3        # Test S3/MinIO functionality
just test-all       # Run all tests
```

### Data Management
```bash
just create-sample-data  # Create sample tables and data
just clean-data          # Clean data directories only
just clean               # Clean up everything
just backup-config       # Backup configurations
```

### Docker Image Management
```bash
just docker-build [tag]     # Build custom Kyuubi image
just docker-publish [tag]   # Publish image to registry
just docker-release <ver>   # Build and publish with versioning
just docker-use-custom [tag] # Update compose to use custom image
just docker-use-official    # Restore official image in compose
just docker-info            # Show Docker image information
```

## ⚙️ Configuration

### Environment Variables

Edit `.env` file to customize:

```bash
# MinIO credentials
MINIO_ACCESS_KEY=your_access_key
MINIO_SECRET_KEY=your_secret_key

# AWS region
AWS_REGION=us-east-1

# Resource allocation
SPARK_EXECUTOR_MEMORY=4g
SPARK_EXECUTOR_CORES=2
SPARK_DRIVER_MEMORY=2g
```

### Storage Options

This setup supports multiple storage backends:

1. **Local Storage**: Uses local filesystem (`local` catalog)
2. **S3/MinIO**: Uses MinIO S3-compatible storage (`s3` catalog)
3. **Hive Metastore**: Centralized metadata with PostgreSQL backend

### Custom Catalogs

You can add custom catalogs by modifying `config/kyuubi/kyuubi-defaults.conf`:

```properties
# Add new catalog
kyuubi.engine.spark.sql.catalog.my_catalog=org.apache.iceberg.spark.SparkCatalog
kyuubi.engine.spark.sql.catalog.my_catalog.type=hadoop
kyuubi.engine.spark.sql.catalog.my_catalog.warehouse=s3a://my-bucket/warehouse/
```

## 🔒 Security

### Environment Configuration

This project uses environment variables for configuration. For security reasons:

1. **`.env` file**: Contains sensitive information (credentials, keys) and is **NOT** tracked in git
2. **`.env.template`**: Template file with example values that **IS** tracked in git

**Setup your environment:**
```bash
# Copy the template to create your local environment file
cp .env.template .env

# Edit with your actual values
nano .env
```

### Git Ignore Configuration

The `.gitignore` file is configured to exclude:

- **Sensitive files**: `.env`, certificates, keys
- **Data directories**: `data/`, `warehouse/`, logs
- **Build artifacts**: JAR files, class files, target directories
- **Runtime files**: PID files, lock files, temporary files
- **IDE files**: Editor-specific configurations
- **System files**: OS-generated files

### Best Practices

1. **Never commit credentials**: Always use environment variables for secrets
2. **Change default passwords**: Update MinIO and database credentials in production
3. **Use different environments**: Maintain separate `.env` files for dev/staging/prod
4. **Regular security updates**: Keep Docker images and dependencies updated
5. **Access control**: Implement authentication in production environments

### Production Security Checklist

- [ ] Change all default passwords and credentials
- [ ] Enable Kyuubi authentication (KERBEROS/LDAP)
- [ ] Use HTTPS for all endpoints
- [ ] Implement network security groups/firewalls
- [ ] Enable audit logging
- [ ] Use secrets management (HashiCorp Vault, AWS Secrets Manager)
- [ ] Regular security scans and updates

## 🐳 Docker Image Management

This project includes a custom Docker image that extends the official Apache Kyuubi image with Delta Lake and Iceberg extensions pre-installed.

### Custom Image Features

- **Base**: `apache/kyuubi:1.9.0-spark-3.5`
- **Delta Lake**: v3.2.1 with Spark runtime and storage modules
- **Apache Iceberg**: v1.7.1 with Spark runtime and AWS bundle
- **PostgreSQL Driver**: v42.7.3 for Hive Metastore connectivity
- **Hadoop AWS**: v3.3.6 for S3/MinIO integration

### Building and Publishing

#### Build Custom Image
```bash
# Build with default 'latest' tag
just docker-build

# Build with custom tag
just docker-build 1.9.0-delta-iceberg
```

#### Publish to Registry
```bash
# Publish with default 'latest' tag
just docker-publish

# Publish with custom tag
just docker-publish 1.9.0-delta-iceberg
```

#### Complete Release Process
```bash
# Build and publish with versioning (creates both versioned and latest tags)
just docker-release 1.9.0-delta-iceberg
```

This will:
1. Build image: `regv2.gsingh.io/core/kyuubi:1.9.0-delta-iceberg`
2. Tag as latest: `regv2.gsingh.io/core/kyuubi:latest`
3. Publish both tags to the registry

### Using Custom Image

#### Update Docker Compose
```bash
# Use custom image with specific tag
just docker-use-custom 1.9.0-delta-iceberg

# Use custom image with latest tag
just docker-use-custom latest
```

#### Restore Official Image
```bash
just docker-use-official
```

### Docker Commands Reference

```bash
# Show Docker image information
just docker-info

# Build image with custom tag
just docker-build <tag>

# Publish image to registry
just docker-publish <tag>

# Complete release with versioning
just docker-release <version>

# Update compose to use custom image
just docker-use-custom <tag>

# Restore official image
just docker-use-official
```

### Image Registry

All custom images are published to: `regv2.gsingh.io/core/kyuubi`

Available tags:
- `latest` - Most recent build
- `1.9.0-delta-iceberg` - Versioned releases
- Custom tags as specified during build

### Benefits of Custom Image

1. **Faster Deployment**: Extensions pre-installed, no download time
2. **Consistency**: Same extensions across all environments
3. **Version Control**: Specific versions of Delta and Iceberg
4. **Registry Management**: Centralized image repository
5. **Reduced Complexity**: No need to manage JAR files separately

## 🔧 Advanced Configuration

### Performance Tuning

Adjust Spark settings in `config/spark/spark-defaults.conf`:

```properties
# Increase shuffle partitions for larger datasets
spark.sql.shuffle.partitions=400

# Enable dynamic allocation
spark.dynamicAllocation.enabled=true
spark.dynamicAllocation.minExecutors=2
spark.dynamicAllocation.maxExecutors=8
```

### Security

To enable authentication:

1. Set `KYUUBI_AUTHENTICATION=KERBEROS` or `LDAP` in `.env`
2. Configure security settings in `config/kyuubi/kyuubi-defaults.conf`

### Custom JARs

Place additional JARs in the `jars/` directory. They will be automatically added to the classpath.

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**: Modify ports in `.env` if services conflict with existing applications
2. **Memory issues**: Increase `SPARK_DRIVER_MEMORY` and `SPARK_EXECUTOR_MEMORY` in `.env`
3. **Permission errors**: Ensure Docker has proper permissions to access data directories

### Debug Commands

```bash
# Check service logs
just logs kyuubi
just logs minio
just logs postgres

# Check container status
docker-compose ps

# Access container shell
just shell

# Restart specific service
docker-compose restart kyuubi
```

### Health Checks

```bash
# Manual health check
just health

# Check specific service
curl http://localhost:10009/  # Kyuubi
curl http://localhost:9000/minio/health/live  # MinIO
```

## 📚 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Applications  │    │   BI Tools      │    │   Notebooks     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────────────┼──────────────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │      Kyuubi Server       │
                    │    (JDBC Interface)      │
                    └─────────────┬─────────────┘
                                 │
                    ┌─────────────▼─────────────┐
                    │    Spark SQL Engine       │
                    │  (Delta + Iceberg)       │
                    └─────────────┬─────────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
┌─────────▼─────────┐  ┌─────────▼─────────┐  ┌─────────▼─────────┐
│   Local Storage  │  │   MinIO (S3)     │  │  Hive Metastore  │
│   (local catalog)│  │   (s3 catalog)   │  │   (metadata)     │
└───────────────────┘  └───────────────────┘  └───────────────────┘
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `just test-all`
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## 🔗 Related Links

- [Apache Kyuubi Documentation](https://kyuubi.apache.org/docs/latest/)
- [Delta Lake Documentation](https://docs.delta.io/latest/)
- [Apache Iceberg Documentation](https://iceberg.apache.org/docs/latest/)
- [MinIO Documentation](https://docs.min.io/)
- [Just Command Runner](https://github.com/casey/just)

## 💡 Tips and Best Practices

1. **Data Organization**: Use separate buckets/directories for different projects
2. **Performance**: Monitor Spark UI for optimization opportunities
3. **Backups**: Regularly backup MinIO data and configurations
4. **Security**: Change default MinIO credentials in production
5. **Monitoring**: Set up monitoring for production deployments

## 🆘 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review service logs with `just logs`
3. Verify all prerequisites are installed
4. Check for port conflicts
5. Ensure sufficient system resources

For additional help, create an issue in the repository with:
- Error messages
- System information
- Steps to reproduce
- Relevant logs