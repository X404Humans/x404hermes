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
  if (!ev.deltaY) return false; // let xterm handle horizontal wheels
  const lines = Math.round(ev.deltaY / 50);
  if (lines !== 0) {
    term.scrollLines(lines > 0 ? -lines : -lines);
  }
  return false; // stop xterm.js from sending wheel bytes to the PTY
});
```

Caveats:
- Returning `false` suppresses xterm's wheel handling entirely. Inside
  full-screen TUIs (e.g. Claude Code, `less`, `vim`) that means wheel scrolling
  will be disabled unless the app requests mouse tracking itself. If those apps
  are important, gate the override: only suppress when there is scrollback, or
  expose a user toggle.
- Scroll amount (`50`) is a heuristic; trackpads produce pixel deltas and may
  need `Math.round(ev.deltaY / 40)` or `Math.sign(ev.deltaY)`.

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

Inspect the live DOM after the build to find the real scrollbar element. In
xterm.js 6.x it is typically `.xterm-decoration-scrollbar` or an internal layer
rather than `.xterm-viewport`. Add matching CSS and remove or update the stale
`.xterm-viewport::-webkit-scrollbar` block in `globals.css`.

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
