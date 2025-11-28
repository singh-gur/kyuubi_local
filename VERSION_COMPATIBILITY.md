# Version Compatibility Matrix

This document outlines the compatible versions of all components in the Kyuubi local development environment.

## Updated Component Versions

| Component | Previous Version | Updated Version | Notes |
|-----------|-----------------|-----------------|-------|
| **Apache Kyuubi** | 1.10.2 | **1.10.0** | Latest stable release with Spark 3.5 support |
| **Apache Spark** | 3.5.2 | **3.5.2** | Bundled with Kyuubi 1.10.0 image |
| **Scala** | 2.13 | **2.13** | No change - standard for Spark 3.5.x |
| **Delta Lake** | 3.2.1 | **3.2.1** | Fully compatible with Spark 3.5.x |
| **Apache Iceberg** | 1.7.1 | **1.7.1** | Fully compatible with Spark 3.5.x |
| **PostgreSQL Driver** | 42.7.3 | **42.7.4** | Latest stable JDBC driver |
| **Hadoop AWS** | 3.3.6 | **3.3.6** | Compatible with Spark 3.5.2 |
| **Apache Hive** | 4.0.0 | **4.0.0** | No change - compatible metastore |

## Compatibility Details

### Spark 3.5.2 Compatibility
- **Delta Lake 3.2.1**: ✅ Fully supported (Spark 3.5.x compatible)
- **Iceberg 1.7.1**: ✅ Fully supported (Spark 3.5.x compatible)
- **Scala 2.13**: ✅ Default Scala version for Spark 3.5.x
- **Hadoop 3.3.6**: ✅ Compatible with Spark 3.5.2

### Key Features Enabled
1. **Delta Lake 3.2.1**
   - Deletion Vectors
   - Liquid Clustering
   - V2 Checkpoints
   - Coordinated Commits
   - Type Widening

2. **Iceberg 1.7.1**
   - Puffin Statistics
   - Position Delete Deltas
   - Metadata Delete Files
   - Branching and Tagging
   - Partition Evolution

3. **Kyuubi 1.10.0**
   - Multi-tenancy support
   - REST API
   - Spark 3.5.x engine support
   - Enhanced security features

## JAR Dependencies

The following JARs are automatically downloaded and installed in the Docker image:

```
delta-spark_2.13-3.2.1.jar
delta-storage-3.2.1.jar
iceberg-spark-runtime-3.5_2.13-1.7.1.jar
iceberg-aws-bundle-1.7.1.jar
hadoop-aws-3.4.1.jar
postgresql-42.7.4.jar
```

## Version Selection Rationale

### Why Spark 3.5.2?
- Bundled with Kyuubi 1.10.0 official image
- Fully compatible with Delta Lake 3.2.x and Iceberg 1.7.x
- Production-ready and stable
- Tested and verified with Kyuubi 1.10.0

### Why Kyuubi 1.10.0?
- Latest stable release with Spark 3.5 support
- Enhanced multi-tenancy features
- Better REST API support
- Improved engine lifecycle management

### Why Delta Lake 3.2.1?
- Latest stable release for Spark 3.5.x
- Includes all modern Delta Lake features
- Production-ready with extensive testing
- Best performance optimizations

### Why Iceberg 1.7.1?
- Latest stable release for Spark 3.5.x
- Includes branching and tagging features
- Enhanced metadata management
- Better performance with position deletes

## Testing Compatibility

After updating, verify compatibility with:

```sql
-- Test Delta Lake
CREATE TABLE delta_test USING delta AS SELECT 1 as id;
SELECT * FROM delta_test;

-- Test Iceberg
CREATE TABLE local.db.iceberg_test (id INT) USING iceberg;
INSERT INTO local.db.iceberg_test VALUES (1);
SELECT * FROM local.db.iceberg_test;

-- Check versions
SELECT version() as spark_version;
```

## Upgrade Path

To apply these updates:

```bash
# Rebuild the Docker image
docker-compose build --no-cache

# Restart services
docker-compose down
docker-compose up -d

# Verify versions
docker exec kyuubi-server /opt/kyuubi/externals/spark-3.5.2-bin-hadoop3/bin/spark-submit --version
```

## Known Issues and Workarounds

### Issue: Hadoop AWS Version Mismatch
**Solution**: Updated to Hadoop AWS 3.4.1 which is compatible with Spark 3.5.3

### Issue: Delta Lake S3 LogStore
**Solution**: Using `S3SingleDriverLogStore` for local development (single-writer mode)

### Issue: Iceberg Timestamp Handling
**Solution**: Set `spark.sql.iceberg.handle-timestamp-without-timezone=false` for consistent behavior

## Future Upgrade Considerations

When upgrading to Spark 4.0 (future):
- Delta Lake will require version 4.0+
- Iceberg will require version 2.0+
- Scala version may change to 2.13 or 3.x
- Kyuubi will require version 1.11+

## References

- [Apache Spark Releases](https://spark.apache.org/downloads.html)
- [Delta Lake Compatibility](https://docs.delta.io/latest/releases.html)
- [Iceberg Compatibility](https://iceberg.apache.org/releases/)
- [Kyuubi Releases](https://kyuubi.apache.org/releases.html)

---
Last Updated: November 28, 2025
