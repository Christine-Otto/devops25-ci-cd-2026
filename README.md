## Lektion 3 – Automatiserade tester och CI (självstudier 6/11)

I denna övning utökades projektets automatiserade tester med ett nytt unit test för division med negativa tal. Testet ligger i `tests/test_service.py`:

```python
def test_divide_negative_number():
    assert divide(-10, 2) == -5
```

### Verifiering

- **Lokalt:** `python -m pytest -v` gav **6 passed, 1 warning**.
- **Kodkontroll:** `ruff check app tests` gav **All checks passed!**.
- **Kontrollerat fel:** Testets förväntade resultat ändrades till `-6`. Pytest visade **1 failed, 5 passed**, vilket bekräftade att testet upptäcker avvikelsen. Felet rättades sedan tillbaka till `-5`.
- **GitHub Actions:** Efter push av branchen `demo/dag3-tester` körde workflowen **CI Pipeline / Test and Lint** automatiskt. Samtliga **6 tester passerade**, inklusive `test_divide_negative_number`, och Ruff-steget blev godkänt.

### Git och CI

- Arbetsbranch: `demo/dag3-tester`
- Commit: `0a3fc38` – `test: add negative division test`
- Workflow: `.github/workflows/ci.yml`
- Körning: [GitHub Actions i min fork](https://github.com/Christine-Otto/devops25-ci-cd-2026/actions)

**Lärdom:** Ett lyckat byggsteg räcker inte för att visa att en applikation fungerar. Automatiska tester kontrollerar definierade beteenden, medan Ruff granskar kodkvalitet. En grön CI-körning betyder att kontrollerna passerade, inte att alla tänkbara fel är uteslutna. De obligatoriska kraven före merge behöver konfigureras separat med exempelvis rulesets.

> Observera: Det avsiktliga felet visades lokalt, inte som en röd GitHub Actions-körning i denna nya branch. En tidigare övning använde röd och grön CI. En `StarletteDeprecationWarning` förekom, men hindrade inte testerna.
>
> ## Lektion 4 – Docker och automatiserade byggen (2026-11-10)

### Syfte

Syftet med Lektion 4 var att förstå hur en applikation paketeras i en Dockerimage, hur containern körs och testas samt hur Dockerbygget kan automatiseras med GitHub Actions.

Arbetet genomfördes enligt lärarens studentguide för Dag 4.

### Demo 4A – Skapa Dockerfile

En ny branch skapades för lektionen:

`demo/dag4-docker`

En `Dockerfile` skapades i repositoryts rot.

Dockerfile använder Python 3.12, installerar projektets beroenden från `requirements.txt`, kopierar FastAPI-applikationen och startar Uvicorn på port 8000.

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Resultat:** Dockerfile skapades och kontrollerades enligt lärarens instruktioner.

### Demo 4B – Bygga Dockerimage lokalt

Docker Desktop användes för att bygga en Dockerimage från projektet.

Följande kommandon kördes:

```powershell
docker version
docker build -t devops25-cicd-demo:local .
docker image ls
```

**Resultat:** Dockerbygget genomfördes utan fel. Imagen `devops25-cicd-demo:local` skapades och verifierades i listan över lokala images.

### Demo 4C – Starta och testa Dockercontainer

Först kontrollerades att ingen annan Dockercontainer använde port 8000.

```powershell
docker ps
```

Därefter startades containern:

```powershell
docker run --rm -p 8000:8000 devops25-cicd-demo:local
```

FastAPI-applikationen startade korrekt med Uvicorn.

Följande API-endpoints testades i webbläsaren:

**Health check**

`http://127.0.0.1:8000/health`

Förväntat och verifierat svar:

```json
{"status":"ok"}
```

**Addition**

`http://127.0.0.1:8000/add?a=2&b=3`

Förväntat och verifierat svar:

```json
{"result":5.0}
```

Containern stoppades med `Ctrl+C`.

Därefter kördes:

```powershell
docker ps -a
docker image ls
```

**Resultat:** Båda API-testerna godkändes. Containern avslutades och togs bort med hjälp av `--rm`, medan Dockerimagen fanns kvar.

### Demo 4D – Automatisera Dockerbygget med GitHub Actions

Den befintliga workflow-filen `.github/workflows/ci.yml` utökades med ett separat jobb för Dockerbygget.

Det befintliga jobbet `test-and-lint`, som kör Pytest och Ruff, behölls.

Följande jobb lades till under `jobs:`:

```yaml
  docker-build:
    name: Build Docker Image
    needs: test-and-lint
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Build Docker image
        run: docker build -t devops25-cicd-demo:${{ github.sha }} .
```

`needs: test-and-lint` innebär att Dockerbygget endast körs om de automatiska testerna och Ruff-kontrollen har godkänts.

`${{ github.sha }}` används som image-tagg för att koppla Dockerbygget till en specifik Git-commit.

Ändringarna sparades i Git med:

- **Branch:** `demo/dag4-docker`
- **Commit:** `bf5a781`
- **Commitmeddelande:** `Demo 4D: add Docker build to CI`

Ändringarna pushades till GitHub.

### Verifiering i GitHub Actions

GitHub Actions-körning #9 genomfördes med status **Success**.

| Jobb | Resultat |
|---|---|
| Test and Lint | Godkänt |
| Build Docker Image | Godkänt |

Total körtid: 38 sekunder.

[Visa den godkända GitHub Actions-körningen](https://github.com/Christine-Otto/devops25-ci-cd-2026/actions/runs/42801471778)

Det automatiska Dockerbygget genomfördes efter att test- och lintjobbet hade godkänts.

### Slutsats

Under Lektion 4 skapades en fungerande Dockerimage för FastAPI-applikationen. Containern startades lokalt och båda API-endpoints verifierades.

GitHub Actions utökades därefter så att CI-pipelinen automatiskt bygger en Dockerimage efter godkända tester och kodkontroller.

Därmed har projektets CI-kedja utökats från automatiserad testning till att också omfatta ett automatiserat Dockerbygge.

**Avgränsning:** Dockerimagen byggdes men publicerades inte till något containerregister. Automatisk deployment och rollback ingick inte i de genomförda övningarna för Lektion 4.

**Status:** Samtliga praktiska moment 4A–4D är genomförda och verifierade.

## Lektion 5 – Continuous Delivery och deployment (12 november 2026)

### Syfte

Under Lektion 5 arbetade jag vidare med FastAPI-applikationen och Dockerimagen från Lektion 4. Syftet var att förstå hur en applikation kan driftsättas och verifieras automatiskt.

Vi arbetade med ett simulerat CD-workflow i GitHub Actions och genomförde även en lokal deployment med Docker och Bash-skript.

Det centrala flödet var:

**Build → Run → Verify → Cleanup**

### Demo 5A – Simulerat CD-workflow i GitHub Actions

Jag skapade filen `.github/workflows/cd-simulated.yml` på branchen `demo/dag5`.

Workflowet heter `CD - Simulated Deployment` och startar automatiskt när kod pushas till branchen. Det innehåller även `workflow_dispatch` för manuell start där GitHub tillåter detta.

Workflowet genomför följande steg:

1. Hämtar repositoryts kod med `actions/checkout@v6`.
2. Bygger Dockerimagen `devops25-app`.
3. Startar en container på port 8000.
4. Kontrollerar applikationens `/health`-endpoint.
5. Tar bort containern med hjälp av `if: always()`.

Verifieringen försöker ansluta till applikationen upp till tio gånger med två sekunders mellanrum.

Om applikationen inte svarar skrivs containerloggarna ut och jobbet avslutas med ett fel.

Detta är en simulerad deployment eftersom containern endast körs på GitHubs tillfälliga runner. Applikationen publiceras inte som en permanent tjänst i produktion.

Arbetet sparades i Git:

- Branch: `demo/dag5`
- Commit: `7b39eaa`
- Commitmeddelande: `Dag 5A: Skapa simulerat CD-workflow`

### Demo 5B – Granska och uppdatera GitHub Actions

Jag granskade CD-workflowets körning och kontrollerade att Dockerimagen byggdes, containern startades och applikationen svarade på `/health`.

Verifieringsloggen visade:

```text
Waiting for application...
{"status":"ok"}Deployment verified successfully
```

Jag kontrollerade också de GitHub Actions-versioner som användes i projektet.

I den befintliga `ci.yml` användes `actions/checkout@v4` på två ställen. Jag uppdaterade dessa till `actions/checkout@v6` enligt lärarens instruktioner.

Den nya CD-filen använde redan version 6.

Ändringen sparades med:

- Commit: `ad361fe`
- Commitmeddelande: `Dag 5B: Uppdatera checkout till v6`

Efter uppdateringen verifierades både CI Pipeline #12 och CD - Simulated Deployment #2 med status Success.

Under logggranskningen upptäckte jag också en kvarvarande varning om att `actions/setup-python@v5` använder en äldre Node.js-runtime. GitHub visade dessutom informationsmeddelanden om att `ubuntu-latest` migrerar till Ubuntu 26.

Vi noterade dessa meddelanden men gjorde inga ytterligare ändringar, eftersom de inte ingick i laborationens instruktioner.

Detta visade varför det är viktigt att granska loggar och Annotations även när en pipeline har grön status.

### Demo 5C – Lokal deployment med Bash-skript

Jag skapade mappen `scripts` i projektroten med två filer:

- `scripts/deploy_local.sh`
- `scripts/verify.sh`

`deploy_local.sh` bygger Dockerimagen, tar bort en eventuell tidigare övningscontainer med samma namn och startar applikationen.

`verify.sh` kontrollerar att applikationens `/health`-endpoint svarar korrekt.

Skripten kördes från projektroten med Git Bash:

```bash
bash scripts/deploy_local.sh
bash scripts/verify.sh
```

Det första försöket genomfördes via Windows/WSL:s Bash-miljö. Dockerbygget lyckades, men verifieringen misslyckades.

Jag undersökte därefter Dockercontainern, imagen och vilken Bash-miljö som användes.

När jag i stället körde skripten i Git Bash med Dockerkontexten `desktop-linux` lyckades både deployment och verifiering.

Resultatet blev:

```text
=== Deployment started ===
=== Verifying deployment ===
Waiting for application...
{"status":"ok"}
Deployment verified successfully
```

Detta visade att det är viktigt att kontrollera vilken terminalmiljö och Dockerkontext som används vid felsökning. Den exakta orsaken till det första misslyckandet fastställdes inte.

### Demo 5D – Verifiering av den körande containern

Efter den lokala deploymenten kontrollerade jag containern och applikationen med följande kommandon:

```bash
docker ps
docker logs devops25-app
curl -i http://127.0.0.1:8000/health
curl "http://127.0.0.1:8000/add?a=2&b=3"
```

`docker ps` visade att containern kördes.

`docker logs` bekräftade att Uvicorn hade startat och att applikationen var tillgänglig på port 8000.

Hälsokontrollen gav HTTP 200 och:

```json
{"status":"ok"}
```

Additionstestet gav:

```json
{"result":5.0}
```

När kontrollerna var klara stoppade och tog jag bort containern:

```bash
docker rm -f devops25-app
```

Därefter verifierade jag att containern var borttagen men att Dockerimagen `devops25-app:latest` fortfarande fanns kvar.

### Git och slutlig verifiering

De lokala Bash-skripten sparades och pushades till GitHub.

- Branch: `demo/dag5`
- Commit: `16122a9`
- Commitmeddelande: `Dag 5C: Lokal deployment och verifiering med skript`

Efter denna push kontrollerade jag GitHub Actions igen.

| Workflow | Körning | Resultat |
|---|---|---|
| CI Pipeline | #13 | Success |
| CD - Simulated Deployment | #3 | Success |

Båda körningarna gällde commit `16122a9`.

CI-pipelinen genomförde både tester och Dockerbygge. CD-workflowet genomförde den simulerade deploymenten.

### Slutsats och reflektion

Under Lektion 5 har jag fått en tydligare förståelse för skillnaden mellan Continuous Integration, Continuous Delivery och deployment.

I Lektion 4 byggde vi en Dockerimage automatiskt efter godkända tester. I Lektion 5 gick vi vidare genom att automatisera start, verifiering och cleanup av applikationen.

Jag har lärt mig att en lyckad Dockerbuild inte automatiskt betyder att applikationen fungerar. En container kan vara startad utan att tjänsten är redo att ta emot anrop.

Därför behöver vi kontrollera både containerstatus, loggar och applikationens faktiska svar.

Jag har också sett hur viktigt det är att granska varningar i GitHub Actions och att inte enbart förlita sig på grön status.

I denna laboration startar CI och CD oberoende av varandra vid push. Det innebär att CD inte väntar på att CI först ska bli godkänt. I en mer robust leveranskedja skulle beroenden och kvalitetskontroller behöva hanteras tydligare.

**Status:** Samtliga praktiska moment 5A–5D är genomförda och verifierade. Applikationen har körts och verifierats både i GitHub Actions och lokalt med Docker. Ingen permanent produktionsdeployment har genomförts.

## Lektion 6 – Continuous Delivery, rollback och hela ändringsresan (13 november 2026)

### Syfte

Under Lektion 6 arbetade jag vidare med FastAPI-applikationen och Dockerprojektet från tidigare lektioner.

Syftet var att förstå hur en applikation kan driftsättas, verifieras, versionshanteras och återställas om något går fel.

Jag arbetade även med hela CI/CD-processen, från kodändring och automatiska tester till Pull Request, merge och simulerad deployment i GitHub Actions.

De viktigaste momenten var:

- Felsökning av Dockercontainrar och portkonflikter.
- Versionshantering av Dockerimages.
- Rollback till en tidigare fungerande version.
- Utveckling och testning av en ny API-endpoint.
- Pull Request och merge mellan Git-branches.
- Automatisk CI och simulerad CD i GitHub Actions.
- Kontroll av applikationens version efter deployment.

### Demo 6A – Felsökning av portkonflikt

Jag började med att starta FastAPI-applikationen i Docker på port 8000.

```bash
docker run -d --name devops25-app -p 8000:8000 devops25-app:latest
```

Jag kontrollerade att containern kördes och att applikationens health-endpoint fungerade.

```bash
docker ps
curl http://localhost:8000/health
```

Applikationen svarade:

```json
{"status":"ok"}
```

Därefter försökte jag starta ytterligare en container, `devops25-fel`, med samma port 8000.

Detta misslyckades eftersom porten redan användes av den första containern.

Docker rapporterade:

```text
Bind for 0.0.0.0:8000 failed: port is already allocated
```

Jag undersökte problemet med `docker ps -a` och identifierade den befintliga portbindningen.

Jag löste problemet genom att ta bort den misslyckade containern och starta den nya containern på värdport 8001.

```bash
docker rm -f devops25-fel

docker run -d --name devops25-fel -p 8001:8000 devops25-app:latest
```

Jag verifierade sedan båda applikationerna:

```bash
curl http://localhost:8000/health
curl http://localhost:8001/health
```

Båda returnerade `{"status":"ok"}`.

Efter testet tog jag bort den extra containern.

**Lärdom:** Två containrar kan använda samma interna port, men de kan inte samtidigt använda samma värdport och nätverksadress.

### Demo 6B – Versionshantering och rollback

I nästa moment arbetade jag med två versioner av samma Dockerimage.

Jag skapade först en versionstagg för den fungerande imagen:

```bash
docker tag devops25-app:latest devops25-app:v1
```

Därefter byggde jag en ny version:

```bash
docker build -t devops25-app:v2 .
```

Jag kontrollerade att båda versionerna fanns tillgängliga med:

```bash
docker images devops25-app
```

Jag stoppade och tog bort den tidigare containern och startade version 2.

```bash
docker rm -f devops25-app
docker run -d --name devops25-app -p 8000:8000 devops25-app:v2
```

Jag verifierade deploymenten med:

```bash
bash scripts/verify.sh
```

Skriptet kontrollerade applikationens `/health`-endpoint och bekräftade att applikationen fungerade.

#### Rollback till version 1

För att simulera en återställning skapade jag skriptet:

`scripts/rollback_local.sh`

Skriptet genomför följande:

1. Kontrollerar att Dockerimagen `devops25-app:v1` finns.
2. Stoppar och tar bort den befintliga containern.
3. Startar en ny container från version 1.
4. Kör `scripts/verify.sh`.
5. Visar vilken Dockerimage containern använder.

Jag körde skriptet med:

```bash
bash scripts/rollback_local.sh
```

Terminalen bekräftade:

```text
Deployment verified successfully
devops25-app:v1
=== Rollback completed ===
```

**Resultat:** Rollback till version 1 lyckades och applikationen fungerade efter återställningen.

**Lärdom:** Rollback gör det möjligt att återgå till en tidigare fungerande applikationsversion om en ny deployment orsakar problem.

### Demo 6C – Hela ändringsresan genom CI/CD

I detta moment arbetade jag med en separat branch:

`demo/dag6-full-pipeline`

Jag använde branchen för att utveckla en ny funktion utan att direkt ändra målbranchen `demo/dag6`.

#### Steg 1 – Ny version-endpoint

Jag uppdaterade `app/main.py` med en endpoint som returnerar applikationens version och miljö.

```python
@app.get("/version")
def version():
    return {
        "version": "1.1",
        "environment": "demo",
    }
```

Endpointen gör det möjligt att kontrollera vilken applikationsversion som faktiskt körs efter en deployment.

#### Steg 2 – Automatiskt test

Jag lade till ett test i `tests/test_api.py`.

```python
def test_version():
    response = client.get("/version")
    assert response.status_code == 200
    assert response.json() == {
        "version": "1.1",
        "environment": "demo",
    }
```

Jag körde tester och kodkontroll lokalt:

```bash
python -m pytest -v
python -m ruff check .
```

Resultatet blev:

```text
7 passed, 1 warning
All checks passed!
```

Varningen gällde en föråldrad användning av `httpx` i testmiljön och hindrade inte testerna från att godkännas.

#### Steg 3 – Commit och push

Jag sparade kodändringarna med Git.

Commit:

`da7a73f` – Dag 6C: Lägg till version-endpoint och test

Ändringarna pushades till GitHub och startade CI Pipeline #17.

GitHub Actions genomförde automatiskt:

- Test and Lint.
- Build Docker Image.

Båda jobben godkändes.

#### Steg 4 – Pull Request

Jag skapade Pull Request #2 med titeln:

**Dag 6C: Lägg till version-endpoint och test**

Pull Requesten jämförde:

- Base: `demo/dag6`
- Compare: `demo/dag6-full-pipeline`

Jag dokumenterade ändringarnas syfte, genomförande, verifiering och avgränsning.

GitHub visade att båda CI-kontrollerna var godkända och att inga merge-konflikter fanns.

Pull Requesten mergades sedan till `demo/dag6`.

Pull Request:

https://github.com/Christine-Otto/devops25-ci-cd-2026/pull/2

#### Steg 5 – CI efter merge

Efter merge synkroniserade jag min lokala branch.

```bash
git switch demo/dag6
git pull --ff-only origin demo/dag6
git status
```

Merge-commit:

`527d1a1`

GitHub Actions startade CI Pipeline #18 för målbranchen.

Resultat:

| Jobb | Status |
|---|---|
| Test and Lint | Success |
| Build Docker Image | Success |
| Hela CI Pipeline #18 | Success |

Total körtid: 30 sekunder.

Det bekräftade att den sammanfogade koden passerade CI-kontrollerna.

CI-körning:

https://github.com/Christine-Otto/devops25-ci-cd-2026/actions/runs/43416826183

### Simulerad CD med versionskontroll

För att komplettera CI-processen uppdaterade jag GitHub Actions-workflowet:

`.github/workflows/cd-simulated.yml`

Jag behöll triggern för `demo/dag5` och lade även till `demo/dag6`.

```yaml
on:
  push:
    branches:
      - demo/dag5
      - demo/dag6
  workflow_dispatch:
```

Därefter lade jag till ett nytt steg, `Verify application version`, som anropar `/version` och kontrollerar att applikationen returnerar rätt värden.

Kontrollen verifierar:

- Version: `1.1`
- Environment: `demo`

Om något värde är fel misslyckas versionskontrollen.

Det befintliga cleanup-steget med `if: always()` behölls för att stoppa och ta bort testcontainern även om ett tidigare steg misslyckas.

#### Kontroll av YAML-filen

Jag installerade PyYAML i min lokala virtuella Pythonmiljö och använde biblioteket för att kontrollera att workflowfilen kunde läsas.

Resultat:

```text
YAML syntax OK
```

Jag körde även:

```bash
git diff --check
git status
```

Kontrollerna visade inga formateringsfel och endast den avsedda workflowfilen var ändrad.

#### Commit och push av CD-workflow

Jag skapade följande commit:

`2a38dd1` – Dag 6C: Lägg till versionskontroll i CD

När ändringen pushades till `demo/dag6` startade både CI och CD automatiskt.

Resultatet blev:

| Workflow | Körning | Status |
|---|---|---|
| CI Pipeline | #19 | Success |
| CD - Simulated Deployment | #5 | Success |

### Slutlig verifiering av deployment

I GitHub Actions granskade jag loggarna för `CD - Simulated Deployment #5`.

Workflowet genomförde:

1. Checkout repository.
2. Build Docker image.
3. Start application.
4. Verify deployment.
5. Verify application version.
6. Stop application.

Samtliga steg godkändes.

Versionskontrollen visade:

```text
Deployed version: {'version': '1.1', 'environment': 'demo'}
Version verification successful
```

Detta bekräftade att applikationen startades och att rätt version kördes.

Även cleanup-steget `Stop application` slutfördes.

Total körtid för CD-körningen var cirka 30 sekunder.

Godkänd CD-körning:

https://github.com/Christine-Otto/devops25-ci-cd-2026/actions/runs/43418338644

### Viktiga lärdomar från Lektion 6

- En portkonflikt uppstår när flera containrar försöker använda samma värdport.
- Dockerimages kan versionshanteras med taggar som `v1` och `v2`.
- Rollback gör det möjligt att återställa en tidigare fungerande version.
- En health check verifierar att applikationen svarar, men inte nödvändigtvis att rätt version körs.
- En versionsendpoint gör det möjligt att verifiera vilken version som faktiskt är driftsatt.
- Pull Requests gör att kodändringar kan granskas och testas före merge.
- CI kontrollerar automatiskt kodkvalitet, tester och byggprocessen.
- CD kan automatisera bygg, start, verifiering och cleanup.
- En grön GitHub Actions-körning ska alltid kompletteras med granskning av loggar.
- En lyckad simulerad deployment är inte samma sak som en permanent produktionsdeployment.

### Slutsats

Under Lektion 6 genomförde jag felsökning av Dockercontainrar, versionshantering, rollback och en komplett kodändringsprocess genom Git och GitHub Actions.

Jag skapade en version-endpoint, lade till automatiska tester, arbetade med en separat Git-branch, skapade en Pull Request och mergade ändringen efter godkända CI-kontroller.

Jag uppdaterade även CD-workflowet för att kontrollera applikationens version efter deployment.

Den slutliga körningen verifierade att version `1.1` kördes i miljön `demo` och att testcontainern togs bort efteråt.

**Avgränsning:** Laborationen använde lokala Dockercontainrar och simulerad deployment i GitHub Actions. Ingen permanent produktionsdeployment eller automatisk produktionsrollback genomfördes.

**Status:** Samtliga praktiska moment i Demo 6A, 6B och 6C är genomförda och verifierade.
