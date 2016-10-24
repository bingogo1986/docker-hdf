#!/bin/sh

set -e

do_site2site_configure() {
  sed -i "s/nifi\.remote\.input\.host=.*/nifi.remote.input.host=${HOSTNAME}/g" ${HDF_HOME}/conf/nifi.properties
  sed -i "s/nifi\.remote\.input\.socket\.port=.*/nifi.remote.input.socket.port=10101/g" ${HDF_HOME}/conf/nifi.properties
  sed -i "s/nifi\.remote\.input\.secure=true/nifi.remote.input.secure=false/g" ${HDF_HOME}/conf/nifi.properties
}

do_cluster_node_configure() {
# NiFi properties
  sed -i "s/nifi\.web\.http\.host=.*/nifi.web.http.host=${HOSTNAME}/g" ${HDF_HOME}/conf/nifi.properties
  sed -i "s/nifi\.cluster\.protocol\.is\.secure=true/nifi.cluster.protocol.is.secure=false/g" ${HDF_HOME}/conf/nifi.properties
  sed -i "s/nifi\.cluster\.is\.node=false/nifi.cluster.is.node=true/g" ${HDF_HOME}/conf/nifi.properties
  sed -i "s/nifi\.cluster\.node\.address=.*/nifi.cluster.node.address=${HOSTNAME}/g" ${HDF_HOME}/conf/nifi.properties
  sed -i "s/nifi\.cluster\.node\.protocol\.port=.*/nifi.cluster.node.protocol.port=10201/g" ${HDF_HOME}/conf/nifi.properties
  sed -i "s/nifi\.zookeeper\.connect\.string=.*/nifi.zookeeper.connect.string=${ZK_NODES_LIST}/g" ${HDF_HOME}/conf/nifi.properties
  if [ "$USE_EMBEDDED_ZK" == "true" ]; then
    sed -i "s/nifi\.state\.management\.embedded\.zookeeper\.start=false/nifi.state.management.embedded.zookeeper.start=true/g" ${HDF_HOME}/conf/nifi.properties
  else 
    sed -i "s/nifi\.state\.management\.embedded\.zookeeper\.start=true/nifi.state.management.embedded.zookeeper.start=false/g" ${HDF_HOME}/conf/nifi.properties
  fi

# State management
  sed -i "s/<property name=\"Connect String\">.*</<property name=\"Connect String\">${ZK_NODES_LIST}</g" ${HDF_HOME}/conf/state-management.xml

# MyId zookeeper
  if [ "$USE_EMBEDDED_ZK" == "true" ]; then
    mkdir -p ${HDF_HOME}/state/zookeeper
    echo ${MYID} > ${HDF_HOME}/state/zookeeper/myid
  fi

# Zookeeper properties
#  sed -i "/^server\.1=/q" ${HDF_HOME}/conf/zookeeper.properties; sed -i "s/^server\.1=.*/server.1=/g" ${HDF_HOME}/conf/zookeeper.properties
}

do_site2site_configure

if [ "$INSTANCE_ROLE" == "cluster-node" ]; then
  do_cluster_node_configure
fi

tail -F ${HDF_HOME}/logs/nifi-app.log &
${HDF_HOME}/bin/nifi.sh run
