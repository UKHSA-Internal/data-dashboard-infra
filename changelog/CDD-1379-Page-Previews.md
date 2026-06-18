# CDD-1379 - Page Previews

**Date:** 2026-02-27

**Ticket:** https://ukhsa.atlassian.net/browse/CDD-1379?search_id=055fe61d-bee9-48d9-80bc-ffb0f1c26b76&referrer=quick-find

**Authors:** Jean-Pierre Fouche

**Impact:** Affects all pages - broad testing required

**Testing:** Comprehensive unit tests supplied.  UAT needed.


## Summary

Allow editors of headless composite pages to click a **Preview** button that immediately redirects them to the external frontend application, rather than opening the built-in Wagtail iframe preview.  Preview URLs include a short-lived signed token so the frontend can safely fetch draft content from the CMS.

Additionally, allow users to select to set "Embargo Date" by selecting a virtual date in order to preview otherwise embargoed data.

## Deployment

### Environment Variables

The following environment variables apply: 

```bash
PAGE_PREVIEWS_ENABLED: [true | false] # enables page preview for this server instance.  If disabled, an error with an appropriate message will be thrown from the API

PAGE_PREVIEWS_TOKEN_TTL: 30s # Sets the expiry window for a token generated from the cms-admin service.  Set this to a higher value if pages are taking longer than 30s to render.  Lower values are better for security, as the window of opportunity is narrowed.

PAGE_PREVIEWS_TOKEN_SALT: # <random secret>.  Set in AWS Secrets Manager, this adds an element of randomness into the token.  A random password is set upon initial deployment.
```

### Caching
Two CloudFront behaviours are in place: 

* `/preview/*`: for routes that render draft pages
* `/nocache/*`: for routes that render published pages

### Security

* **Authenticated gate:** page previews can be rendered only through the authenticated CMS application.  The CMS will generate a secure HMAC token which guarantees that the payload has not been tampered with.

* **Token Expiry:**  Page previews works with a presigned url, generated securely by the CMS application.  The presigned url works with an HMAC token with a short expiry window (set to the expected max length of a transaction, this being the round-trip from CMS to Front-End and back to the CMS drafts api).

## Component Architecture

The following components are important from an operational point of view:

* Browser (with caching)
* CloudFront (behaviours)
* FrontEnd (env vars to enable or disable page previews)
* CMS-Admin 
  * env vars 
    * to enable or disable page previews
    * to set the token TTL (increase this if page load times are too slow)

### Deployment

* Delete all secrets before deployment:

```bash
uhd secrets delete-all-secrets <env id> 
```

Note: the above command has been modified as part of this feature to make it dynamic.  Previously, it depended upon hard-coded secret names.

Note: env id can be obtained by running: 

```bash
uhd terraform get-dev-workspace-name
```



