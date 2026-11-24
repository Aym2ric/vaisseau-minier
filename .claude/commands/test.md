Run the Godot script checker then the full test suite. ALWAYS execute BOTH steps below, in order.

**Step 1 — Parse check** (MANDATORY — run this first every time):

```
timeout 25 "/mnt/c/Users/Aym2ric/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" --headless --check-only --path "C:/Users/Aym2ric/Desktop/vaisseau-minier-godot/vaisseau-minier" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|error:" || echo "clean"
```

If the output contains any errors (not just "clean" or "Terminated"), read the offending file, fix it, and re-run Step 1 before continuing.

**Step 2 — Tests** (only after Step 1 is clean):

```
"/mnt/c/Users/Aym2ric/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe" --headless --path "C:/Users/Aym2ric/Desktop/vaisseau-minier-godot/vaisseau-minier" --script tests/run_tests.gd 2>&1
```

After showing the output:
- If all tests pass: confirm with the count (e.g. "50/50 ✓")
- If any test fails: identify which tests failed, read the relevant source files, diagnose the root cause, and fix the code. Then re-run both steps to confirm the fix.
- If Godot reports parse/compile errors before tests run: read the offending file(s), fix the error(s), then re-run both steps.
