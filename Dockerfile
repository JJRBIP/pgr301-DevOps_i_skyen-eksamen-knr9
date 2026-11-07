# Stage 1: bygger JAR-filen
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn -B dependency:go-offline
COPY src ./src
RUN mvn -B package -DskipTests

# Stage 2: kjører bare JRE, uten Maven og kildekode
FROM eclipse-temurin:21-jre
WORKDIR /app
RUN useradd -r -m appuser
COPY --from=build /app/target/exam-app-1.0.0.jar app.jar
USER appuser
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]