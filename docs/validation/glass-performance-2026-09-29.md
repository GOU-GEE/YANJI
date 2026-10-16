# Glass control performance — 2026-09-29

Device: realme RMX3820, Android, 1240×2772, app display mode 60 Hz. Both variants were Flutter **profile** builds using the same preview database. The only variant difference for the button comparison was whether `YanjiGlassControl` created a `LiquidGlassLayer`. A temporary frame-timing callback was used in both builds and removed afterward.

Workload: on the Profile page, repeatedly drag across “我的科目” and “设备与同步” without opening either page. Each variant had two runs of 40 identical ADB swipes; startup and navigation were excluded. `FrameTiming` reported Flutter build and raster durations. The SurfaceFlinger sample covers the last 127 presented frames of a separate matching run, so its FPS number is a short-window check, not a whole-session average.

| Metric | Refractive buttons | Flat glass + elastic buttons |
| --- | ---: | ---: |
| Flutter frames sampled | 1,689 | 1,749 |
| Build duration p50 / p90 | 1.75 / 2.39 ms | 1.20 / 1.96 ms |
| Raster duration p50 / p90 / p99 | 10.38 / 16.97 / 25.43 ms | 4.51 / 5.13 / 6.84 ms |
| Frames with build or raster duration >16.67 ms | 177 (10.5%) | 0 (0%) |
| SurfaceFlinger FPS, last ~2.1 s | 59.75 | 60.28 |
| Presentation gaps >25 ms in that window | 15 | 0 |

Interpretation: average presented FPS was already near the 60 Hz cap, so a ~0.5 FPS numerical difference is too small and short-window to claim a meaningful average FPS uplift. The useful gain is frame-time headroom: raster p90 fell about 70%, and long frames disappeared in these runs. Results apply to the tested Profile interactions, not every screen or thermal state.

Further code inspection found that the statistics range bar's outer shell also had a full `LiquidGlassLayer` over a flat page. It now uses the lightweight surface while retaining `GlassElastic`; the inner moving indicator still refracts the labels. This second change has widget and visual validation but was not included in the A/B figures above.

Next candidates for isolated measurement: the always-on outer navigation glass during long-list scrolling, full-width glass app bars during scroll, and statistics chart painters whose `shouldRepaint` currently always returns true. The navigation lens and indicator should keep their separate sampling layers, since merging their backdrops would change the requested optical effect.

Raw timing logs: `work/perf-baseline-run{1,2}.log`, `work/perf-optimized-run{1,2}.log`; presentation samples: `work/perf-baseline-sf.log`, `work/perf-optimized-sf.log`.

## Physical-device refresh check after the interactive-rate change

With USB debugging restored, the same RMX3820 was updated in place with a profile APK. Android reports supported 60/90/120/144 Hz display modes. While the app was idle, `dumpsys display` reported mode 2 (60 Hz). During an ADB-driven 1.8-second drag across the navigation dock it changed to mode 1 (120 Hz), then returned to mode 2 after interaction. The phone's on-screen refresh indicator agreed with 60 at rest and 120 during interaction.

In a separate 3-second dock drag, SurfaceFlinger's Flutter SurfaceView latency history contained 127 frames. The median interval between successive frames was 8.32 ms; 115 of 126 intervals were under 11 ms, with none over 16 ms. This confirms roughly 120 presented frames per second for this interaction, not just a 120 Hz display mode. Raw sample: `work/phone-swipe-latency.txt`. It is a short interaction sample; it does not prove every page, scroll workload or thermal condition will sustain 120 FPS.
