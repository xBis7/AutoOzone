#!/usr/bin/env bash
cd /hadoop/app/ozone/
 export CLASSPATH=`bin/ozone classpath hadoop-ozone-tools`:.

javac SimpleTest.java
