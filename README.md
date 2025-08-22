🐔 ChicChicken

A voice-controlled mini-game in MATLAB with optimized jump physics & reliable mic buffering

🎯 Overview

ChicChicken – FINAL FIX is a lightweight MATLAB game where you help a tiny chicken jump over obstacles using your voice volume. Louder input → jump! The physics are tuned for smoother, controlled arcs, and the audio loop is buffered to avoid glitches and lag.

✨ Features

Voice-controlled jump using RMS volume (no DSP toolboxes needed)

Stable physics: reduced jump strength + gravity tuned for control

Audio ring-buffering: reads the latest slice safely to minimize hiccups

Simple GUI using MATLAB graphics (no extra dependencies)

Start/Pause buttons, score counter, live volume bar

Plug-and-play: works with any standard microphone device

📦 Requirements

MATLAB R2018a or later (tested with base MATLAB)

A working microphone

OS: Windows/macOS/Linux supported by MATLAB audio

🚀 Quick Start

Save the script as chicken_scream_final_fix.m.

Set your microphone device ID (see below).

Run the script in MATLAB:

run('chicken_scream_final_fix.m')


Click Start. Speak/clap/blow to make the chicken jump.
Click Pause to pause.

🎙️ Choose the Correct Mic Device ID

The recorder is created with:

recObj = audiorecorder(fs, 8, 1, 1); % last argument = device ID


Replace the last 1 with your mic’s device ID.

Find your device ID
% List all audio devices
audiodevinfo

% OR programmatically pick a device by name (example)
nameToFind = "Microphone";
devCount = audiodevinfo(1); % 1 = input devices
for k = 1:devCount
    info = audiodevinfo(1, k); % struct with device details
    if contains(string(info.Name), nameToFind, 'IgnoreCase', true)
        fprintf('Use device ID: %d  ->  %s\n', k, info.Name);
    end
end


Once you know the ID, set it in audiorecorder(fs, 8, 1, YOUR_ID).

🕹️ How to Play

Goal: Jump over the red pillar to earn points.

Jump: Make a brief loud sound; volume above threshold triggers a jump.

Score: +1 each time a pillar scrolls past.

Game Over: Collision when the pillar reaches the chicken and chicken height < 2.

⚙️ Tunable Parameters

You can quickly tweak gameplay from the “Parameters” block near the top.

Parameter	Default	What it does
fs	8000	Sample rate for audio
duration	0.05	Audio slice size (s)
gravity	-0.7	Pull-down per frame; more negative = faster fall
jump_strength	4.5	Velocity injected on jump; higher = higher jumps
obstacle_speed	0.3	Horizontal speed of the red pillar
jump_thresh	0.06	RMS volume threshold to trigger a jump
Tips

If jumps feel too eager, increase jump_thresh (e.g., 0.08–0.12).

If jumps are too low, increase jump_strength slightly (e.g., 4.8–5.2).

If the game feels too fast/slow, adjust obstacle_speed.

🏗️ How It Works (Under the Hood)

Audio loop continuously records (record(recObj)) and reads the latest buffered slice:

data = getaudiodata(recObj);
buffer = data(end-buffer_samples+1:end);
vol = sqrt(mean(buffer.^2)); % RMS volume


Jump logic: if vol > jump_thresh and chicken is grounded, set vy = jump_strength.

Physics: each frame updates chicken_y += vy and vy += gravity until grounded.

Collision: checks horizontal overlap with the pillar and chicken_y < 2.

🧩 Controls & UI

Start: begins the game loop

Pause: pauses updates (audio still records)

HUD: score (top-left), volume bar (top-right)

🛠️ Troubleshooting

No jump detected

Mic ID wrong → verify with audiodevinfo.

Threshold too high → lower jump_thresh (e.g., 0.04–0.06).

Mic gain too low → increase system mic level.

Laggy or choppy motion

Try reducing duration to 0.03–0.04.

Close heavy background apps; ensure MATLAB figure is in focus.

Immediate Game Over

Gravity too strong or jump too weak → raise jump_strength or reduce magnitude of gravity.

Multiple inputs / USB mic

Recheck device ID after plugging/unplugging devices—IDs can change across sessions.

🗺️ Roadmap (Nice-to-haves)

Parallax clouds & animated chicken sprite

Variable obstacle heights/gaps

Calibrated auto-threshold (ambient noise sensing)

Start menu with device picker

📄 License

This project is suitable for permissive licensing. If you’re publishing publicly, MIT License is a good default:

MIT License

Copyright (c) 2025 <Your Name>

Permission is hereby granted, free of charge, to any person obtaining a copy...


Create a LICENSE file with the full MIT text (or choose Apache-2.0 if you prefer explicit patent grants).

🙌 Credits

Original concept inspired by “scream to jump” mini-games

Implemented in pure MATLAB graphics & audio APIs by you 💪

📸 (Optional) Repo Extras

Add a short GIF of gameplay in the README (e.g., assets/demo.gif)

Include a config.m for quick parameter presets (quiet room / noisy room)




Happy squawking! 🐣
