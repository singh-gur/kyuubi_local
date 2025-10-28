#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Spark Environment Configuration

# Java options
export SPARK_EXECUTOR_MEMORY=${SPARK_EXECUTOR_MEMORY:-4g}
export SPARK_EXECUTOR_CORES=${SPARK_EXECUTOR_CORES:-2}
export SPARK_DRIVER_MEMORY=${SPARK_DRIVER_MEMORY:-2g}
export SPARK_DRIVER_CORES=${SPARK_DRIVER_CORES:-1}

# Python options (if using PySpark)
export PYSPARK_PYTHON=python3
export PYSPARK_DRIVER_PYTHON=python3

# Hadoop configuration
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop

# AWS credentials (for S3/MinIO)
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-minioadmin}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-minioadmin}
export AWS_REGION=${AWS_REGION:-us-east-1}

# Additional classpath for Delta and Iceberg
export SPARK_DIST_CLASSPATH=$(hadoop classpath):/opt/kyuubi/externals/engines/spark/jars/*