# Custom Kyuubi Image Build Notes

## Issue Fixed
**Problem**: NullPointerException due to Spark version mismatch
- Kyuubi 1.10.0 base image is compiled with Spark 3.5.2
- Configuration files were incorrectly referencing Spark 3.5.3

## Changes Made

### 1. Dockerfile Updates
- Changed `SPARK_JARS_DIR` from `spark-3.5.3-bin-hadoop3` to `spark-3.5.2-bin-hadoop3`
- Updated label `spark.version` from "3.5.3" to "3.5.2"

### 2. docker-compose.yml Updates
- Changed `SPARK_HOME` environment variable to use `spark-3.5.2-bin-hadoop3`
- Updated volume mount path for Spark config to `spark-3.5.2-bin-hadoop3/conf`
- Changed image from `apache/kyuubi:1.10.0-spark` to `regv2.gsingh.io/core/kyuubi:latest`

### 3. VERSION_COMPATIBILITY.md Updates
- Updated verification command to use correct Spark path

## Custom Image Details

**Image Name**: `regv2.gsingh.io/core/kyuubi:latest`
**Also Tagged As**: `regv2.gsingh.io/core/kyuubi:1.10.0-spark-3.5.2`

### Installed Extensions
The custom image includes the following JARs in the Spark classpath:
1. `delta-spark_2.13-3.2.1.jar` (6.2 MB)
2. `delta-storage-3.2.1.jar` (24 KB)
3. `iceberg-spark-runtime-3.5_2.13-1.7.1.jar` (42.8 MB)
4. `iceberg-aws-bundle-1.7.1.jar` (49.6 MB)
5. `hadoop-aws-3.4.1.jar` (865 KB)
6. `postgresql-42.7.4.jar` (1.1 MB)

### Version Matrix
| Component | Version |
|-----------|---------|
| Kyuubi | 1.10.0 |
| Spark | 3.5.2 |
| Scala | 2.13 |
| Delta Lake | 3.2.1 |
| Iceberg | 1.7.1 |
| Hadoop AWS | 3.4.1 |
| PostgreSQL Driver | 42.7.4 |

## Build Commands

### Build the image
```bash
docker build -t regv2.gsingh.io/core/kyuubi:latest .
```

Or using justfile:
```bash
just docker-build latest
```

### Verify the build
```bash
docker run --rm regv2.gsingh.io/core/kyuubi:latest ls -la /opt/kyuubi/externals/spark-3.5.2-bin-hadoop3/jars/ | grep -E "(delta|iceberg|postgresql|hadoop-aws)"
```

## Usage

### Start services with custom image

Using justfile (recommended - builds image first):
```bash
just start
```

Or for quick restart without rebuilding:
```bash
just start-quick
```

Or using docker-compose directly (requires manual build first):
```bash
docker build -t regv2.gsingh.io/core/kyuubi:latest .
docker-compose up -d
```

### Verify Spark version
```bash
docker exec kyuubi-server /opt/kyuubi/externals/spark-3.5.2-bin-hadoop3/bin/spark-submit --version
```

## Testing

Run the test suite to verify Delta Lake and Iceberg functionality:
```bash
just test-all
```

Or individual tests:
```bash
just test-delta
just test-iceberg
just test-s3
```

## Troubleshooting

### If you still see version mismatch errors:
1. Stop all containers: `docker-compose down`
2. Remove old images: `docker rmi apache/kyuubi:1.10.0-spark`
3. Rebuild: `docker build --no-cache -t regv2.gsingh.io/core/kyuubi:latest .`
4. Start services: `docker-compose up -d`

### Verify correct image is running:
```bash
docker inspect kyuubi-server | grep Image
```

Should show: `regv2.gsingh.io/core/kyuubi:latest`

## Publishing to Registry (Optional)

If you want to push to your registry:
```bash
just docker-publish latest
```

Or with version tag:
```bash
just docker-release 1.10.0-spark-3.5.2
```

---
Built on: $(date)

## Justfile Commands Reference

### Updated Workflow

The justfile has been updated to ensure the custom image is always built before starting services:

| Command | Description | When to Use |
|---------|-------------|-------------|
| `just start` | Build custom image + start all services | **First time** or after Dockerfile changes |
| `just start-quick` | Start services without rebuilding | Quick restarts when no Dockerfile changes |
| `just restart` | Stop and start services (no rebuild) | Restart after config changes |
| `just stop` | Stop all services | When done working |
| `just docker-build [tag]` | Build custom image only | Manual image builds |

### Recommended Workflow

**Initial Setup:**
```bash
just setup          # Create directories and download JARs
just start          # Build image and start services (first time)
```

**Daily Development:**
```bash
just start-quick    # Quick start (image already built)
just logs           # View logs
just beeline        # Connect to Kyuubi
```

**After Dockerfile Changes:**
```bash
just stop           # Stop services
just start          # Rebuild image and start
```

**After Config Changes (spark-defaults.conf, kyuubi-defaults.conf):**
```bash
just restart        # Quick restart without rebuild
```

---
Last Updated: November 28, 2025
