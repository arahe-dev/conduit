# Space JSON schema

Used by the Import Space Definition App Intent.

```json
{
  "name": "Thermodynamics",
  "color": "blue",
  "tasks": ["Review lecture", "Practice problems"]
}
```

- `name` required, 1–80 characters
- `color` one of: orange, blue, teal, purple, green, red, yellow, indigo, pink, gray
- `tasks` 1–40 unique non-empty strings (duplicates ignored)

Shortcuts: Use Model / ChatGPT to emit exactly this JSON, then pass it to ProductivityTracker → Import Space Definition.
