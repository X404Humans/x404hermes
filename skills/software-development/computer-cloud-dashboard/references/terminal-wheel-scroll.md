# Terminal wheel/touchpad scrolling — Computer dashboard

Session: 2026-08-30. Issue: mouse wheel / 2-finger touchpad scroll in
`components/modules/TerminalView.tsx` cycled bash history instead of scrolling
the terminal viewport, and no scrollbar was visible.

## Files involved

- `components/modules/TerminalView.tsx` — xterm.js frontend.
- `server/terminal.ts` — tmux config generated on startup.
- `app/globals.css` — scrollbar styling.

## Observed behavior

- 2-finger trackpad up/down or mouse wheel performed the same as `Up`/`Down`
  arrow keys, cycling previous commands.
- No scrollbar was rendered, so there was no visual affordance and no way to
  drag to scroll.

## Root causes

1. **Wheel events became arrow-key sequences.** xterm.js translates wheel events
   into cursor-up/down bytes when the running program has not requested mouse
   tracking. At a bash/zsh prompt those bytes read as history navigation.
   `server/terminal.ts` explicitly sets `set -g mouse off` in tmux so that xterm.js
   keeps click/drag selection (the copy/paste requirement). With mouse off,
   tmux does not capture wheel events either, so xterm.js's default translation
   reaches the shell.

2. **Invisible / missing scrollbar.** xterm.js 6.0.0 (the version pinned in
   `package-lock.json`) rewrote the viewport/scroll implementation in PR #5096.
   The old `.xterm-viewport::-webkit-scrollbar` CSS in `globals.css` no longer
   matches the scrollbar element used internally, so the thumb is not visible.
   xterm.js 6.0.0 also has a known touch-scroll regression (issue #5489,
   fixed in 6.1.0 via PR #5563), which can affect touchpad/touch scrolling.

## Fix options

Pick one or combine:

### Option A — client-side wheel override (preserves copy/paste)

Intercept wheel events in `TerminalView.tsx` and scroll the xterm viewport
manually instead of letting xterm.js send arrow keys.

```ts
term.attachCustomWheelEventHandler((ev) => {
  // Let modifier+wheel through (e.g. Ctrl+wheel zoom if ever enabled).
  if (ev.ctrlKey || ev.metaKey || ev.altKey || ev.shiftKey) return true;
  // For normal wheel/trackpad scrolling, tell xterm.js NOT to translate the
  // wheel event into terminal input bytes. xterm.js will still scroll its own
  // viewport natively, so the user sees scrollback move rather than bash/zsh
  // cycling through command history.
  return false;
});
```

Caveats:
- Returning `false` suppresses xterm's wheel handling entirely. Inside
  full-screen TUIs (e.g. Claude Code, `less`, `vim`) that means wheel scrolling
  will be disabled unless the app requests mouse tracking itself. If those apps
  are important, gate the override (e.g. only suppress when the terminal is not
  in the alternate screen buffer) or expose a user toggle.
- This is the simplest implementation. If xterm.js's native viewport scrolling
  feels too fast or slow for trackpads, switch to a manual
  `term.scrollLines(Math.sign(ev.deltaY) * lines)` approach and call
  `ev.preventDefault()`.

### Option B — enable tmux mouse mode (simplest, but breaks native selection)

Change `server/terminal.ts`:

```ts
"set -g mouse on"
```

This makes tmux enter copy mode on wheel events and scroll its own history.
Trade-off: click/drag selection is handled by tmux, not xterm.js, so the current
native copy/paste workflow in `TerminalView.tsx` needs reworking (use tmux
selection + key bindings instead).

### Option C — upgrade xterm.js to 6.1.0+

`package.json` pins `^6.0.0`. Upgrading to `^6.1.0` (or the latest 6.x)
resolves the touch-scroll regression (#5489 / #5563) and may restore the
scrollbar element rendering. This alone does **not** fix arrow-key translation
at a plain shell prompt — combine with Option A for that.

### Option D — fix the scrollbar CSS

In xterm.js 6.x the internal scrollbar element changed. Target the likely classes
and keep the old `.xterm-viewport` selector as a fallback:

```css
/* WebKit */
.xterm-viewport::-webkit-scrollbar,
.xterm-decoration-scrollbar::-webkit-scrollbar,
.xterm-screen::-webkit-scrollbar {
  width: 6px;
}
.xterm-viewport::-webkit-scrollbar-track,
.xterm-decoration-scrollbar::-webkit-scrollbar-track,
.xterm-screen::-webkit-scrollbar-track {
  background: transparent;
}
.xterm-viewport::-webkit-scrollbar-thumb,
.xterm-decoration-scrollbar::-webkit-scrollbar-thumb,
.xterm-screen::-webkit-scrollbar-thumb {
  background: #9ca3af;
  border-radius: 3px;
}
.xterm-viewport::-webkit-scrollbar-thumb:hover,
.xterm-decoration-scrollbar::-webkit-scrollbar-thumb:hover,
.xterm-screen::-webkit-scrollbar-thumb:hover {
  background: #6b7280;
}
/* Firefox */
.xterm-viewport,
.xterm-decoration-scrollbar,
.xterm-screen {
  scrollbar-width: thin;
  scrollbar-color: #9ca3af transparent;
}
```

If the thumb is still invisible after deployment, inspect the live xterm DOM
(in the browser DevTools) and add the actual scrollbar class to the selector
list in `app/globals.css`.

## Recommended combination

For the least user-visible regression, do:
1. **Option A** first — add `attachCustomWheelEventHandler` in
   `TerminalView.tsx` with a sensible scroll-lines heuristic.
2. **Option D** — update the CSS target for the 6.x scrollbar element.
3. **Option C** as a follow-up — upgrade `@xterm/xterm` to 6.1.0+ to pick up
   touch-scroll fixes.

Keep `set -g mouse off` in `server/terminal.ts` until a deliberate decision is
made to move selection to tmux; the copy/paste skill depends on that setting.

## Deployment

`/computer` is production systemd; every change needs commit, build, and service
restart:

```bash
cd /computer
npm run build
printf '{"operation":"restart","service":"all"}' | sudo -n /usr/local/libexec/computer-service-helper
```

## Verification checklist

- [ ] Open a terminal tab, run a command that produces many lines of output
  (e.g. `seq 200`).
- [ ] 2-finger trackpad scroll or mouse wheel scrolls through previous output;
  bash history is **not** cycled while the terminal has scrollback.
- [ ] A scrollbar thumb is visible when scrollback exists and can be dragged.
- [ ] Copy/paste shortcuts still work (selection and `⌘+C` / `Ctrl+Shift+C`).
- [ ] Inside a mouse-aware TUI such as `vim` or Claude Code, scrolling behaves
  acceptably (or document the chosen trade-off).

## See also

- `references/terminal-copy-paste.md` — the copy/paste conventions that keep
  tmux mouse mode off.
- xterm.js issue #5489 — "Regression - Touch scrolling not functioning in
  6.0.0" (fixed in 6.1.0).
- xterm.js PR #5096 — integrated VS Code scrollbar into the viewport (breaking
  change in 6.0.0).
