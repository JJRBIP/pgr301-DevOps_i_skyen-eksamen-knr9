
# PGR301 Eksamen 2026 – Wishifai

Kandidatnummer: 9
Repo: https://github.com/JJRBIP/pgr301-DevOps_i_skyen-eksamen-knr9

## Oppgave 1A – Dockerfile

Kjør lokalt:

    docker build -t wishifai .
    docker run -p 9999:8080 -e AWS_REGION=eu-west-1 \
      -e AWS_ACCESS_KEY_ID=... -e AWS_SECRET_ACCESS_KEY=... wishifai

Appen svarer på http://localhost:9999.

Jeg bruker en multi-stage Dockerfile med to steg. I det første steget bygges JAR-filen 
med Maven (maven:3.9-eclipse-temurin-21). I det andre kopieres bare den ferdige JAR-filen inn i et lite 
runtime-image (eclipse-temurin:21-jre). Dermed havner ikke Maven, kildekoden og byggeverktøyene i det endelige imaget, 
som blir mindre og får færre ting som kan ha sikkerhetshull. Jeg kopierer også pom.xml og laster ned avhengigheter før 
jeg kopierer src, slik at Docker kan gjenbruke cachen når bare koden endres.

Containeren kjører som en egen bruker (appuser) og ikke som root. Hvis noen utnytter en svakhet i appen, 
får angriperen da færre rettigheter i containeren, og det er vanskeligere å gjøre skade på verten. 
Det er også god praksis å gi en prosess kun de rettighetene den trenger.

Imaget kjøres lokalt med docker run -p 9999:8080, slik at appen er tilgjengelig på http://localhost:9999.

## Oppgave 1B – GitHub Actions og ECR

- ECR-repo: wishifai-9
- Grønn kjøring: https://github.com/JJRBIP/pgr301-DevOps_i_skyen-eksamen-knr9/actions/runs/42501678287
- Tagging: Jeg tagger imaget med commit-SHA `${{ github.sha }}` i tillegg til latest. SHA-taggen gjør at jeg alltid kan 
           se hvilken commit et image kommer fra, så hvis noe feiler i en kjørende container, kan jeg finne nøyaktig 
           hvilken kode som ligger i den. Hver commit får sin egen SHA, så taggen blir i praksis ikke overskrevet av 
           senere bygg. `latest` flytter seg for hver push og sier ingenting om hvilken versjon som kjører, 
           så den bruker jeg bare som en praktisk snarvei.

## Oppgave 2A – Terraform

All Terraform-kode ligger i `infra/` (`provider.tf`, `variables.tf`, `main.tf`, `outputs.tf`).

**Ressurser:**
- `aws_ecs_express_gateway_service` (`wishifai-9`): kjører imaget fra ECR på port 8080, med health check på `/actuator/health`.
- `aws_s3_bucket` (`wishifai-uploads-9`): lagrer opplastede bilder.
- `aws_iam_role` og `aws_iam_role_policy` (`wishifai-task-role-9`): task role med tilgang til S3, Rekognition, Bedrock og CloudWatch.

**Valg:**
- Region, kandidatnummer og image-tag er variabler.
- Jeg bruker de eksisterende rollene (execution og infrastructure) og lager bare task role selv.
- `S3_BUCKET` og `AWS_REGION` settes automatisk fra Terraform.

**Offentlig URL:** https://wi-9b78dad250744149b7a4e51a96cf8056.ecs.eu-west-1.on.aws

## Oppgave 2B – Backend

Terraform-state lagres i S3 i stedet for lokalt:
    - **Bucket:** `pgr301-terraform-state` (region `eu-west-1`)
    - **Key:** `wishifai/9/terraform.tfstate`

Nøkkelen inneholder kandidatnummeret, slik at hver kandidat får sin egen state-fil i den delte bucketen og ingen 
overskriver andres infrastruktur.

**Hvorfor remote state:** 
    - State-filen er Terraforms oversikt over hva som er opprettet. Hvis den bare ligger på min maskin, 
      kan ikke andre eller en GitHub Actions-pipeline se den, og Terraform ville forsøkt å opprette alt på nytt. 
      Med felles state kan flere jobbe mot samme infrastruktur, og pipelinen i 2C kan kjøre `apply` mot de 
      samme ressursene. Kandidatnummeret er hardkodet fordi backend-blokken ikke støtter variabler.

## Oppgave 2C – GitHub Actions-job for Terraform

Workflowen `.github/workflows/build.yml` har to jobs:
1. `build` bygger Docker-imaget og pusher det til ECR med både commit-SHA og `latest` som tagger.
2. `terraform` har `needs: build` og kjører bare på `main`. Den sjekker formatet (`terraform fmt -check`), 
    kjører `init`, `validate` og `apply -auto-approve` mot `infra/`, med `image_tag` satt til commit-SHA-en.

AWS-credentials hentes fra GitHub Secrets (`AWS_ACCESS_KEY_ID` og `AWS_SECRET_ACCESS_KEY`), 
og alt annet står som `env` i workflowen.

**Hvorfor Terraform kjører etter build:**
    - Terraform-jobben bruker commit-SHA-en som image-tag, og det imaget finnes først i ECR når `build`-jobben er ferdig. 
Hvis Terraform kjørte før eller parallelt, kunne ECS Express blitt bedt om å starte et image som ennå ikke var pushet, 
og deployen ville feilet eller startet en gammel versjon. Derfor har `terraform` `needs: build`. Det betyr også at hvis 
bygget feiler, kjører ikke Terraform i det hele tatt, og en ødelagt versjon rulles aldri ut.

**Grønn kjøring:**: https://github.com/JJRBIP/pgr301-DevOps_i_skyen-eksamen-knr9/actions/runs/42620820542

## Oppgave 3A – Metrikker

(Hvilke metrikker du lagde og hvorfor.)

## Oppgave 3B – Dashboard og alarm

(Hva dashboardet viser, alarmens terskel, og skjermbilde.)

## Oppgave 4 – Drøfting

(300–500 ord, skrevet av deg.)