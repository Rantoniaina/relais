# syntax=docker/dockerfile:1

# ---------- Étape 1 : build + découpage en couches ----------
FROM eclipse-temurin:25-jdk AS builder
WORKDIR /builder

# 1) Uniquement ce qui décrit les dépendances : cette couche ne bouge
#    que si le pom.xml change.
COPY mvnw pom.xml ./
COPY .mvn .mvn
RUN chmod +x mvnw
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -q dependency:go-offline

# 2) Le code source, puis le jar (les tests tourneront en CI, avec une vraie base)
COPY src src
RUN --mount=type=cache,target=/root/.m2 ./mvnw -B -q package -DskipTests \
 && cp target/*.jar application.jar

# 3) Découpage du jar en couches (dependencies, spring-boot-loader,
#    snapshot-dependencies, application)
RUN java -Djarmode=tools -jar application.jar extract --layers --destination extracted

# ---------- Étape 2 : image d'exécution ----------
FROM eclipse-temurin:25-jre
WORKDIR /app

# Utilisateur système sans shell de login, sans droits root
RUN groupadd --system relais && useradd --system --gid relais --no-create-home relais

# De la couche la plus stable à la plus volatile : un changement de code
# ne réécrit que la dernière couche (quelques Ko au lieu de ~30 Mo).
COPY --from=builder /builder/extracted/dependencies/ ./
COPY --from=builder /builder/extracted/spring-boot-loader/ ./
COPY --from=builder /builder/extracted/snapshot-dependencies/ ./
COPY --from=builder /builder/extracted/application/ ./

USER relais
EXPOSE 8080
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"
ENTRYPOINT ["java", "-jar", "application.jar"]