# Local Context AI Assistant Design

## Goal

Upgrade the assistant from a fixed template answer into an offline, profile-aware guidance surface.

This phase uses the saved local health profile to generate safer and more relevant wellness suggestions without calling a real AI API.

## Current State

The app already has:

- `generateHealthAnswer(question, constitution)` in `AIService.ets`.
- Local health profile persistence through `HealthProfileRepository`.
- Saved constitution results, tongue notes, health indicators, and reminder preferences.
- `AssistantTab` loading the saved profile only to restore questionnaire score.

The gap is that the generated assistant answer does not use saved tongue observations or health indicators.

## Scope

This phase includes:

- A local context answer generator that accepts a question and `HealthProfile`.
- Context extraction for latest constitution, latest tongue note, and latest health indicator.
- Assistant tab loading the full local profile and generating a profile-aware answer.
- Tests for fallback profile, tongue note context, health indicator context, and medical disclaimer.

This phase does not include:

- Real AI API calls.
- Streaming chat.
- Web search.
- Cloud sync.
- Medical diagnosis or treatment claims.

## Architecture

`AIService` remains deterministic and local.

Add:

- `generateContextualHealthAnswer(question, profile)`

The function should:

1. Normalize an empty question to `日常调理`.
2. Read `profile.constitution.name`.
3. Read the newest tongue note if one exists.
4. Read the newest health indicator if one exists.
5. Compose a concise Chinese answer with lifestyle suggestions.
6. Always include the existing medical disclaimer.

`AssistantTab` should:

- Store `localProfile` in `@State`.
- Load profile through `HealthProfileRepository`.
- Use saved profile for recommendation, generated answer, and questionnaire score.
- Refresh local profile after questionnaire submission.

## Data Flow

1. `AssistantTab.aboutToAppear()` loads local profile.
2. `generateContextualHealthAnswer()` receives the current question and profile.
3. The generated answer card renders local-context advice.
4. If questionnaire is submitted, repository saves the record and returns an updated profile.
5. Assistant tab updates `localProfile`, and generated answer uses the new profile.

## Error Handling

- If the saved profile has no tongue notes or indicators, the answer omits those sections.
- If the question is blank, use `日常调理`.
- If profile loading fails, `AssistantTab` keeps the default local profile and still renders a safe fallback answer.
- All output avoids diagnosis claims and includes the medical disclaimer.

## UI Direction

- Keep the current assistant tab layout.
- Keep the existing AI 安全回复 card.
- Do not add chat input in this phase.
- Do not claim real AI, online AI, or diagnostic ability.

## Testing

Unit tests should cover:

- Contextual answer includes constitution.
- Contextual answer includes newest tongue note when present.
- Contextual answer includes newest health indicator when present.
- Contextual answer falls back when profile has no records.
- Contextual answer includes medical disclaimer.

Verification should include:

- `hvigor test`
- `hvigor assembleHap`
- Static search for real AI/API/cloud claims.
- Static search for mojibake and malformed interpolation.

If `hvigor` remains unavailable in the local shell, record the exact command failure.

## Migration Strategy

1. Add contextual AI tests.
2. Implement `generateContextualHealthAnswer()`.
3. Update `AssistantTab` to keep full `localProfile`.
4. Use contextual answer in `GeneratedAnswerCard`.
5. Refresh local profile after questionnaire save.
6. Run static and toolchain verification.
