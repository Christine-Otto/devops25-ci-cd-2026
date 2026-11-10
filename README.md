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
