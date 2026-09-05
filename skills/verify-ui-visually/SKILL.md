---
name: verify-ui-visually
description: >-
  Verify a visual or UI fix by what is actually rendered — computed style, box
  geometry, a screenshot — never by reading back the flag or attribute the code
  just set. Use when fixing anything that shows, hides, moves, resizes, or
  restyles an element, and whenever a user reports a UI problem that
  instrumentation says is already fixed. Triggers: "hide", "show", "toggle",
  "modal", "overlay", "popup", "it's still showing", "looks wrong", "covering
  the page", "won't close", "verify the fix".
---

# Verify UI fixes visually

`el.hidden === true` proves the code ran. It does not prove the element left the
screen. Those are different claims and only one of them is what the user asked
for.

## The verification, in order

1. **Computed style, not the attribute.**
   ```js
   const el = document.querySelector(SELECTOR);
   const cs = getComputedStyle(el);
   const r  = el.getBoundingClientRect();
   console.log({
     hidden: el.hidden,           // what the code set  — NOT evidence
     display: cs.display,         // what the browser did — evidence
     visibility: cs.visibility,
     opacity: cs.opacity,
     w: r.width, h: r.height,     // a hidden element is 0x0
     onscreen: r.width > 0 && r.height > 0,
   });
   ```
2. **A screenshot.** Actually look at it. Full page, at the viewport size the
   user is on. This is the only check that catches "the element is gone but it
   left a gap" and "it's hidden on desktop and covering everything on mobile."
3. **Only then report it fixed.**

## The `[hidden]` trap

`hidden` is styled by a *user-agent* rule, `[hidden] { display: none }`. Any
author-level `display` wins over it:

```css
.panel { display: flex; }   /* beats [hidden] — the panel never hides */
```

So whenever an element uses the `hidden` attribute, the stylesheet needs its own
explicit rule:

```css
.panel[hidden] { display: none !important; }
```

Same class of bug applies to `.d-none`-style utility classes losing to a more
specific selector, and to any `display` set in an inline style attribute.

## When the user says it's broken and your check says it works

**Believe the user and change the measurement.** The instrument is what's wrong.
A report from someone looking at the real page beats a `console.log` from an
assertion you chose.

Look for the tell you already have. In the incident below, the giveaway was
visible in the screenshot the whole time: an open chat box with *no greeting
message in it* — impossible if the open/close code had actually run. Any
inconsistency like that means you are measuring a different thing than the user
is seeing.

## Why this skill exists

A chat panel had `<div hidden>` plus a CSS rule setting `display: flex`. The
author rule beat the UA rule, so the panel sat permanently on screen covering
products on every page load. Clicking the close button set `hidden = true`
correctly — the box never moved. The fix was reported as "verified working"
**three times across several rounds**, because every check read `panel.hidden`
and got back `true`. It took a non-technical staff member sending a screenshot
before anyone measured the right thing.

Three rounds of false confidence, all from verifying the state flag instead of
the pixels.
