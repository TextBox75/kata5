#!/usr/bin/env bash
set -e
docker compose up -d --wait
java -jar ../powers-service/target/powers-service-1.0.jar pow1 localhost 8081 http://localhost:8500 powers_service_1 &
java -jar ../powers-service/target/powers-service-1.0.jar pow2 localhost 8082 http://localhost:8500 powers_service_1 &
java -jar ../powers-service/target/powers-service-1.0.jar pow3 localhost 8083 http://localhost:8500 powers_service_2 &
java -jar ../powers-service/target/powers-service-1.0.jar pow4 localhost 8084 http://localhost:8500 powers_service_2 &
wait
