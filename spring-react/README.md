# Spring Boot + React

Spring Boot 백엔드에 React 프론트엔드로 구성한 포트원 결제 샘플 프로젝트입니다.

## 사전 준비

샘플 프로젝트는 Node.js v20과 Java 21 기준으로 작성되었습니다.

```bash
$ node --version
v20.16.0
$ java -version
openjdk version "21.0.2" 2024-07-16
```

## 프로젝트 실행

프로젝트를 실행하기 전, 설정이 필요합니다. `app/src/main/resources/application.properties` 파일에 필요한 내용을 작성해 주세요.

```bash
# V2 API 시크릿
portone.secret.api=00000000000000000000000000000000000000000000000000000000000000000000000000000000
# V2 웹훅 시크릿
portone.secret.webhook=whsec_00000000000000000000000000000000000000000000
```

`.env` 파일을 `.env.local` 파일로 복사하고 필요한 내용을 작성해 주세요.

```bash
# 상점 ID
VITE_STORE_ID=store-00000000-0000-0000-0000-000000000000
# 채널 키
VITE_CHANNEL_KEY=channel-key-00000000-0000-0000-0000-000000000000
```

이후 프로젝트를 실행하면 됩니다.

```bash
$ pnpm dev
```
