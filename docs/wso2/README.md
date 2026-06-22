# WSO2 Integration Guide

This document describes how to integrate the driver fatigue detection backend with WSO2 API Manager and WSO2 Identity Server.

## API Manager Gateway

1. Register a new API in WSO2 API Manager.
2. Configure the backend endpoint as:
   - `http://<backend-host>:8000`
3. Define the resources:
   - `POST /auth/token`
   - `GET /auth/users/me`
   - `POST /predict/image`
   - `POST /trips/record`
   - `GET /trips/history`
4. Apply security policies on the API:
   - OAuth2 token validation
   - Rate limiting / throttling
   - CORS enforcement if needed

## Identity Server

Use WSO2 Identity Server to issue JWT access tokens and manage user authentication.

1. Create a Service Provider for the backend API.
2. Configure OAuth2/OpenID Connect.
3. Provide the token endpoint to the mobile app and API Manager.
4. Map the WSO2-issued JWT to backend security expectations.

## Backend Auth

The FastAPI backend already exposes:

- `POST /auth/token` — accepts username and password, returns JWT
- `GET /auth/users/me` — returns current user profile

### Recommended approach

- Keep the backend behind WSO2 API Gateway.
- Use WSO2 Identity Server for user management and MFA.
- Use the gateway to validate tokens before forwarding requests to the backend.

## Mobile App Deployment

For mobile apps, use the API Gateway URL as the backend base URL.

- Flutter app: connect to `http://<gateway-host>:<gateway-port>`
- React Native app: connect to the same API Gateway base URL

## Notes

- Replace the placeholder `SECRET_KEY` in `backend/.env.example` with a secure random value before production.
- Use HTTPS for all mobile and gateway traffic in production.
