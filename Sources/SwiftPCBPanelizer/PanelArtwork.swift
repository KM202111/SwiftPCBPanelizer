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

enum PanelArtworkFace: String, CaseIterable, Identifiable {
    case front, back
    var id: Self { self }
    var title: String {
        self == .front
            ? L10n.text("Front", "表面", "Oberseite")
            : L10n.text("Back (viewed from below)", "裏面（裏から見た向き）", "Unterseite (von unten)")
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
            throw PanelValidation.invalid("PanelArtworkRenderer.sources", "nonempty bounded input")
        }
        guard let executable = KiCadImporter.executable else {
            throw RoutingError.invalid(
                L10n.text(
                    "Detailed artwork preview requires KiCad 10 or later. Install KiCad in Applications and try again.",
                    "完成プレビューにはKiCad 10以降が必要です。アプリケーションフォルダーにKiCadをインストールしてから再度お試しください。",
                    "Die Fertigungsansicht erfordert KiCad 10 oder neuer. Installieren Sie KiCad im Ordner Programme und versuchen Sie es erneut."
                ))
        }
        progress(L10n.text("Creating the panel board…", "面付け基板を生成しています…", "Leiterplattennutzen wird erstellt…"))
        let panel = try PanelComposer.compose(sources: sources, options: options)
        let data: Data
        if panel.fileExtension == "brd" {
            progress(
                L10n.text("Preparing EAGLE artwork…", "EAGLEの描画データを準備しています…", "EAGLE-Grafikdaten werden vorbereitet…"))
            data = try KiCadImporter.convertEagle(PanelSource(name: "PCBPanel.brd", data: panel.data, kind: .eagle))
        } else {
            data = panel.data
        }
        let shape = try KiCadPanelEngine.shape(data: data)
        let drills = try KiCadPanelEngine.previewDrills(data: data)
        let fm = FileManager.default
        let work = fm.temporaryDirectory.appendingPathComponent(
            "SwiftPCBPanelizer-artwork-" + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: work) }
        let input = work.appendingPathComponent("panel.kicad_pcb")
        try data.write(to: input)
        var images: [PanelArtworkFace: String] = [:]
        for face in PanelArtworkFace.allCases {
            let prefix = face == .front ? "F" : "B"
            var layers: [String: String] = [:]
            for layer in ["Cu", "Mask", "SilkS"] {
                progress(
                    L10n.text(
                        "Rendering \(face.title): \(layer)…", "\(face.title)の\(layer)を描画しています…",
                        "\(face.title) wird gerendert: \(layer)…"))
                let output = work.appendingPathComponent("\(prefix)-\(layer).svg")
                // EN: Page mode 1 and scale 1 preserve world coordinates for all layers. The final SVG is cropped to
                //     the panel outline below.
                // JA: ページモード1・倍率1で全レイヤーのワールド座標を保持する。完成SVGは後段でパネル外形に合わせて切り詰める。
                // DE: Seitenmodus 1 und Maßstab 1 erhalten die Weltkoordinaten aller Lagen. Das fertige SVG wird
                //     anschließend auf die Panelkontur zugeschnitten.
                try run(
                    executable,
                    arguments: [
                        "pcb", "export", "svg", "--layers", "\(prefix).\(layer)", "--mode-single", "--page-size-mode",
                        "1", "--scale", "1", "--exclude-drawing-sheet", "--black-and-white", "--drill-shape-opt", "0",
                        "--output", output.path, input.path,
                    ], work: work)
                layers[layer] = try String(contentsOf: output, encoding: .utf8)
            }
            guard let copper = layers["Cu"], let mask = layers["Mask"], let silk = layers["SilkS"] else {
                throw PanelValidation.invalid("artwork.layers", "Cu/Mask/SilkS")
            }
            images[face] = try assemble(
                shape: shape, drills: drills, copper: copper, mask: mask, silk: silk, face: face)
        }
        guard let front = images[.front], let back = images[.back] else {
            throw PanelValidation.invalid("artwork.faces", "front/back")
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
        let log = work.appendingPathComponent("plot.log")
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
                    "Artwork rendering timed out. Try a smaller panel.", "完成プレビューの生成がタイムアウトしました。基板数を減らしてお試しください。",
                    "Zeitüberschreitung beim Erstellen der Fertigungsansicht. Versuchen Sie einen kleineren Nutzen."))
        }
        guard task.terminationStatus == 0 else {
            let details = (try? String(contentsOf: log, encoding: .utf8)) ?? ""
            throw RoutingError.invalid(
                L10n.text(
                    "KiCad could not render the panel.\n\(details.suffix(1600))",
                    "KiCadでパネルを描画できませんでした。\n\(details.suffix(1600))",
                    "KiCad konnte den Nutzen nicht rendern.\n\(details.suffix(1600))"))
        }
    }

    /// EN: Convert validated dimensions to locale-independent SVG strings.
    ///
    /// JA: 検証済み寸法をSVG用のロケール非依存文字列へ変換する。
    ///
    /// DE: Geprüfte Abmessungen in sprachunabhängige SVG-Zeichenketten umwandeln.
    private static func number(_ value: Double) -> String {
        String(format: "%.8g", locale: Locale(identifier: "en_US_POSIX"), value)
    }
    /// EN: Convert validated closed contours [mm] to SVG paths. Do not draw empty contours.
    ///
    /// JA: 検証済みの閉ループ [mm] をSVGパスへ変換する。空ループは描画しない。
    ///
    /// DE: Geprüfte geschlossene Konturen [mm] in SVG-Pfade umwandeln. Leere Konturen nicht zeichnen.
    private static func path(_ loops: [[RoutePoint]]) -> String {
        loops.compactMap { loop in
            guard let first = loop.first else { return nil }
            return "M\(number(first.x)) \(number(first.y)) "
                + loop.dropFirst().map { "L\(number($0.x)) \(number($0.y))" }.joined(separator: " ") + " Z"
        }.joined(separator: " ")
    }
    /// EN: Create SVG slots or circular holes from validated centers, dimensions [mm] and rotation [degrees].
    ///
    /// JA: 検証済み穴中心・寸法 [mm]・回転 [度] からSVGの長穴または円形穴を作る。
    ///
    /// DE: SVG-Langlöcher oder kreisförmige Bohrungen aus geprüften Mittelpunkten, Abmessungen [mm] und Drehwinkeln
    ///     [Grad] erstellen.
    private static func hole(_ drill: PanelPreviewDrill, fill: String, stroke: String = "none") -> String {
        "<rect x=\"\(number(drill.center.x - drill.width / 2))\" y=\"\(number(drill.center.y - drill.height / 2))\" width=\"\(number(drill.width))\" height=\"\(number(drill.height))\" rx=\"\(number(min(drill.width, drill.height) / 2))\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"0.035\" transform=\"rotate(\(number(drill.angle)) \(number(drill.center.x)) \(number(drill.center.y)))\"/>"
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
        try PanelValidation.shape(shape, field: "assemble.shape")
        try PanelValidation.drills(drills)
        let b = shape.bounds
        let margin = max(1.5, min(b.maxX - b.minX, b.maxY - b.minY) * 0.025)
        let x = b.minX - margin, y = b.minY - margin, w = b.maxX - b.minX + margin * 2, h = b.maxY - b.minY + margin * 2
        let viewBox = "\(number(x)) \(number(y)) \(number(w)) \(number(h))"
        let boardPath = path(shape.contours)
        let holes = drills.filter { face == .front ? $0.front : $0.back }
        let copperGreen = try layerContents(copper, color: "#358268", prefix: "covered-")
        let copperGold = try layerContents(copper, color: "#d9ba70", prefix: "exposed-")
        let openings = try layerContents(mask, color: "#ffffff", prefix: "openings-")
        let silkscreen = try layerContents(silk, color: "#f2f1df", prefix: "silk-")
        let transform = face == .back ? "translate(\(number(b.minX + b.maxX)) 0) scale(-1 1)" : "translate(0 0)"
        let result = """
            <?xml version="1.0" encoding="UTF-8"?>
            <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" width="\(number(w))mm" height="\(number(h))mm" viewBox="\(viewBox)">
              <title>SwiftPCBPanelizer — \(face.rawValue)</title>
              <defs>
                <path id="panel-material" d="\(boardPath)" fill-rule="evenodd"/>
                <mask id="substrate" maskUnits="userSpaceOnUse" x="\(number(x))" y="\(number(y))" width="\(number(w))" height="\(number(h))" style="mask-type:luminance">
                  <rect x="\(number(x))" y="\(number(y))" width="\(number(w))" height="\(number(h))" fill="black"/>
                  <use xlink:href="#panel-material" fill="white"/>
                  \(holes.map { hole($0, fill: "black") }.joined())
                </mask>
                <mask id="mask-openings" maskUnits="userSpaceOnUse" x="\(number(x))" y="\(number(y))" width="\(number(w))" height="\(number(h))" style="mask-type:luminance">
                  <rect x="\(number(x))" y="\(number(y))" width="\(number(w))" height="\(number(h))" fill="black"/>
                  \(openings)
                </mask>
              </defs>
              <g transform="\(transform)">
                <g mask="url(#substrate)">
                  <use xlink:href="#panel-material" fill="#10533f"/>
                  \(copperGreen)
                  <g mask="url(#mask-openings)">\(copperGold)</g>
                  \(silkscreen)
                </g>
                <use xlink:href="#panel-material" fill="none" stroke="#9ac5aa" stroke-width="0.085" fill-rule="evenodd"/>
                \(holes.map { hole($0, fill: "none", stroke: "#183b31") }.joined())
              </g>
            </svg>
            """
        try PanelValidation.document(Data(result.utf8), field: "assemble.outputSVG")
        let parsed = try XMLDocument(xmlString: result, options: [.nodeLoadExternalEntitiesNever])
        guard parsed.rootElement()?.localName == "svg" else {
            throw PanelValidation.invalid("assemble.outputSVG", "SVG")
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
        try PanelValidation.document(Data(source.utf8), field: "layerContents.inputSVG")
        let document = try XMLDocument(xmlString: source, options: [.nodeLoadExternalEntitiesNever])
        guard let root = document.rootElement(), root.localName == "svg" else {
            throw RoutingError.invalid(
                L10n.text(
                    "KiCad returned an invalid SVG image.", "KiCadが生成したSVGを読み込めませんでした。",
                    "KiCad hat ein ungültiges SVG-Bild zurückgegeben."))
        }
        var ids: [String: String] = [:]
        /// EN: Collect SVG IDs and map them to new IDs that do not collide with other layers.
        ///
        /// JA: SVG内のIDを収集し、別レイヤーと重複しない新IDの対応表を作る。
        ///
        /// DE: SVG-IDs sammeln und auf neue IDs abbilden, die mit keiner anderen Lage kollidieren.
        func collect(_ element: XMLElement) {
            if let id = element.attribute(forName: "id")?.stringValue { ids[id] = prefix + id }
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
                if name == "style" {
                    value = value.components(separatedBy: ";").map { declaration in
                        let parts = declaration.split(separator: ":", maxSplits: 1).map {
                            $0.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        guard parts.count == 2, ["fill", "stroke"].contains(parts[0]),
                            !["none", "transparent"].contains(parts[1]), !parts[1].hasPrefix("url(")
                        else { return declaration }
                        return parts[0] + ":" + color
                    }.joined(separator: ";")
                } else if ["fill", "stroke"].contains(name), value != "none", value != "transparent",
                    !value.hasPrefix("url(")
                {
                    value = color
                }
                if name == "id", let replacement = ids[value] { value = replacement }
                for (old, new) in ids {
                    value = value.replacingOccurrences(of: "url(#\(old))", with: "url(#\(new))");
                    if value == "#" + old { value = "#" + new }
                }
                attribute.stringValue = value
            }
            for case let child as XMLElement in element.children ?? [] { recolor(child) }
        }
        recolor(root)
        return (root.children ?? []).filter { !["title", "desc"].contains($0.name ?? "") }.map(\.xmlString).joined(
            separator: "\n")
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
        window.title = "SwiftPCBPanelizer — " + L10n.text("Artwork preview", "完成プレビュー", "Fertigungsansicht")
        window.minSize = NSSize(width: 900, height: 560)
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: PanelArtworkView(artwork: artwork).interfaceTypography())
        window.center()
        super.init(window: window)
        window.delegate = self
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    /// EN: Remove references to closed windows from the registry.
    ///
    /// JA: 閉じたウィンドウの参照を管理表から取り除く。
    ///
    /// DE: Verweise auf geschlossene Fenster aus der Verwaltung entfernen.
    func windowWillClose(_ notification: Notification) { Self.windows.removeValue(forKey: token) }
}

private struct PanelArtworkView: View {
    @Environment(\.interfaceTextScale) private var textScale
    let artwork: PanelArtwork
    @State private var face: PanelArtworkFace = .front
    @State private var zoom = 1.0
    @State private var error: String?

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
            PanelArtworkWebView(svg: artwork.svg(for: face), zoom: zoom)
            Divider()
            HStack {
                Text(
                    L10n.text(
                        "Bare-board appearance · Copper, solder mask, silk and drills",
                        "部品実装前の仕上がり · 銅箔・ソルダーマスク・シルク・ドリル穴",
                        "Unbestückte Leiterplatte · Kupfer, Lötstoppmaske, Bestückungsdruck und Bohrungen"))
                Spacer()
                Text(
                    String(format: "%.1f × %.1f mm · %d", artwork.widthMM, artwork.heightMM, artwork.boardCount)
                        + L10n.text(" boards", " 枚", artwork.boardCount == 1 ? " Leiterplatte" : " Leiterplatten"))
            }.interfaceFont(.caption).foregroundStyle(.secondary).padding(12)
        }
        .alert(
            L10n.text("Cannot save SVG", "SVGを保存できませんでした", "SVG kann nicht gespeichert werden"),
            isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })
        ) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "")
        }
    }

    private var facePicker: some View {
        Picker(L10n.text("Side", "表示面", "Seite"), selection: $face) {
            ForEach(PanelArtworkFace.allCases) { side in Text(side.title).tag(side) }
        }.pickerStyle(.segmented).frame(width: 310 * textScale)
    }

    private var zoomControls: some View {
        HStack(spacing: 12) {
            Button {
                zoom = max(0.25, zoom / 1.3)
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .help(L10n.text("Zoom out", "縮小", "Verkleinern"))
            .accessibilityLabel(L10n.text("Zoom out", "縮小", "Verkleinern"))
            Text("\(Int(zoom * 100))%").interfaceFont(.caption, monospaced: true).frame(width: 46 * textScale)
            Button {
                zoom = min(8, zoom * 1.3)
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .help(L10n.text("Zoom in", "拡大", "Vergrößern"))
            .accessibilityLabel(L10n.text("Zoom in", "拡大", "Vergrößern"))
            Button(L10n.text("Fit", "全体表示", "Einpassen")) { zoom = 1 }
        }
    }

    private var saveControls: some View {
        HStack(spacing: 12) {
            InterfaceTextSizeControl()
            Button {
                saveSVG()
            } label: {
                Label(L10n.text("Save SVG", "SVG保存", "SVG speichern"), systemImage: "square.and.arrow.down")
            }
        }
    }

    /// EN: Save the validated SVG of the displayed side. Show write failures in the UI.
    ///
    /// JA: 表示面の検証済みSVGを保存する。書き込み失敗は画面に表示する。
    ///
    /// DE: Das geprüfte SVG der angezeigten Seite speichern. Schreibfehler in der Oberfläche anzeigen.
    private func saveSVG() {
        let chooser = NSSavePanel()
        chooser.allowedContentTypes = [.svg]
        chooser.nameFieldStringValue = "SwiftPCBPanelizer_\(face.rawValue).svg"
        chooser.canCreateDirectories = true
        guard chooser.runModal() == .OK, let url = chooser.url else { return }
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do { try artwork.svg(for: face).write(to: url, atomically: true, encoding: .utf8) } catch {
            self.error = error.localizedDescription
        }
    }
}

private struct PanelArtworkWebView: NSViewRepresentable {
    let svg: String
    let zoom: Double
    final class Coordinator { var svg: String?; var zoom = 0.0 }
    /// EN: Return an empty coordinator for tracking WebView update state.
    ///
    /// JA: WebView更新状態を保持する空のコーディネーターを返す。
    ///
    /// DE: Einen leeren Koordinator zur Verwaltung des WebView-Aktualisierungszustands zurückgeben.
    func makeCoordinator() -> Coordinator { Coordinator() }
    /// EN: Create an SVG WebView that requires no external network access.
    ///
    /// JA: 外部通信を必要としないSVG表示用WebViewを作る。
    ///
    /// DE: Eine SVG-WebView erstellen, die keine externen Netzwerkzugriffe benötigt.
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        return WKWebView(frame: .zero, configuration: configuration)
    }
    /// EN: Update only when SVG or scale changes, and clamp zoom to its allowed range.
    ///
    /// JA: SVGまたは倍率が変わった場合だけ表示を更新し、ズームを許容範囲へ制限する。
    ///
    /// DE: Nur bei Änderungen an SVG oder Skalierung aktualisieren und den Zoom auf den zulässigen Bereich begrenzen.
    func updateNSView(_ view: WKWebView, context: Context) {
        let factor = String(format: "%.5f", locale: Locale(identifier: "en_US_POSIX"), max(0.25, min(8, zoom)))
        if context.coordinator.svg != svg {
            context.coordinator.svg = svg; context.coordinator.zoom = zoom
            let inline = svg.replacingOccurrences(of: "<?xml version=\"1.0\" encoding=\"UTF-8\"?>", with: "")
            view.loadHTMLString(
                """
                <!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data:; font-src data:"><style>
                :root{color-scheme:light dark;--zoom:\(factor)}*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;background:#e6e9ed}#viewport{width:100vw;height:100vh;overflow:auto}#stage{width:calc((100vw - 48px)*var(--zoom));height:calc((100vh - 48px)*var(--zoom));margin:24px auto}svg{display:block;width:100%;height:100%;filter:drop-shadow(0 5px 7px #0003)}@media(prefers-color-scheme:dark){html,body{background:#20252b}}
                </style></head><body><div id="viewport"><div id="stage">\(inline)</div></div></body></html>
                """, baseURL: nil)
        } else if context.coordinator.zoom != zoom {
            context.coordinator.zoom = zoom
            view.evaluateJavaScript(
                "document.documentElement.style.setProperty('--zoom','\(factor)')", completionHandler: nil)
        }
    }
}
