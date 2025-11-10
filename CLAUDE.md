# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**portone-sample** is a collection of sample integration projects demonstrating how to integrate PortOne payment system across multiple platforms and technology stacks. This repository serves as:

- **Reference implementations** for developers integrating PortOne
- **Quick-start templates** for different tech stacks
- **Testing ground** for SDK updates and new features
- **Documentation by example** showing real-world usage patterns

## Repository Structure

```
portone-sample/
├── Web Backend + Frontend Samples
│   ├── express-html/          # Express.js + vanilla HTML
│   ├── express-react/         # Express.js + React + Vite
│   ├── nextjs/                # Next.js full-stack
│   ├── fastapi-html/          # FastAPI + vanilla HTML
│   ├── fastapi-react/         # FastAPI + React
│   ├── flask-html/            # Flask + vanilla HTML
│   ├── flask-react/           # Flask + React
│   ├── spring-html/           # Spring Boot + vanilla HTML (Kotlin)
│   ├── spring-java-html/      # Spring Boot + vanilla HTML (Java)
│   └── spring-react/          # Spring Boot + React (Kotlin)
├── Mobile Samples
│   ├── ios/                   # iOS SwiftUI (V2 SDK)
│   ├── ios-uikit/             # iOS UIKit (V2 SDK)
│   ├── react-native/          # React Native (V2 SDK)
│   ├── react-native-expo/     # React Native + Expo (V2 SDK)
│   └── flutter/               # Flutter (V2 SDK)
└── Configuration
    ├── .devcontainer/         # Dev container configurations
    ├── README.md              # Repository overview
    ├── LICENSE-APACHE         # Apache 2.0 license
    ├── LICENSE-MIT            # MIT license
    └── COPYRIGHT              # License information
```

## Technology Stack by Sample

### Node.js/JavaScript Samples
- **express-html**, **express-react**: Node.js 20+, Express.js, Vite
- **nextjs**: Node.js 20+, Next.js, React
- **Dependencies**: `@portone/browser-sdk`, `@portone/server-sdk`

### Python Samples
- **fastapi-html**, **fastapi-react**: Python 3.8+, FastAPI, Uvicorn
- **flask-html**, **flask-react**: Python 3.8+, Flask
- **Dependencies**: `portone-server-sdk` (Python package)

### JVM Samples
- **spring-html**, **spring-react**: Kotlin, Spring Boot, Gradle
- **spring-java-html**: Java, Spring Boot, Gradle
- **Dependencies**: `io.portone:server-sdk` (Maven Central)

### Mobile Samples
- **ios**, **ios-uikit**: Swift 6.0+, iOS 14.0+, PortOneSDK (SPM)
- **react-native**: React Native 0.76+, `@portone/react-native-sdk`
- **react-native-expo**: Expo SDK 51+, `@portone/react-native-sdk`
- **flutter**: Dart, Flutter, `portone_flutter` (pub.dev)

## Common Development Patterns

### Environment Variables

All samples require environment variables for API credentials. Each sample contains:
- `.env` - Template file with placeholder values
- `.env.local` - Local configuration (gitignored, you create this)

**Required Variables**:
```bash
# Store ID (V2 API)
VITE_STORE_ID=store-00000000-0000-0000-0000-000000000000

# Channel Key (PG connection)
VITE_CHANNEL_KEY=channel-key-00000000-0000-0000-0000-000000000000

# V2 API Secret (server-side only, never expose to client)
V2_API_SECRET=00000000000000000000000000000000000000000000000000000000000000000000000000000000

# V2 Webhook Secret (optional, for webhook signature verification)
V2_WEBHOOK_SECRET=whsec_00000000000000000000000000000000000000000000
```

**CRITICAL SECURITY RULES**:
- ✗ **NEVER** commit `.env.local` files
- ✗ **NEVER** expose `V2_API_SECRET` to client-side code
- ✗ **NEVER** hardcode production credentials
- ✓ **ALWAYS** use environment variables for secrets
- ✓ **ALWAYS** verify webhooks using `V2_WEBHOOK_SECRET`

### Payment Flow Architecture

All samples follow the same flow:

```
┌─────────────────────────────────────────────────────────────┐
│ Client-Side (Browser/Mobile App)                            │
│ 1. User clicks "Pay" button                                 │
│ 2. SDK loads payment UI (PortOne.requestPayment)           │
│ 3. User completes payment on PG provider page               │
│ 4. Redirected back to success/failure page                  │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ↓ (Webhook notification)
┌─────────────────────────────────────────────────────────────┐
│ Server-Side (Backend)                                       │
│ 1. Receive webhook from PortOne                             │
│ 2. Verify webhook signature                                 │
│ 3. Fetch payment details via Server SDK                     │
│ 4. Update order status in database                          │
│ 5. Send response to PortOne (200 OK)                        │
└─────────────────────────────────────────────────────────────┘
```

**Why Webhook is Critical**: 
- Client redirect can fail (browser closed, network error)
- Webhook is the **source of truth** for payment status
- Always verify payment server-side before fulfilling orders

### Sample Code Structure

Each sample typically contains:

**Backend** (`server/` or root):
- Payment webhook endpoint
- Payment verification logic
- Server SDK usage examples

**Frontend** (`src/` or `public/`):
- Payment button implementation
- Browser SDK integration
- Success/failure page handling

**Configuration**:
- `.env` template
- `README.md` with setup instructions
- Package manager files (`package.json`, `pubspec.yaml`, `build.gradle.kts`)

## Running Samples

### Node.js Samples (Express, Next.js)

```bash
cd express-react  # or any Node.js sample

# 1. Copy environment template
cp .env .env.local

# 2. Edit .env.local with your credentials
# (Get credentials from PortOne Console)

# 3. Install dependencies
npm install  # or pnpm install

# 4. Run development server
npm run dev

# Server runs on http://localhost:5173 (or check console output)
```

### Python Samples (FastAPI, Flask)

```bash
cd fastapi-html  # or any Python sample

# 1. Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Copy environment template
cp .env .env.local

# 4. Edit .env.local with your credentials

# 5. Run development server
# FastAPI:
uvicorn main:app --reload

# Flask:
python app.py
```

### Spring Boot Samples (Kotlin/Java)

```bash
cd spring-react  # or any Spring Boot sample

# 1. Copy environment template
cp .env .env.local

# 2. Edit .env.local with your credentials

# 3. Run with Gradle
./gradlew bootRun

# Server runs on http://localhost:8080
```

### Mobile Samples

#### iOS (Swift)

```bash
cd ios  # or ios-uikit

# 1. Open Xcode project
open PortOneSample.xcodeproj

# 2. Edit Config.swift with your credentials

# 3. Run on simulator or device (Cmd+R)
```

#### React Native

```bash
cd react-native  # or react-native-expo

# 1. Install dependencies
npm install

# 2. Copy environment template
cp .env .env.local

# 3. Edit .env.local with your credentials

# 4. Run on iOS
npm run ios

# 5. Run on Android
npm run android
```

#### Flutter

```bash
cd flutter

# 1. Get dependencies
flutter pub get

# 2. Edit lib/config.dart with your credentials

# 3. Run on device/simulator
flutter run
```

## Development Guidelines

### Code Style

**JavaScript/TypeScript**:
- Use Prettier for formatting (`.prettierrc` provided)
- Use `const`/`let` (never `var`)
- Prefer async/await over promises
- ESLint configurations per project

**Python**:
- Follow PEP 8 style guide
- Use type hints for function signatures
- Black formatter (if configured)

**Kotlin/Java**:
- Follow Kotlin/Java conventions
- Use ktlint/kotlinter for Kotlin
- Google Java Style for Java

**Swift**:
- Follow Swift API Design Guidelines
- Use SwiftLint (if configured)

### Adding New Samples

When creating a new sample project:

1. **Choose minimal dependencies** - Samples should be easy to understand
2. **Follow existing structure** - Match patterns from similar samples
3. **Include complete README.md** with:
   - Prerequisites (language version, tools)
   - Setup instructions (step-by-step)
   - Environment variable documentation
   - Run/build commands
4. **Provide `.env` template** with placeholder values
5. **Add to root README.md** with link to new sample
6. **Test end-to-end** before committing:
   - Payment flow works
   - Webhook handling works
   - Error cases handled gracefully

### Testing Payment Flows

**Test Mode Credentials**: Get from PortOne Console (Test Mode)

**Test Cards**: Use test card numbers provided by PG providers
- Check PortOne docs for test card numbers
- Different cards trigger different scenarios (success, failure, 3DS)

**Webhook Testing**:
- Use ngrok or similar tool to expose local server
- Configure webhook URL in PortOne Console
- Verify webhook signature validation works

### Security Checklist

Before committing code:

- [ ] No hardcoded API secrets
- [ ] `.env.local` is in `.gitignore`
- [ ] Server-side validation of payment amounts
- [ ] Webhook signature verification implemented
- [ ] HTTPS required for production (documented)
- [ ] CORS properly configured (not `*` in production)
- [ ] No sensitive data logged

## Common Issues & Solutions

### Issue: "Invalid API Secret"
**Cause**: Wrong API secret or not passing in Authorization header
**Solution**: 
- Verify `V2_API_SECRET` in `.env.local`
- Check server code passes secret to SDK correctly
- Ensure secret is not exposed to client

### Issue: "Channel not found"
**Cause**: Wrong `VITE_CHANNEL_KEY` or channel not configured
**Solution**:
- Verify channel key in PortOne Console
- Ensure channel is enabled for test mode
- Check channel supports the payment method being used

### Issue: "Webhook not received"
**Cause**: Local server not reachable from PortOne servers
**Solution**:
- Use ngrok: `ngrok http 3000`
- Configure webhook URL in PortOne Console with ngrok URL
- Check server is running and endpoint is correct

### Issue: "CORS error" in browser
**Cause**: Backend not allowing frontend origin
**Solution**:
- Configure CORS middleware in backend
- Allow origin from frontend (e.g., `http://localhost:5173`)
- Don't use `*` in production (security risk)

### Issue: Mobile SDK payment not working
**Cause**: WebView configuration or deep link handling
**Solution**:
- Ensure `react-native-webview` is installed and linked
- Configure URL schemes in iOS/Android manifests
- Check deep link handling in app code

## SDK Version Compatibility

This repository uses **V2 SDKs** for all platforms:

| Platform | SDK Package | Version | Docs |
|----------|-------------|---------|------|
| Browser | `@portone/browser-sdk` | 0.0.x | [Link](https://developers.portone.io/docs/sdk/browser-sdk) |
| Server (Node.js) | `@portone/server-sdk` | 0.x | [Link](https://developers.portone.io/docs/sdk/server-sdk/node) |
| Server (Python) | `portone-server-sdk` | 0.x | [Link](https://developers.portone.io/docs/sdk/server-sdk/python) |
| Server (JVM) | `io.portone:server-sdk` | 0.x | [Link](https://developers.portone.io/docs/sdk/server-sdk/jvm) |
| iOS | `PortOneSDK` (SPM) | 0.x | [Link](https://developers.portone.io/docs/sdk/ios-sdk) |
| Android | `io.portone:android-sdk` | 0.x | [Link](https://developers.portone.io/docs/sdk/android-sdk) |
| React Native | `@portone/react-native-sdk` | 0.x | [Link](https://developers.portone.io/docs/sdk/react-native-sdk) |
| Flutter | `portone_flutter` | 0.x | [Link](https://developers.portone.io/docs/sdk/flutter-sdk) |

**Note**: All SDKs are in active development (0.x versions). Check changelogs before updating.

## Contributing

When contributing to samples:

1. **Test thoroughly** - Payment flows are critical, bugs affect real money
2. **Keep it simple** - Samples should be educational, not production-ready frameworks
3. **Document everything** - Assume the reader is new to PortOne
4. **Follow existing patterns** - Consistency across samples helps learning
5. **Update root README.md** - Add links to new samples

## License

This repository is dual-licensed under:
- **Apache License 2.0** ([LICENSE-APACHE](LICENSE-APACHE))
- **MIT License** ([LICENSE-MIT](LICENSE-MIT))

You may use this code under either license.

## Related Resources

- **PortOne Docs**: https://developers.portone.io
- **PortOne Console**: https://console.portone.io
- **SDK Repositories**: 
  - Browser SDK: `portone-io/browser-sdk`
  - Server SDK: `portone-io/server-sdk`
  - Mobile SDKs: `portone-io/ios-sdk`, `portone-io/android-sdk`, `portone-io/react-native-sdk`
- **Help Center**: https://help.portone.io
- **Support**: support@portone.io
