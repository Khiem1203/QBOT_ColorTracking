# 6 - Color Tracking Teleop (QBot 2e)

Built with MATLAB R2019b + QUARC. Four models, one picking script.

| File | What it does |
|---|---|
| `QBot2e_Manual_Control.mdl` | Keyboard driving only (copy of Lab 1 teleop) |
| `QBot2e_Color_Picker.mdl` | Keyboard driving + press **C** to freeze a camera frame |
| `pick_color.m` | Click the line color in the frozen frame; writes RGB thresholds into the tracking models |
| `QBot2e_Color_Line_Tracking.mdl` | Follows the picked color only (copy of Lab 4 line following) |
| `QBot2e_Manual_Track_Switch.mdl` | Starts in manual mode; **P** toggles color tracking on/off |
| `build_models.m` | Regenerates all four models from the lab originals (overwrites them and resets the thresholds) |

Run exactly one of the four `.mdl` workflows below depending on what you want to do today.

---

## 0. One-time setup (every session)

1. Open **MATLAB R2019b** (must match the version these models were saved with).
2. `cd` into this folder (`LABS/6-Color Tracking Teleop`) so MATLAB's current folder matches it —
   `pick_color.m` reads/writes files relative to here.
3. Power on the QBot 2e and make sure your PC is on the same network as the robot.
4. Check the robot's IP address matches the one in the model. All four models use:
   `Host Initialize → uri = tcpip://192.168.2.104:17001`
   If your robot's IP is different, open the model, double-click **Host Initialize**, and update the URI
   before building.

For every model the run sequence is the same QUARC pattern:
**Open `.mdl` → Build (hammer icon / Ctrl+B) → Connect → Start (play ▶).**
Stop with the ■ button before closing or switching to another model.
Keyboard input only works while the small QUARC/Host window has focus — click it before pressing keys.

---

## 1. Manual control only

**File:** `QBot2e_Manual_Control.mdl`

1. Open the model in MATLAB/Simulink.
2. Build it (Ctrl+B). Wait for the build to finish (status bar at the bottom).
3. Click **Connect**, then **Start** (▶).
4. Click on the small Host/keyboard window so it has focus.
5. Drive:
   - **↑ / ↓** — forward / backward (0.15 m/s)
   - **← / →** — turn left / right (0.6 rad/s)
6. Click **Stop** (■) when done.

---

## 2. Pick the color

This is a two-part flow: capture a frame on the robot, then pick the color in MATLAB.

**Part A — capture the frame**

**File:** `QBot2e_Color_Picker.mdl`

1. Open, Build, Connect, Start — same as above.
2. Click the Host window for keyboard focus.
3. Drive with the arrow keys until the colored line/object fills a good part of the camera view
   (check the "RGB" video display window).
4. Press **C** to freeze the frame.
   - The **"Captured Frame"** display window now shows the frozen image.
   - The **"Frame captured (1 = yes)"** readout shows `1`.
   - Not happy with it? Just press **C** again — it overwrites the previous capture.
5. Once you're happy with the frozen frame, wait about 1 second (lets the slow camera-rate signal
   propagate to the workspace sink), then click **Stop** (■).
6. `captured_frame` is now a variable in the MATLAB base workspace (check with `whos` if you like).

**Part B — pick the color in MATLAB**

7. In the MATLAB command window, run:
   ```matlab
   pick_color
   ```
8. A figure opens showing the captured frame. **Click directly on the colored line/object.**
9. A second figure appears with two panels:
   - Left: your click location marked, with the sampled RGB value in the title.
   - Right: a black/white mask preview — **white pixels are what the robot will treat as "the color."**
10. In the command window, answer the prompt:
    - `y` — save these thresholds
    - `r` — re-click a different point (if the mask looks wrong)
    - `n` — cancel, nothing is saved
11. If the mask is too small/patchy, re-run with a wider tolerance:
    ```matlab
    pick_color('Tol', 45)
    ```
    If the mask also picks up the background, tighten it:
    ```matlab
    pick_color('Tol', 20)
    ```
12. On save, `pick_color` writes `red_th` / `green_th` / `blue_th` into **both**
    `QBot2e_Color_Line_Tracking.mdl` and `QBot2e_Manual_Track_Switch.mdl`, and also saves
    `color_config.mat` in this folder as a backup record.

> **Important:** close `QBot2e_Color_Line_Tracking.mdl` and `QBot2e_Manual_Track_Switch.mdl` in
> Simulink before running `pick_color` (or re-open them afterward) — MATLAB can't edit a model that's
> open with unsaved state in a conflicting way. If you forget, `pick_color` will still report success/failure
> per model in the command window; just check both say "Updated".

> After a new pick you must **rebuild** whichever tracking model you're about to run (Ctrl+B) so the
> new thresholds actually get compiled onto the robot — just re-running Start without rebuilding keeps
> the old color.

---

## 3. Color line tracking only

**File:** `QBot2e_Color_Line_Tracking.mdl` (run *after* you've picked a color — step 2 above)

1. Open the model (rebuild it first if you just ran `pick_color`).
2. Build, Connect.
3. Before pressing Start, double-click the **Manual Switch** block so it's set to enable the motors
   (it's the master motor enable / e-stop for this model).
4. Click **Start** (▶).
5. Point the robot at the target color — it will steer toward the largest blob of that color and drive
   toward it, slowing/stopping within the configured stop distance.
6. If the color leaves the camera view, the robot stops and waits; it resumes as soon as the color
   reappears.
7. Toggle the **Manual Switch** off at any time to cut the motors (emergency stop), **Stop** (■) to end
   the run.

---

## 4. Manual control with P-key tracking toggle

**File:** `QBot2e_Manual_Track_Switch.mdl` (also run *after* picking a color)

1. Open the model (rebuild it first if you just ran `pick_color`).
2. Build, Connect, Start (▶). Motors are enabled by default; the **Manual Switch** block is still
   there as an emergency stop if you need to cut power instantly.
3. Click the Host window for keyboard focus.
4. You start in **manual mode** (Mode display shows `0`):
   - **↑ / ↓ / ← / →** drive the robot as in workflow 1.
5. Press **P** to switch to **tracking mode** (Mode display changes to `1`):
   - Arrow keys are now ignored; the robot steers itself toward the picked color.
   - If the color goes out of view, it stops and waits (does not revert to manual automatically).
6. Press **P** again to switch back to **manual mode** (Mode display back to `0`) and drive normally.
7. You can toggle **P** back and forth as many times as you like during the same run.
8. **Stop** (■) to end the run.

---

## Troubleshooting

- **Keys don't do anything:** click the small QUARC Host window first — Simulink's own window
  doesn't receive keyboard input.
- **`captured_frame` doesn't exist in MATLAB after stopping the picker:** make sure you pressed
  **C** at least once before stopping, and waited ~1 s after pressing it before clicking Stop.
- **`pick_color` can't find a file / errors on load:** confirm MATLAB's current folder is this one
  (`pwd` should show `...\LABS\6-Color Tracking Teleop`).
- **Robot doesn't move in tracking mode:** check the **Manual Switch** is enabled, and check the
  mask preview from `pick_color` actually showed solid white on the target color — a mostly-black
  mask means the robot can't see any matching blob.
- **Color tracking is unreliable / drifts:** re-pick the color in the same lighting you'll actually run
  in — thresholds are plain RGB ranges, so they shift if the lighting changes.
- **Want to start over:** run `build_models` in MATLAB — it regenerates all four `.mdl` files from
  the original labs and resets the color thresholds to the Lab 4 default. You'll need to re-pick your
  color afterward.

## Notes

- Tracking gains (Kv, Kw, speed limit, stop distance) are the Constant blocks feeding the
  "Trajectory control" subsystem inside the tracking models — same values as the original Lab 4 model.
- `color_config.mat` is just a saved record of the last pick (RGB value, thresholds, timestamp); the
  models themselves don't read it — the thresholds live inside the `.mdl` files.
