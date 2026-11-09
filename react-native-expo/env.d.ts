/// <reference types="expo/types" />

declare namespace NodeJS {
  interface ProcessEnv {
    /** 상점 ID (.env.local) */
    EXPO_PUBLIC_STORE_ID?: string
    /** 채널 키 (.env.local) */
    EXPO_PUBLIC_CHANNEL_KEY?: string
  }
}
