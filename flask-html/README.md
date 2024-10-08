# Flask + HTML

Flask 백엔드에 단일 HTML 파일로 구성한 포트원 결제 샘플 프로젝트입니다.

## 사전 준비

샘플 프로젝트는 Python 3.9 이상을 기준으로 작성되었습니다.

```bash
$ python --version
Python 3.9.19
```

서버의 경우 uv를 사용하여 작성되었으나 `pyproject.toml`을 지원하는 다른 도구를 쓰셔도 무방합니다.

## 프로젝트 실행

프로젝트를 실행하기 전, 환경변수 설정이 필요합니다. `.env` 파일에 아래와 같이 필요한 내용을 작성해 주세요.

```bash
# V2 API 시크릿
V2_API_SECRET=00000000000000000000000000000000000000000000000000000000000000000000000000000000
# V2 웹훅 시크릿 (선택)
V2_WEBHOOK_SECRET=whsec_00000000000000000000000000000000000000000000
```

`public/index.html` 파일에서 다음 내용을 찾아 변경해 주세요.

```js
const checkout = new Checkout(
  "store-00000000-0000-0000-0000-000000000000", // 상점 ID
  "channel-key-00000000-0000-0000-0000-000000000000", // 채널 키
)
```

이후 의존성을 다운로드하고 프로젝트를 실행하면 됩니다.

```bash
$ uv sync # 의존성 다운로드
$ uv run flask run # 프로젝트 실행
```
