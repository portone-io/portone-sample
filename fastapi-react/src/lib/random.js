// 16자리 랜덤 아이디를 생성
export function randomId() {
  return Array.from(crypto.getRandomValues(new Uint32Array(2)))
    .map((word) => word.toString(16).padStart(8, "0"))
    .join("")
}
