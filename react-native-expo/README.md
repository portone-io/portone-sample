# React Native + Expo

React Native와 Expo를 사용한 샘플 프로젝트입니다.

## 사전 준비

샘플 프로젝트는 yarn 4.5.1을 기준으로 작성되었습니다.

```bash
$ yarn --version
4.5.1
```

## 프로젝트 실행

프로젝트를 실행하기 전 설정이 필요합니다. `App.tsx` 파일을 수정해 주세요.

```jsx
<Payment
  request={{
    storeId: "store-00000000-0000-0000-0000-000000000000", // 상점 ID
    channelKey: "channel-key-00000000-0000-0000-0000-000000000000", // 채널키
  }}
/>
```

이후 프로젝트를 실행하면 됩니다.

```bash
$ yarn # 의존성 다운로드
$ yarn android # 안드로이드 에뮬레이터에서 실행
$ yarn ios # iOS 에뮬레이터에서 실행
```
