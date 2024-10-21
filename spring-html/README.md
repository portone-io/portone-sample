# Spring Boot + HTML

Spring Boot 백엔드에 단일 HTML 파일로 구성한 포트원 결제 샘플 프로젝트입니다.

## 사전 준비

샘플 프로젝트는 Java 21를 기준으로 작성되었습니다.

```bash
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

`app/src/main/resources/public/index.html` 파일에서 다음 내용을 찾아 변경해 주세요.

```js
const checkout = new Checkout(
  "store-00000000-0000-0000-0000-000000000000", // 상점 ID
  "channel-key-00000000-0000-0000-0000-000000000000", // 채널 키
)
```

이후 프로젝트를 실행하면 됩니다.

```bash
$ ./gradlew bootRun
```
