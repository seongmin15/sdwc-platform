# sdwc-platform

SDwC 서비스들의 통합 배포 및 인프라 관리.

## 디렉토리 레이아웃

```
SDwC_projects/
├── SDwC/                  ← git repo (documentation generator)
├── intake-assistant/      ← git repo (AI conversation → YAML)
└── sdwc-platform/         ← git repo (이 레포: 통합 배포)
    ├── manifests/         # 서비스별 k8s 배포 매니페스트
    │   ├── sdwc/          # SDwC 서비스 (sdwc-api, sdwc-web)
    │   └── intake/        # intake-assistant 서비스 (api, web)
    ├── scripts/           # 배포/운영 스크립트
    ├── ingress/           # 통합 Ingress 매니페스트
    ├── argocd/            # ArgoCD Application 정의
    └── README.md
```

## 사전 준비

- Docker Desktop (WSL2 backend)
- [k3d](https://k3d.io/#installation)
- kubectl
- [Helm](https://helm.sh/docs/intro/install/) — Traefik Ingress Controller 설치에 필요
- hosts 파일에 추가:
  ```
  127.0.0.1 sdwc.local intake.local
  ```

## 시크릿 설정

배포 전 `.env.secrets` 파일을 프로젝트 루트에 생성하세요 (`.gitignore`에 포함됨):

```bash
cp .env.secrets.example .env.secrets
# .env.secrets 파일에서 실제 API 키로 변경
```

```
ANTHROPIC_API_KEY=sk-ant-your-key-here
```

`deploy-all.sh`가 자동으로 이 파일을 읽어 K8s secret을 생성합니다. 또는 환경 변수로 직접 전달할 수도 있습니다:

```bash
ANTHROPIC_API_KEY=sk-ant-... ./scripts/deploy-all.sh
```

## 사용법

```bash
# 전체 배포 (클러스터 생성 + 빌드 + 배포)
./scripts/deploy-all.sh

# 상태 확인
./scripts/status.sh

# 특정 서비스만 리빌드
./scripts/rebuild.sh sdwc-api    # sdwc-api만
./scripts/rebuild.sh sdwc        # sdwc-api + sdwc-web
./scripts/rebuild.sh intake      # intake-api + intake-web
./scripts/rebuild.sh all         # 전체

# 로그 확인
./scripts/logs.sh sdwc-api       # 개별 서비스
./scripts/logs.sh intake         # intake 전체
./scripts/logs.sh                # 전체

# ArgoCD 관리
./scripts/argocd.sh status    # 상태 확인
./scripts/argocd.sh restart   # 재시작
./scripts/argocd.sh password  # admin 비밀번호
./scripts/argocd.sh ui        # 웹 UI (localhost:8080)
./scripts/argocd.sh sync      # 전체 앱 동기화
./scripts/argocd.sh sync sdwc # 특정 앱 동기화

# 클러스터 삭제
./scripts/clean.sh
```

## 접속

| 서비스 | URL |
|--------|-----|
| SDwC Web | https://sdwc.local:8443 |
| SDwC API | https://sdwc.local:8443/api/v1/template |
| intake-assistant Web | https://intake.local:8443 |
| intake-assistant API | https://intake.local:8443/api/v1/health |

## 서비스 간 통신

intake-assistant → SDwC API는 클러스터 내부 DNS로 통신:

```
http://sdwc-api.sdwc.svc.cluster.local:8000  (cluster-internal, TLS terminates at ingress)
```

## ArgoCD (GitOps)

`deploy-all.sh`가 ArgoCD를 자동으로 설치하고, `argocd/` 디렉토리의 Application 정의를 적용합니다.

### 구성

| Application | Git Path | Namespace |
|-------------|----------|-----------|
| `sdwc` | `manifests/sdwc` | sdwc |
| `intake-assistant` | `manifests/intake` | intake |

두 앱 모두 **자동 동기화**가 설정되어 있습니다:
- **Automated Sync** — `main` 브랜치에 push하면 자동 배포
- **Self-Heal** — 수동 변경 시 Git 상태로 자동 복원
- **Prune** — Git에서 삭제된 리소스는 클러스터에서도 삭제

### 상태 확인

```bash
# ArgoCD 앱 상태
kubectl get applications -n argocd

# ArgoCD 파드 상태
kubectl get pods -n argocd
```

### 웹 UI 접속

```bash
# 포트 포워딩
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

브라우저에서 `https://localhost:8080` 접속.

```bash
# 초기 admin 비밀번호 확인
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

- **Username:** `admin`
- **Password:** 위 명령어 출력값

### ArgoCD CLI (선택)

```bash
# CLI 설치 후 로그인
argocd login localhost:8080 --username admin --password $(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d) --insecure

# 앱 목록
argocd app list

# 수동 동기화
argocd app sync sdwc
argocd app sync intake-assistant
```
