# Crate — the design system

The visual direction of Vinyl Collection Manager, approved 27 August 2026 and
shipped over five phases.

This file records the decisions and the rules that follow from them. It is not
the source of truth for values — the tokens live in
[`app/assets/tailwind/application.css`](../../app/assets/tailwind/application.css)
and are the only place they are defined. What is here is the *why*, which the
code cannot tell you, plus a pointer to the test that keeps each rule honest.

The original proposal is kept as a dated snapshot in
[`crate-proposal.html`](crate-proposal.html) — open it in a browser. Everything
it diagnoses has since been fixed, so read it as history, not as a to-do list.

## The direction

**The cover is the interface.** A collector recognises a record by its sleeve,
not its title. Artwork is the content; everything else is chrome and gets out
of its way. This is why the grid puts art straight on the page ground with its
own shadow instead of inside a card, and why the album page lets the blurred
cover tint its own header.

**Chrome is desaturated so the artwork carries the colour.** Album covers are
wildly colourful and all different. A saturated interface would fight every one
of them. One muted brass accent, warm-biased neutrals, and nothing else.

**Liner notes, not dashboard.** Metadata reads like the back of a sleeve:
condensed uppercase labels, values in tabular mono, hairline separators. No
cards inside cards.

**Square, like a sleeve.** 3px radius (`rounded-sleeve`) everywhere. The object
this app catalogues has straight corners.

## Colour

Defined once in `application.css`: the light palette on `:root`, dark
redefining *values only* under both `[data-theme="dark"]` and
`prefers-color-scheme` (the latter covers the no-JS case).

Views must use semantic utilities — `bg-surface`, `text-fg-muted`,
`border-line` — never `bg-white` or `text-gray-700`. A literal Tailwind colour
in a view means dark mode is broken there.

> Guarded by `test/integration/theme_test.rb`, which fails on any literal
> colour utility in `app/views`.

**Green and red are reserved** for success and danger. They are never
decoration. Blue is not in the palette at all; what used to be blue is the
accent.

Contrast is measured, not assumed: 26 token pairs across both themes, all at or
above their WCAG AA threshold. The tightest are subtle text at 3.66:1 (needs
3.0) and the accent on the page ground at 4.79:1 (needs 4.5). **Changing a
token means re-checking those two.**

## Typography

| Role | Face | Used for |
|---|---|---|
| Display | Archivo | Album titles, headings, the brand, condensed uppercase labels |
| Interface | Instrument Sans | Body, buttons, form labels, navigation |
| Data | IBM Plex Mono | Catalog numbers, years, track positions, durations, counts |

Anything that is a number and might line up in a column gets the mono face and
`tabular-nums`.

## Components

Component classes live in the `@layer components` block of `application.css`.
Use them instead of repeating utility strings — a button's intent belongs in
its class.

**Buttons carry weight, not variety.** One filled primary per view, an outlined
secondary, and a destructive that looks like neither and sits away from both so
it is never the accidental click.

- `.btn` + `.btn-primary` — the one action the view is for
- `.btn` + `.btn-secondary` — everything else actionable
- `.btn` + `.btn-danger` — destructive, kept at a distance
- `.btn` + `.btn-ghost` — cancel and dismissals

> The hierarchy on the album page is asserted in
> `test/integration/album_detail_test.rb`.

Fields use `.field`, `.field-label`, `.field-help`.

## Accessibility

These are commitments, not aspirations — each one has a test.

- **44px minimum touch target** on everything tappable. Carried by `.btn`,
  `.field`, `.control` and `.control-icon` rather than remembered per call
  site. For an inline link, grow the hit area with padding and an equal
  negative margin so the text does not move.
  → `test/system/navigation_system_test.rb`
- **State is never colour alone.** The Discogs indicator is a dot *and* an icon
  *and* words. → `test/integration/navigation_test.rb`
- **Announcements reach screen readers.** A notice is `role="status"` and
  clears itself; an error is `role="alert"` and stays, because it carries
  something still to act on. → `test/integration/accessibility_test.rb`
- **One focus ring** for everything focusable, in the base layer. Never a
  per-input `focus:` utility.
- **Skip link and `aria-current`** on every page.
- **`prefers-reduced-motion`** honoured in the base layer.
- **Covers carry real alt text** naming the record and artist.

## Interface language

Every user-facing string comes from `config/locales/`. English and Spanish are
at full parity — 169 keys, aligned interpolations.

A Stimulus controller cannot reach I18n, so any label a controller writes must
be handed to it from the view as a Stimulus value, and those values must sit on
the **controller element**, not on a target.

> Guarded by `test/integration/locale_test.rb`, which fails on any string a
> controller assigns to `textContent` or an `aria-label`.

## Turbo

The collection results sit in a turbo frame. The frame targets `_top`, so a
link inside it navigates the page normally and only pagination opts back in.
The toolbar deliberately lives **outside** the frame: replacing it on every
keystroke would pull the caret out of the search field.

A failed save must answer `422`, or Turbo discards the response and the
validation errors never reach the page.

`data-turbo-confirm` goes through the app's own `<dialog>`, wired up in
`app/javascript/confirm_dialog.js`.

## Verifying a change

The test suite does not catch design regressions on its own. Every phase of
this redesign turned up something only visible in a browser — a panel
overflowing the viewport, a dialog stuck in a corner, an icon that never
swapped, a confirmation that silently did nothing.

Run the app and look at it, at 1440, 768 and 390, in both themes.
