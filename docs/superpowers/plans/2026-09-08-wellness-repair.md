# Wellness Repair Implementation Plan

> Execution: subagent-driven-development for the backend; main agent owns HarmonyOS integration and verification. User approved the design on 2026-09-08.

Goal: Deliver the approved model, location, calendar, navigation, seasonal background, points and reminder changes.

Architecture: One Spring Boot endpoint and explicitly selected model provider. Device coordinates and reverse geocoding supply real location; local calendar and images work offline. Points and fulfillment are transactional server state; reminders use the OS scheduler.

Tech stack: ArkTS / HarmonyOS API 22, Java 17 / Spring Boot / MySQL, JUnit and Hypium.

## Backend

- [ ] Add regression tests for provider failures, context preservation and accurate source reporting; run targeted Maven tests to establish failures.
- [ ] Unify chat and suggestions on configured DeepSeek-compatible provider; preserve keyword retrieval, make local inference optional, expose truthful status and structured errors.
- [ ] Replace seven-city guessing with validated coordinates and explicit city/district supplied by device reverse geocoder; never fabricate weather on failure.
- [ ] Add transactional points account, ledger, daily check-in and redemption orders with authenticated ownership, stock checks, idempotency and administrator fulfillment endpoints.
- [ ] Add chat reservation, settlement and refunds with request IDs and result recovery; test concurrency and failure behavior.
- [ ] Run Maven regression suite and package; publish only changed files to original backend after permission check.

## HarmonyOS

- [ ] Add tests for shared base URL, model timeout, 24 solar terms and source/error formatting; run them before implementation.
- [ ] Update ApiConfig, BackendStatusService, RequestErrorService, AssistantReplyService, SuggestionService and Index to use one saved backend address and truthful error state.
- [ ] Update WeatherService and WellnessModels with fresh coordinates, reverse geocoded province/city/district and unknown weather state.
- [ ] Replace SolarTermUtil with verified year-aware solar-term data or library; refresh at foreground and midnight, derive seasonal image choice.
- [ ] Wire HomeTab actions through Index to questionnaire, tongue form or assistant draft; fix chat empty-state and stable message keys.
- [ ] Add four packaged bitmap backgrounds through common page surface and preserve text contrast.
- [ ] Add RewardsService and RewardsPanel to ProfileTab, with balance, ledger, check-in, catalog, address confirmation and orders; wire charged chat request IDs.
- [ ] Implement NotificationService with system reminder registration/cancellation, permission requests, persisted IDs and account cleanup; update ProfileTab controls and module permissions.

## Verification And Delivery

- [ ] Compile HarmonyOS using installed DevEco SDK, resolve ArkTS restrictions and execute feasible tests.
- [ ] Review requirements first, then code quality; fix actionable findings.
- [ ] Verify configured local services and document missing keys or unavailable devices separately from code test results.
- [ ] Update design status and provide launch steps and evidence without claiming unperformed device tests passed.

The existing .git directory is not recognized as a repository; do not reconstruct it or make commit claims. Backend staging is under .work/backend and preserves the original for explicit changed-file publication.
