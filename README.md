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
