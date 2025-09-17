# Handover Documentation

## Login process

The system uses AWS Cognito to federate authentication with the upstream UKHSA Azure AD.
The upstream UKHSA Azure AD is the only identity provider which the non-public dashboard *knows* about.

In summary:
1. User navigates to the non-public app.
2. User hits login.
3. Request is made to AWS Cognito.
4. Traffic is redirected to the upstream UKHSA Azure AD login flow.
5. Azure AD provides federated login. 
6. User enters the login details for their organisation user account.
7. Login flow is completed, tokens passed back into the non-public dashboard.
8. Auth tokens are sent via API gateway to the backend to filter for datasets which the user is allowed to see.

## Non-public outstanding items

The non-public dashboard is in a somewhat incomplete state.
Most of the requisite infrastructure pieces are in place.

### API Gateway

The API gateway is **not** currently hooked up to the frontend and the public API, this will need to be resolved
so that the API gateway can parse, handle and process auth tokens on behalf of the frontend and public API.

### Azure AD user groups administration

Note that you will also need to create a separate Azure AD app to pair up with each environment so that
we can control user access on a more granular level. 
Unfortunately this can only be granted by the UKHSA IDAM team.
At the time of writing (Sep 2025) this was still out of the hands of the engineering team.


### Automating creation of user groups in Azure AD <-> Django admin 

There is also piece missing around managing user groups in the UKHSA Azure AD and the backend django admin panel.
Currently, the process is very manually-intensive. 
It will require personnel to:
- Login to Azure AD.
- Assign a user to a new user group.
- Make note of the user group guid.
- Go to the django admin panel
- Create new RBAC permissions and assign the requisite datasets to that user group guid.

We were aware of this limitation and this was included in the roadmap after the COVER work in Sep 2025.
Unfortunately we did not get round to this piece of work so it is left outstanding.

### Frontend

There are a number of bugs currently outstanding in the frontend including:
- Once signed in, the token is not invalidated upon sign-out, 
which means when they sign in again they are redirected back into the app without being made to sign-in again.
- The frontend is not currently including the auth token / user group ID in the requests it makes to the backend.
As such, the backend will only return data which has been labelled as public

For more information on the outstanding frontend issues 
see the [frontend docs](https://github.com/UKHSA-Internal/data-dashboard-frontend/tree/main/docs/auth)
