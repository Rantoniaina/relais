# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Mode de travail : projet d'apprentissage

Ce projet a un but pédagogique. Sauf demande explicite de coder (« fais-le », « applique », « implémente-le »…), Claude ne modifie pas les fichiers du projet. Il répond par un guide d'implémentation :

- les étapes à suivre, dans l'ordre, avec le code ou la configuration à écrire ;
- pour chaque étape, ce qu'elle fait et pourquoi elle est nécessaire ;
- comment vérifier que l'étape fonctionne.

Lire les fichiers et lancer des commandes en lecture seule pour diagnostiquer reste autorisé. Quand l'utilisateur dit avoir modifié un fichier, relire ce fichier et signaler précisément ce qui manque ou ce qui ne va pas, sans le corriger à sa place.

## Vue d'ensemble

Relais est un monorepo (voir `docs/adr/0001-monorepo.md`) : services dans `services/`, console dans `console/` et libs multi-langages dans `packages/` à terme, avec un seul `compose.yaml` à la racine pour l'infra locale. Aujourd'hui seul `services/gateway` existe. Les ADR sont dans `docs/adr/` et rédigées en français.

## Infra locale (racine du dépôt)

```bash
docker compose up -d            # postgres:18 (5432) + ollama/ollama (11434)
docker compose down -v          # supprime aussi les volumes (données Postgres et modèles Ollama)
docker compose exec ollama ollama pull <modèle>
```

- Postgres 18 : le volume est monté sur `/var/lib/postgresql` (et non `/data`), car depuis la v18 `PGDATA` vaut `/var/lib/postgresql/18/docker`.
- Le mot de passe vient de `POSTGRES_PASSWORD` (`.env` à la racine, ignoré par git ; défaut `relais`). Il n'est appliqué qu'à l'initialisation du volume. S'il change ensuite, l'authentification échoue tant que le volume n'est pas recréé.

## Gateway (`services/gateway`)

Spring Boot 4.1 (Web MVC, JDBC, Flyway, Actuator), Java 25, Maven wrapper. Toutes les commandes se lancent depuis `services/gateway`.

- Java 25 est fourni par mise (`mise.toml`). Le JDK par défaut de la machine est le 21. Si `./mvnw -v` n'affiche pas Java 25, mise n'est pas actif dans le shell.

```bash
./mvnw spring-boot:run
./mvnw test
./mvnw test -Dtest=RelaisApplicationTests              # une classe
./mvnw test -Dtest=RelaisApplicationTests#contextLoads  # une méthode
./mvnw package
```

- Les tests `@SpringBootTest` démarrent tout le contexte, Flyway compris. Ils exigent donc un Postgres joignable (`docker compose up -d postgres`). Testcontainers n'est pas encore en place.
- Configuration dans `src/main/resources/application.yaml`, surchargée par des variables d'environnement : `DB_HOST`, `DB_PORT`, `DB_USER`, `POSTGRES_PASSWORD`. Spring ne lit pas `.env` : il faut l'exporter dans le shell ou dans la configuration de lancement de l'IDE.
- Actuator expose `health` et `info`, avec `show-details: always` sur `/actuator/health`.

### Base de données et Flyway

- Toutes les tables vivent dans le schéma `relais`. Flyway le crée et y place `flyway_schema_history` (`spring.flyway.schemas` / `default-schema`). Les migrations n'écrivent donc pas de préfixe `relais.`.
- Les requêtes de l'application ne fixent pas de schéma. Elles s'appuient sur le `search_path` par défaut de Postgres (`"$user", public`), qui résout vers `relais` parce que l'utilisateur s'appelle `relais`. Changer d'utilisateur DB casserait cette résolution.
- Migrations : `src/main/resources/db/migration/V<n>__<description>.sql`, avec **deux** underscores. Avec un seul, Flyway ignore le fichier sans erreur. Ne jamais modifier une migration déjà appliquée (le checksum est vérifié au démarrage) : ajouter une nouvelle version à la place.
- `provider` (V1) : `kind` est limité par une contrainte `CHECK` à `ollama | openai | anthropic`. Pour ajouter un type, il faut une migration qui modifie cette contrainte. La ligne seed `ollama-local` pointe sur `http://localhost:11434`, ce qui suppose que le gateway tourne sur l'hôte et non dans compose (là il faudrait `http://ollama:11434`).
