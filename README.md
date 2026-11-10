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
