#!/usr/bin/env bash
set -e
docker compose up -d --wait
java -jar ../odd-service/target/odd-service-1.0.jar odd1 localhost 8081 http://localhost:8500 odd_service_1 &
java -jar ../odd-service/target/odd-service-1.0.jar odd2 localhost 8082 http://localhost:8500 odd_service_1 &
java -jar ../odd-service/target/odd-service-1.0.jar odd3 localhost 8083 http://localhost:8500 odd_service_2 &
java -jar ../odd-service/target/odd-service-1.0.jar odd4 localhost 8084 http://localhost:8500 odd_service_2 &
wait
