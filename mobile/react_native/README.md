# React Native App Scaffold

This folder contains a starter React Native mobile application.

## Getting started

1. Install dependencies:

```bash
cd mobile/react_native
npm install
```

2. Run the app:

```bash
npm start
```

3. Launch on Android or iOS:

```bash
npm run android
npm run ios
```

## Backend connection

The example app checks the backend health endpoint at `http://127.0.0.1:8000/health`.
Update `mobile/react_native/src/services/apiService.js` to point to your deployed backend or API gateway.

## Notes

- Use the WSO2 gateway base URL for production mobile deployments.
- Add screens for login, camera capture, and trip history next.
