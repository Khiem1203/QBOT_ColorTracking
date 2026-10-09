# 6 - Color Tracking Teleop (QBot 2e)

Built with MATLAB R2019b + QUARC. Four models, one picking script.

| File | What it does |
|---|---|
| `QBot2e_Manual_Control.mdl` | Keyboard driving only (copy of Lab 1 teleop) |
| `QBot2e_Color_Picker.mdl` | Keyboard driving + press **C** to freeze a camera frame |
| `pick_color.m` | Live picker window: shows each frame frozen with **C**, you click the line, it saves the RGB range into the tracking models |
| `read_captured_frame.m` | Helper used by `pick_color` to read the frames the robot sends to `captured_frames.bin` |
| `set_tracking_gains.m` | Sets the tracking speed gains (Kv forward, Kw turning) in both tracking models |
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
QUARC reads the keyboard from the whole desktop (no special window needs focus), so keys you type
anywhere — including in the MATLAB command window — reach the robot while a model is running.

---

## 1. Manual control only

**File:** `QBot2e_Manual_Control.mdl`

1. Open the model in MATLAB/Simulink.
2. Build it (Ctrl+B). Wait for the build to finish (status bar at the bottom).
3. Click **Connect**, then **Start** (▶).
4. Drive:
   - **↑ / ↓** — forward / backward (0.15 m/s)
   - **← / →** — turn left / right (0.6 rad/s)
5. Click **Stop** (■) when done.

---

## 2. Pick the color

Everything happens while the robot is running — no need to stop the model.

**Files:** `QBot2e_Color_Picker.mdl` + `pick_color.m`

1. In MATLAB (current folder = this folder) run:
   ```matlab
   pick_color
   ```
   The **QBot 2e Color Picker** window opens and says *"Waiting for a frame…"*. Leave it open.
2. Open `QBot2e_Color_Picker.mdl` → Build → Connect → Start.
3. Drive with the arrow keys until the colored line fills a good part of the camera view
   (watch the "RGB" video window).
4. Press **C**. Within about a second:
   - the frame freezes in the robot's **"Captured Frame"** video window,
   - the **Color Picker** window pops to the front showing that frame (*"Frame #1 received"*).
5. **Click on the line** in the left image — click **2–3 spots**: one on a brightly lit part and
   one on a shaded part of the same color. Each click adds to the range. The picker:
   - marks the clicked pixels and reads their color (average of a 7×7 patch around each),
   - shows the range it will follow: `R [lo hi]  G [lo hi]  B [lo hi]`,
   - shows a mask preview on the right — **white = what the robot will follow**.
6. Aim for: the whole line white, the floor black.
   - Parts of the line still black → click on them too, or slide **Tolerance** right.
   - Floor / background speckled white → **Clear points** and pick less dark spots, or slide
     Tolerance left. Many speckles are not harmless: with more than 50 separate blobs the
     tracker gives up and the robot stops.
   Bad frame? Just press **C** again on the robot; the new frame replaces the old one.
7. Press **Save color**. The range is written into `red_th` / `green_th` / `blue_th` of
   **both** `QBot2e_Color_Line_Tracking.mdl` and `QBot2e_Manual_Track_Switch.mdl`, and a record
   is saved in `color_config.mat`. The status line confirms "Updated … .mdl" for each model.
8. Stop the picker model and close the picker window.

> The robot sends the frozen frame to `captured_frames.bin` in this folder. If you open
> `pick_color` after the run, it shows the last frame from that file, so you can still pick then.

> If one of the tracking models is open in Simulink when you press Save, it is updated and saved
> too — any other unsaved edits in that model get saved with it.

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
3. You start in **manual mode** (Mode display shows `0`):
   - **↑ / ↓ / ← / →** drive the robot as in workflow 1.
4. Press **P** to switch to **tracking mode** (Mode display changes to `1`):
   - Arrow keys are now ignored; the robot steers itself toward the picked color.
   - If the color goes out of view, it stops and waits (does not revert to manual automatically).
5. Press **P** again to switch back to **manual mode** (Mode display back to `0`) and drive normally.
6. You can toggle **P** back and forth as many times as you like during the same run.
7. **Stop** (■) to end the run.

---

## Troubleshooting

- **Keys don't do anything:** check the model is Connected and Started (not just built), and that
  the robot IP in Host Initialize is correct.
- **Pressed C but the picker window stays on "Waiting for a frame…":**
  - check the **"Frames captured"** display in the picker model goes up by 1 per press — if not,
    the key isn't reaching the robot (see above);
  - if it does go up, check `captured_frames.bin` appears in this folder and grows by ~690 KB per
    press. If it doesn't, the picker model you're running is an old build: run `build_models`,
    then Build the picker model again;
  - make sure `pick_color` was started from this folder (`pwd` should end in
    `\LABS\6-Color Tracking Teleop`).
- **The picker opened an old frame:** that's the last frame from a previous run, read from
  `captured_frames.bin`. Press C again with the model running to get a new one.
- **Robot doesn't move in tracking mode:**
  - check the **Manual Switch** is enabled;
  - check the mask in `pick_color` covered the target well — a mostly-black mask means the robot
    can't see a matching blob; a speckled background (>50 blobs) also makes it stop;
  - the robot also stops when the blob is at the bottom-center of the image (it counts as
    "reached") — move the target further ahead;
  - speeds are `Kv × distance` and `Kw × angle`. Run `set_tracking_gains` (Kv 0.5, Kw 1.2) or
    `set_tracking_gains(Kv, Kw)` for other values, then rebuild. The Lab 4 originals (0.2 / 0.4)
    are too slow to move the QBot.
- **Color tracking is unreliable / drifts:** re-pick the color in the same lighting you'll actually run
  in — thresholds are plain RGB ranges, so they shift if the lighting changes.
- **Want to start over:** run `build_models` in MATLAB — it regenerates all four `.mdl` files from
  the original labs and resets the color thresholds to the Lab 4 default. You'll need to re-pick your
  color afterward.

## Notes

- Tracking gains (Kv, Kw, speed limit, stop distance) are the Constant blocks feeding the
  "Trajectory control" subsystem inside the tracking models. Kv/Kw are raised to 0.5 / 1.2
  (`set_tracking_gains`); speed limit 0.5 m/s and stop distance 0.1 are the Lab 4 values.
- `color_config.mat` is just a saved record of the last pick (RGB value, thresholds, timestamp); the
  models themselves don't read it — the thresholds live inside the `.mdl` files.
