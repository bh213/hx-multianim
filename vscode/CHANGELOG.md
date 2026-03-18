# Change Log

## [1.5.0]

### .manim grammar
- New element type: `richText`
- New filter keywords: `grayscale`, `hue`
- New color names: `brown`, `coral`, `crimson`, `darkGray`, `forestGreen`, `gold`, `indigo`, `lightGray`, `skyBlue`, `slate`, `tomato`, `wheat`
- New keywords: `align`, `angle`, `angleSpread`, `anim`, `animFile`, `animSelector`, `attachTo`, `bounds`, `boundsLine`, `burstCount`, `cellHeight`, `cells`, `cellWidth`, `centerX`, `centerY`, `click`, `colorStops`, `cols`, `condenseWhite`, `deg`, `dist`, `distRand`, `down`, `events`, `externallyDriven`, `font`, `forwardAngle`, `from`, `halign`, `horizontalAlign`, `hover`, `images`, `layouts`, `middle`, `onBounce`, `push`, `rad`, `rotate`, `rows`, `rRand`, `spawnCurve`, `styles`, `tangent`, `to`, `until`, `up`, `valign`, `verticalAlign`
- Removed stale: `reference` (now `staticRef`), `component` (now `dynamicRef`), `relativeLayouts` (now `layouts`), `colorStart`/`colorEnd`/`colorMid`/`colorMidPos` (now `colorStops`), `html`, `trailEnabled`/`trailLength`/`trailFadeOut`

### .anim grammar
- New keywords: `anim`, `filters`
- New directive: `@final`

## [1.4.0]

### .manim grammar
- New element types: `dynamicRef`, `staticRef`, `slotContent`
- New type keyword: `tile`
- New keywords: `colorCurve`, `corner`, `cube`, `doubled`, `edge`, `error`, `even`, `odd`, `pathguide`, `pingPong`
- Removed stale keywords: `function`, `gridWidth`, `gridHeight`

## [1.3.0]

### .manim grammar
- New element types: `curves`, `data`, `mask`, `atlas2`
- New @ directives: `@tint`, `@pos`, `@filter`, `@blendMode`, `@final`
- New type names: `array`, `record`
- Easing function highlighting: `linear`, `easeInQuad`, `easeOutQuad`, `easeInOutQuad`, `easeInCubic`, `easeOutCubic`, `easeInOutCubic`, `easeInBack`, `easeOutBack`, `easeInOutBack`, `easeOutBounce`, `easeOutElastic`, `cubicBezier`
- New color names: `maroon`, `olive`, `lime`, `fuchsia`, `teal`, `aqua`, `navy`, `silver`
- New path commands: `close`, `lineTo`, `lineAbs`, `moveTo`, `moveAbs`, `spiral`, `wave`, `bezierAbs`
- Particle trail properties: `trailEnabled`, `trailLength`, `trailFadeOut`
- Sub-emitter support: `subEmitters`, `groupId`, `probability`, `inheritVelocity`, `offsetX`, `offsetY`, `onBirth`, `onDeath`, `onCollision`, `onInterval`
- Animated path curves: `speedCurve`, `scaleCurve`, `alphaCurve`, `rotationCurve`, `progressCurve`, `custom`
- Data/curve keywords: `easing`, `duration`, `points`, `record`, `type`
- Other new keywords: `dx`, `dy`, `multiline`, `tint`, `width`, `blob47`, `distance`, `time`, `as`, `knockout`, `smoothColor`

### .anim grammar
- Conditional directives: `@if(...)`, `@ifStrict(...)`, `@else`, `@default`
- Negation operator `!=` and comparison operators in conditionals
- Multi-value matching `[v1,v2]` in conditionals

### Packaging
- Extension now packaged as `.vsix` using `@vscode/vsce`
- Install via `code --install-extension` instead of manual file copy
- Added `.vscodeignore` for clean packages

## [1.2.0]

- Adds step iterator support
- Script update

## [1.1.0]

- Adds `.anim` file support

## [1.0.0]

- Initial release
