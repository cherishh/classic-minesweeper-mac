# Screenshot production

> Status: the original draft is rejected. The Chinese first-image replacement under `candidates/editorial-cover-v3/` is ready for visual approval. The remaining `modern-teal-v2` images are awaiting copy revision. Do not upload either candidate set before approval.

## Replacement candidate

The preferred Chinese first-image candidate is `candidates/editorial-cover-v3/zh-Hans/01.png`. It adapts the supplied portrait artwork into the required 16:10 format without a teal presentation frame and uses the real default Beginner 10-mine state.

The replacement set uses modern, high-contrast marketing typography over the classic Windows desktop teal. The app itself remains pixel-authentic and is shown in the requested failure, victory, and open-menu states.

- `candidates/modern-teal-v2/en-US/`: ordered English set.
- `candidates/modern-teal-v2/zh-Hans/`: ordered Simplified Chinese set.
- `candidates/modern-teal-v2/alternatives/`: first-image alternatives.
- `candidates/modern-teal-v2/*-contact-sheet.png`: review sheets.

The Chinese first image embeds the supplied `xhs-01-cover.png` artwork intact. All candidate exports are 2880 × 1800 RGB PNGs with no alpha channel.

## Rejected original draft

Final exports are 2880 × 1800 PNG files with no alpha channel. Every app interface shown in an export comes from a real capture of the Xcode app target. Marketing copy and the `#008080` default desktop background are composited deterministically.

### Original recommendation

The six ordered images in `exports/en-US/` form one coherent set:

1. Pixel-for-pixel product hero.
2. Standard board range.
3. Familiar mouse and keyboard controls.
4. Offline, ad-free positioning.
5. Full Expert field.
6. Native interface scaling.

All outer presentation windows use the MIT-licensed `jdan/98.css` component structure. Six cover alternatives remain in `exports/alternatives/` for comparison.

The two ImageGen backgrounds under `source/generated-*.png` are retained as unused exploration only. They are not included in any recommended or alternate export because the selected visual system uses the solid default desktop color.
