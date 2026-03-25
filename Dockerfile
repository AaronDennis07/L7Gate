# Stage 1: Build React UI
FROM node:24-alpine AS client-builder
WORKDIR /app/client
COPY client/package*.json ./
RUN npm ci
COPY client/ ./
RUN npm run build

# Stage 2: Build Spring Boot and Inject React UI
FROM maven:3.9.6-eclipse-temurin-21 AS server-builder
WORKDIR /app/server
COPY server/pom.xml ./
RUN mvn dependency:resolve dependency:resolve-plugins  
COPY server/src ./src
COPY --from=client-builder /app/client/dist ./src/main/resources/static
RUN mvn clean package -DskipTests

# Stage 3: Final Minimal Image
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app
RUN groupadd -r spring && useradd -r -g spring spring
USER spring:spring
COPY --from=server-builder /app/server/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]