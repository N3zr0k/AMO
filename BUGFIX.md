# Bugfixes

## 0.1.10
- **LowHealthFrame.lua:112: attempt to perform arithmetic on a secret number value (execution tainted by 'AMO')**
  after a cinematic. Cause: warnings were shown via `RaidNotice_AddMessage(RaidWarningFrame, ...)`, which writes tainted
  values into Blizzard's own message tables; `CinematicFrame_OnEvent` (CINEMATIC_STOP) reads them and ends up tainted.
  Fix: `AMO:ShowLine` shows the line in an own frame, Blizzard's raid warning frame is no longer touched.
