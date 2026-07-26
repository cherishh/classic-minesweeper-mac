# Screenshot production

> Status: the original draft is rejected. The preferred Chinese first and last images are under `candidates/editorial-set-v4/`. Pages 02–04 are awaiting copy selection, and the former dedicated Expert page is removed. Do not upload the candidate set before approval.

## Replacement candidate

The preferred Chinese candidates are `candidates/editorial-set-v4/zh-Hans/01.png` and `05.png`. The first image adapts the supplied portrait artwork into the required 16:10 format without a teal presentation frame and uses a real Beginner state with one flag placed. The fifth image replaces both the former Expert page and the old feature-summary ending with a smiley-led CTA.

The preferred English ending is `candidates/win98-cta-v5/en-US/05.png`. It uses a dedicated Windows 98 desktop, dialog, and taskbar treatment rather than the Chinese cover’s off-white editorial direction. The English sequence also omits the former dedicated Expert page and ends at 05 of 05.

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
