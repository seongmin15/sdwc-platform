# sdwc-platform

SDwC 서비스들의 통합 배포 및 인프라 관리.

## 디렉토리 레이아웃

```
SDwC_projects/
├── SDwC/                  ← git repo (documentation generator)
├── intake_assistant/      ← git repo (AI conversation → YAML)
└── sdwc-platform/         ← git repo (이 레포: 통합 배포)
    ├── scripts/           # 배포/운영 스크립트
    ├── ingress/           # 통합 Ingress 매니페스트
    ├── argocd/            # ArgoCD Application 정의
    └── README.md
```

## 사전 준비

- Docker Desktop (WSL2 backend)
- [k3d](https://k3d.io/#installation)
- kubectl
- hosts 파일에 추가:
  ```
  127.0.0.1 sdwc.local intake.local
  ```

## 사용법

```bash
# 전체 배포 (클러스터 생성 + 빌드 + 배포)
./scripts/deploy-all.sh

# 상태 확인
./scripts/status.sh

# 특정 서비스만 리빌드
./scripts/rebuild.sh sdwc-api
./scripts/rebuild.sh intake
./scripts/rebuild.sh all

# 로그 확인
./scripts/logs.sh intake-api
./scripts/logs.sh sdwc
./scripts/logs.sh            # 전체

# 클러스터 삭제
./scripts/clean.sh
```

## 접속

| 서비스 | URL |
|--------|-----|
| SDwC Web | http://sdwc.local:8080 |
| SDwC API | http://sdwc.local:8080/api/v1/template |
| intake-assistant Web | http://intake.local:8080 |
| intake-assistant API | http://intake.local:8080/api/v1/health |

## 서비스 간 통신

intake-assistant → SDwC API는 클러스터 내부 DNS로 통신:

```
http://sdwc-api.sdwc.svc.cluster.local:8000
```
