# Story content

Stories are data, not code. Bundled stories are JSON files in `PeekAhead.swiftpm/Resources/Stories/`, one per
story, named `story-<id>.json`. Stories a grown-up writes or drafts in the app use the same format and are saved in
the progress file.

The unit tests load every bundled file, validate it and run the rule checker on it, so a malformed story, or one
that breaks a writing rule, fails CI before it can reach the app.

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
      "scene": "waiting_room",
      "kind": "describes"
    }
  ],
  "practice": {
    "steps": [
      { "id": "car", "label": "Go in the car", "pictogram": "step_car" },
      { "id": "home", "label": "Go home", "pictogram": "step_home" }
    ],
    "sounds": [
      { "sound": "dentist_drill", "label": "The little brush (it buzzes)" }
    ],
    "calmTools": ["headphones", "breathe"]
  }
}
```

### Story

| Field | Rules |
|---|---|
| `id` | Unique across all stories |
| `title` | Shown on Home and read aloud |
| `language` | BCP 47 tag used for the narration voice: `en-US` or `id-ID` |
| `review` | `placeholder` until an expert has approved the wording, then `reviewed` |
| `pages` | At least one page |
| `practice` | Optional. What the child can practise after the story (see below) |
| `draftSource` | Optional, set by the app only: `template` or `on_device_model` while a draft is unsaved |

### Pages

| Field | Rules |
|---|---|
| `id` | Unique within the story |
| `sentence` | Not empty. One or two short sentences, at most 12 words each |
| `sometimesNote` | Optional. Prepares for a change ("Sometimes … That is okay.") |
| `scene` | One of `waiting_room`, `big_chair`, `family_visit`, `pip_room`, `street_trip` |
| `kind` | What the page does (below). Optional in older files; missing means `describes` |
| `photoID` | Optional, set by the app only: a photo the grown-up added. Never in bundled stories |

Page kinds come from the structure in DESIGN.md:

| `kind` | The page… | Example |
|---|---|---|
| `describes` | says what happens or what is there | "The dentist has a big chair that goes back." |
| `feelings` | names a feeling, without telling the child how to feel | "I might feel a little worried. That is okay." |
| `i_can` | says something the child can do | "I can hold my favourite toy." |
| `ends_well` | ends with something good and true, usually the last page | "Then I can go home." |

### Practice

All three lists are optional; an activity only appears when it has something to show.

| Field | Rules |
|---|---|
| `steps` | Shown as **Put the steps in order** when there are two or more. `id` unique within the story; `pictogram` is one of `step_waiting`, `step_breakfast`, `step_book`, `step_car`, `step_dentist`, `step_home` |
| `sounds` | Shown as **Hear the sounds**. `sound` is one of `hair_clipper`, `dentist_drill`, `suction`, `hand_dryer`, `school_bell`, `fire_alarm`, `bedug_drum`, `fireworks`, `thunder_rain`. `label` says what makes the sound, literally |
| `calmTools` | Shown as **What helps me**. Any of `headphones`, `sunglasses`, `squishy`, `breathe`, `quiet_corner`, `break_card`, `ask_help`, `hold_hand` |

Only use a pictogram that shows the step. If none fits, leave the step out; a misleading picture is worse than none.
New pictograms, sounds or tools need a file in `Resources/` and a case in `Core/Models/Practice.swift`; the tests
check that every case has its file.

## Writing rules (summary of DESIGN.md)

- First person ("I", "we"), present tense, literal. Describe what happens and what the child *can* do.
- Say "usually", "might" or "sometimes" instead of promising ("Sometimes we wait a long time").
- No "don't …" commands, no threats, nothing frightening, no comparisons with other children.
- One idea per page. Short sentences.
- At least two `describes` or `feelings` pages for every `i_can` page.
- End well: the last page is something good and true.
- Do not call these stories "Social Stories": that name is Carol Gray's trademark. Say "picture stories".

### The rule checker

`Core/Rules/StoryRuleChecker.swift` checks the rules that can be checked mechanically, in English and Indonesian.
The grown-up's editor shows its findings as chips on each page; the bundled-story test fails on any coral finding.

| Rule | Catches | Chip |
|---|---|---|
| `directive` | Telling the child what not to do: "don't", "never", "must"; "jangan", "tidak boleh", "harus" | coral: change it |
| `length` | A sentence longer than 12 words | coral |
| `idiom` | A figure of speech a literal reader may misread: "piece of cake" | coral |
| `ratio` | Fewer than two describing or feeling pages per "I can" page | coral |
| `absolute` | A promise: "always", "will"; "selalu", "pasti" | sky: take a second look |
| `ending` | The last page is not marked `ends_well` | sky |

The word lists are short on purpose. They catch common slips; they cannot judge whether a story is kind, accurate
or right for a child. Only a reviewer can. The lists themselves are part of what the expert reviews.

## Drafts made in the app

A grown-up can draft a story from an event and a few notes. On iOS 26 devices with Apple Intelligence the
on-device model writes the draft; otherwise, or if anything goes wrong, a built-in template is used and the editor
says why. Every draft starts as `placeholder`, gets the template's practice section, and goes through the same
validation and rule checks as a bundled story. The grown-up reads and edits every page before the child sees it.

## Review log

Record each review here before changing a story to `"reviewed"`.

| Date | Story | Reviewer (role) | Changes made |
|---|---|---|---|
| | | | |
