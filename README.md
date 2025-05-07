# NetBoxCI

Repozytorium do zarządzania infrastrukturą dla GitHub Actions self-hosted runnerów w Azure Kubernetes Service.

## Struktura projektu

```
NetBoxCI/
├── .github/
│   └── workflows/
│       ├── create-infra.yml      # Workflow tworzący infrastrukturę AKS
│       ├── update-infra.yml      # Workflow aktualizujący klaster AKS (skalowanie, upgrade K8s)
│       ├── add-runner.yml        # Workflow dodający nowe runnery GH
│       ├── delete-runner.yml     # Workflow usuwający runnery GH
│       └── destroy-infra.yml     # Workflow usuwający całą infrastrukturę
│
├── k8s/
│   └── runner-deployment.yaml    # Przykładowy manifest Kubernetes dla runnerów
│
└── scripts/
    ├── create-aks.sh             # Skrypt tworzenia klastra AKS
    ├── deploy-runners.sh         # Skrypt wdrażania runnerów GitHub
    └── update-node-size.sh       # Skrypt aktualizacji rozmiaru nodów
```

## Wymagania

- Subskrypcja Azure
- Uprawnienia do tworzenia zasobów w Azure
- Token dostępu do GitHub z uprawnieniami do zarządzania repozytoriami i runnerami

## Konfiguracja

1. Dodaj następujące sekrety do repozytorium:
   - `AZURE_CREDENTIALS` - poświadczenia Azure Service Principal
   - `GH_PERSONAL_TOKEN` - token GitHub z odpowiednimi uprawnieniami

2. Uruchom workflow "Create Infrastructure" aby stworzyć klaster AKS
3. Po utworzeniu klastra, uruchom workflow "Add Runner" aby wdrożyć self-hosted runnery

## Użycie workflowów

### Tworzenie infrastruktury
Uruchom workflow "Create Infrastructure" z GUI GitHub Actions podając:
- Nazwę resource group
- Nazwę klastra AKS
- Region Azure
- Wersję Kubernetes
- Liczbę i rozmiar nodów

### Dodawanie runnerów
Uruchom workflow "Add Runner" podając:
- Nazwę resurce group i klastra
- Prefiks nazwy runnera
- Liczbę runnerów do wdrożenia
- Etykiety runnerów (oddzielone przecinkami)

### Aktualizacja infrastruktury
Uruchom workflow "Update Infrastructure" aby:
- Zaktualizować wersję Kubernetes
- Zmienić liczbę nodów
- Zmienić rozmiar maszyn wirtualnych

### Usuwanie runnerów
Uruchom workflow "Delete Runner" podając:
- Nazwę resurce group i klastra
- Dokładną nazwę runnera do usunięcia

### Usuwanie infrastruktury
Uruchom workflow "Destroy Infrastructure" podając:
- Nazwę resource group
- Potwierdzenie "DESTROY" w celu weryfikacji zamiaru usunięcia zasobów
