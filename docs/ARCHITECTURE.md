# Architecture Overview

## Layers

1. Mobile App
   - React Native front-end for drivers and passengers
   - captures camera images and sends them to the backend
2. WSO2 API Manager
   - API gateway for rate limiting, security, analytics, and versioning
3. FastAPI Backend
   - executes ML inference
   - records trip history
   - returns alerts and prediction results
4. WSO2 Identity Server
   - handles OAuth2 authentication and JWT issuance
5. Database
   - stores trip events, user profiles, and safety logs

## Data flow

1. Mobile app authenticates to WSO2 Identity Server
2. App requests access token
3. App sends image to WSO2 API Manager
4. WSO2 forwards request to FastAPI backend
5. FastAPI runs prediction and returns JSON
6. Mobile app displays alerts and saves trip history
