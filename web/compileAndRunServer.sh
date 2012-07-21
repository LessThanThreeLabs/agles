#!/bin/bash 
cd front
./compile.sh
cd ..

cd back
./compile.sh
./runServer.sh
cd ..