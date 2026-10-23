# 2. Image du gateway : Dockerfile multi-stage
Contexte : le gateway doit tourner dans Compose, en CI puis sur Kubernetes.
Décision : Dockerfile multi-stage (JDK pour builder, JRE pour exécuter), jar découpé en couches Spring Boot, utilisateur non-root.
Alternative écartée pour l'instant : Buildpacks (`spring-boot:build-image`), plus lent et moins lisible pour apprendre.
Conséquences : rebuild rapide grâce au cache, image plus petite ; à durcir en P6 (distroless, cache AOT Java 25).