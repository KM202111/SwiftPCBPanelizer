// SPDX-License-Identifier: MIT
/*
MIT License

Copyright (c) 2026 SwiftPCBPanelizer contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

import Foundation
import SwiftUI
import AppKit
import WebKit
import UniformTypeIdentifiers
import ImageIO

// EN: String/character literals are defined in TextConstants.Artwork, Common and Characters; variable text uses constant templates.
// JA: 文字列・文字リテラルはTextConstants.Artwork・Common・Charactersに定義し、可変文は定数テンプレートから生成する。
// DE: Zeichenketten-/Zeichenliterale stehen in TextConstants.Artwork, Common und Characters; variable Texte nutzen konstante Vorlagen.

enum PanelArtworkFace: String, CaseIterable, Identifiable {
    case front, back
    var id: Self { self }
    var title: String {
        self == .front
            ? L10n.text(
                TextConstants.Artwork.frontEnglish, TextConstants.Artwork.frontJapanese,
                TextConstants.Artwork.frontGerman)
            : L10n.text(
                TextConstants.Artwork.backViewedFromBelowEnglish, TextConstants.Artwork.backViewedFromBelowJapanese,
                TextConstants.Artwork.backViewedFromBelowGerman)
    }
}

struct PanelArtwork {
    let frontSVG: String
    let backSVG: String
    let boardCount: Int
    let widthMM: Double
    let heightMM: Double
    /// EN: Return front/back SVG validated by generate. Selecting a side does not change the source data.
    ///
    /// JA: generateで検証済みの表面または裏面SVGを返す。面の選択で元データは変更しない。
    ///
    /// DE: Das durch generate geprüfte SVG der Vorder- oder Rückseite zurückgeben. Die Seitenauswahl ändert die
    ///     Quelldaten nicht.
    func svg(for face: PanelArtworkFace) -> String { face == .front ? frontSVG : backSVG }
}

/// EN: Render a snapshot of the exact board sent to export. KiCad supplies the copper, mask openings and stroked silk
///     text; our SVG adds the PCB substrate, routed voids, drill holes and a consistent physical appearance.
///
/// JA: 出力する基板そのもののスナップショットを描画する。KiCadが銅箔・マスク開口・線で描くシルク文字を提供し、このSVG合成で基材・切り抜き・穴と一貫した外観を加える。
///
/// DE: Einen Schnappschuss genau der zu exportierenden Platine rendern. KiCad liefert Kupfer, Maskenöffnungen und als
///     Konturen gezeichnete Schrift des Bestückungsdrucks; unser SVG ergänzt Substrat, Ausfräsungen, Bohrungen und
///     ein einheitliches Erscheinungsbild.
enum PanelArtworkRenderer {
    /// EN: Generate the same board as export from the input settings; return SVG with validated KiCad artwork, holes
    ///     and dimensions.
    ///
    /// JA: 入力設定から出力と同じ基板を生成し、KiCadの描画結果・穴・寸法を検証したSVGを返す。
    ///
    /// DE: Aus den Eingabeeinstellungen dieselbe Platine wie beim Export erzeugen; SVG mit geprüfter
    ///     KiCad-Darstellung, Bohrungen und Abmessungen zurückgeben.
    static func generate(sources: [PanelSource], options: PanelOptions, progress: (String) -> Void) throws
        -> PanelArtwork
    {
        try PanelRouting.validate(options.forSourceCount(sources.count))
        guard !sources.isEmpty && sources.count <= PanelLimits.maxBoardPositions else {
            throw PanelValidation.invalid(
                TextConstants.Artwork.tokenPanelArtworkRendererSources, TextConstants.Artwork.textNonemptyBoundedInput)
        }
        guard let executable = KiCadImporter.executable else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Artwork.detailedArtworkPreviewRequiresKiCadOrLaterInstallKiCadEnglish,
                    TextConstants.Artwork.detailedArtworkPreviewRequiresKiCadOrLaterInstallKiCadJapanese,
                    TextConstants.Artwork.detailedArtworkPreviewRequiresKiCadOrLaterInstallKiCadGerman
                ))
        }
        progress(
            L10n.text(
                TextConstants.Artwork.creatingThePanelBoardEnglish, TextConstants.Artwork.creatingThePanelBoardJapanese,
                TextConstants.Artwork.creatingThePanelBoardGerman))
        let panel = try PanelComposer.compose(sources: sources, options: options)
        let data: Data
        if panel.fileExtension == TextConstants.Common.tokenBrd {
            progress(
                L10n.text(
                    TextConstants.Artwork.preparingEAGLEArtworkEnglish,
                    TextConstants.Artwork.preparingEAGLEArtworkJapanese,
                    TextConstants.Artwork.preparingEAGLEArtworkGerman))
            data = try KiCadImporter.convertEagle(
                PanelSource(name: TextConstants.Artwork.tokenPCBPanelBrd, data: panel.data, kind: .eagle))
        } else {
            data = panel.data
        }
        let shape = try KiCadPanelEngine.shape(data: data)
        let drills = try KiCadPanelEngine.previewDrills(data: data)
        let fm = FileManager.default
        let work = fm.temporaryDirectory.appendingPathComponent(
            TextConstants.Artwork.tokenSwiftPCBPanelizerArtwork + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: work) }
        let input = work.appendingPathComponent(TextConstants.Artwork.tokenPanelKicadPcb)
        try data.write(to: input)
        var images: [PanelArtworkFace: String] = [:]
        for face in PanelArtworkFace.allCases {
            let prefix = face == .front ? TextConstants.Artwork.letterUpperF : TextConstants.Artwork.letterUpperB
            var layers: [String: String] = [:]
            for layer in [
                TextConstants.Artwork.tokenCu, TextConstants.Artwork.tokenMask, TextConstants.Artwork.tokenSilkS,
            ] {
                progress(
                    L10n.text(
                        TextConstants.Artwork.renderingFaceTitleLayerEnglishTemplate(face.title, layer),
                        TextConstants.Artwork.renderingFaceTitleLayerJapaneseTemplate(face.title, layer),
                        TextConstants.Artwork.renderingFaceTitleLayerGermanTemplate(face.title, layer)))
                let output = work.appendingPathComponent(TextConstants.Artwork.tokenSvgTemplate(prefix, layer))
                // EN: Page mode 1 and scale 1 preserve world coordinates for all layers. The final SVG is cropped to
                //     the panel outline below.
                // JA: ページモード1・倍率1で全レイヤーのワールド座標を保持する。完成SVGは後段でパネル外形に合わせて切り詰める。
                // DE: Seitenmodus 1 und Maßstab 1 erhalten die Weltkoordinaten aller Lagen. Das fertige SVG wird
                //     anschließend auf die Panelkontur zugeschnitten.
                try run(
                    executable,
                    arguments: [
                        TextConstants.Common.tokenPcb, TextConstants.Artwork.tokenExport,
                        TextConstants.Artwork.tokenSvg, TextConstants.Artwork.tokenLayers,
                        TextConstants.Artwork.qualifiedLayerNameTemplate(prefix, layer),
                        TextConstants.Artwork.tokenModeSingle, TextConstants.Artwork.tokenPageSizeMode,
                        TextConstants.Common.number1, TextConstants.Artwork.tokenScale, TextConstants.Common.number1,
                        TextConstants.Artwork.tokenExcludeDrawingSheet, TextConstants.Artwork.tokenBlackAndWhite,
                        TextConstants.Artwork.tokenDrillShapeOpt, TextConstants.Common.number0,
                        TextConstants.Common.tokenOutput, output.path, input.path,
                    ], work: work)
                layers[layer] = try String(contentsOf: output, encoding: .utf8)
            }
            guard let copper = layers[TextConstants.Artwork.tokenCu],
                let mask = layers[TextConstants.Artwork.tokenMask], let silk = layers[TextConstants.Artwork.tokenSilkS]
            else {
                throw PanelValidation.invalid(
                    TextConstants.Artwork.tokenArtworkLayers, TextConstants.Artwork.tokenCuMaskSilkS)
            }
            images[face] = try assemble(
                shape: shape, drills: drills, copper: copper, mask: mask, silk: silk, face: face)
        }
        guard let front = images[.front], let back = images[.back] else {
            throw PanelValidation.invalid(TextConstants.Artwork.tokenArtworkFaces, TextConstants.Artwork.tokenFrontBack)
        }
        return PanelArtwork(
            frontSVG: front, backSVG: back,
            boardCount: sources.count > 1 ? sources.count : options.columns * options.rows,
            widthMM: shape.bounds.maxX - shape.bounds.minX, heightMM: shape.bounds.maxY - shape.bounds.minY)
    }

    /// EN: Render with validated executable and arguments. Check the exit code and wait for termination after a
    ///     timeout.
    ///
    /// JA: 検証済みの実行ファイルと引数で描画する。終了コードを確認し、タイムアウト時は終了を待つ。
    ///
    /// DE: Mit geprüfter ausführbarer Datei und geprüften Argumenten rendern. Den Exitcode prüfen und nach einem
    ///     Timeout auf das Prozessende warten.
    private static func run(_ executable: URL, arguments: [String], work: URL) throws {
        let log = work.appendingPathComponent(TextConstants.Artwork.tokenPlotLog)
        FileManager.default.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        defer { try? handle.close() }
        let task = Process()
        task.executableURL = executable
        task.arguments = arguments
        task.standardOutput = handle; task.standardError = handle
        let finished = DispatchSemaphore(value: 0)
        task.terminationHandler = { _ in finished.signal() }
        try task.run()
        guard finished.wait(timeout: .now() + 120) != .timedOut else {
            KiCadImporter.terminateAndWait(task, finished: finished)
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Artwork.artworkRenderingTimedOutTryASmallerPanelEnglish,
                    TextConstants.Artwork.artworkRenderingTimedOutTryASmallerPanelJapanese,
                    TextConstants.Artwork.artworkRenderingTimedOutTryASmallerPanelGerman))
        }
        guard task.terminationStatus == 0 else {
            let details = (try? String(contentsOf: log, encoding: .utf8)) ?? TextConstants.Common.empty
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Artwork.kicadCouldNotRenderThePanelDetailsSuffixEnglishTemplate(details.suffix(1600)),
                    TextConstants.Artwork.kicadCouldNotRenderThePanelDetailsSuffixJapaneseTemplate(
                        details.suffix(1600)),
                    TextConstants.Artwork.kicadCouldNotRenderThePanelDetailsSuffixGermanTemplate(details.suffix(1600))))
        }
    }

    /// EN: Convert validated dimensions to locale-independent SVG strings.
    ///
    /// JA: 検証済み寸法をSVG用のロケール非依存文字列へ変換する。
    ///
    /// DE: Geprüfte Abmessungen in sprachunabhängige SVG-Zeichenketten umwandeln.
    private static func number(_ value: Double) -> String {
        String(
            format: TextConstants.Artwork.artworkNumberFormat,
            locale: Locale(identifier: TextConstants.Common.posixLocaleIdentifier), value)
    }
    /// EN: Convert validated closed contours [mm] to SVG paths. Do not draw empty contours.
    ///
    /// JA: 検証済みの閉ループ [mm] をSVGパスへ変換する。空ループは描画しない。
    ///
    /// DE: Geprüfte geschlossene Konturen [mm] in SVG-Pfade umwandeln. Leere Konturen nicht zeichnen.
    private static func path(_ loops: [[RoutePoint]]) -> String {
        loops.compactMap { loop in
            guard let first = loop.first else { return nil }
            return TextConstants.Artwork.textMTemplate(number(first.x), number(first.y))
                + loop.dropFirst().map { TextConstants.Artwork.textLTemplate(number($0.x), number($0.y)) }.joined(
                    separator: TextConstants.Common.space) + TextConstants.Artwork.tokenZ
        }.joined(separator: TextConstants.Common.space)
    }
    /// EN: Create SVG slots or circular holes from validated centers, dimensions [mm] and rotation [degrees].
    ///
    /// JA: 検証済み穴中心・寸法 [mm]・回転 [度] からSVGの長穴または円形穴を作る。
    ///
    /// DE: SVG-Langlöcher oder kreisförmige Bohrungen aus geprüften Mittelpunkten, Abmessungen [mm] und Drehwinkeln
    ///     [Grad] erstellen.
    private static func hole(_ drill: PanelPreviewDrill, fill: String, stroke: String = TextConstants.Common.tokenNone)
        -> String
    {
        TextConstants.Artwork.markupRectXYWidthHeightRxFillTemplate(
            number(drill.center.x - drill.width / 2), number(drill.center.y - drill.height / 2), number(drill.width),
            number(drill.height), number(min(drill.width, drill.height) / 2), fill, stroke, number(drill.angle),
            number(drill.center.x), number(drill.center.y))
    }

    /// EN: Validate outlines, holes and layer SVGs, then compose a standalone finished SVG.
    ///
    /// JA: 外形・穴・各層のSVGを検証し、単独表示できる完成SVGへ合成する。
    ///
    /// DE: Konturen, Bohrungen und Lagen-SVGs prüfen und zu einem eigenständig darstellbaren fertigen SVG
    ///     zusammensetzen.
    private static func assemble(
        shape: PanelBoardShape, drills: [PanelPreviewDrill], copper: String, mask: String, silk: String,
        face: PanelArtworkFace
    ) throws -> String {
        try PanelValidation.shape(shape, field: TextConstants.Artwork.tokenAssembleShape)
        try PanelValidation.drills(drills)
        let b = shape.bounds
        let margin = max(1.5, min(b.maxX - b.minX, b.maxY - b.minY) * 0.025)
        let x = b.minX - margin, y = b.minY - margin, w = b.maxX - b.minX + margin * 2, h = b.maxY - b.minY + margin * 2
        let viewBox = TextConstants.Artwork.viewBoxTemplate(number(x), number(y), number(w), number(h))
        let boardPath = path(shape.contours)
        let holes = drills.filter { face == .front ? $0.front : $0.back }
        let copperGreen = try layerContents(
            copper, color: TextConstants.Artwork.colorHex358268, prefix: TextConstants.Artwork.tokenCovered)
        let copperGold = try layerContents(
            copper, color: TextConstants.Artwork.colorHexD9BA70, prefix: TextConstants.Artwork.tokenExposed)
        let openings = try layerContents(
            mask, color: TextConstants.Artwork.colorHexFFFFFF, prefix: TextConstants.Artwork.tokenOpenings)
        let silkscreen = try layerContents(
            silk, color: TextConstants.Artwork.colorHexF2F1DF, prefix: TextConstants.Artwork.tokenSilk)
        let transform =
            face == .back
            ? TextConstants.Artwork.textTranslateScaleTemplate(number(b.minX + b.maxX))
            : TextConstants.Artwork.textTranslate
        let result = TextConstants.Artwork.finishedPanelSVGTemplate(
            number(w), number(h), viewBox, face.rawValue, boardPath, number(x), number(y), number(w), number(h),
            number(x), number(y), number(w), number(h),
            holes.map { hole($0, fill: TextConstants.Artwork.tokenBlack) }.joined(), number(x), number(y), number(w),
            number(h), number(x), number(y), number(w), number(h), openings, transform, copperGreen, copperGold,
            silkscreen,
            holes.map { hole($0, fill: TextConstants.Common.tokenNone, stroke: TextConstants.Artwork.colorHex183B31) }
                .joined())
        try PanelValidation.document(Data(result.utf8), field: TextConstants.Artwork.tokenAssembleOutputSVG)
        let parsed = try XMLDocument(xmlString: result, options: [.nodeLoadExternalEntitiesNever])
        guard parsed.rootElement()?.localName == TextConstants.Artwork.tokenSvg else {
            throw PanelValidation.invalid(TextConstants.Artwork.tokenAssembleOutputSVG, TextConstants.Artwork.tokenSVG)
        }
        return result
    }

    /// EN: Preserve KiCad's precise geometry and text strokes while changing only paint colors. Keep fill:none,
    ///     opacity and stroke widths intact.
    ///
    /// JA: 描画色だけを変え、KiCadの正確な図形と文字ストロークを保持する。fill:none・不透明度・線幅を維持する。
    ///
    /// DE: Nur die Farben ändern und KiCads exakte Geometrie und Schriftkonturen erhalten. fill:none, Deckkraft und
    ///     Strichbreiten beibehalten.
    private static func layerContents(_ source: String, color: String, prefix: String) throws -> String {
        try PanelValidation.document(Data(source.utf8), field: TextConstants.Artwork.tokenLayerContentsInputSVG)
        let document = try XMLDocument(xmlString: source, options: [.nodeLoadExternalEntitiesNever])
        guard let root = document.rootElement(), root.localName == TextConstants.Artwork.tokenSvg else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Artwork.kicadReturnedAnInvalidSVGImageEnglish,
                    TextConstants.Artwork.kicadReturnedAnInvalidSVGImageJapanese,
                    TextConstants.Artwork.kicadReturnedAnInvalidSVGImageGerman))
        }
        var ids: [String: String] = [:]
        /// EN: Collect SVG IDs and map them to new IDs that do not collide with other layers.
        ///
        /// JA: SVG内のIDを収集し、別レイヤーと重複しない新IDの対応表を作る。
        ///
        /// DE: SVG-IDs sammeln und auf neue IDs abbilden, die mit keiner anderen Lage kollidieren.
        func collect(_ element: XMLElement) {
            if let id = element.attribute(forName: TextConstants.Artwork.tokenId)?.stringValue { ids[id] = prefix + id }
            for case let child as XMLElement in element.children ?? [] { collect(child) }
        }
        collect(root)
        /// EN: Reconcile SVG colors and ID references, preserving coordinates, text strokes and transparency.
        ///
        /// JA: SVGの色とID参照を整合させる。座標・文字のストローク・透過設定は維持する。
        ///
        /// DE: SVG-Farben und ID-Verweise abstimmen; Koordinaten, Schriftkonturen und Transparenzeinstellungen
        ///     beibehalten.
        func recolor(_ element: XMLElement) {
            for attribute in element.attributes ?? [] {
                guard let name = attribute.name, var value = attribute.stringValue else { continue }
                if name == TextConstants.Artwork.tokenStyle {
                    value = value.components(separatedBy: TextConstants.Common.semicolon).map { declaration in
                        let parts = declaration.split(separator: TextConstants.Characters.colon, maxSplits: 1).map {
                            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        guard parts.count == 2,
                            [TextConstants.Common.tokenFill, TextConstants.Common.tokenStroke].contains(parts[0]),
                            ![TextConstants.Common.tokenNone, TextConstants.Artwork.tokenTransparent].contains(
                                parts[1]), !parts[1].hasPrefix(TextConstants.Artwork.tokenUrl)
                        else { return declaration }
                        return parts[0] + TextConstants.Common.colon + color
                    }.joined(separator: TextConstants.Common.semicolon)
                } else if [TextConstants.Common.tokenFill, TextConstants.Common.tokenStroke].contains(name),
                    value != TextConstants.Common.tokenNone, value != TextConstants.Artwork.tokenTransparent,
                    !value.hasPrefix(TextConstants.Artwork.tokenUrl)
                {
                    value = color
                }
                if name == TextConstants.Artwork.tokenId, let replacement = ids[value] { value = replacement }
                for (old, new) in ids {
                    value = value.replacingOccurrences(
                        of: TextConstants.Artwork.markupUrlTemplate(old),
                        with: TextConstants.Artwork.markupUrlTemplate(new));
                    if value == TextConstants.Artwork.hashMark + old {
                        value = TextConstants.Artwork.hashMark + new
                    }
                }
                attribute.stringValue = value
            }
            for case let child as XMLElement in element.children ?? [] { recolor(child) }
        }
        recolor(root)
        return (root.children ?? []).filter {
            ![TextConstants.Artwork.tokenTitle, TextConstants.Artwork.tokenDesc].contains(
                $0.name ?? TextConstants.Common.empty)
        }.map(\.xmlString).joined(
            separator: TextConstants.Common.newline)
    }
}

@MainActor
final class PanelArtworkWindowController: NSWindowController, NSWindowDelegate {
    private static var windows: [UUID: PanelArtworkWindowController] = [:]
    private let token = UUID()

    /// EN: Open a window from display data validated during generation. Its content is a snapshot of that generation.
    ///
    /// JA: 生成時に検証済みの表示データからウィンドウを開く。表示内容は生成時点のスナップショット。
    ///
    /// DE: Ein Fenster mit den bei der Erzeugung geprüften Anzeigedaten öffnen. Sein Inhalt ist ein Schnappschuss
    ///     dieses Erzeugungsstands.
    static func show(_ artwork: PanelArtwork) {
        let controller = PanelArtworkWindowController(artwork: artwork)
        windows[controller.token] = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
    }

    private init(artwork: PanelArtwork) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 820),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title =
            TextConstants.Artwork.textSwiftPCBPanelizer
            + L10n.text(
                TextConstants.Common.artworkPreviewEnglish, TextConstants.Common.artworkPreviewJapanese,
                TextConstants.Common.artworkPreviewGerman)
        window.minSize = NSSize(width: 900, height: 560)
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: PanelArtworkView(artwork: artwork).interfaceTypography())
        window.center()
        super.init(window: window)
        window.delegate = self
    }
    required init?(coder: NSCoder) { fatalError(TextConstants.Artwork.textInitCoderIsUnavailable) }
    /// EN: Remove references to closed windows from the registry.
    ///
    /// JA: 閉じたウィンドウの参照を管理表から取り除く。
    ///
    /// DE: Verweise auf geschlossene Fenster aus der Verwaltung entfernen.
    func windowWillClose(_ notification: Notification) { Self.windows.removeValue(forKey: token) }
}

/// EN: Shared zoom limits for toolbar actions and trackpad gestures.
/// JA: ツールバー操作とトラックパッド操作で共通に使うズーム範囲。
/// DE: Gemeinsame Zoomgrenzen für Werkzeugleiste und Trackpad-Gesten.
private enum PanelArtworkZoom {
    static let minimum = 0.25
    static let maximum = 8.0
    static let step = 1.3

    static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return 1 }
        return min(maximum, max(minimum, value))
    }
}

private struct PanelArtworkView: View {
    @Environment(\.interfaceTextScale) private var textScale
    let artwork: PanelArtwork
    @State private var face: PanelArtworkFace = .front
    @State private var zoom = 1.0
    @State private var error: String?
    @State private var isSavingPNG = false
    @State private var pngExporter = PanelArtworkPNGExporter()

    var body: some View {
        VStack(spacing: 0) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 18) {
                    facePicker
                    zoomControls
                    saveControls
                }.fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 12) {
                    facePicker
                    HStack {
                        zoomControls
                        Spacer(minLength: 12)
                        saveControls
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.bordered).padding(14).background(.bar)
            Divider()
            PanelArtworkWebView(svg: artwork.svg(for: face), zoom: $zoom, pngExporter: pngExporter)
            Divider()
            HStack {
                Text(
                    L10n.text(
                        TextConstants.Artwork.bareBoardAppearanceCopperSolderMaskSilkAndDrillsEnglish,
                        TextConstants.Artwork.bareBoardAppearanceCopperSolderMaskSilkAndDrillsJapanese,
                        TextConstants.Artwork.bareBoardAppearanceCopperSolderMaskSilkAndDrillsGerman))
                Spacer()
                Text(
                    String(
                        format: TextConstants.Artwork.panelDimensionsAndBoardCountFormat, artwork.widthMM,
                        artwork.heightMM, artwork.boardCount)
                        + L10n.text(
                            TextConstants.Artwork.boardsEnglish, TextConstants.Artwork.boardsJapanese,
                            artwork.boardCount == 1
                                ? TextConstants.Artwork.tokenLeiterplatte : TextConstants.Artwork.tokenLeiterplatten))
            }.interfaceFont(.caption).foregroundStyle(.secondary).padding(12)
        }
        .alert(
            L10n.text(
                TextConstants.Artwork.cannotSavePNGEnglish, TextConstants.Artwork.cannotSavePNGJapanese,
                TextConstants.Artwork.cannotSavePNGGerman),
            isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })
        ) {
            Button(TextConstants.Common.tokenOKKey) { error = nil }
        } message: {
            Text(error ?? TextConstants.Common.empty)
        }
    }

    private var facePicker: some View {
        Picker(
            L10n.text(
                TextConstants.Artwork.sideEnglish, TextConstants.Artwork.sideJapanese, TextConstants.Artwork.sideGerman),
            selection: $face
        ) {
            ForEach(PanelArtworkFace.allCases) { side in Text(side.title).tag(side) }
        }.pickerStyle(.segmented).frame(width: 310 * textScale).disabled(isSavingPNG)
    }

    private var zoomControls: some View {
        HStack(spacing: 12) {
            Button {
                zoom = PanelArtworkZoom.clamped(zoom / PanelArtworkZoom.step)
            } label: {
                Image(systemName: TextConstants.Artwork.tokenMinusMagnifyingglass)
            }
            .help(
                L10n.text(
                    TextConstants.Artwork.zoomOutEnglish, TextConstants.Artwork.zoomOutJapanese,
                    TextConstants.Artwork.zoomOutGerman)
            )
            .accessibilityLabel(
                L10n.text(
                    TextConstants.Artwork.zoomOutEnglish, TextConstants.Artwork.zoomOutJapanese,
                    TextConstants.Artwork.zoomOutGerman))
            Text(TextConstants.Common.localizedPercentageTemplate(Int(zoom * 100))).interfaceFont(
                .caption, monospaced: true
            ).frame(width: 46 * textScale)
            Button {
                zoom = PanelArtworkZoom.clamped(zoom * PanelArtworkZoom.step)
            } label: {
                Image(systemName: TextConstants.Artwork.tokenPlusMagnifyingglass)
            }
            .help(
                L10n.text(
                    TextConstants.Artwork.zoomInEnglish, TextConstants.Artwork.zoomInJapanese,
                    TextConstants.Artwork.zoomInGerman)
            )
            .accessibilityLabel(
                L10n.text(
                    TextConstants.Artwork.zoomInEnglish, TextConstants.Artwork.zoomInJapanese,
                    TextConstants.Artwork.zoomInGerman))
            Button(
                L10n.text(
                    TextConstants.Artwork.fitEnglish, TextConstants.Artwork.fitJapanese, TextConstants.Artwork.fitGerman
                )
            ) { zoom = 1 }
        }
    }

    private var saveControls: some View {
        Button {
            savePNG()
        } label: {
            Label(
                isSavingPNG
                    ? L10n.text(
                        TextConstants.Artwork.savingPNGEnglish, TextConstants.Artwork.savingPNGJapanese,
                        TextConstants.Artwork.savingPNGGerman)
                    : L10n.text(
                        TextConstants.Artwork.savePNGEnglish, TextConstants.Artwork.savePNGJapanese,
                        TextConstants.Artwork.savePNGGerman),
                systemImage: TextConstants.Artwork.tokenSquareAndArrowDown)
        }.disabled(isSavingPNG)
    }

    /// EN: Export the selected side as PNG independently of window zoom. Keep file access until the async write ends.
    /// JA: ウィンドウの倍率に依存せず表示面をPNG出力する。非同期の保存完了までファイルのアクセス権を保持する。
    /// DE: Die gewählte Seite unabhängig vom Fensterzoom als PNG exportieren. Dateizugriff bis zum Ende des asynchronen Schreibens behalten.
    private func savePNG() {
        guard !isSavingPNG else { return }
        let selectedSVG = artwork.svg(for: face)
        let chooser = NSSavePanel()
        chooser.allowedContentTypes = [.png]
        chooser.nameFieldStringValue = TextConstants.Artwork.tokenSwiftPCBPanelizerPngTemplate(face.rawValue)
        chooser.canCreateDirectories = true
        guard chooser.runModal() == .OK, let url = chooser.url else { return }
        isSavingPNG = true
        Task { @MainActor in
            let access = url.startAccessingSecurityScopedResource()
            defer {
                if access { url.stopAccessingSecurityScopedResource() }
                isSavingPNG = false
            }
            do {
                let png = try await pngExporter.pngData(svg: selectedSVG)
                try png.write(to: url, options: .atomic)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

/// EN: Use WebKit to rasterize the entire composed artwork, including SVG masks and transparent holes.
/// JA: SVGのマスクと透過する穴を含む完成画像全体をWebKitでラスター化する。
/// DE: Die gesamte zusammengesetzte Grafik einschließlich SVG-Masken und transparenter Bohrungen mit WebKit rastern.
@MainActor
private final class PanelArtworkPNGExporter {
    weak var webView: WKWebView?

    /// EN: Validate millimetre dimensions, bound pixel memory, then verify PNG type and dimensions before returning bytes.
    /// JA: mm寸法と画素メモリの上限を確認し、PNG形式と画素寸法を検証してからデータを返す。
    /// DE: Millimetermaße und Pixelspeicher begrenzen; PNG-Format und Pixelabmessungen vor der Datenrückgabe prüfen.
    func pngData(svg: String) async throws -> Data {
        try PanelValidation.document(Data(svg.utf8), field: TextConstants.Artwork.tokenPNGInputSVG)
        let document = try XMLDocument(xmlString: svg, options: [.nodeLoadExternalEntitiesNever])
        guard let root = document.rootElement(), root.localName == TextConstants.Artwork.tokenSvg,
            let width = root.attribute(forName: TextConstants.Common.tokenWidth)?.stringValue,
            width.hasSuffix(TextConstants.Artwork.tokenMm),
            let height = root.attribute(forName: TextConstants.Common.tokenHeight)?.stringValue,
            height.hasSuffix(TextConstants.Artwork.tokenMm),
            let widthMM = Double(width.dropLast(2)), let heightMM = Double(height.dropLast(2))
        else {
            throw PanelValidation.invalid(
                TextConstants.Artwork.tokenPNGInputSVG, TextConstants.Artwork.textSVGDimensionsMm)
        }
        // EN: Allow the small transparent margin added by assemble outside the validated panel bounds.
        // JA: assembleが検証済みパネル外形の外側へ追加する小さな透過余白を許容する。
        // DE: Den von assemble außerhalb der geprüften Panelgrenzen ergänzten kleinen transparenten Rand zulassen.
        for dimension in [widthMM, heightMM] {
            try PanelValidation.number(
                dimension, field: TextConstants.Artwork.tokenPNGDimensionMM,
                range: Double.leastNonzeroMagnitude...(PanelLimits.maxMeasurementMM * 1.1))
        }
        // EN: Convert physical extents to target pixels; one common reduction preserves aspect ratio within both limits.
        // JA: 実寸を目標画素数へ変換し、共通の縮小率で縦横比を保ちながら辺長と総画素数の両上限へ収める。
        // DE: Physische Maße in Zielpixel umrechnen; ein gemeinsamer Faktor wahrt das Seitenverhältnis innerhalb beider Grenzen.
        let widthPixels = widthMM * PanelLimits.artworkPNGDPI / 25.4
        let heightPixels = heightMM * PanelLimits.artworkPNGDPI / 25.4
        let scale = min(
            1, Double(PanelLimits.maxArtworkPNGSidePixels) / widthPixels,
            Double(PanelLimits.maxArtworkPNGSidePixels) / heightPixels,
            sqrt(Double(PanelLimits.maxArtworkPNGPixelCount) / widthPixels / heightPixels))
        let pixelWidth = max(1, Int(floor(widthPixels * scale)))
        let pixelHeight = max(1, Int(floor(heightPixels * scale)))
        guard pixelWidth <= PanelLimits.maxArtworkPNGSidePixels,
            pixelHeight <= PanelLimits.maxArtworkPNGSidePixels,
            pixelWidth * pixelHeight <= PanelLimits.maxArtworkPNGPixelCount
        else {
            throw PanelValidation.invalid(
                TextConstants.Artwork.tokenPNGPixelDimensions, TextConstants.Artwork.textBoundedImageSize)
        }
        guard let webView else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Artwork.theArtworkPreviewIsNotReadyOpenItAgainEnglish,
                    TextConstants.Artwork.theArtworkPreviewIsNotReadyOpenItAgainJapanese,
                    TextConstants.Artwork.theArtworkPreviewIsNotReadyOpenItAgainGerman))
        }
        let failure = L10n.text(
            TextConstants.Artwork.theArtworkCouldNotBeConvertedToPNGPleaseEnglish,
            TextConstants.Artwork.theArtworkCouldNotBeConvertedToPNGPleaseJapanese,
            TextConstants.Artwork.theArtworkCouldNotBeConvertedToPNGPleaseGerman)
        // EN: Pass SVG as a JavaScript argument, avoiding string interpolation. Render full artwork, not the viewport.
        // JA: SVGをJavaScriptの引数で渡して文字列埋め込みを避ける。表示領域ではなく画像全体を描画する。
        // DE: SVG als JavaScript-Argument statt als interpolierten Code übergeben. Die gesamte Grafik statt des Bildausschnitts zeichnen.
        let script = TextConstants.Artwork.pngRasterizationJavaScript
        let result: Any?
        do {
            result = try await webView.callAsyncJavaScript(
                script,
                arguments: [
                    TextConstants.Artwork.tokenSvg: svg, TextConstants.Artwork.tokenPixelWidth: pixelWidth,
                    TextConstants.Artwork.tokenPixelHeight: pixelHeight,
                    TextConstants.Artwork.tokenTimeoutMS: PanelLimits.artworkPNGTimeoutMilliseconds,
                    TextConstants.Artwork.tokenFailure: failure,
                ], in: nil, contentWorld: .page)
        } catch {
            throw RoutingError.invalid(failure + TextConstants.Common.newline + error.localizedDescription)
        }
        guard let encoded = result as? String, let data = Data(base64Encoded: encoded) else {
            throw RoutingError.invalid(failure)
        }
        try PanelValidation.document(data, field: TextConstants.Artwork.tokenPNGOutput)
        guard let image = CGImageSourceCreateWithData(data as CFData, nil),
            CGImageSourceGetType(image) as String? == UTType.png.identifier,
            let properties = CGImageSourceCopyPropertiesAtIndex(image, 0, nil) as? [CFString: Any],
            (properties[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue == pixelWidth,
            (properties[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue == pixelHeight
        else { throw RoutingError.invalid(failure) }
        return data
    }
}

/// EN: Handle pinch gestures only inside the artwork, preserving the point under the fingers.
/// JA: 完成プレビュー内のピンチを処理し、指の下にある位置を保って拡大縮小する。
/// DE: Pinch-Gesten nur in der Vorschau verarbeiten und den Punkt unter den Fingern beibehalten.
private final class PanelArtworkMagnifyingWebView: WKWebView {
    var onZoomChange: ((Double) -> Void)?
    private(set) var artworkZoom = 1.0
    // EN: Magnification is cumulative within one gesture; retain its starting scale.
    // JA: ジェスチャーの倍率変化は累積値なので、開始時の倍率を保持する。
    // DE: Die Vergrößerung einer Geste ist kumulativ; ihren Ausgangszoom speichern.
    private var gestureStartZoom = 1.0

    override init(frame: NSRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        allowsMagnification = false
        addGestureRecognizer(NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinch(_:))))
    }

    required init?(coder: NSCoder) { fatalError(TextConstants.Artwork.textInitCoderIsUnavailable) }

    @objc private func handlePinch(_ recognizer: NSMagnificationGestureRecognizer) {
        if recognizer.state == .began {
            gestureStartZoom = artworkZoom
        }
        guard recognizer.state == .began || recognizer.state == .changed || recognizer.state == .ended,
            recognizer.magnification.isFinite
        else { return }
        let requested = gestureStartZoom * (1 + Double(recognizer.magnification))
        guard requested.isFinite else { return }
        let nextZoom = PanelArtworkZoom.clamped(requested)
        guard nextZoom != artworkZoom else { return }
        let point = recognizer.location(in: self)
        let anchor = NSPoint(x: point.x - bounds.minX,
                             y: isFlipped ? point.y - bounds.minY : bounds.maxY - point.y)
        applyZoom(nextZoom, anchor: anchor)
        onZoomChange?(nextZoom)
    }

    /// EN: Apply one shared CSS scale; native WebKit magnification stays disabled to avoid a second scale.
    /// JA: 共通のCSS倍率を反映する。二重に拡大されないようWebKit標準の拡大は無効にする。
    /// DE: Einen gemeinsamen CSS-Zoom anwenden; die WebKit-Vergrößerung bleibt gegen doppelte Skalierung deaktiviert.
    func applyZoom(_ value: Double, anchor: NSPoint? = nil, force: Bool = false) {
        let nextZoom = PanelArtworkZoom.clamped(value)
        guard force || nextZoom != artworkZoom else { return }
        artworkZoom = nextZoom
        let center = NSPoint(x: bounds.width / 2, y: bounds.height / 2)
        let point = anchor ?? center
        guard bounds.width > 0, bounds.height > 0, point.x.isFinite, point.y.isFinite else { return }
        let locale = Locale(identifier: TextConstants.Common.posixLocaleIdentifier)
        let factor = String(format: TextConstants.Artwork.previewZoomFormat, locale: locale, nextZoom)
        let x = String(format: TextConstants.Artwork.previewZoomFormat, locale: locale,
                       min(bounds.width, max(0, point.x)))
        let y = String(format: TextConstants.Artwork.previewZoomFormat, locale: locale,
                       min(bounds.height, max(0, point.y)))
        evaluateJavaScript(TextConstants.Artwork.artworkPreviewZoomJavaScriptTemplate(factor, x, y),
                           completionHandler: nil)
    }
}

private struct PanelArtworkWebView: NSViewRepresentable {
    let svg: String
    @Binding var zoom: Double
    let pngExporter: PanelArtworkPNGExporter

    final class Coordinator: NSObject, WKNavigationDelegate {
        var svg: String?

        /// EN: Reapply the latest zoom if a gesture occurred while the SVG document was loading.
        /// JA: SVG読込中にも倍率が変わり得るため、読込完了時に最新の倍率を反映する。
        /// DE: Nach dem Laden den neuesten Zoom anwenden, falls er sich während des SVG-Ladens geändert hat.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let view = webView as? PanelArtworkMagnifyingWebView else { return }
            view.applyZoom(view.artworkZoom, force: true)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    /// EN: Create an offline SVG view with a native pinch recognizer scoped to its preview area.
    /// JA: プレビュー領域だけでピンチを受け取る、外部通信不要のSVG表示を作る。
    /// DE: Eine Offline-SVG-Ansicht mit einem auf den Vorschaubereich begrenzten Pinch-Erkenner erstellen.
    func makeNSView(context: Context) -> PanelArtworkMagnifyingWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let view = PanelArtworkMagnifyingWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.onZoomChange = { zoom = $0 }
        pngExporter.webView = view
        return view
    }

    /// EN: Toolbar and gesture changes share the same binding and scale, including after switching sides.
    /// JA: ツールバーとピンチ操作で同じ倍率を共有し、表裏を切り替えた後も倍率を維持する。
    /// DE: Werkzeugleiste und Gesten teilen denselben Zoom, auch nach einem Seitenwechsel.
    func updateNSView(_ view: PanelArtworkMagnifyingWebView, context: Context) {
        view.onZoomChange = { zoom = $0 }
        view.applyZoom(zoom)
        if context.coordinator.svg != svg {
            context.coordinator.svg = svg
            let factor = String(format: TextConstants.Artwork.previewZoomFormat,
                                locale: Locale(identifier: TextConstants.Common.posixLocaleIdentifier),
                                PanelArtworkZoom.clamped(zoom))
            let inline = svg.replacingOccurrences(
                of: TextConstants.Artwork.markupXmlVersionEncodingUTF, with: TextConstants.Common.empty)
            view.loadHTMLString(
                TextConstants.Artwork.artworkPreviewHTMLTemplate(factor, inline), baseURL: nil)
        }
    }

    static func dismantleNSView(_ view: PanelArtworkMagnifyingWebView, coordinator: Coordinator) {
        view.onZoomChange = nil
        view.navigationDelegate = nil
    }
}
