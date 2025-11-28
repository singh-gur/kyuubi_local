# Custom Kyuubi image with Delta Lake and Iceberg extensions
# Based on official Apache Kyuubi image
FROM apache/kyuubi:1.10.0-spark

# Set environment variables
ENV DELTA_VERSION="3.2.1" \
    ICEBERG_VERSION="1.7.1" \
    SCALA_VERSION="2.13" \
    POSTGRES_VERSION="42.7.4" \
    HADOOP_AWS_VERSION="3.4.1"

# Use the existing SPARK_HOME for JARs
ENV SPARK_JARS_DIR="/opt/kyuubi/externals/spark-3.5.2-bin-hadoop3/jars"

# Switch to root to install dependencies
USER root

# Download and install Delta Lake JARs using curl (should be available)
RUN echo "Installing Delta Lake JARs..." && \
    cd ${SPARK_JARS_DIR} && \
    curl -s -L -o "delta-spark_${SCALA_VERSION}-${DELTA_VERSION}.jar" "https://repo1.maven.org/maven2/io/delta/delta-spark_${SCALA_VERSION}/${DELTA_VERSION}/delta-spark_${SCALA_VERSION}-${DELTA_VERSION}.jar" && \
    curl -s -L -o "delta-storage-${DELTA_VERSION}.jar" "https://repo1.maven.org/maven2/io/delta/delta-storage/${DELTA_VERSION}/delta-storage-${DELTA_VERSION}.jar"

# Download and install Iceberg JARs
RUN echo "Installing Iceberg JARs..." && \
    cd ${SPARK_JARS_DIR} && \
    curl -s -L -o "iceberg-spark-runtime-3.5_${SCALA_VERSION}-${ICEBERG_VERSION}.jar" "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_${SCALA_VERSION}/${ICEBERG_VERSION}/iceberg-spark-runtime-3.5_${SCALA_VERSION}-${ICEBERG_VERSION}.jar" && \
    curl -s -L -o "iceberg-aws-bundle-${ICEBERG_VERSION}.jar" "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-aws-bundle/${ICEBERG_VERSION}/iceberg-aws-bundle-${ICEBERG_VERSION}.jar"

# Download and install PostgreSQL driver
RUN echo "Installing PostgreSQL driver..." && \
    cd ${SPARK_JARS_DIR} && \
    curl -s -L -o "postgresql-${POSTGRES_VERSION}.jar" "https://repo1.maven.org/maven2/org/postgresql/postgresql/${POSTGRES_VERSION}/postgresql-${POSTGRES_VERSION}.jar"

# Download and install Hadoop AWS JAR
RUN echo "Installing Hadoop AWS JAR..." && \
    cd ${SPARK_JARS_DIR} && \
    curl -s -L -o "hadoop-aws-${HADOOP_AWS_VERSION}.jar" "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_AWS_VERSION}/hadoop-aws-${HADOOP_AWS_VERSION}.jar"

# Verify installation
RUN echo "Verifying installed extensions..." && \
    ls -la ${SPARK_JARS_DIR}/ | grep -E "(delta|iceberg|postgresql|hadoop-aws)" && \
    echo "✅ All extensions installed successfully!"

# Add labels for metadata
LABEL maintainer="gsingh" \
      description="Apache Kyuubi with Delta Lake and Iceberg extensions" \
      version="1.10.0" \
      kyuubi.version="1.10.0" \
      delta.version="${DELTA_VERSION}" \
      iceberg.version="${ICEBERG_VERSION}" \
      spark.version="3.5.2"

# Set working directory
WORKDIR /opt/kyuubi

# Default command (can be overridden)
CMD ["/opt/kyuubi/bin/kyuubi", "start"]