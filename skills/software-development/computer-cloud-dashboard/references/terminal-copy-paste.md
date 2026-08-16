# Terminal copy/paste recipe — Computer dashboard

Session: 2026-08-16. Issue: terminal copy/paste in `components/modules/TerminalView.tsx` worked intermittently and was not discoverable.

## Files involved

- `components/modules/TerminalView.tsx` — xterm.js frontend.
- `server/terminal.ts` — tmux config generated on startup.

## Root causes addressed

1. `navigator.clipboard` fails in non-secure contexts or when permission is denied; the old code had no fallback.
2. Keyboard shortcuts were narrow (`Cmd+C/V`, `Ctrl+Shift+C/V` only) and did not handle Linux legacy keys (`Ctrl+Insert`, `Shift+Insert`).
3. No UI hint or context menu, so users didn't know copy/paste was possible.
4. The wrapper div had an inline `userSelect: "none"` in addition to xterm.css's own `.xterm { user-select: none; }`, which could block selection in some browsers.

## Robust clipboard helpers

```ts
async function copyToClipboard(text: string): Promise<boolean> {
  if (!text) return false;
  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      return true;
    }
  } catch {
    // fall through to execCommand fallback
  }
  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "");
  textarea.style.position = "fixed";
  textarea.style.left = "-9999px";
  document.body.appendChild(textarea);
  textarea.focus();
  textarea.select();
  try {
    const ok = document.execCommand("copy");
    document.body.removeChild(textarea);
    return ok;
  } catch {
    document.body.removeChild(textarea);
    return false;
  }
}

async function pasteFromClipboard(): Promise<string> {
  try {
    if (navigator.clipboard?.readText) {
      return await navigator.clipboard.readText();
    }
  } catch {
    // fall through
  }
  const textarea = document.createElement("textarea");
  textarea.style.position = "fixed";
  textarea.style.left = "-9999px";
  document.body.appendChild(textarea);
  textarea.focus();
  try {
    const ok = document.execCommand("paste");
    const text = ok ? textarea.value : "";
    document.body.removeChild(textarea);
    return text;
  } catch {
    document.body.removeChild(textarea);
    return "";
  }
}
```

## Keyboard shortcuts

```ts
function isCopyShortcut(e: KeyboardEvent) {
  return (
    (e.metaKey && !e.ctrlKey && !e.altKey && e.key.toLowerCase() === "c") ||
    (e.ctrlKey && !e.metaKey && e.shiftKey && !e.altKey && e.key.toLowerCase() === "c") ||
    (e.ctrlKey && !e.metaKey && !e.shiftKey && !e.altKey && e.key === "Insert")
  );
}

function isPasteShortcut(e: KeyboardEvent) {
  return (
    (e.metaKey && !e.ctrlKey && !e.altKey && e.key.toLowerCase() === "v") ||
    (e.ctrlKey && !e.metaKey && e.shiftKey && !e.altKey && e.key.toLowerCase() === "v") ||
    (!e.ctrlKey && !e.metaKey && !e.altKey && e.shiftKey && e.key === "Insert")
  );
}
```

Use these inside `term.attachCustomKeyEventHandler`. When a copy shortcut fires
and xterm has a selection, copy it and `return false` so the key is not sent to
the shell. When nothing is selected, `return true` so `Ctrl+C` still sends
SIGINT. For paste, always read from the clipboard and `term.paste(text)`.

## Context menu

Render a fixed-position menu on `onContextMenu`. Snapshot the selection at menu
open time and store it in the menu state so the Copy button works even if the
xterm selection changes before the user clicks.

```tsx
const [contextMenu, setContextMenu] = useState<{
  x: number;
  y: number;
  open: boolean;
  selection: string;
} | null>(null);

const handleContextMenu = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
  e.preventDefault();
  const selection = stateRef.current.term?.getSelection() || "";
  if (!selection && !navigator.clipboard?.readText) return;
  setContextMenu({ x: e.clientX, y: e.clientY, open: true, selection });
}, []);
```

## Server-side requirement

Keep tmux mouse mode off so xterm.js owns selection. In `server/terminal.ts`:

```ts
function getTmuxConf(): string {
  return [
    "set -g status off",
    "set -g prefix None",
    "set -g escape-time 0",
    "set -g default-terminal screen-256color",
    "set -g mouse off",            // critical for xterm.js selection
    "set -g history-limit 50000",
    ...
  ].join("\n") + "\n";
}
```

## Deployment

`/computer` is production systemd; every change needs commit, build, and service
restart:

```bash
cd /computer
npm run build
printf '{"operation":"restart","service":"all"}' | sudo -n /usr/local/libexec/computer-service-helper
```

## Verification

- `npx tsc --noEmit` should pass.
- `npx eslint components/modules/TerminalView.tsx` should pass.
- `systemctl status computer-web.service computer-terminal.service` should show
  both services active after restart.
