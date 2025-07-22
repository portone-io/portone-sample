# Ruby on Rails + HTML

Ruby on Rails 백엔드에 단일 HTML 파일로 구성한 포트원 결제 샘플 프로젝트입니다.

## 사전 준비

샘플 프로젝트는 Ruby 3.3 이상과 Rails 8.0 이상을 기준으로 작성되었습니다.

```bash
$ ruby --version
ruby 3.3.0
$ rails --version
Rails 8.0.2
```

## 프로젝트 실행

프로젝트를 실행하기 전, 환경변수 설정이 필요합니다. Rails credentials를 편집하여 필요한 내용을 작성해 주세요.

```bash
$ rails credentials:edit
```

다음 내용을 추가합니다:

```yaml
portone:
  api_secret: 00000000000000000000000000000000000000000000000000000000000000000000000000000000
  webhook_secret: whsec_00000000000000000000000000000000000000000000

# Secret key base는 이미 자동으로 생성되어 있습니다
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
$ bundle install # 의존성 다운로드
$ rails server   # 프로젝트 실행
```