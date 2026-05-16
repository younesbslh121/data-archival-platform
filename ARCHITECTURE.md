# 🏗️ Architecture du Projet : Intelligent Data Archiving Platform

Cette plateforme utilise une architecture Serverless et des services managés AWS pour automatiser l'archivage des données froides, garantissant ainsi la conformité et la réduction des coûts de stockage.

```mermaid
graph LR
    subgraph "Application Active"
        API[("fa:fa-server Spring Boot API\n(:8081)")]
        RDS[("fa:fa-database Amazon RDS\n(PostgreSQL 15)\nHot Data")]
        API <-->|Read/Write| RDS
    end

    subgraph "Processus d'Archivage (Serverless)"
        Cron(("fa:fa-clock Amazon EventBridge\n(Cron 2h00 UTC)"))
        Lambda["fa:fa-code AWS Lambda\n(Python 3.12)\nArchiver"]
        Cron -->|Trigger quotidien| Lambda
        Lambda -->|1. SELECT old data\n2. DELETE from DB| RDS
    end

    subgraph "Amazon S3 (Cold Storage & Lifecycle)"
        S3Std["S3 Standard\n(Accès fréquent)"]
        S3IT["S3 Intelligent-Tiering\n(Accès irrégulier)"]
        S3Glacier["S3 Glacier\n(Archives)"]
        S3Deep["S3 Glacier Deep Archive\n(Long terme)"]
        
        Lambda -->|3. Upload JSON| S3Std
        S3Std -.->|"Lifecycle Policy\n(+30 jours)"| S3IT
        S3IT -.->|"Lifecycle Policy\n(+90 jours)"| S3Glacier
        S3Glacier -.->|"Lifecycle Policy\n(+365 jours)"| S3Deep
    end

    %% Styles
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:black;
    classDef app fill:#6DB33F,stroke:#232F3E,stroke-width:2px,color:white;
    classDef db fill:#336791,stroke:#232F3E,stroke-width:2px,color:white;
    classDef storage fill:#527FFF,stroke:#232F3E,stroke-width:2px,color:white;

    class Lambda,Cron aws;
    class API app;
    class RDS db;
    class S3Std,S3IT,S3Glacier,S3Deep storage;
```

## Flux de données

1. **Production** : L'API Spring Boot insère et consulte en continu les données chaudes (Hot Data) dans la base de données PostgreSQL (Amazon RDS).
2. **Déclencheur** : Tous les jours à 2h00 du matin, Amazon EventBridge déclenche la fonction AWS Lambda de manière asynchrone.
3. **Extraction** : La Lambda exécute une requête SQL pour récupérer les anciennes données (ex: Logs de plus de 30 jours, Factures payées) et les supprime de la base RDS pour libérer de l'espace.
4. **Stockage Initial** : La Lambda formate ces données en JSON et les téléverse dans le bucket S3 (S3 Standard).
5. **Cycle de Vie (Cost Optimization)** : S3 applique automatiquement ses politiques de cycle de vie (*Lifecycle Policies*) :
   - Après 30 jours : Migration vers **Intelligent-Tiering**
   - Après 90 jours : Migration vers **Glacier Flexible Retrieval** (Archives)
   - Après 365 jours : Migration vers **Glacier Deep Archive** (Conservation à très long terme, coût minimum)
