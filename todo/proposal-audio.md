# Proposal C: sound in hx-multianim — stages A to B4 built

Written 2026-10-14 from a game's audio plan, checked
against the code and against Heaps 2.1.0's `hxd.snd` that day. Built one session a stage, each
with its tests, docs and `CHANGELOG.md` lines, and committed together on `dev`.

Stage A is built: `ResourceLoader.loadSound`, the widget events `UIHover`, `UIOpen`, `UIClose` and a
slider's change said only when its value changes, `AnimationSM.addEventListener`, and
`ScreenManager.clock` set by the DevBridge's pause (`AudioHooksTest`). Stage B1 is built: the
`sounds` block, `bh.audio.Audio` on `ScreenManager.audio` with `HeapsBackend` and `LogBackend`,
banks taken as a file loads (`AudioTest`, `docs/manim.md` "Sounds", `TECHNICAL-DOCS.md` "Audio").
Changed from the plan while building: a random spread is a range, `volume: -5db..-1db`,
`pitch: -5%..5%`, as a layer's `delay: 40..120ms` is, instead of `±` (not a token of the lexer,
and one form for every rolled value); `volume`, `pitch` and `pick` go on a sound's own files or on
its layers, not on a sound beside its layers. Stage B2 is built: the `mix` block, `setVca`,
`snapshot`, `busState`, `AudioBackend.setBus`, the clock on `Audio.clock` (`AudioMixTest`). Stage B3
is built: the widgets' sounds from the `ui` bank and `sound.<key>` settings, the `.anim` `sounds { }`
block played by the state machine through the loader's audio, the `music` block with `playMusic`
and a screen's `music =>` crossfaded on every mode change with the `dialog` snapshot, `history` and
the DevBridge's `audio_state`, `audio_log`, `audio_set` and `audio` event (`AudioScreenTest`).
Changed from the plan: an `.anim`'s sound name is written in quotes (`fire: "fx.shot"`), since the
anim lexer has no dotted identifier; the MCP server's tools of the DevBridge's new ops live in
`hx-multianim-mcp`, not here. Stage B4 is built: `bh.audio.AudioNames.build(path)` for typed names,
a `@:manim` programmable beside the blocks (fixture 158, `AudioCodegenTest`), the blocks taken again
on a hot reload (`HotReloadTest`), the grammars. Every stage's tests pass on the standard and the
DEV build (105 visual, the unit suites).

Of stage C the held sound is built (2026-10-19, asked for by a game's engines): `loop: yes` on a
layer or a sound's own files, `on: stop` for the layer played as the sound stops (in place of the
planned `start:` `loop:` `end:` keys, since the three parts are layers already: picked, rolled,
delayed, by chance), `SoundInstance.setPitch`/`setVolume` to drive it, a bank taken again cutting
its plays; the `.anim` `hold anim: "…"` line (the planned `hold`), and of stage D a screen's
`ambience =>` with `playAmbience`/`stopAmbience` beside the music (`AudioTest`, `AudioScreenTest`).
What is left, by what each waits on: C (music switches on the beat, intros, stems, markers,
ducking, global parameters with a seek rate) for a game with music made for it; D
(placing by x, voice) for a game that asks; a playground demo (its file loader reads
bytes now, done 2026-10-14, as were the MCP server's `audio_state`, `audio_log` and `audio_set`
tools in `hx-multianim-mcp` 1.20.0); hover sounds from widgets other than the button; `voices` on a bus counted by the service rather than
left to Heaps' `maxAudible` (which silences by priority, time running). The rest is below as planned.

## The idea

Everything about sound is data in `.manim` and `.anim` files. The game's code fires a sound by
name and sets parameters; it never names a file, a volume or a bus. What FMOD calls an event is a
**sound** here: a name, behind it its files, how one is picked, how loud, on which bus, how many at
once. "Event" stays the word for an `.anim` event; a sprite's event *plays* a sound.

Four places fire sounds, from the most automatic to the least:

- **Widgets, with no code.** The controller plays `ui.hover`, `ui.click`, `ui.toggle`, `ui.change`,
  `ui.open`, `ui.close` when a `sounds` block named `ui` defines them. An element's settings
  override one: `sound.click => "ui.confirm"`, or `none`.
- **Sprites, from their `.anim`.** A `sounds { }` block maps the animation's events to sounds and the
  state machine plays them as the events fire.
- **Screens.** `music => "music.title"` in a screen's settings: started on enter, crossfaded on a
  switch, the `dialog` snapshot on while a dialog is up.
- **Code.** `audio.play("fx.explosion")`, `audio.set("danger", 0.7)`, `audio.snapshot("paused",
  true)`, `audio.setVca("Music", 0.6)`, where `audio` is a service `ScreenManager` owns like `tweens`.

Under it one `Audio` service reads the clock (paused, scale), routes voices onto buses, blends
snapshots and talks to a backend: `HeapsBackend` over `hxd.snd`, and `LogBackend` that plays nothing
and records every sound with its time, bus, volume and pitch, for the tests and for tools.

## Decisions

1. **Name first, then kind**, as `#name cursor { }` is: `#ui sounds { }`, `#fx sounds { }`,
   `#main mix { }`, `#music music { }`. A sound's name is its block's and its own: `ui.click`,
   `fx.explosion`, `music.title`.
2. **`lowpass` is a share of highs kept** (`lowpass: 0.2`), Heaps' `LowPass.gainHF`, not a frequency:
   WebAudio turns `gainHF` into a filter frequency by an octave formula and OpenAL applies it as it
   is, so a value in Hz would sound different per driver.
3. **A backend interface, no FMOD backend.** The service's calls map one to one onto FMOD's (sounds,
   parameters, buses, snapshots), so a backend for a game made in FMOD Studio could come later;
   none is built, and nothing of FMOD's is a dependency.
4. **Slow motion pitches sounds with the clock** (a snapshot that says `pitch clock`), silent under a
   quarter speed by the snapshot's own numbers, not by a rule in code.
5. **Pause is `Channel.pause` per channel, never `Manager.suspended`**: suspended silences everything
   but a virtual channel keeps counting time, so a sound would resume further on.
6. **WAV and MP3.** Both play on both drivers (MP3 on HashLink with `-D heaps_enable_hl_mp3`,
   `hxd/res/Config.hx`); OGG only on HashLink, or in the browser with the slow `stb_ogg_sound`. The
   engine plays what it is given; converting is the asset pipeline's.
7. **Tests never create `hxd.snd.Manager`.** The CI build has no audio device, and with no driver
   Heaps makes every channel virtual and still counts time. The tests use the log backend; one test
   on the Heaps backend tolerates a missing driver. Tests write their own WAVs (`format.wav.Writer`);
   no bought pack's sound goes into the public engine.
8. **`voices`, `steal`, `cooldown`, layers, picks, VCAs, snapshots and ducking are the engine's,
   above Heaps**: `SoundGroup.maxAudible` silences extras by priority and lets their time run, which
   is not stealing. Heaps gives the hard cap (16 sources, the lowest `priority` virtual).

## What Heaps gives, what the engine adds

| Feature | Heaps 2.1.0 | The engine adds |
|---|---|---|
| Volume in dB | linear `volume` on channel, group, sound group, multiplied | 10^(dB/20) at parse |
| `±` spreads | nothing | a roll per play |
| Pitch | `effect.Pitch`, a rate, on a channel or a group; `AL_PITCH`, `playbackRate` | `%` to rate; a bus pitched by the clock's scale |
| Voices, steal, cooldown | `maxAudible` (by priority, time runs) | counting per sound, oldest or quietest stopped, a play in cooldown skipped |
| Priority | `priority` per channel, lowest virtual at the cap | `low`, `normal`, `high` |
| Fade | `fadeTo(volume, seconds, onEnd)`, linear, wall clock; setting `volume` cancels it | in: start at 0 then fade; out: fade then stop; snapshots blend with it |
| Layers, delay, chance | nothing | several channels per play, a timer, a roll |
| Buses | `ChannelGroup` (volume, mute, effects, fade; effects bind to every channel) | one level, no bus in a bus |
| VCAs, snapshots, duck | nothing | the engine's |
| Pause | `pause` per channel freezes it | a bus paused channel by channel |
| Low-pass | `effect.LowPass.gainHF` 0..1 | the keyword |
| Reverb | OpenAL only | left out |
| Panning | `effect.Spatialization` | stage D |
| Gapless intro then loop | `queueSound`, `onEnd` at the join | stage C |
| Streaming | a sound over 5 s streams | nothing |
| On the beat | no sample-accurate start | a short crossfade hides a frame, stage C |

## Keywords

Root blocks in `.manim`:

| Keyword | Means | Stage |
|---|---|---|
| `sounds` | `#name sounds { }`: a bank; each sound is `name.sound`; loaded when a screen that names it is entered | B |
| `mix` | `#name mix { }`: buses, VCAs, snapshots; one per game | B |
| `music` | `#name music { }`: tracks; later tempo, switches, stems | B, C |

Inside `sounds`: `bus:` (the block's default), a sound `name { }` with `file:` or `files:` and
`pick: random | shuffle | turn`, `volume: -3db ±2db`, `pitch: ±5%`, `voices: 4`, `steal: oldest |
quietest | none` (`furthest` with placing, D), `cooldown: 30ms`, `priority: low | normal | high`,
`fade: in 20ms out 300ms`, `layer name { files delay: 40..120ms chance: 70% }`, `@(…)` arms for a
sound's variant by a parameter (`param surface: [stone, grass]`); a held sound as layers, built:
`loop: yes` on a layer or the sound's own files, `layer x { on: stop }`; C: `global danger: 0..1
seek 0.5/s`.

Inside `mix`: `bus name { voices: 24 }`, `vca Name: bus, bus`, `snapshot name { bus: -6db | pause |
lowpass 0.2 | pitch clock, fade: 200ms }`; C: `duck: music -8db 150ms` on a bus. The snapshots
`paused` and `dialog` are put on by the engine (the clock's pause, a dialog opening); any other is
the game's to switch.

Inside `music`: `track name { file: "…", loop: yes }`; C: `intro:`, `bpm:`, `meter:`, `switch a -> b
{ on: bar, fade: 1 beat, stinger: "…" }`, `stem name { file volume: param 0..0.5 => -inf..0db }`,
`marker a.name: bar 17`.

In `.anim`: a top-level `sounds { event: block.sound }` played by the state machine, and
`hold animation: "block.sound"` held while the animation plays (built).

Settings: `sound.<event> => "block.sound" | none` on an element (`hover`, `click`, `toggle`,
`change`, `open`, `close`), `music => "block.track"` and `ambience => "block.sound"` on a screen.

Units: `db`, `±`, `%`, `ms`, `s`, `a..b`, `beat`, `bar`.

## Stages

- **A, built.** The hooks above.
- **B1, a sound played by name.** The `sounds` block (parser, keyword info, builder, LSP, docs),
  `bh.audio.Audio` on `ScreenManager` with `AudioBackend`, `HeapsBackend`, `LogBackend`; banks loaded
  with a screen. Tests on the log: thirty hits in a frame log three with `voices: 3`, a cooldown skips,
  a shuffle plays every file before a repeat, a layer at `chance: 0%` never plays.
- **B2, the mix and the clock.** The `mix` block; buses to channel groups, VCAs, snapshots; the
  clock's pause puts `paused` on and its scale pitches a `pitch clock` bus; `setVca`. Tests: a
  snapshot fades in and out by the log's volumes, a pause freezes a channel, two VCAs multiply.
- **B3, sound with no code.** Widget sounds from the controller with the `sound.` prefix; the
  `.anim` `sounds` block; `music` tracks and `music =>` on a screen with a crossfade and the `dialog`
  snapshot; DevBridge `audio_state`, `audio_log`, `audio_set` and an `audio` event.
- **B4, parity and reload.** Codegen at parity, typed names, hot reload of the three blocks, the
  grammar.
- **C, music** and **D, placing, voice**: when a game asks. Of these the held sound (C) and a
  screen's ambience (D) are built, 2026-10-19.

## Open

- Hover sounds from widgets other than the button (checkbox, radio, list items) when a game wants
  them: `UIHover` from each is a line apiece.
- `fade:` is linear in amplitude (Heaps' `fadeTo`); fine at these lengths, a dB curve if ever not.
