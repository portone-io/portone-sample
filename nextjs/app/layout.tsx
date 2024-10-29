import type { Metadata } from "next"
import "./globals.css"

export const metadata: Metadata = {
  title: "포트원 결제연동 샘플",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="ko">
      <body>
        <div id="root">{children}</div>
      </body>
    </html>
  )
}
