# React Native

React Native를 사용한 샘플 프로젝트입니다.

## 사전 준비

샘플 프로젝트는 yarn 4.5.1을 기준으로 작성되었습니다.

```bash
$ yarn --version
4.5.1
```

## 프로젝트 실행

프로젝트를 실행하기 전 먼저 의존성 패키지를 설치합니다.

```bash
yarn
```

이후 `App.tsx` 파일을 수정해 주세요.

```jsx
<Payment
  request={{
    storeId: "store-00000000-0000-0000-0000-000000000000", // 상점 ID
    channelKey: "channel-key-00000000-0000-0000-0000-000000000000", // 채널키
  }}
/>
```

### iOS 추가 설정

1. ios 디렉토리에서 아래 명령어를 입력해 주세요.

```bash
pod install
```

1. Xcode에서 ios/PortoneSample.xcodeproj 파일을 여신 뒤, Signing & Capabilities 설정에서 Team을 본인의 개발자 계정으로 설정해 주세요.

## 실행

```bash
$ yarn android # 안드로이드 에뮬레이터에서 실행
$ yarn ios # iOS 에뮬레이터에서 실행
```
