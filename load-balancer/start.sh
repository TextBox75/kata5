#!/usr/bin/env bash
set -e
docker compose up -d --wait
java -jar ../even-service/target/even-service-1.0.jar even1 localhost 8081 http://localhost:8500 even_service_1 &
java -jar ../even-service/target/even-service-1.0.jar even2 localhost 8082 http://localhost:8500 even_service_1 &
java -jar ../even-service/target/even-service-1.0.jar even3 localhost 8083 http://localhost:8500 even_service_2 &
java -jar ../even-service/target/even-service-1.0.jar even4 localhost 8084 http://localhost:8500 even_service_2 &
wait
