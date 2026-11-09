# React Native + Expo

React Native와 Expo를 사용한 샘플 프로젝트입니다.

- Expo SDK 58 / React Native 0.88 / React 19.3
- [`@portone/react-native-sdk`](https://github.com/portone-io/react-native-sdk)

## 사전 준비

- Node.js 22.23.4+, 24.22.1+, 26.12.1+
- pnpm 12 (`package.json`의 `packageManager` 참고)

## 프로젝트 설정

`.env` 템플릿을 `.env.local`로 복사한 뒤 상점 ID와 채널 키를 입력합니다.

```bash
EXPO_PUBLIC_STORE_ID=store-00000000-0000-0000-0000-000000000000 # storeId
EXPO_PUBLIC_CHANNEL_KEY=channel-key-00000000-0000-0000-0000-000000000000 # channelKey
```

## 프로젝트 실행

```bash
$ pnpm install   # 의존성 다운로드
$ pnpm android   # 안드로이드 에뮬레이터에서 실행
$ pnpm ios       # iOS 시뮬레이터에서 실행
```
