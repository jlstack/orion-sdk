#!/bin/sh

ROOT_DIR=`dirname $0`

$ROOT_DIR/ProtoGen/ProtoGen.sh $ROOT_DIR/Communications/OrionPublicProtocol.xml $ROOT_DIR/Communications -no-doxygen
