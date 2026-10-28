# Story content

Stories are data, not code: one JSON file per story in `PeekAhead.swiftpm/Resources/Stories/`, named `story-<id>.json`.
The unit tests load every bundled file, so a malformed story fails CI before it can reach the app.

## Format

```json
{
  "id": "dentist-en",
  "title": "Going to the dentist",
  "language": "en-US",
  "review": "placeholder",
  "pages": [
    {
      "id": "p1",
      "sentence": "Today I am going to the dentist.",
      "sometimesNote": null,
      "scene": "waiting_room"
    }
  ]
}
```

| Field | Rules |
|---|---|
| `id` | Unique across all stories |
| `language` | BCP 47 tag used for the narration voice (`en-US`, `id-ID`) |
| `review` | `placeholder` until an expert has approved the wording, then `reviewed` |
| `pages[].id` | Unique within the story |
| `pages[].sentence` | Not empty. One or two short sentences |
| `pages[].sometimesNote` | Optional. Prepares for a change ("Sometimes … That is okay.") |
| `pages[].scene` | One of `waiting_room`, `big_chair`, `family_visit`, `pip_room`, `street_trip` |

## Writing rules (summary of DESIGN.md)

- First person ("I", "we"), present tense, literal. Describe what happens and what the child *can* do.
- Say "sometimes" instead of promising ("Sometimes we wait a long time").
- No "don't …" commands, no threats, nothing frightening, no comparisons with other children.
- One idea per page. Short sentences.
- Do not call these stories "Social Stories": that name is Carol Gray's trademark. Say "picture stories".

## Review log

Record each review here before changing a story to `"reviewed"`.

| Date | Story | Reviewer (role) | Changes made |
|---|---|---|---|
| | | | |
