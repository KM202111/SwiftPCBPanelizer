# SwiftPCBPanelizer for macOS

A macOS SwiftUI app for panelizing EAGLE `.brd` and KiCad `.kicad_pcb` boards.

Initially, I tried building the app using the C# GerberPanelizer code as a reference. The current app is written from scratch without referring to that code.

The current code takes inspiration from SWITCHSCIENCE's Python script:
`https://github.com/SWITCHSCIENCE/eagle-panelize`

That script is the basis for this app; projects such as `kitkit` were not consulted.

Panelizing boards in both EAGLE and KiCad was cumbersome, so this app was created by ChatGPT.

## License

MIT License. See the `LICENSE` file for the full terms.

## Build and run

Open `SwiftPCBPanelizer.xcodeproj`, select the `SwiftPCBPanelizer` scheme, then use **Product > Run** (⌘R). Requires macOS 14 or later and Xcode.

## App icon

The icon uses the single black-and-gold PCB from the upper-right 100px example in the latest user-provided image, with a central gold IC and a pale continuous inner outline. Transparent outer padding is removed so the rounded-square body reaches all four canvas edges. It is included in both Debug and Release builds, with all ten macOS sizes from 16 to 1024 pixels. The sidebar loads the bundled `PanelizerArtwork` image directly. At launch, the app explicitly applies that same image to the Dock, avoiding stale system icon caches. The transparent PNG source, packaging script and actual-size Dock previews at 40, 64 and 100 pixels are documented in `Design/AppIcon/README.md`.

## Text size

Interface text defaults to 115% of the previous size. Use **Text size** in the main window's toolbar to adjust it from 100% to 160%. The native slider thumb is visible by default, including before hovering or focusing. The slider moves continuously while text size updates in all windows in real time, with layout updates coalesced to at most 30 per second. Values below one percent are retained during dragging; release the slider to save the final whole-percent preference for the next launch. Saving cancels pending previews so an older value cannot overwrite the final choice. The fixed-size native popover is anchored to the window rather than the resizing toolbar, so layout changes do not replace the slider or its anchor. The same slider is available in the app's Settings. The artwork preview has no text-size button; its interface text follows this shared setting. **Reset to default (115%)** restores the initial size.

## Source text constants

All string and character literals used by the application are declared as immutable constants in `Sources/SwiftPCBPanelizer/TextConstants.swift`, grouped by feature, shared values and parser characters. English, Japanese and German values retain the existing OS-language selection. Character tokens and SwiftUI localized keys retain their original types.

Variable text uses constant `TextTemplate` or `LocalizedIntegerTemplate` definitions. Their ordered `%@` markers are filled without printf processing or recursive substitution; literal percent signs and inserted values remain unchanged. Existing printf format strings continue to use their original formatting API. Source comments describe constant locations, template contracts and types in English, Japanese and German. Build configuration files and parser fixtures retain their own required syntax.

## Workflow

1. Add one or more `.brd` or `.kicad_pcb` files, or drop them into the window.
2. For one source, set rows and columns to repeat it. For multiple sources, each board is placed once in one shared panel; columns control wrapping and rows are calculated automatically. Row heights follow the tallest board in that row.
3. Set horizontal and vertical gaps, frame clearance and widths, optional tabs, perforations, guide lines and mounting holes.
4. Save one panel board with the save dialog. The source files remain unchanged.

EAGLE processing follows the structure and options of `panelize.py` from SWITCHSCIENCE/eagle-panelize: the board outline comes from Dimension layer 20, `plain`, `elements`, and `signals` are duplicated, existing V-score wires on layer 102 are expanded, and a new panel border and optional corner holes are added.

KiCad processing parses the board S-expression and obtains the outline from `Edge.Cuts`. It places board elements and assigns unique UUIDs and internal footprint reference names to copied elements. Panel outlines, separation guide lines and mounting holes can be added. The preview displays the original board contours and the routing that combines the boards, frame and tabs.

## Default panel settings

New panels start with these settings. All lengths are in millimetres.

| Setting | Default |
| --- | --- |
| Columns × rows | 2 × 2 |
| Horizontal / vertical board gap | 2 / 2 |
| Left/right and top/bottom frame widths | 10 / 10 |
| Frame clearance / panel corner radius | 2 / 2 |
| Outline line width | 0.01 |
| Breakaway tabs | Enabled, width 3, two per edge |
| Frame connections / neighboring board connections | All four sides enabled / enabled |
| Mouse-bite perforations | Enabled, hole diameter 0.5, pitch 1 |
| Separation guides | Disabled |
| Four corner mounting holes | Enabled, X/Y edge insets 3 / 3, drill diameter 3.2 |

## Parser regression checks

From this project directory:

```sh
swiftc Sources/SwiftPCBPanelizer/TextConstants.swift Sources/SwiftPCBPanelizer/EaglePanelEngine.swift Sources/SwiftPCBPanelizer/KiCadPanelEngine.swift Sources/SwiftPCBPanelizer/PanelRouting.swift Sources/SwiftPCBPanelizer/PanelComposition.swift Checks/ParserRegression.swift -o /tmp/ParserRegression
/tmp/ParserRegression
```

These checks cover XML sibling hierarchy, element/contact references, the KiCad root token, panel dimensions, footprint-local pad coordinates, and reading the generated board again. They also cover trailing data, invalid UTF-8, excessive nesting, non-finite or excessive settings, source-file aliases, arc validation, preview-task cancellation and termination of a child process that ignores SIGTERM. Optional `--samples --eagle <path> --kicad <path>` arguments additionally exercise real EAGLE, KiCad and mixed panel exports through the installed KiCad CLI.

Note: ChatGPT wrote this explanation, but I do not fully understand it.

## Frame clearance and tabs

Frame widths specify solid rail material. Frame clearance is a separate distance between the board array and the inner face of the frame. The panel dimensions include both distances on each side.

Set both frame widths and clearance above zero, then enable breakaway tabs. Configure the tab width, count per edge, frame sides and optional links between neighboring boards. Board-to-board links require positive row/column spacing. Tabs have mouse-bite perforations enabled by default: 0.5 mm NPTH holes at 1.0 mm pitch, on both attachment interfaces. Hole diameter and pitch are editable. EAGLE outputs plain holes; KiCad outputs hidden-label NPTH footprints. Perforations can be disabled to keep solid bridges.

Frame tabs attach only to visible straight outline sections that can contain the complete tab width and perforation holes. This also applies to nonrectangular boards. Original arcs and circles remain ineligible even though routing approximates them with segments. Curved sections, corners and short straight sections are skipped without forced bridges or holes. Neighboring-board tabs follow the same rule for both identical arrays and heterogeneous panels, across rows and columns. A tab is generated only where the facing straight sections of both boards overlap enough to contain the full tab width and holes. If either side is an arc, curved section or too short, that connection and its perforations are omitted. Irregular boards whose frame tabs are intentionally omitted are not rejected for lacking a frame connection.

Routed output combines the frame, boards and bridge material before emitting the cutting boundary (Dimension 20 / Edge.Cuts). Board holes remain holes. Arcs are approximated with a maximum chord deviation of 0.005 mm when clearance/tab routing is enabled. Outlines must be closed. The preview displays the actual board contours. Dotted colored source contours identify each board; solid panel routing shows the cuts around the material and tabs.

UI and error messages support English, Japanese and German. The app uses the first supported language in the OS preferred-language list, including regional German variants such as de-DE, de-AT and de-CH, and falls back to English if none match. There is no app-specific language switch.

The panel outer corners default to R2 mm when a frame is present. Set the panel corner radius to zero to use square corners. The radius is limited by half the panel width/height. Corner geometry follows the same maximum 0.005 mm chord deviation as routed outlines. The panel envelope dimensions remain unchanged.

## Original silkscreen labels

Panel copies keep unique component identifiers for board connectivity, while visible reference labels retain the original board spelling. KiCad reference fields on copies are hidden and replaced by ordinary footprint text with the same position, rotation, layer and effects; `${REFERENCE}` in footprint text is frozen to its source value. Hidden labels stay hidden. EAGLE moved/smashed NAME attributes become fixed plain text, retaining their display settings and coordinates, while copied element/contact references remain consistent. Package NAME/VALUE labels are resolved within their own library.

Re-export from the original board to apply this behavior to a previously generated panel.

## Heterogeneous panels

Drop multiple files together, or add files to the existing list. All listed designs share one output panel. Each drop is collected before importing, preserving the order supplied by drag and drop so that asynchronous file loading does not reorder the boards.

Duplicate source paths are skipped. Files that cannot be read are listed with their names and reasons, while successfully loaded boards remain available. Each source is placed once, wrapping at the specified column count. Rows are calculated automatically, and each row follows the height of its tallest board. With only one source file, the board is repeated according to the row and column counts.

| Sources | Output | Requirements |
| --- | --- | --- |
| EAGLE only | One `.brd` | Native processing |
| KiCad only | One `.kicad_pcb` | Native processing |
| EAGLE + KiCad | One `.kicad_pcb` | KiCad 10 or later installed |

Cross-format panels use the installed KiCad PCB import command with the EAGLE importer. SwiftPCBPanelizer searches `/Applications/KiCad/KiCad.app`, `/Applications/KiCad.app`, the matching paths in `~/Applications`, and the standard Homebrew CLI locations. Original data is converted in a temporary directory and removed after importing. Install KiCad 10 or later if the conversion command is unavailable.

Before conversion, plain EAGLE rectangles on tRestrict (41), bRestrict (42), and vRestrict (43) become equivalent polygons in the temporary copy. This avoids KiCad 10 importing these rectangles as zones on `UNDEFINED`. Rectangle bounds and rotation are preserved, as are the front/back copper restrictions and via restrictions. The original board file is unchanged. This also applies to detailed previews of EAGLE panels.

EAGLE output uses plain decimal numbers so that near-zero rounding errors cannot become displaced holes or other geometry when KiCad imports exponent notation. Numeric geometry attributes in older EAGLE exports are also normalized in the temporary import copy before conversion.

Components, nets, UUIDs and EAGLE libraries are namespaced per source. Visible silkscreen labels retain their original spelling. KiCad group membership is remapped across the whole source board. Both numeric-net and named-net KiCad formats are handled. EAGLE net classes are preserved within EAGLE's 16-class limit.

Common panel settings, including stack-up and board thickness, come from the first KiCad board in the list for mixed-format panels, or the first board for panels using one format. Copper layer counts and order must agree across all boards.

Layer references are normalized after EAGLE conversion and before panel output. Imported reference/value fields on undefined layers receive the corresponding silk/fabrication layer; other unmapped annotations are retained on the comments layer. Positions, text and visibility are preserved. Layer aliases are resolved, required standard definitions are added, and the layer table precedes setup and geometry. Electrical items with undefined layers produce an error identifying the item type instead of being assigned to an arbitrary copper layer.

Heterogeneous routing uses each placed board's contours. Tabs connect to a visible neighboring board or frame without passing through another board; overlapping spans too narrow for a tab are skipped. When tabs are enabled, export prompts for settings changes if a rectangular board cannot be connected to the frame. Full-panel separation guides are generated only along lines that do not cross another board. Frame and mouse-bite settings apply to the complete panel.

## Detailed artwork preview

Click **Open artwork preview** below the layout preview. A separate resizable window displays a vector image of the bare panel: green solder mask, covered copper traces, gold exposed copper, white silkscreen, routed gaps, tabs and drilled holes.

| Operation | Control |
| --- | --- |
| Select the displayed side | Switch between the front and the back viewed from below. |
| Zoom in or out | Spread or pinch two fingers on the trackpad over the preview area, or use the zoom buttons. The range is 25–800%. |
| Check the zoom level | The toolbar percentage stays synchronized with pinch gestures and the zoom buttons. |
| Fit the complete panel | Click **Fit** to return to the 100% fitted view. |
| Move around an enlarged view | Scroll within the preview area. |
| Save the displayed side | Click **Save PNG** to export a PNG image with transparency. |

Pinch zoom uses the point under your fingers as its anchor, within the available scroll range. Zoom is preserved when switching sides. To adjust interface text, use **Text size** in the main window or the app's Settings; the artwork preview has no separate text-size button.

PNG export captures the complete panel independently of the window zoom, targeting 300 dpi and scaling down large panels to at most 8,192 pixels per side and 16,777,216 pixels in total.

Generation runs in the background only when requested. Each window holds a snapshot of the settings used to create it; click the main window's button again after changing the layout. The existing layout preview remains available while editing. All newly exported panels, including single-source arrays, use the same material-union routing as the detailed preview, avoiding duplicate overlapping outer outlines.

Detailed preview requires installed **KiCad 10 or later** for every input format. It composes the actual export board, uses KiCad's EAGLE importer when necessary, then obtains copper, solder-mask openings and silkscreen through the KiCad SVG exporter. Layer coordinates and stroked text geometry are retained, and the board outlines and drill holes are combined with the rendered layers.

The internal SVG includes its own colors, masks and geometry. Saved PNG files preserve this appearance and transparent holes without requiring linked image files. Input files remain unchanged and temporary plotting files are removed after generation.

## Validation and limits

`PanelLimits` defines separate limits for signed coordinates (mm), measurements (mm), placement count, generated holes, parser depth and file size. These are numerical and resource limits; fabrication requirements remain separate. Function boundaries validate input values and results, including finite values, closed outlines, hole placement, serialized output and agreement between exported geometry and reported dimensions. Source comments describe function roles, variable units, valid ranges and the reasons for checks in English (EN), Japanese (JA) and German (DE). These languages are written together in the source; they do not switch with the OS locale. The canonical MIT license text, SPDX identifiers and tool directives remain unchanged. Control-flow statements always include braces.

Regression checks include four- and six-layer EAGLE/KiCad panels, inner-copper preservation and rejection of different copper layer counts or order. Mixed-format checks use the installed KiCad importer when `--samples` is supplied.
