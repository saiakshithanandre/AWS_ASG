# 1️⃣ Build stage
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Copy Maven wrapper and config
COPY mvnw .
COPY .mvn .mvn

# Copy project sources
COPY pom.xml .
COPY src ./src

# Make wrapper executable and build the jar
RUN chmod +x mvnw
RUN ./mvnw -B -q package -DskipTests

# 2️⃣ Runtime stage
FROM eclipse-temurin:21-jre
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
