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

struct PanelOptions: Equatable {
    /// EN: Column count [columns]. Copy count for one board; wrapping position for multiple inputs.
    ///
    /// JA: 列数 [個]。単一基板では複製数、複数入力では折り返し位置。
    ///
    /// DE: Spaltenanzahl [Spalten]. Kopienanzahl bei einer Platine, Umbruchposition bei mehreren Eingaben.
    var columns = 2
    /// EN: Row count [rows]. Computed automatically from the input count for multiple inputs.
    ///
    /// JA: 行数 [個]。複数入力時は入力数から自動算出する。
    ///
    /// DE: Zeilenanzahl [Zeilen]. Bei mehreren Eingaben automatisch aus deren Anzahl berechnet.
    var rows = 2
    /// EN: Board spacing between adjacent columns [mm], independent of the frame clearance.
    ///
    /// JA: 隣接列の基板間隔 [mm]。外枠との隙間とは独立。
    ///
    /// DE: Platinenabstand zwischen benachbarten Spalten [mm], unabhängig vom Abstand zum Rahmen.
    var columnGapMM = 0.0
    /// EN: Board spacing between adjacent rows [mm]. A finite, nonnegative value.
    ///
    /// JA: 隣接行の基板間隔 [mm]。0以上の有限値。
    ///
    /// DE: Platinenabstand zwischen benachbarten Zeilen [mm]. Ein endlicher, nicht negativer Wert.
    var rowGapMM = 0.0
    /// EN: Material width retained along the panel's top and bottom edges [mm].
    ///
    /// JA: パネル上辺・下辺に残す材料幅 [mm]。
    ///
    /// DE: Verbleibende Materialbreite am oberen und unteren Panelrand [mm].
    var horizontalFrameMM = 0.0
    /// EN: Material width retained along the panel's left and right edges [mm].
    ///
    /// JA: パネル左辺・右辺に残す材料幅 [mm]。
    ///
    /// DE: Verbleibende Materialbreite am linken und rechten Panelrand [mm].
    var verticalFrameMM = 0.0
    /// EN: Distance from left/right edges to mounting hole centers [mm]. At least the hole radius when enabled.
    ///
    /// JA: 左右端から取付穴中心までの距離 [mm]。有効時は穴半径以上。
    ///
    /// DE: Abstand vom linken/rechten Rand zum Mittelpunkt der Befestigungsbohrung [mm]. Bei aktivierter Bohrung
    ///     mindestens ihr Radius.
    var mountingHoleOffsetXMM = 0.0
    /// EN: Distance from top/bottom edges to mounting hole centers [mm]. At least the hole radius when enabled.
    ///
    /// JA: 上下端から取付穴中心までの距離 [mm]。有効時は穴半径以上。
    ///
    /// DE: Abstand vom oberen/unteren Rand zum Mittelpunkt der Befestigungsbohrung [mm]. Bei aktivierter Bohrung
    ///     mindestens ihr Radius.
    var mountingHoleOffsetYMM = 0.0
    /// EN: Mounting hole diameter [mm]. Finite and positive when enabled.
    ///
    /// JA: 取付穴直径 [mm]。有効時は正の有限値。
    ///
    /// DE: Durchmesser der Befestigungsbohrung [mm]. Bei aktivierter Bohrung endlich und positiv.
    var mountingHoleDrillMM = 3.2
    var addMountingHoles = false
    /// EN: Output outline stroke width [mm], distinct from the array's physical dimensions.
    ///
    /// JA: 出力外形線の幅 [mm]。配列の物理寸法とは区別する。
    ///
    /// DE: Linienbreite der Ausgabekontur [mm], getrennt von den physischen Abmessungen der Anordnung.
    var dimensionLineWidthMM = 0.05
    var addVScoreSeparators = false
    var vScoreLineWidthMM = 0.1
    /// EN: Routed clearance between the board array and the inside of the frame [mm].
    ///
    /// JA: 基板配列と外枠内側の間を切り抜く隙間 [mm]。
    ///
    /// DE: Ausgefräster Abstand zwischen der Platinenanordnung und der Rahmeninnenseite [mm].
    var frameGapMM = 0.0
    var addTabs = false
    /// EN: Connecting tab width [mm]. Validate the numerically supported lower and upper limits.
    ///
    /// JA: 接続タブの幅 [mm]。数値的に扱える下限と上限を検証する。
    ///
    /// DE: Breite der Verbindungsstege [mm]. Die numerisch unterstützten Unter- und Obergrenzen prüfen.
    var tabWidthMM = 3.0
    /// EN: Number of tabs per side [tabs], limited separately from the total hole count.
    ///
    /// JA: 1辺当たりのタブ数 [個]。穴の総数とは別に制限する。
    ///
    /// DE: Anzahl der Stege pro Seite [Stege], unabhängig von der gesamten Bohrungsanzahl begrenzt.
    var tabsPerEdge = 2
    var tabsLeft = true
    var tabsRight = true
    var tabsTop = true
    var tabsBottom = true
    var connectBoardsWithTabs = true
    var perforateTabs = true
    /// EN: Perforation hole diameter [mm]. Smaller than the pitch when enabled.
    ///
    /// JA: ミシン目の穴径 [mm]。有効時はピッチ未満。
    ///
    /// DE: Durchmesser der Perforationsbohrungen [mm]. Bei aktivierter Perforation kleiner als der Mittenabstand.
    var mouseBiteDiameterMM = 0.5
    /// EN: Perforation hole center spacing [mm]. Greater than the diameter and no greater than the tab width.
    ///
    /// JA: ミシン目の穴中心間隔 [mm]。穴径より大きく、タブ幅以下。
    ///
    /// DE: Mittenabstand der Perforationsbohrungen [mm]. Größer als der Durchmesser und höchstens so groß wie die
    ///     Stegbreite.
    var mouseBitePitchMM = 1.0
    /// EN: Frame corner radius [mm]. The effective radius is at most half the bounding dimensions.
    ///
    /// JA: 外枠の角R [mm]。実際の半径は外接寸法の半分以下。
    ///
    /// DE: Eckenradius des Rahmens [mm]. Der tatsächliche Radius beträgt höchstens die Hälfte der
    ///     Begrenzungsabmessungen.
    var panelCornerRadiusMM = 2.0
}

struct PanelSummary {
    /// EN: Source board or array width [mm]. Validate that the returned value is positive and finite.
    ///
    /// JA: 元基板または配列の幅 [mm]。戻り値の正値・有限性を検証する。
    ///
    /// DE: Breite der Quellplatine oder Anordnung [mm]. Den Rückgabewert auf Positivität und Endlichkeit prüfen.
    let boardWidthMM: Double
    /// EN: Source board or array height [mm]. Validate that the returned value is positive and finite.
    ///
    /// JA: 元基板または配列の高さ [mm]。戻り値の正値・有限性を検証する。
    ///
    /// DE: Höhe der Quellplatine oder Anordnung [mm]. Den Rückgabewert auf Positivität und Endlichkeit prüfen.
    let boardHeightMM: Double
    /// EN: Final panel width including the frame [mm]. Compare against the saved data's outline.
    ///
    /// JA: 外枠を含む最終パネル幅 [mm]。保存データの外形と照合する。
    ///
    /// DE: Endgültige Panelbreite einschließlich Rahmen [mm]. Mit der Kontur der gespeicherten Daten vergleichen.
    let panelWidthMM: Double
    /// EN: Final panel height including the frame [mm]. Compare against the saved data's outline.
    ///
    /// JA: 外枠を含む最終パネル高さ [mm]。保存データの外形と照合する。
    ///
    /// DE: Endgültige Panelhöhe einschließlich Rahmen [mm]. Mit der Kontur der gespeicherten Daten vergleichen.
    let panelHeightMM: Double
    /// EN: Column count [columns]. Copy count for one board; wrapping position for multiple inputs.
    ///
    /// JA: 列数 [個]。単一基板では複製数、複数入力では折り返し位置。
    ///
    /// DE: Spaltenanzahl [Spalten]. Kopienanzahl bei einer Platine, Umbruchposition bei mehreren Eingaben.
    let columns: Int
    /// EN: Row count [rows]. Computed automatically from the input count for multiple inputs.
    ///
    /// JA: 行数 [個]。複数入力時は入力数から自動算出する。
    ///
    /// DE: Zeilenanzahl [Zeilen]. Bei mehreren Eingaben automatisch aus deren Anzahl berechnet.
    let rows: Int
    /// EN: Output outline stroke width [mm], distinct from the array's physical dimensions.
    ///
    /// JA: 出力外形線の幅 [mm]。配列の物理寸法とは区別する。
    ///
    /// DE: Linienbreite der Ausgabekontur [mm], getrennt von den physischen Abmessungen der Anordnung.
    let dimensionLineWidthMM: Double
}

enum EaglePanelError: LocalizedError {
    case invalidCount
    case negativeMeasurement(String)
    case malformedXML(String)
    case unsupportedRoot(String)
    case noBoard
    case noPlainSection
    case noDimension

    var errorDescription: String? {
        switch self {
        case .invalidCount:
            return L10n.text(
                "Columns and rows must be at least one.", "列数と行数は1以上を指定してください。",
                "Spalten- und Zeilenanzahl müssen mindestens 1 betragen.")
        case .negativeMeasurement(let name):
            return L10n.text(
                "\(name) must be zero or greater.", "\(name)は0以上で指定してください。", "\(name) muss mindestens 0 betragen.")
        case .malformedXML(let reason):
            return L10n.text(
                "Cannot read EAGLE .brd XML: \(reason)", "EAGLE .brd XMLを読み込めませんでした: \(reason)",
                "EAGLE-.brd-XML kann nicht gelesen werden: \(reason)")
        case .unsupportedRoot(let name):
            return L10n.text(
                "Not an EAGLE file (root element: \(name)).", "EAGLE形式ではありません（ルート要素: \(name)）。",
                "Keine EAGLE-Datei (Wurzelelement: \(name)).")
        case .noBoard:
            return L10n.text(
                "No <board> element was found in this EAGLE file.", "このEAGLEファイルに<board>が見つかりません。",
                "In dieser EAGLE-Datei wurde kein <board>-Element gefunden.")
        case .noPlainSection:
            return L10n.text(
                "No <plain> section was found in the board.", "基板内に<plain>が見つかりません。",
                "Die Leiterplatte enthält keinen <plain>-Abschnitt.")
        case .noDimension:
            return L10n.text(
                "No outline wires were found on Dimension layer 20. Create the board outline on that layer.",
                "Dimensionレイヤー（20）のwireがありません。外形をDimensionレイヤーに作成してください。",
                "Auf dem Dimension-Layer 20 wurden keine Konturlinien gefunden. Erstellen Sie dort die Leiterplattenkontur."
            )
        }
    }
}

enum EaglePanelEngine {
    private static let dimensionLayer = "20"
    private static let vScoreLayer = "102"
    private static let vScoreOverrunMM = 5.0

    /// EN: KiCad 10 imports plain restriction rectangles as ordinary zones on UNDEFINED. Its polygon importer
    ///     preserves the restriction layer and rules, so express the same filled rectangle with four explicit
    ///     vertices. Only the temporary import copy is changed; native EAGLE output is intact.
    ///
    /// JA: KiCad
    ///     10は通常の禁止領域の矩形を、UNDEFINED上の通常ゾーンとして読み込む。ポリゴンでは禁止レイヤーと規則が保持されるため、同じ塗りつぶし矩形を4頂点で表す。変更対象はインポート用の一時コピーだけで、EAGLE形式の出力は保持する。
    ///
    /// DE: KiCad 10 importiert einfache Sperrflächenrechtecke als normale Zonen auf UNDEFINED. Der Polygonimport
    ///     erhält Sperrlage und Regeln; dasselbe gefüllte Rechteck daher mit vier expliziten Eckpunkten darstellen.
    ///     Nur die temporäre Importkopie wird geändert; die native EAGLE-Ausgabe bleibt erhalten.
    static func preparedForKiCadImport(data: Data) throws -> Data {
        let source = try EagleXMLParser.parse(data)
        guard source.name == "eagle" else { throw EaglePanelError.unsupportedRoot(source.name) }
        guard let board = source.child(named: "drawing")?.child(named: "board") else { throw EaglePanelError.noBoard }
        guard let plain = board.child(named: "plain") else { throw EaglePanelError.noPlainSection }
        let restrictionLayers: Set<String> = ["41", "42", "43"]
        var changed = false
        for index in plain.children.indices {
            let rectangle = plain.children[index]
            guard rectangle.name == "rectangle", let layer = rectangle.attributes["layer"],
                restrictionLayers.contains(layer)
            else { continue }
            guard let x1 = rectangle.number("x1"), let y1 = rectangle.number("y1"),
                let x2 = rectangle.number("x2"), let y2 = rectangle.number("y2"),
                [x1, y1, x2, y2, rectangle.rotationDegrees].allSatisfy(\.isFinite)
            else {
                throw EaglePanelError.malformedXML(
                    L10n.text(
                        "A restriction rectangle has invalid coordinates or rotation.", "禁止領域の矩形の座標または回転角が不正です。",
                        "Ein Rechteck einer Sperrfläche hat ungültige Koordinaten oder einen ungültigen Drehwinkel."))
            }
            let center = RoutePoint(x: (x1 + x2) / 2, y: (y1 + y2) / 2)
            let angle = rectangle.rotationDegrees * .pi / 180
            let corners = [
                RoutePoint(x: x1, y: y1), RoutePoint(x: x2, y: y1),
                RoutePoint(x: x2, y: y2), RoutePoint(x: x1, y: y2),
            ]
            let vertices = corners.map { corner -> EagleXMLNode in
                let dx = corner.x - center.x, dy = corner.y - center.y
                return EagleXMLNode(
                    name: "vertex",
                    attributes: [
                        "x": numberString(center.x + dx * cos(angle) - dy * sin(angle)),
                        "y": numberString(center.y + dx * sin(angle) + dy * cos(angle)),
                    ])
            }
            // EN: Zero stroke width keeps the original rectangle boundary exact. tRestrict/bRestrict prohibit copper,
            //     tracks, pads and vias on their respective face; vRestrict prohibits vias across the copper stack.
            // JA: 線幅を0にして元の矩形境界を正確に保持する。tRestrict/bRestrictは各面の銅箔・配線・パッド・ビアを禁止し、vRestrictは銅箔積層全体のビアを禁止する。
            // DE: Eine Linienbreite von null erhält die ursprüngliche Rechteckgrenze exakt. tRestrict/bRestrict
            //     sperren Kupfer, Leiterbahnen, Pads und Vias auf der jeweiligen Seite; vRestrict sperrt Vias durch
            //     den gesamten Kupferlagenaufbau.
            let polygon = EagleXMLNode(name: "polygon", attributes: ["layer": layer, "width": "0"], children: vertices)
            polygon.parent = plain
            plain.children[index] = polygon
            changed = true
        }
        let result = changed ? EagleXMLWriter.serialize(source) : data
        try PanelValidation.document(result, field: "preparedForKiCadImport.output")
        _ = try EagleXMLParser.parse(result)
        return result
    }

    /// EN: Validate EAGLE source data and placement settings; return copied XML and validated dimensions [mm].
    ///
    /// JA: EAGLEの元データ・配置設定を検証し、複製したXMLと検証済み寸法 [mm] を返す。
    ///
    /// DE: EAGLE-Quelldaten und Platzierungseinstellungen prüfen; kopiertes XML und geprüfte Abmessungen [mm]
    ///     zurückgeben.
    static func panelize(data: Data, options: PanelOptions) throws -> (Data, PanelSummary) {
        try PanelRouting.validate(options)
        guard options.columns >= 1, options.rows >= 1 else { throw EaglePanelError.invalidCount }
        for (name, value) in [
            (L10n.text("Column spacing", "列間隔", "Spaltenabstand"), options.columnGapMM),
            (L10n.text("Row spacing", "行間隔", "Zeilenabstand"), options.rowGapMM),
            (L10n.text("Horizontal frame", "横方向の外枠", "Horizontaler Rahmen"), options.horizontalFrameMM),
            (L10n.text("Vertical frame", "縦方向の外枠", "Vertikaler Rahmen"), options.verticalFrameMM),
            (
                L10n.text("Mounting hole X inset", "取付穴のXオフセット", "Randabstand der Befestigungsbohrung in X"),
                options.mountingHoleOffsetXMM
            ),
            (
                L10n.text("Mounting hole Y inset", "取付穴のYオフセット", "Randabstand der Befestigungsbohrung in Y"),
                options.mountingHoleOffsetYMM
            ),
            (L10n.text("Outline line width", "外形線幅", "Konturlinienbreite"), options.dimensionLineWidthMM),
            (L10n.text("Guide line width", "分割ガイド線幅", "Hilfslinienbreite"), options.vScoreLineWidthMM),
        ] where value < 0 { throw EaglePanelError.negativeMeasurement(name) }
        if options.addMountingHoles, options.mountingHoleDrillMM <= 0 {
            throw EaglePanelError.negativeMeasurement(
                L10n.text("Mounting hole diameter", "取付穴径", "Durchmesser der Befestigungsbohrung"))
        }

        let source = try EagleXMLParser.parse(data)
        guard source.name == "eagle" else { throw EaglePanelError.unsupportedRoot(source.name) }
        guard let drawing = source.child(named: "drawing"), let board = drawing.child(named: "board") else {
            throw EaglePanelError.noBoard
        }
        guard let plain = board.child(named: "plain") else { throw EaglePanelError.noPlainSection }

        var xs: [Double] = []
        var ys: [Double] = []
        var dimensionWidth = 0.0
        for wire in plain.children where wire.name == "wire" && wire.attributes["layer"] == dimensionLayer {
            if let x = wire.number("x1") { xs.append(x) }
            if let x = wire.number("x2") { xs.append(x) }
            if let y = wire.number("y1") { ys.append(y) }
            if let y = wire.number("y2") { ys.append(y) }
            dimensionWidth = max(dimensionWidth, wire.number("width") ?? 0)
        }
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max(), maxX > minX,
            maxY > minY
        else {
            throw EaglePanelError.noDimension
        }
        let boardWidth = maxX - minX
        let boardHeight = maxY - minY
        let columnOffset = boardWidth + options.columnGapMM
        let rowOffset = boardHeight + options.rowGapMM
        let panelMinX = minX - options.verticalFrameMM - options.frameGapMM
        let panelMaxX =
            minX + columnOffset * Double(options.columns) - options.columnGapMM + options.verticalFrameMM
            + options.frameGapMM
        let panelMinY = minY - options.horizontalFrameMM - options.frameGapMM
        let panelMaxY =
            minY + rowOffset * Double(options.rows) - options.rowGapMM + options.horizontalFrameMM + options.frameGapMM
        let routed = options.frameGapMM > 0 || options.addTabs
        var routingOptions = options
        routingOptions.tabsTop = options.tabsBottom; routingOptions.tabsBottom = options.tabsTop
        let routingPlan =
            routed
            ? try PanelRouting.plan(
                contours: PanelRouting.closedLoops(
                    plain.children.filter { $0.attributes["layer"] == dimensionLayer }.flatMap {
                        try routingSegments($0)
                    }), bounds: RouteRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY), options: routingOptions)
            : RoutingPlan(segments: [], mouseBites: [])
        let routedEdges = routingPlan.segments

        var packageLabels: [String: [EagleXMLNode]] = [:]
        for library in board.child(named: "libraries")?.children ?? [] {
            for package in library.child(named: "packages")?.children ?? [] where package.name == "package" {
                let key = (library.attributes["name"] ?? "") + "/" + (package.attributes["name"] ?? "")
                packageLabels[key] = package.descendants(named: "text").filter {
                    [">NAME", ">VALUE"].contains($0.text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }

        let output = source.deepCopy()
        guard let outputDrawing = output.child(named: "drawing"), let outputBoard = outputDrawing.child(named: "board"),
            let outputPlain = outputBoard.child(named: "plain")
        else { throw EaglePanelError.noBoard }

        var generatedNameTexts: [EagleXMLNode] = []
        let sourceElements = board.child(named: "elements")
        var generatedElements: [EagleXMLNode] = []
        if let sourceElements {
            for sourceElement in sourceElements.children where sourceElement.name == "element" {
                let name = sourceElement.attributes["name"] ?? ""
                let element = sourceElement.deepCopy()
                let key =
                    (sourceElement.attributes["library"] ?? "") + "/" + (sourceElement.attributes["package"] ?? "")
                let isSmashed = sourceElement.attributes["smashed"] == "yes"
                var labels: [EagleXMLNode] = []
                if isSmashed {
                    // EN: NAME attributes already have board coordinates and may have been moved independently of the
                    //     footprint.
                    // JA: NAME属性は既に基板座標であり、フットプリントと独立して移動されている場合がある。
                    // DE: NAME-Attribute liegen bereits in Platinenkoordinaten vor und können unabhängig vom
                    //     Footprint verschoben worden sein.
                    for attribute in sourceElement.children
                    where attribute.name == "attribute" && attribute.attributes["name"] == "NAME" {
                        if attribute.attributes["display"] != "off" {
                            var attributes = attribute.attributes
                            for key in ["name", "value", "display", "constant"] { attributes.removeValue(forKey: key) }
                            let text: String
                            switch attribute.attributes["display"] {
                            case "name": text = "NAME"
                            case "both": text = "NAME = " + name
                            default: text = attribute.attributes["value"] ?? name
                            }
                            labels.append(EagleXMLNode(name: "text", attributes: attributes, text: text))
                        }
                    }
                    element.children.removeAll { $0.name == "attribute" && $0.attributes["name"] == "NAME" }
                } else if let templates = packageLabels[key], !templates.isEmpty {
                    element.attributes["smashed"] = "yes"
                    for template in templates {
                        let value =
                            template.text.trimmingCharacters(in: .whitespacesAndNewlines) == ">NAME"
                            ? name : (sourceElement.attributes["value"] ?? "")
                        labels.append(makeNameLabel(from: template, element: sourceElement, fallbackName: value))
                    }
                    element.children.removeAll {
                        $0.name == "attribute" && ["NAME", "VALUE"].contains($0.attributes["name"] ?? "")
                    }
                }
                for column in 0..<options.columns {
                    for row in 0..<options.rows {
                        generatedElements.append(
                            offsetCopy(
                                element, column: column, row: row,
                                columnOffset: columnOffset, rowOffset: rowOffset, recursive: true))
                        for label in labels {
                            generatedNameTexts.append(
                                offsetCopy(
                                    label, column: column, row: row,
                                    columnOffset: columnOffset, rowOffset: rowOffset, recursive: true))
                        }
                    }
                }
            }
        }

        var scoreX: [Double: Double] = [:]
        var scoreY: [Double: Double] = [:]
        var generatedPlain: [EagleXMLNode] = []
        for element in plain.children {
            if routed && element.attributes["layer"] == dimensionLayer { continue }
            if element.name == "wire", element.attributes["layer"] == vScoreLayer {
                let width = element.number("width") ?? 0
                if let x1 = element.number("x1"), let x2 = element.number("x2"), x1 == x2 {
                    for column in 0..<options.columns {
                        let x = x1 + Double(column) * columnOffset
                        scoreX[x] = max(scoreX[x] ?? 0, width)
                    }
                }
                if let y1 = element.number("y1"), let y2 = element.number("y2"), y1 == y2 {
                    for row in 0..<options.rows {
                        let y = y1 + Double(row) * rowOffset
                        scoreY[y] = max(scoreY[y] ?? 0, width)
                    }
                }
                continue
            }
            for column in 0..<options.columns {
                for row in 0..<options.rows {
                    generatedPlain.append(
                        offsetCopy(
                            element, column: column, row: row,
                            columnOffset: columnOffset, rowOffset: rowOffset, recursive: false))
                }
            }
        }

        for (x, width) in scoreX {
            generatedPlain.append(
                wire(
                    x1: x, y1: panelMinY - vScoreOverrunMM, x2: x,
                    y2: panelMaxY + vScoreOverrunMM, width: width, layer: vScoreLayer))
        }
        for (y, width) in scoreY {
            generatedPlain.append(
                wire(
                    x1: panelMinX - vScoreOverrunMM, y1: y,
                    x2: panelMaxX + vScoreOverrunMM, y2: y,
                    width: width, layer: vScoreLayer))
        }
        if routed {
            generatedPlain += routedEdges.map {
                wire(x1: $0.a.x, y1: $0.a.y, x2: $0.b.x, y2: $0.b.y, width: dimensionWidth, layer: dimensionLayer)
            }
        } else {
            let radius = options.verticalFrameMM > 0 && options.horizontalFrameMM > 0 ? options.panelCornerRadiusMM : 0
            let loop = try PanelRouting.roundedRectangle(
                RouteRect(minX: panelMinX, minY: panelMinY, maxX: panelMaxX, maxY: panelMaxY), radius: radius)
            generatedPlain += PanelRouting.edges(loop).map {
                wire(x1: $0.a.x, y1: $0.a.y, x2: $0.b.x, y2: $0.b.y, width: dimensionWidth, layer: dimensionLayer)
            }
        }
        generatedPlain += routingPlan.mouseBites.map { point in
            EagleXMLNode(
                name: "hole",
                attributes: [
                    "x": numberString(point.x), "y": numberString(point.y),
                    "drill": numberString(options.mouseBiteDiameterMM),
                ])
        }
        if options.addMountingHoles {
            let holeX1 = panelMinX + options.mountingHoleOffsetXMM
            let holeX2 = panelMaxX - options.mountingHoleOffsetXMM
            let holeY1 = panelMinY + options.mountingHoleOffsetYMM
            let holeY2 = panelMaxY - options.mountingHoleOffsetYMM
            for (x, y) in [(holeX1, holeY1), (holeX1, holeY2), (holeX2, holeY1), (holeX2, holeY2)] {
                generatedPlain.append(
                    EagleXMLNode(
                        name: "hole",
                        attributes: [
                            "x": numberString(x), "y": numberString(y),
                            "drill": numberString(options.mountingHoleDrillMM),
                        ]))
            }
        }
        generatedPlain.append(contentsOf: generatedNameTexts)
        outputPlain.children = generatedPlain

        if let sourceElements, let destinationElements = outputBoard.child(named: "elements") {
            destinationElements.children = generatedElements
            _ = sourceElements
        }
        if let sourceSignals = board.child(named: "signals"),
            let destinationSignals = outputBoard.child(named: "signals")
        {
            var replicated: [EagleXMLNode] = []
            for column in 0..<options.columns {
                for row in 0..<options.rows {
                    for signal in sourceSignals.children {
                        replicated.append(
                            offsetCopy(
                                signal, column: column, row: row,
                                columnOffset: columnOffset, rowOffset: rowOffset, recursive: true))
                    }
                }
            }
            destinationSignals.children = replicated
        }

        let summary = PanelSummary(
            boardWidthMM: boardWidth, boardHeightMM: boardHeight,
            panelWidthMM: panelMaxX - panelMinX, panelHeightMM: panelMaxY - panelMinY,
            columns: options.columns, rows: options.rows,
            dimensionLineWidthMM: dimensionWidth)
        let result = try PanelValidation.output(EagleXMLWriter.serialize(output), summary: summary, options: options)
        _ = try EagleXMLParser.parse(result.0)
        return result
    }

    /// EN: Parse closed EAGLE outlines and return validated signed-coordinate bounding rectangles and contours [mm].
    ///
    /// JA: EAGLEの閉じた外形を解析し、符号付きmm座標の外接矩形と輪郭を検証して返す。
    ///
    /// DE: Geschlossene EAGLE-Konturen parsen und geprüfte Begrenzungsrechtecke und Konturen mit vorzeichenbehafteten
    ///     Koordinaten [mm] zurückgeben.
    static func shape(data: Data) throws -> PanelBoardShape {
        let source = try EagleXMLParser.parse(data)
        guard let plain = source.child(named: "drawing")?.child(named: "board")?.child(named: "plain") else {
            throw EaglePanelError.noBoard
        }
        let loops = try PanelRouting.closedLoops(
            plain.children.filter { $0.attributes["layer"] == dimensionLayer }.flatMap { try routingSegments($0) })
        var points = loops.flatMap { $0 }
        /// EN: Normalize a finite relative angle [rad] to [0, 2π). Input was checked by the parser and arc
        ///     validation.
        ///
        /// JA: 有限の相対角 [rad] を0以上2π未満へ戻す。入力はパーサーと円弧検証で確認済み。
        ///
        /// DE: Einen endlichen relativen Winkel [rad] auf [0, 2π) normalisieren. Die Eingabe wurde vom Parser und der
        ///     Kreisbogenprüfung validiert.
        func positiveAngle(_ value: Double) -> Double {
            (value.truncatingRemainder(dividingBy: 2 * .pi) + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        }
        for item in plain.children where item.attributes["layer"] == dimensionLayer {
            if item.name == "circle", let x = item.number("x"), let y = item.number("y"), let r = item.number("radius")
            {
                points += [RoutePoint(x: x - r, y: y - r), RoutePoint(x: x + r, y: y + r)]
            }
            if item.name == "wire", let x1 = item.number("x1"), let y1 = item.number("y1"), let x2 = item.number("x2"),
                let y2 = item.number("y2"), let curve = item.number("curve"), abs(curve) > 1e-8
            {
                let a = RoutePoint(x: x1, y: y1), b = RoutePoint(x: x2, y: y2), theta = curve * .pi / 180
                let delta = b - a,
                    center = (a + b) * 0.5 + RoutePoint(x: -delta.y, y: delta.x) * (1 / (2 * tan(theta / 2)))
                let radius = (a - center).length, start = atan2(a.y - center.y, a.x - center.x)
                for angle in [0.0, .pi / 2, .pi, 3 * .pi / 2]
                where positiveAngle(theta > 0 ? angle - start : start - angle) <= abs(theta) + 1e-9 {
                    points.append(RoutePoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle)))
                }
            }
        }
        let result = PanelBoardShape(
            bounds: RouteRect(
                minX: points.map(\.x).min()!, minY: points.map(\.y).min()!, maxX: points.map(\.x).max()!,
                maxY: points.map(\.y).max()!), contours: loops)
        try PanelValidation.shape(result, field: "EaglePanelEngine.shape.output")
        return result
    }

    /// EN: Place EAGLE boards with matching copper layer stacks. Validate arguments, routing, output XML and
    ///     dimensions.
    ///
    /// JA: 同じ銅箔層構成のEAGLE基板を配置する。引数・加工線・出力XMLと寸法を検証する。
    ///
    /// DE: EAGLE-Platinen mit gleichem Kupferlagenaufbau platzieren. Argumente, Fräskonturen, Ausgabe-XML und
    ///     Abmessungen prüfen.
    static func compose(sources: [PanelSource], options: PanelOptions) throws -> (Data, PanelSummary) {
        let options = options.forSourceCount(sources.count)
        guard
            !sources.isEmpty && sources.count <= PanelLimits.maxBoardPositions
                && sources.allSatisfy({ $0.kind == .eagle })
        else {
            throw PanelValidation.invalid(
                "EaglePanelEngine.compose.sources", "1...\(PanelLimits.maxBoardPositions) EAGLE sources")
        }
        let shapes = try sources.map { try shape(data: $0.data) }
        let layout = try PanelCompositionLayout(bounds: shapes.map(\.bounds), options: options)
        var routingOptions = options
        routingOptions.tabsTop = options.tabsBottom; routingOptions.tabsBottom = options.tabsTop
        let routing = try PanelRouting.plan(
            boards: layout.placedContours(shapes), arrayBounds: layout.arrayBounds, options: routingOptions)
        // EN: The existing one-board export freezes visible NAME/VALUE labels before component identifiers and
        //     library names are namespaced for the panel.
        // JA: 既存の単一基板出力で表示用NAME/VALUEラベルを固定してから、パネル用に部品識別子とライブラリ名へ名前空間を付ける。
        // DE: Der bestehende Export einer einzelnen Platine fixiert sichtbare NAME/VALUE-Beschriftungen, bevor
        //     Bauteilkennungen und Bibliotheksnamen für das Panel mit Namensräumen versehen werden.
        let roots = try sources.map { source -> EagleXMLNode in
            let prepared = try panelize(data: source.data, options: PanelOptions(columns: 1, rows: 1))
            return try EagleXMLParser.parse(prepared.0)
        }
        guard let output = roots.first?.deepCopy(), let drawing = output.child(named: "drawing"),
            let board = drawing.child(named: "board")
        else { throw EaglePanelError.noBoard }
        let sourceBoards = try roots.map { root -> EagleXMLNode in
            guard let board = root.child(named: "drawing")?.child(named: "board") else { throw EaglePanelError.noBoard }
            return board
        }
        let stacks = sourceBoards.map { source in
            source.child(named: "designrules")?.children.first {
                $0.name == "param" && $0.attributes["name"] == "layerSetup"
            }?.attributes["value"] ?? "(1*16)"
        }
        guard Set(stacks).count == 1 else {
            throw RoutingError.invalid(
                L10n.text(
                    "Boards in one EAGLE panel must use the same copper layer stack.",
                    "同じEAGLEパネルに配置する基板は、銅箔の層構成を揃えてください。",
                    "Alle Leiterplatten in einem EAGLE-Nutzen müssen denselben Kupferlagenaufbau haben."))
        }
        /// EN: Get or create the target section and initialize the destination. The returned element belongs to the
        ///     output tree.
        ///
        /// JA: 対象セクションを取得または作成して複製先を初期化する。戻り値は出力ツリーの所有要素。
        ///
        /// DE: Den Zielabschnitt abrufen oder erstellen und das Kopierziel initialisieren. Das zurückgegebene Element
        ///     gehört zum Ausgabebaum.
        func section(_ name: String) -> EagleXMLNode {
            if let node = board.child(named: name) { node.children = []; return node }
            let node = EagleXMLNode(name: name); board.children.append(node); return node
        }
        let plain = section("plain"), libraries = section("libraries"), elements = section("elements"),
            signals = section("signals"), classes = section("classes")
        let layers = drawing.child(named: "layers") ?? EagleXMLNode(name: "layers")
        if drawing.child(named: "layers") == nil { drawing.children.insert(layers, at: 0) }
        layers.children = []
        var usedLayers: [String: String] = [:]
        var usedNumbers = Set(
            roots.flatMap {
                $0.child(named: "drawing")?.child(named: "layers")?.children.compactMap { $0.attributes["number"] }
                    ?? []
            })
        var nextClass = 0
        var classSets: [String: [String: String]] = [:]
        /// EN: Translate input-validated elements [mm] and reconcile internal identifiers and layer references. The
        ///     caller revalidates the output.
        ///
        /// JA: 入力検証済みの要素をmm単位で移動し、内部識別子とレイヤー参照を整合させる。出力は呼び出し元で再検証する。
        ///
        /// DE: Bereits eingabegeprüfte Elemente [mm] verschieben und interne Kennungen sowie Lagenverweise abstimmen.
        ///     Der Aufrufer prüft die Ausgabe erneut.
        func move(_ node: EagleXMLNode, by offset: RoutePoint, prefix: String, layers: [String: String]) {
            for key in ["x", "x1", "x2", "x3"] {
                if let value = node.number(key) { node.attributes[key] = numberString(value + offset.x) }
            }
            for key in ["y", "y1", "y2", "y3"] {
                if let value = node.number(key) { node.attributes[key] = numberString(value + offset.y) }
            }
            if let layer = node.attributes["layer"], let replacement = layers[layer] {
                node.attributes["layer"] = replacement
            }
            if ["element", "signal"].contains(node.name), let name = node.attributes["name"] {
                node.attributes["name"] = prefix + name
            }
            if node.name == "contactref", let name = node.attributes["element"] {
                node.attributes["element"] = prefix + name
            }
            for child in node.children { move(child, by: offset, prefix: prefix, layers: layers) }
        }
        var copiedLibraries = Set<Int>()
        for (instance, placement) in layout.placements.enumerated() {
            let index = placement.sourceIndex, source = sourceBoards[index], prefix = "B\(instance + 1)_"
            let libraryPrefix = "B\(index + 1)_"
            var layerMap: [String: String] = [:]
            for layer in roots[index].child(named: "drawing")?.child(named: "layers")?.children ?? [] {
                guard let old = layer.attributes["number"] else { continue }
                var number = old
                if let oldName = usedLayers[old], oldName != layer.attributes["name"], (Int(old) ?? 0) >= 100 {
                    guard let free = (100...255).first(where: { !usedNumbers.contains(String($0)) }) else {
                        throw RoutingError.invalid(
                            L10n.text(
                                "The EAGLE panel has too many custom layers.", "EAGLEパネルのカスタムレイヤー数が上限を超えています。",
                                "Der EAGLE-Nutzen enthält zu viele benutzerdefinierte Layer."))
                    }
                    number = String(free); usedNumbers.insert(number)
                }
                layerMap[old] = number
                if usedLayers[number] == nil {
                    let copy = layer.deepCopy(); copy.attributes["number"] = number
                    layers.children.append(copy); usedLayers[number] = layer.attributes["name"] ?? number
                }
            }
            for library
                in (copiedLibraries.insert(index).inserted ? source.child(named: "libraries")?.children ?? [] : [])
            {
                let copy = library.deepCopy()
                if let name = copy.attributes["name"] { copy.attributes["name"] = libraryPrefix + name }
                /// EN: Rewrite layer references, including descendants, according to the validated layer map.
                ///
                /// JA: 検証済みのレイヤー対応表に従って、子要素を含むレイヤー参照を書き換える。
                ///
                /// DE: Lagenverweise einschließlich untergeordneter Elemente gemäß der geprüften Lagenzuordnung
                ///     umschreiben.
                func remapLayers(_ node: EagleXMLNode) {
                    if let old = node.attributes["layer"], let new = layerMap[old] { node.attributes["layer"] = new }
                    for child in node.children { remapLayers(child) }
                }
                remapLayers(copy); libraries.children.append(copy)
            }
            var classMap: [String: String] = [:]
            let sourceClasses = source.child(named: "classes")?.children.filter { $0.name == "class" } ?? []
            let classSignature = sourceClasses.map { EagleXMLWriter.serialize($0).base64EncodedString() }.joined(
                separator: ";")
            if let existing = classSets[classSignature] {
                classMap = existing
            } else {
                for entry in sourceClasses {
                    guard let number = entry.attributes["number"] else { continue }
                    guard nextClass < 16 else {
                        throw RoutingError.invalid(
                            L10n.text(
                                "This panel exceeds EAGLE's 16 net classes. Reduce the number of boards or classes.",
                                "EAGLEのネットクラス数上限（16）を超えています。基板数またはクラス数を減らしてください。",
                                "Dieser Nutzen überschreitet die EAGLE-Grenze von 16 Netzklassen. Verringern Sie die Anzahl der Leiterplatten oder Netzklassen."
                            ))
                    }
                    classMap[number] = String(nextClass); nextClass += 1
                }
                for entry in sourceClasses {
                    let copy = entry.deepCopy()
                    copy.attributes["number"] = classMap[entry.attributes["number"] ?? "0"]
                    copy.attributes["name"] = prefix + (entry.attributes["name"] ?? "default")
                    for clearance in copy.children {
                        if let value = clearance.attributes["class"] {
                            clearance.attributes["class"] = classMap[value] ?? value
                        }
                    }
                    classes.children.append(copy)
                }
                classSets[classSignature] = classMap
            }
            for item in source.child(named: "plain")?.children ?? [] where item.attributes["layer"] != dimensionLayer {
                let copy = item.deepCopy(); move(copy, by: placement.offset, prefix: prefix, layers: layerMap);
                plain.children.append(copy)
            }
            for item in source.child(named: "elements")?.children ?? [] {
                let copy = item.deepCopy()
                if let name = copy.attributes["library"] { copy.attributes["library"] = libraryPrefix + name }
                move(copy, by: placement.offset, prefix: prefix, layers: layerMap); elements.children.append(copy)
            }
            for item in source.child(named: "signals")?.children ?? [] {
                let copy = item.deepCopy()
                copy.attributes["class"] = classMap[copy.attributes["class"] ?? "0"] ?? "0"
                move(copy, by: placement.offset, prefix: prefix, layers: layerMap); signals.children.append(copy)
            }
        }
        if !layers.children.contains(where: { $0.attributes["number"] == vScoreLayer }) && options.addVScoreSeparators {
            layers.children.append(
                EagleXMLNode(
                    name: "layer",
                    attributes: [
                        "number": vScoreLayer, "name": "Vscore", "color": "7", "fill": "1", "visible": "yes",
                        "active": "yes",
                    ]))
        }
        plain.children += routing.segments.map {
            wire(
                x1: $0.a.x, y1: $0.a.y, x2: $0.b.x, y2: $0.b.y, width: options.dimensionLineWidthMM,
                layer: dimensionLayer)
        }
        plain.children += try layout.guides(options: options).map {
            wire(x1: $0.a.x, y1: $0.a.y, x2: $0.b.x, y2: $0.b.y, width: options.vScoreLineWidthMM, layer: vScoreLayer)
        }
        var holes = routing.mouseBites.map { ($0, options.mouseBiteDiameterMM) }
        if options.addMountingHoles {
            let b = layout.panelBounds, dx = options.mountingHoleOffsetXMM, dy = options.mountingHoleOffsetYMM
            holes += [
                (RoutePoint(x: b.minX + dx, y: b.minY + dy), options.mountingHoleDrillMM),
                (RoutePoint(x: b.maxX - dx, y: b.minY + dy), options.mountingHoleDrillMM),
                (RoutePoint(x: b.minX + dx, y: b.maxY - dy), options.mountingHoleDrillMM),
                (RoutePoint(x: b.maxX - dx, y: b.maxY - dy), options.mountingHoleDrillMM),
            ]
        }
        plain.children += holes.map {
            EagleXMLNode(
                name: "hole",
                attributes: ["x": numberString($0.0.x), "y": numberString($0.0.y), "drill": numberString($0.1)])
        }
        board.children.removeAll { ["errors", "mfgpreviewcolors"].contains($0.name) }
        let b = layout.panelBounds
        let summary = PanelSummary(
            boardWidthMM: layout.arrayBounds.maxX, boardHeightMM: layout.arrayBounds.maxY,
            panelWidthMM: b.maxX - b.minX, panelHeightMM: b.maxY - b.minY, columns: options.columns,
            rows: layout.rowCount, dimensionLineWidthMM: options.dimensionLineWidthMM)
        let result = try PanelValidation.output(EagleXMLWriter.serialize(output), summary: summary, options: options)
        _ = try EagleXMLParser.parse(result.0)
        return result
    }

    /// EN: Convert XML outline elements to segments [mm]. Throw on unsupported elements or invalid arcs.
    ///
    /// JA: XMLの外形要素を線分 [mm] に変換する。未対応要素や不正円弧は例外にする。
    ///
    /// DE: XML-Konturelemente in Segmente [mm] umwandeln. Bei nicht unterstützten Elementen oder ungültigen
    ///     Kreisbögen einen Fehler auslösen.
    private static func routingSegments(_ node: EagleXMLNode) throws -> [RouteSegment] {
        /// EN: Convert validated arc approximation points to adjacent segments. Return an empty array for fewer than
        ///     two points.
        ///
        /// JA: 検証済みの円弧近似点を隣接する線分へ変換する。点が2個未満なら空配列。
        ///
        /// DE: Geprüfte Näherungspunkte eines Kreisbogens in benachbarte Segmente umwandeln. Bei weniger als zwei
        ///     Punkten ein leeres Array zurückgeben.
        func chain(_ points: [RoutePoint]) -> [RouteSegment] {
            zip(points, points.dropFirst()).map { RouteSegment(a: $0, b: $1) }
        }
        if node.name == "wire", let x1 = node.number("x1"), let y1 = node.number("y1"), let x2 = node.number("x2"),
            let y2 = node.number("y2")
        {
            let a = RoutePoint(x: x1, y: y1), b = RoutePoint(x: x2, y: y2)
            let theta = (node.number("curve") ?? 0) * .pi / 180
            if abs(theta) < 1e-8 || (b - a).length < 1e-8 { return [RouteSegment(a: a, b: b)] }
            let delta = b - a, mid = (a + b) * 0.5
            let center = mid + RoutePoint(x: -delta.y, y: delta.x) * (1 / (2 * tan(theta / 2)))
            var points = try PanelRouting.arc(center: center, start: a, sweep: theta)
            points[points.count - 1] = b
            return chain(points)
        }
        if node.name == "circle", let x = node.number("x"), let y = node.number("y"), let radius = node.number("radius")
        {
            return chain(
                try PanelRouting.arc(
                    center: RoutePoint(x: x, y: y), start: RoutePoint(x: x + radius, y: y), sweep: 2 * .pi))
        }
        throw RoutingError.invalid(
            L10n.text(
                "Use wires or circles for the EAGLE outline when routing tabs.",
                "タブ生成時のEAGLE外形にはwireまたはcircleを使用してください。",
                "Verwenden Sie für die EAGLE-Kontur beim Erstellen von Stegen Linien (wire) oder Kreise (circle)."))
    }

    /// EN: Convert original display names to fixed text. Validate position [mm] and rotation [degrees] when reparsing
    ///     output.
    ///
    /// JA: 元の表示名を固定テキストへ変換する。位置 [mm] と回転 [度] は出力再解析で検証する。
    ///
    /// DE: Ursprüngliche Anzeigenamen in festen Text umwandeln. Position [mm] und Drehwinkel [Grad] beim erneuten
    ///     Parsen der Ausgabe prüfen.
    private static func makeNameLabel(from packageText: EagleXMLNode, element: EagleXMLNode, fallbackName: String)
        -> EagleXMLNode
    {
        let label = packageText.deepCopy()
        let x = element.number("x") ?? 0
        let y = element.number("y") ?? 0
        var rotation = element.rotationDegrees
        if element.attributes["rot"]?.contains("M") == true { rotation = -rotation }
        let localX = packageText.number("x") ?? 0
        let localY = packageText.number("y") ?? 0
        let angle = rotation * .pi / 180
        let rotatedX = localX * cos(angle) - localY * sin(angle)
        let rotatedY = localX * sin(angle) + localY * cos(angle)
        label.attributes["x"] = numberString(x + rotatedX)
        label.attributes["y"] = numberString(y + rotatedY)
        label.text = fallbackName
        if let rot = element.attributes["rot"] { label.attributes["rot"] = rot }
        return label
    }

    /// EN: Deep-copy input-validated XML and apply placement offsets [mm] and identifiers without changing the source
    ///     tree.
    ///
    /// JA: 入力検証済みXMLを深く複製し、配置オフセット [mm] と識別子を反映する。元ツリーは変更しない。
    ///
    /// DE: Eingabegeprüftes XML tief kopieren und Platzierungsversätze [mm] sowie Kennungen anwenden, ohne den
    ///     Quellbaum zu ändern.
    private static func offsetCopy(
        _ source: EagleXMLNode, column: Int, row: Int,
        columnOffset: Double, rowOffset: Double, recursive: Bool
    ) -> EagleXMLNode {
        let copy = source.deepCopy()
        let suffix = "-\(column)-\(row)"
        if ["element", "signal"].contains(copy.name), let value = copy.attributes["name"] {
            copy.attributes["name"] = value + suffix
        }
        if copy.name == "contactref", let value = copy.attributes["element"] {
            copy.attributes["element"] = value + suffix
        }
        for key in ["x", "x1", "x2"] {
            if let value = copy.number(key) {
                copy.attributes[key] = numberString(value + Double(column) * columnOffset)
            }
        }
        for key in ["y", "y1", "y2"] {
            if let value = copy.number(key) { copy.attributes[key] = numberString(value + Double(row) * rowOffset) }
        }
        if recursive {
            copy.children = source.children.map {
                offsetCopy(
                    $0, column: column, row: row, columnOffset: columnOffset, rowOffset: rowOffset, recursive: true)
            }
        }
        return copy
    }

    /// EN: Build a wire element from validated endpoints [mm], line width [mm] and layer name. Revalidate final XML
    ///     before returning.
    ///
    /// JA: 検証済み端点 [mm]・線幅 [mm]・レイヤー名からwire要素を構築する。最終XMLは返却前に再検証する。
    ///
    /// DE: Ein wire-Element aus geprüften Endpunkten [mm], Linienbreite [mm] und Lagenname erstellen. Das fertige XML
    ///     vor der Rückgabe erneut prüfen.
    private static func wire(x1: Double, y1: Double, x2: Double, y2: Double, width: Double, layer: String)
        -> EagleXMLNode
    {
        EagleXMLNode(
            name: "wire",
            attributes: [
                "x1": numberString(x1), "y1": numberString(y1),
                "x2": numberString(x2), "y2": numberString(y2),
                "width": numberString(width), "layer": layer,
            ])
    }

    /// EN: Format numbers using a decimal point, assuming validated inputs and intermediate results.
    ///
    /// JA: 入力・中間結果が検証済みであることを前提に、数値を小数点が常にピリオドの文字列へ変換する。
    ///
    /// DE: Zahlen mit einem Dezimalpunkt formatieren; geprüfte Eingaben und Zwischenergebnisse werden vorausgesetzt.
    private static func numberString(_ value: Double) -> String {
        String(format: "%.10g", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

private final class EagleXMLNode {
    let name: String
    var attributes: [String: String]
    var text: String
    var children: [EagleXMLNode]
    weak var parent: EagleXMLNode?

    init(name: String, attributes: [String: String] = [:], text: String = "", children: [EagleXMLNode] = []) {
        self.name = name
        self.attributes = attributes
        self.text = text
        self.children = children
        for child in children { child.parent = self }
    }

    /// EN: Return the specified immediate child, or nil if absent. The caller checks whether it is required.
    ///
    /// JA: 直下の指定要素を返す。見つからなければnilを返し、必須要素の判定は呼び出し元で行う。
    ///
    /// DE: Das angegebene direkte Kindelement oder bei Fehlen nil zurückgeben. Der Aufrufer prüft, ob es erforderlich
    ///     ist.
    func child(named name: String) -> EagleXMLNode? { children.first { $0.name == name } }
    /// EN: Return descendants with the specified name. Recursion depth was limited when reading XML.
    ///
    /// JA: 指定名の子孫要素を返す。再帰深度はXML読み込み時に制限済み。
    ///
    /// DE: Nachfahren mit dem angegebenen Namen zurückgeben. Die Rekursionstiefe wurde beim Einlesen des XML
    ///     begrenzt.
    func descendants(named name: String) -> [EagleXMLNode] {
        children.flatMap { child in (child.name == name ? [child] : []) + child.descendants(named: name) }
    }
    /// EN: Return an attribute as a number, or nil if missing or unconvertible. The parser also validates its range.
    ///
    /// JA: 属性を数値として返す。属性欠落・変換失敗はnil。属性の範囲はパーサーでも検証する。
    ///
    /// DE: Ein Attribut als Zahl zurückgeben, bei fehlendem oder nicht konvertierbarem Wert nil. Der Parser prüft
    ///     zusätzlich den Wertebereich.
    func number(_ key: String) -> Double? { attributes[key].flatMap(Double.init) }
    var rotationDegrees: Double {
        guard let rotation = attributes["rot"] else { return 0 }
        let value = rotation.drop(while: { !$0.isNumber && $0 != "-" && $0 != "." })
        return Double(value) ?? 0
    }
    /// EN: Return an independent XML tree with parent/child links preserved. Source depth was limited on input.
    ///
    /// JA: 親子参照を保つ独立したXMLツリーを返す。元ツリーの深さは読み込み時に制限済み。
    ///
    /// DE: Einen unabhängigen XML-Baum mit erhaltenen Eltern-Kind-Verweisen zurückgeben. Die Quelltiefe wurde beim
    ///     Einlesen begrenzt.
    func deepCopy() -> EagleXMLNode {
        EagleXMLNode(name: name, attributes: attributes, text: text, children: children.map { $0.deepCopy() })
    }
}

private final class EagleXMLParser: NSObject, XMLParserDelegate {
    private var stack: [EagleXMLNode] = []
    private var root: EagleXMLNode?
    private var failure: Error?
    /// EN: Number of elements read [items]. Limit total memory use separately from recursion depth.
    ///
    /// JA: 読み込み済み要素数 [個]。深度制限とは別に総メモリ消費を制限する。
    ///
    /// DE: Anzahl eingelesener Elemente [Elemente]. Den gesamten Speicherverbrauch unabhängig von der Rekursionstiefe
    ///     begrenzen.
    private var nodeCount = 0

    /// EN: Return an XML tree with validated size, structure and numeric attributes. Throw on empty data or invalid
    ///     structure.
    ///
    /// JA: サイズ・構造・数値属性を検証したXMLツリーを返す。空データや構造異常は例外。
    ///
    /// DE: Einen XML-Baum mit geprüfter Größe, Struktur und Zahlenattributen zurückgeben. Bei leeren Daten oder
    ///     ungültiger Struktur einen Fehler auslösen.
    static func parse(_ data: Data) throws -> EagleXMLNode {
        try PanelValidation.document(data, field: "EagleXMLParser.input")
        let delegate = EagleXMLParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false
        guard parser.parse(), let root = delegate.root else {
            if let failure = delegate.failure { throw failure }
            throw EaglePanelError.malformedXML(
                parser.parserError?.localizedDescription
                    ?? L10n.text("Unknown XML error", "不明なXMLエラー", "Unbekannter XML-Fehler"))
        }
        return root
    }

    /// EN: Handle XML parser events. Abort parsing and retain the error if element count, depth or numeric limits are
    ///     violated.
    ///
    /// JA: XML解析イベントを処理する。要素数・深さ・数値の制約違反は解析を中断して保持する。
    ///
    /// DE: XML-Parserereignisse verarbeiten. Bei Verletzung der Grenzen für Elementanzahl, Tiefe oder Zahlen das
    ///     Parsen abbrechen und den Fehler bewahren.
    func parser(
        _ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        nodeCount += 1
        guard stack.count < PanelLimits.maxParserDepth && nodeCount <= PanelLimits.maxSyntaxNodes else {
            failure = PanelValidation.invalid("EagleXMLParser.depth/nodes", "within parser limits")
            parser.abortParsing()
            return
        }
        // EN: EAGLE XML attributes are strings; also check that they can be converted to Double.
        // JA: EAGLEのXML属性は文字列なので、Doubleへ変換できることも確認する。
        // DE: EAGLE-XML-Attribute sind Zeichenketten; zusätzlich ihre Konvertierbarkeit zu Double prüfen.
        do {
            for (key, value) in attributeDict {
                if ["x", "x1", "x2", "y", "y1", "y2"].contains(key) {
                    guard let coordinate = Double(value) else {
                        throw PanelValidation.invalid("EAGLE." + elementName + "." + key, "numeric coordinate")
                    }
                    try PanelValidation.number(
                        coordinate, field: "EAGLE." + key + "MM",
                        range: -PanelLimits.maxCoordinateMM...PanelLimits.maxCoordinateMM)
                }
                if ["width", "height", "radius", "drill", "dx", "dy", "size"].contains(key) {
                    guard let measurement = Double(value) else {
                        throw PanelValidation.invalid("EAGLE." + elementName + "." + key, "numeric measurement")
                    }
                    try PanelValidation.number(
                        measurement, field: "EAGLE." + key + "MM", range: 0...PanelLimits.maxMeasurementMM)
                }
                if key == "rot" {
                    let angleText = value.drop(while: { $0 == "S" || $0 == "M" || $0 == "R" })
                    guard let angle = Double(angleText) else {
                        throw PanelValidation.invalid("EAGLE.rot", "rotation in degrees")
                    }
                    try PanelValidation.number(
                        angle, field: "EAGLE.rotDegrees",
                        range: -PanelLimits.maxRotationDegrees...PanelLimits.maxRotationDegrees)
                }
            }
        } catch {
            failure = error
            parser.abortParsing()
            return
        }
        let node = EagleXMLNode(name: elementName, attributes: attributeDict)
        if let parent = stack.last { parent.children.append(node); node.parent = parent } else { root = node }
        stack.append(node)
    }
    /// EN: Handle XML parser events. Abort parsing and retain the error if element count, depth or numeric limits are
    ///     violated.
    ///
    /// JA: XML解析イベントを処理する。要素数・深さ・数値の制約違反は解析を中断して保持する。
    ///
    /// DE: XML-Parserereignisse verarbeiten. Bei Verletzung der Grenzen für Elementanzahl, Tiefe oder Zahlen das
    ///     Parsen abbrechen und den Fehler bewahren.
    func parser(
        _ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?
    ) {
        // EN: A sibling belongs to the enclosing element, not the element that just ended. This also applies to
        //     self-closing XML elements.
        // JA: 兄弟要素の親は直前に終了した要素ではなく、その外側の要素。自己終了するXML要素にも適用する。
        // DE: Ein Geschwisterelement gehört zum umschließenden Element, nicht zum gerade beendeten. Dies gilt auch
        //     für selbstschließende XML-Elemente.
        _ = stack.popLast()
    }
    /// EN: Handle XML parser events. Abort parsing and retain the error if element count, depth or numeric limits are
    ///     violated.
    ///
    /// JA: XML解析イベントを処理する。要素数・深さ・数値の制約違反は解析を中断して保持する。
    ///
    /// DE: XML-Parserereignisse verarbeiten. Bei Verletzung der Grenzen für Elementanzahl, Tiefe oder Zahlen das
    ///     Parsen abbrechen und den Fehler bewahren.
    func parser(_ parser: XMLParser, foundCharacters string: String) { stack.last?.text += string }
    /// EN: Handle XML parser events. Abort parsing and retain the error if element count, depth or numeric limits are
    ///     violated.
    ///
    /// JA: XML解析イベントを処理する。要素数・深さ・数値の制約違反は解析を中断して保持する。
    ///
    /// DE: XML-Parserereignisse verarbeiten. Bei Verletzung der Grenzen für Elementanzahl, Tiefe oder Zahlen das
    ///     Parsen abbrechen und den Fehler bewahren.
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // EN: Do not overwrite field-specific validation errors with secondary errors caused by abortParsing.
        // JA: abortParsing由来の二次エラーで、項目名付きの検証エラーを上書きしない。
        // DE: Feldbezogene Validierungsfehler nicht durch Folgefehler von abortParsing überschreiben.
        if failure == nil {
            failure = EaglePanelError.malformedXML(parseError.localizedDescription)
        }
    }
    /// EN: Handle XML parser events. Abort parsing and retain the error if element count, depth or numeric limits are
    ///     violated.
    ///
    /// JA: XML解析イベントを処理する。要素数・深さ・数値の制約違反は解析を中断して保持する。
    ///
    /// DE: XML-Parserereignisse verarbeiten. Bei Verletzung der Grenzen für Elementanzahl, Tiefe oder Zahlen das
    ///     Parsen abbrechen und den Fehler bewahren.
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) { failure = validationError }
}

private enum EagleXMLWriter {
    /// EN: Serialize the validated XML tree as UTF-8 data. Revalidate size and numbers at the receiving function
    ///     boundary.
    ///
    /// JA: 検証済みXMLツリーをUTF-8データへ直列化する。返却先の関数境界でサイズと数値を再検証する。
    ///
    /// DE: Den geprüften XML-Baum als UTF-8-Daten serialisieren. Größe und Zahlen an der empfangenden Funktionsgrenze
    ///     erneut prüfen.
    static func serialize(_ root: EagleXMLNode) -> Data {
        var output = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE eagle SYSTEM \"eagle.dtd\">\n"
        write(root, depth: 0, into: &output)
        return Data(output.utf8)
    }

    /// EN: Recursively write a depth-limited tree. depth is the indentation level; output is the append destination.
    ///
    /// JA: 深さ制限済みのツリーを再帰的に書き出す。depthはインデント段数、outputは追記先。
    ///
    /// DE: Einen tiefenbegrenzten Baum rekursiv schreiben. depth ist die Einrückungstiefe, output das Ziel zum
    ///     Anhängen.
    private static func write(_ node: EagleXMLNode, depth: Int, into output: inout String) {
        let indent = String(repeating: "  ", count: depth)
        output += indent + "<" + node.name
        for key in node.attributes.keys.sorted() {
            output += " \(key)=\"\(escape(node.attributes[key] ?? "", attribute: true))\""
        }
        if node.children.isEmpty && node.text.isEmpty {
            output += "/>\n"
            return
        }
        output += ">"
        if node.children.isEmpty {
            output += escape(node.text, attribute: false) + "</\(node.name)>\n"
        } else {
            if !node.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                output += escape(node.text, attribute: false)
            }
            output += "\n"
            for child in node.children { write(child, depth: depth + 1, into: &output) }
            output += indent + "</\(node.name)>\n"
        }
    }

    /// EN: Return text or attribute values with reserved XML characters escaped.
    ///
    /// JA: テキストまたは属性値のXML予約文字をエスケープした文字列を返す。
    ///
    /// DE: Text oder Attributwerte mit maskierten reservierten XML-Zeichen zurückgeben.
    private static func escape(_ value: String, attribute: Bool) -> String {
        var escaped = value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        if attribute { escaped = escaped.replacingOccurrences(of: "\"", with: "&quot;") }
        return escaped
    }
}
