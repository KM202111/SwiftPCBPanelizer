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

enum KiCadPanelEngine {
    private static let geometryHeads: Set<String> = [
        "footprint", "segment", "via", "arc", "zone", "gr_line", "gr_arc", "gr_rect",
        "gr_poly", "gr_circle", "gr_curve", "gr_text", "gr_text_box", "dimension", "target", "image", "group",
        "table", "barcode", "point", "generated",
    ]
    private static let coordinateHeads: Set<String> = [
        "at", "start", "end", "mid", "center", "xy", "xy1", "xy2", "origin", "position",
    ]

    /// EN: Validate KiCad input and settings, then return copied data and dimensions. Keep footprint coordinates
    ///     local.
    ///
    /// JA: KiCad入力と設定を検証し、複製結果と寸法を返す。フットプリント内の座標はローカルのまま保持する。
    ///
    /// DE: KiCad-Eingabe und Einstellungen prüfen, dann kopierte Daten und Abmessungen zurückgeben.
    ///     Footprint-Koordinaten lokal belassen.
    static func panelize(data: Data, options: PanelOptions) throws -> (Data, PanelSummary) {
        try PanelRouting.validate(options)
        var root = try parseRoot(data)
        guard options.columns > 0, options.rows > 0 else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "Columns and rows must be at least one.", "列数と行数は1以上にしてください。",
                    "Spalten- und Zeilenanzahl müssen mindestens 1 betragen."))
        }
        let measurements = [
            options.columnGapMM, options.rowGapMM, options.horizontalFrameMM,
            options.verticalFrameMM, options.mountingHoleOffsetXMM, options.mountingHoleOffsetYMM,
            options.dimensionLineWidthMM, options.vScoreLineWidthMM,
        ]
        guard measurements.allSatisfy({ $0 >= 0 }), !options.addMountingHoles || options.mountingHoleDrillMM > 0 else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "Spacing and frame widths must be nonnegative; the drill diameter must be positive.",
                    "間隔と外枠は0以上、ドリル径は0より大きくしてください。",
                    "Abstände und Rahmenbreiten müssen mindestens 0 betragen; der Bohrdurchmesser muss größer als 0 sein."
                ))
        }
        let boardOutline = root.compactMap { expression -> [BoardPoint]? in
            guard let head = expression.head,
                ["gr_line", "gr_arc", "gr_rect", "gr_poly", "gr_circle", "gr_curve"].contains(head),
                expression.directList("layer")?.scalar(at: 1) == "Edge.Cuts"
            else { return nil }
            return geometryPoints(expression)
        }.flatMap { $0 }
        guard !boardOutline.isEmpty else { throw KiCadPanelError.noEdgeCuts }
        let minX = boardOutline.map(\.x).min()!, maxX = boardOutline.map(\.x).max()!
        let minY = boardOutline.map(\.y).min()!, maxY = boardOutline.map(\.y).max()!
        guard maxX > minX, maxY > minY else { throw KiCadPanelError.noEdgeCuts }

        let boardWidth = maxX - minX
        let boardHeight = maxY - minY
        let xStep = boardWidth + max(0, options.columnGapMM)
        let yStep = boardHeight + max(0, options.rowGapMM)
        let panelMinX = minX - options.verticalFrameMM - options.frameGapMM
        let panelMinY = minY - options.horizontalFrameMM - options.frameGapMM
        let panelMaxX =
            minX + xStep * Double(options.columns) - options.columnGapMM + options.verticalFrameMM + options.frameGapMM
        let panelMaxY =
            minY + yStep * Double(options.rows) - options.rowGapMM + options.horizontalFrameMM + options.frameGapMM
        let routed = options.frameGapMM > 0 || options.addTabs
        let routingPlan =
            routed
            ? try PanelRouting.plan(
                contours: PanelRouting.closedLoops(
                    root.filter { $0.directList("layer")?.scalar(at: 1) == "Edge.Cuts" }.flatMap {
                        try routingSegments($0)
                    }), bounds: RouteRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY), options: options)
            : RoutingPlan(segments: [], mouseBites: [])
        let routedEdges = routingPlan.segments

        var rebuilt: [SExpression] = []
        var insertedGeometry = false
        for expression in root {
            if routed && expression.directList("layer")?.scalar(at: 1) == "Edge.Cuts" { continue }
            guard let head = expression.head, geometryHeads.contains(head) else {
                rebuilt.append(expression)
                continue
            }
            if !insertedGeometry {
                for row in 0..<options.rows {
                    for column in 0..<options.columns {
                        var copy = expression.deepCopy()
                        let isOriginalCell = row == 0 && column == 0
                        translate(
                            &copy, dx: Double(column) * xStep, dy: Double(row) * yStep, footprint: head == "footprint")
                        if !isOriginalCell {
                            replaceUUIDs(&copy)
                            if head == "footprint" { disambiguateReference(&copy, row: row + 1, column: column + 1) }
                        }
                        rebuilt.append(copy)
                    }
                }
                insertedGeometry = true
            } else {
                // EN: Each original geometry item is expanded at its original position.
                // JA: 元の各図形要素を、それぞれの元の位置で展開する。
                // DE: Jedes ursprüngliche Geometrieelement an seiner ursprünglichen Position vervielfältigen.
                for row in 0..<options.rows {
                    for column in 0..<options.columns {
                        var copy = expression.deepCopy()
                        let isOriginalCell = row == 0 && column == 0
                        translate(
                            &copy, dx: Double(column) * xStep, dy: Double(row) * yStep, footprint: head == "footprint")
                        if !isOriginalCell {
                            replaceUUIDs(&copy)
                            if head == "footprint" { disambiguateReference(&copy, row: row + 1, column: column + 1) }
                        }
                        rebuilt.append(copy)
                    }
                }
            }
        }

        guard insertedGeometry else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "No board items are available to duplicate.", "複製できる基板要素がありません。",
                    "Es sind keine Leiterplattenelemente zum Duplizieren vorhanden."))
        }
        let outline = makeRectangle(
            minX: panelMinX, minY: panelMinY, maxX: panelMaxX, maxY: panelMaxY,
            width: max(0.05, options.dimensionLineWidthMM))
        if routed {
            rebuilt += routedEdges.map {
                makeLine(
                    start: BoardPoint(x: $0.a.x, y: $0.a.y), end: BoardPoint(x: $0.b.x, y: $0.b.y),
                    width: max(0.05, options.dimensionLineWidthMM), layer: "Edge.Cuts")
            }
        } else if options.panelCornerRadiusMM > 0 && options.verticalFrameMM > 0 && options.horizontalFrameMM > 0 {
            let loop = try PanelRouting.roundedRectangle(
                RouteRect(minX: panelMinX, minY: panelMinY, maxX: panelMaxX, maxY: panelMaxY),
                radius: options.panelCornerRadiusMM)
            rebuilt += PanelRouting.edges(loop).map {
                makeLine(
                    start: BoardPoint(x: $0.a.x, y: $0.a.y), end: BoardPoint(x: $0.b.x, y: $0.b.y),
                    width: max(0.05, options.dimensionLineWidthMM), layer: "Edge.Cuts")
            }
        } else {
            rebuilt.append(outline)
        }
        if options.addVScoreSeparators {
            if options.columns > 1 {
                for column in 1..<options.columns {
                    let x = minX + Double(column) * xStep - max(0, options.columnGapMM) / 2
                    rebuilt.append(
                        makeLine(
                            start: BoardPoint(x: x, y: panelMinY), end: BoardPoint(x: x, y: panelMaxY),
                            width: options.vScoreLineWidthMM, layer: "Dwgs.User"))
                }
            }
            if options.rows > 1 {
                for row in 1..<options.rows {
                    let y = minY + Double(row) * yStep - max(0, options.rowGapMM) / 2
                    rebuilt.append(
                        makeLine(
                            start: BoardPoint(x: panelMinX, y: y), end: BoardPoint(x: panelMaxX, y: y),
                            width: options.vScoreLineWidthMM, layer: "Dwgs.User"))
                }
            }
        }
        if options.addMountingHoles {
            let dx = options.mountingHoleOffsetXMM
            let dy = options.mountingHoleOffsetYMM
            let points = [
                BoardPoint(x: panelMinX + dx, y: panelMinY + dy),
                BoardPoint(x: panelMaxX - dx, y: panelMinY + dy),
                BoardPoint(x: panelMinX + dx, y: panelMaxY - dy),
                BoardPoint(x: panelMaxX - dx, y: panelMaxY - dy),
            ]
            var usedReferences = Set(
                root.compactMap { footprint -> String? in
                    guard footprint.head == "footprint" else { return nil }
                    return footprint.directList("property").flatMap {
                        $0.scalar(at: 1) == "Reference" ? $0.scalar(at: 2) : nil
                    }
                })
            for (index, point) in points.enumerated() {
                var suffix = index + 1
                while usedReferences.contains("PH\(suffix)") { suffix += 1 }
                let reference = "PH\(suffix)"
                usedReferences.insert(reference)
                rebuilt.append(makeMountingHole(at: point, diameter: options.mountingHoleDrillMM, reference: reference))
            }
        }
        var usedReferences = Set(
            rebuilt.compactMap { $0.directList("property") }.filter { $0.scalar(at: 1) == "Reference" }.compactMap {
                $0.scalar(at: 2)
            })
        var biteIndex = 1
        for point in routingPlan.mouseBites {
            while usedReferences.contains("PMB\(biteIndex)") { biteIndex += 1 }
            let reference = "PMB\(biteIndex)"
            usedReferences.insert(reference)
            var hole = makeMountingHole(
                at: BoardPoint(x: point.x, y: point.y), diameter: options.mouseBiteDiameterMM, reference: reference)
            if case .list(var items) = hole {
                for i in items.indices where items[i].head == "property" {
                    if case .list(var property) = items[i] {
                        property.append(.list([.atom("hide"), .atom("yes")]))
                        items[i] = .list(property)
                    }
                }
                hole = .list(items)
            }
            rebuilt.append(hole)
        }
        root = rebuilt
        let summary = PanelSummary(
            boardWidthMM: boardWidth, boardHeightMM: boardHeight,
            panelWidthMM: panelMaxX - panelMinX, panelHeightMM: panelMaxY - panelMinY,
            columns: options.columns, rows: options.rows, dimensionLineWidthMM: options.dimensionLineWidthMM)
        return try PanelValidation.output(
            Data((SExpression.list(root).render() + "\n").utf8), summary: summary, options: options)
    }

    /// EN: Validate UTF-8, size, trailing content, structure and numbers; return the kicad_pcb root's elements.
    ///
    /// JA: UTF-8・サイズ・末尾・構造・数値を検証し、kicad_pcbルートの要素配列を返す。
    ///
    /// DE: UTF-8, Größe, nachfolgenden Inhalt, Struktur und Zahlen prüfen; die Elemente der kicad_pcb-Wurzel
    ///     zurückgeben.
    private static func parseRoot(_ data: Data) throws -> [SExpression] {
        try PanelValidation.document(data, field: "KiCadPanelEngine.parseRoot.input")
        guard let text = String(data: data, encoding: .utf8) else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "The KiCad file is not valid UTF-8.", "KiCadファイルの文字コードが正しいUTF-8ではありません。",
                    "Die KiCad-Datei ist nicht gültig UTF-8-kodiert."))
        }
        var parser = SExpressionParser(text)
        guard case .list(let root) = try parser.parseDocument(), root.first?.scalar == "kicad_pcb" else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "The kicad_pcb root element is missing.", "ルート要素kicad_pcbがありません。",
                    "Das Wurzelelement kicad_pcb fehlt."))
        }
        try validateGeometryNumbers(.list(root))
        return root
    }

    /// EN: Validate parsed numbers before use. Distinguish identifiers, net codes and format versions from
    ///     dimensions.
    ///
    /// JA: パース済み数値を使用前に検証する。識別子・ネット番号・形式バージョンは寸法と混同しない。
    ///
    /// DE: Geparste Zahlen vor der Verwendung prüfen. Kennungen, Netznummern und Formatversionen von Abmessungen
    ///     unterscheiden.
    private static func validateGeometryNumbers(_ expression: SExpression) throws {
        guard case .list(let values) = expression else {
            return
        }
        let name = expression.head ?? ""
        if coordinateHeads.contains(name), values.count >= 3, values[1].scalar != nil {
            guard let x = values[1].number, let y = values[2].number else {
                throw PanelValidation.invalid("KiCad." + name, "numeric x/y coordinates")
            }
            try PanelRouting.validatePoints([RoutePoint(x: x, y: y)])
            if name == "at", values.count > 3, let angle = values[3].number {
                try PanelValidation.number(
                    angle, field: "KiCad.at.angleDegrees",
                    range: -PanelLimits.maxRotationDegrees...PanelLimits.maxRotationDegrees)
            }
        }
        if ["size", "width", "thickness", "radius", "diameter"].contains(name) {
            for value in values.dropFirst() {
                if let scalar = value.scalar {
                    guard let number = Double(scalar) else {
                        throw PanelValidation.invalid("KiCad." + name, "numeric measurement")
                    }
                    try PanelValidation.number(
                        number, field: "KiCad." + name + "MM", range: 0...PanelLimits.maxMeasurementMM)
                }
            }
        }
        if name == "drill" {
            let dimensions = values.dropFirst().filter { $0.scalar != "oval" && $0.scalar != nil }
            for value in dimensions {
                guard let number = value.number else {
                    throw PanelValidation.invalid("KiCad.drill", "numeric diameter")
                }
                try PanelValidation.number(
                    number, field: "KiCad.drillMM", range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
            }
        }
        for child in values {
            try validateGeometryNumbers(child)
        }
    }

    /// EN: KiCad's importer can serialize UNDEFINED on an unmapped annotation or a default footprint field. Resolve
    ///     those annotations before combining boards, and never invent a copper assignment for an electrical item.
    ///
    /// JA: KiCadのインポーターは、対応のない注記や既定のフットプリントフィールドにUNDEFINEDを書き出す場合がある。基板統合前に注記を修復し、電気要素の銅箔層を推測して割り当てない。
    ///
    /// DE: Der KiCad-Importer kann bei nicht zugeordneten Beschriftungen oder Standard-Footprint-Feldern UNDEFINED
    ///     ausgeben. Diese Beschriftungen vor dem Zusammenführen korrigieren; elektrischen Elementen keine Kupferlage
    ///     auf Verdacht zuweisen.
    static func normalizeLayers(data: Data, repairImportedAnnotations: Bool = false) throws -> Data {
        var root = try parseRoot(data)
        var rows: [SExpression] = []
        if case .list(let table) = root.first(where: { $0.head == "layers" }) { rows = Array(table.dropFirst()) }
        let undefined: Set<String> = ["UNDEFINED", "Undefined", "Rescue", "UNSELECTED", "", "-1"]
        rows.removeAll { undefined.contains($0.scalar(at: 1) ?? "") }
        var declared = Set(rows.compactMap { $0.scalar(at: 1) })
        var aliases: [String: String] = [
            "User.Drawings": "Dwgs.User", "User.Comments": "Cmts.User", "User.Eco1": "Eco1.User",
            "User.Eco2": "Eco2.User",
            "F.Silkscreen": "F.SilkS", "B.Silkscreen": "B.SilkS", "F.Adhesive": "F.Adhes", "B.Adhesive": "B.Adhes",
            "F.Courtyard": "F.CrtYd", "B.Courtyard": "B.CrtYd",
        ]
        for row in rows {
            if let name = row.scalar(at: 1), let alias = row.scalar(at: 3), !alias.isEmpty, !declared.contains(alias) {
                aliases[alias] = name
            }
        }
        let modernIDs = rows.first(where: { $0.scalar(at: 1) == "B.Cu" })?.scalar(at: 0) == "2"
        let standard: [(String, Int, Int)] = [
            ("F.Cu", 0, 0), ("B.Cu", 2, 31), ("F.Adhes", 9, 33), ("B.Adhes", 11, 32),
            ("F.Paste", 13, 35), ("B.Paste", 15, 34), ("F.SilkS", 5, 37), ("B.SilkS", 7, 36),
            ("F.Mask", 1, 39), ("B.Mask", 3, 38), ("Dwgs.User", 17, 40), ("Cmts.User", 19, 41),
            ("Eco1.User", 21, 42), ("Eco2.User", 23, 43), ("Edge.Cuts", 25, 44), ("Margin", 27, 45),
            ("F.CrtYd", 31, 47), ("B.CrtYd", 29, 46), ("F.Fab", 35, 49), ("B.Fab", 33, 48),
        ]
        /// EN: Check or add required layer definitions. Throw on conflicting definition numbers.
        ///
        /// JA: 必要なレイヤー定義を確認または追加する。定義番号の衝突は例外。
        ///
        /// DE: Erforderliche Lagendefinitionen prüfen oder hinzufügen. Bei kollidierenden Definitionsnummern einen
        ///     Fehler auslösen.
        func ensure(_ name: String) throws {
            if declared.contains(name) { return }
            var number: Int?
            if let entry = standard.first(where: { $0.0 == name }), !name.hasSuffix(".Cu") {
                number = modernIDs ? entry.1 : entry.2
            }
            if name.hasPrefix("User."), let index = Int(name.dropFirst(5)), (1...9).contains(index) {
                number = modernIDs ? 39 + (index - 1) * 2 : 50 + index - 1
            }
            guard let number, !rows.contains(where: { $0.scalar(at: 0) == String(number) }) else {
                throw KiCadPanelError.invalidBoard(
                    L10n.text(
                        "The layer \(name) is missing from the board's layer definitions or its ID conflicts with another layer.",
                        "レイヤー\(name)の定義がないか、レイヤー番号が別の定義と衝突しています。",
                        "Der Layer \(name) fehlt in der Layerdefinition der Leiterplatte oder seine ID steht im Konflikt mit einem anderen Layer."
                    ))
            }
            rows.append(.list([.atom(String(number)), .string(name), .atom("user")]))
            declared.insert(name)
        }
        let graphicHeads: Set<String> = [
            "property", "fp_text", "fp_text_box", "fp_line", "fp_arc", "fp_rect", "fp_poly", "fp_circle", "fp_curve",
            "gr_text", "gr_text_box", "gr_line", "gr_arc", "gr_rect", "gr_poly", "gr_circle", "gr_curve", "dimension",
            "target", "image", "table", "table_cell", "barcode",
        ]
        let electricalHeads: Set<String> = ["segment", "arc", "via", "pad", "zone", "padstack"]
        let layerMasks: Set<String> = [
            "*.Cu", "*In.Cu", "F&B.Cu", "*.Adhes", "*.Paste", "*.Mask", "*.SilkS", "*.Fab", "*.CrtYd",
        ]
        /// EN: Recursively validate S-expression layer references. Apply distinct repair rules to electrical and
        ///     annotation items.
        ///
        /// JA: S式のレイヤー参照を再帰検証する。電気要素と注記要素の修復条件を区別する。
        ///
        /// DE: Lagenverweise in S-Ausdrücken rekursiv prüfen. Für elektrische Elemente und Beschriftungen
        ///     unterschiedliche Korrekturregeln anwenden.
        func walk(
            _ expression: inout SExpression, owner: String = "", field: String? = nil, back: Bool = false,
            electrical: Bool = false
        ) throws {
            guard case .list(var values) = expression, let head = values.first?.scalar else { return }
            let isElectrical = electrical || electricalHeads.contains(head)
            let side = head == "footprint" ? values.first(where: { $0.head == "layer" })?.scalar(at: 1) == "B.Cu" : back
            let fieldName = head == "property" || head == "fp_text" ? values.dropFirst().first?.scalar : field
            if repairImportedAnnotations, ["property", "fp_text", "fp_text_box"].contains(head),
                !values.contains(where: { $0.head == "layer" })
            {
                let reference = fieldName == "Reference" || fieldName == "reference"
                let layer = reference ? (side ? "B.SilkS" : "F.SilkS") : (side ? "B.Fab" : "F.Fab")
                values.append(.list([.atom("layer"), .string(layer)]))
            }
            if head == "layer" || head == "layers" {
                let indices =
                    head == "layer" ? Array(values.indices.dropFirst().prefix(1)) : Array(values.indices.dropFirst())
                for index in indices {
                    guard let old = values[index].scalar else { continue }
                    var name = declared.contains(old) ? old : aliases[old] ?? old
                    if layerMasks.contains(name) && head == "layers" { continue }
                    if name == "Inner" && owner == "padstack" { continue }
                    if undefined.contains(name) && repairImportedAnnotations && !isElectrical
                        && graphicHeads.contains(owner)
                    {
                        if fieldName == "Reference" || fieldName == "reference" {
                            name = side ? "B.SilkS" : "F.SilkS"
                        } else if fieldName == "Value" || fieldName == "value" || owner == "property" {
                            name = side ? "B.Fab" : "F.Fab"
                        } else {
                            name = "Cmts.User"
                        }
                    }
                    if undefined.contains(name) {
                        throw KiCadPanelError.invalidBoard(
                            L10n.text(
                                "An item of type \(owner) uses an undefined layer (\(old)). Its physical layer must be assigned before exporting the panel.",
                                "\(owner)要素に未定義レイヤー（\(old)）があります。基板上の所属レイヤーを指定してから出力してください。",
                                "Ein Element vom Typ \(owner) verwendet einen undefinierten Layer (\(old)). Weisen Sie ihm vor dem Export die richtige Lage auf der Leiterplatte zu."
                            ))
                    }
                    try ensure(name)
                    values[index] = .string(name)
                }
                expression = .list(values)
                return
            }
            for index in values.indices where values[index].head != nil {
                try walk(&values[index], owner: head, field: fieldName, back: side, electrical: isElectrical)
            }
            expression = .list(values)
        }
        for index in root.indices where geometryHeads.contains(root[index].head ?? "") {
            try walk(&root[index])
        }
        // EN: A stackup and custom layer references must follow the layer table. Keep metadata in its original order
        //     and put the table before setup.
        // JA: 積層構成とカスタムレイヤー参照はレイヤー表より後に置く必要がある。メタデータの順序を維持し、setupより前にレイヤー表を置く。
        // DE: Lagenaufbau und benutzerdefinierte Lagenverweise müssen auf die Lagentabelle folgen. Die
        //     Metadatenreihenfolge beibehalten und die Tabelle vor setup einfügen.
        root.removeAll { $0.head == "layers" }
        let insertion =
            root.firstIndex { $0.head == "setup" || geometryHeads.contains($0.head ?? "") || $0.head == "net" }
            ?? root.count
        root.insert(.list([.atom("layers")] + rows), at: insertion)
        let result = Data((SExpression.list(root).render() + "\n").utf8)
        try PanelValidation.document(result, field: "normalizeLayers.output")
        return result
    }

    /// EN: Parse Edge.Cuts and validate the returned bounding rectangle [mm] and closed contours.
    ///
    /// JA: Edge.Cutsを解析し、外接矩形 [mm] と閉ループの戻り値を検証する。
    ///
    /// DE: Edge.Cuts parsen und das zurückgegebene Begrenzungsrechteck [mm] sowie geschlossene Konturen prüfen.
    private static func shape(root: [SExpression]) throws -> PanelBoardShape {
        let loops = try PanelRouting.closedLoops(
            root.filter { $0.directList("layer")?.scalar(at: 1) == "Edge.Cuts" }.flatMap { try routingSegments($0) })
        let points = loops.flatMap { $0 }
        // EN: Arc cardinal points retain exact array dimensions; tessellated contours are used only for routing and
        //     have a maximum 0.005 mm chord deviation.
        // JA: 円弧の極値点で配列の正確な寸法を保持する。加工線だけに使う近似輪郭の最大弦誤差は0.005 mm。
        // DE: Kreisbogenextrema erhalten die exakten Array-Abmessungen. Polygonal angenäherte Konturen dienen nur dem
        //     Fräsen; die maximale Sehnenabweichung beträgt 0,005 mm.
        let measurements = root.filter { $0.directList("layer")?.scalar(at: 1) == "Edge.Cuts" }.flatMap {
            geometryPoints($0)
        }
        guard !points.isEmpty, !measurements.isEmpty else { throw KiCadPanelError.noEdgeCuts }
        let result = PanelBoardShape(
            bounds: RouteRect(
                minX: measurements.map(\.x).min()!, minY: measurements.map(\.y).min()!,
                maxX: measurements.map(\.x).max()!, maxY: measurements.map(\.y).max()!), contours: loops)
        try PanelValidation.shape(result, field: "KiCadPanelEngine.shape.output")
        return result
    }

    /// EN: Parse Edge.Cuts and validate the returned bounding rectangle [mm] and closed contours.
    ///
    /// JA: Edge.Cutsを解析し、外接矩形 [mm] と閉ループの戻り値を検証する。
    ///
    /// DE: Edge.Cuts parsen und das zurückgegebene Begrenzungsrechteck [mm] sowie geschlossene Konturen prüfen.
    static func shape(data: Data) throws -> PanelBoardShape { try shape(root: parseRoot(data)) }

    /// EN: Compute hole centers [mm], slot dimensions [mm] and rotation [degrees]; validate counts and ranges before
    ///     returning.
    ///
    /// JA: 穴の中心 [mm]・長穴寸法 [mm]・回転 [度] を計算し、穴数と値域を検証して返す。
    ///
    /// DE: Bohrungsmittelpunkte [mm], Langlochabmessungen [mm] und Drehwinkel [Grad] berechnen; Anzahl und
    ///     Wertebereiche vor der Rückgabe prüfen.
    static func previewDrills(data: Data) throws -> [PanelPreviewDrill] {
        let root = try parseRoot(data)
        var result: [PanelPreviewDrill] = []
        /// EN: Return at coordinates [mm] validated on input. If omitted, use the format's default origin.
        ///
        /// JA: 入力時に検証済みのat座標 [mm] を返す。省略時は形式既定値の原点。
        ///
        /// DE: Beim Einlesen geprüfte at-Koordinaten [mm] zurückgeben. Bei fehlender Angabe den formatseitigen
        ///     Standardursprung verwenden.
        func position(_ expression: SExpression) -> RoutePoint {
            let at = expression.directList("at")
            return RoutePoint(
                x: at?.scalar(at: 1).flatMap(Double.init) ?? 0, y: at?.scalar(at: 2).flatMap(Double.init) ?? 0)
        }
        for item in root {
            if item.head == "via", let diameter = item.directList("drill")?.scalar(at: 1).flatMap(Double.init),
                diameter > 0
            {
                let layers = item.directList("layers")
                let front = layers?.scalar(at: 1) == "F.Cu" || layers?.scalar(at: 2) == "F.Cu"
                let back = layers?.scalar(at: 1) == "B.Cu" || layers?.scalar(at: 2) == "B.Cu"
                result.append(
                    PanelPreviewDrill(
                        center: position(item), width: diameter, height: diameter, angle: 0, front: front, back: back))
            }
            guard item.head == "footprint", case .list(let fields) = item else { continue }
            let origin = position(item)
            let degrees = item.directList("at")?.scalar(at: 3).flatMap(Double.init) ?? 0
            let radians = -degrees * .pi / 180
            for pad in fields
            where pad.head == "pad" && ["thru_hole", "np_thru_hole"].contains(pad.scalar(at: 2) ?? "") {
                guard case .list(let drill) = pad.directList("drill") else { continue }
                let oval = drill.count > 1 && drill[1].scalar == "oval"
                let start = oval ? 2 : 1
                guard drill.indices.contains(start), let width = drill[start].number, width > 0 else { continue }
                let height = oval && drill.indices.contains(start + 1) ? (drill[start + 1].number ?? width) : width
                let local = position(pad)
                let center =
                    origin
                    + RoutePoint(
                        x: local.x * cos(radians) - local.y * sin(radians),
                        y: local.x * sin(radians) + local.y * cos(radians))
                // EN: Pad positions are footprint-local; pad angles in the board format are absolute. Drill offsets
                //     move the copper shape, while the hole itself remains at the pad's anchor position.
                // JA: パッド位置はフットプリント内のローカル座標だが、基板形式上のパッド角度は絶対角度。ドリルのオフセットは銅箔形状を移動させ、穴自体はパッドのアンカー位置に残る。
                // DE: Pad-Positionen sind relativ zum Footprint; Pad-Winkel im Platinenformat sind absolut.
                //     Bohrungsversätze verschieben die Kupferform, während die Bohrung an der Pad-Ankerposition
                //     bleibt.
                let angle = -(pad.directList("at")?.scalar(at: 3).flatMap(Double.init) ?? 0)
                result.append(
                    PanelPreviewDrill(
                        center: center, width: width, height: height, angle: angle, front: true, back: true))
            }
        }
        try PanelValidation.drills(result)
        return result
    }

    /// EN: Combine boards with matching layer stacks, isolate nets/UUIDs and return validated data and dimensions.
    ///
    /// JA: 層構成が一致する基板を統合し、ネット・UUIDを分離して、検証済みデータと寸法を返す。
    ///
    /// DE: Platinen mit gleichem Lagenaufbau zusammenführen, Netze und UUIDs trennen und geprüfte Daten sowie
    ///     Abmessungen zurückgeben.
    static func compose(data: [Data], options: PanelOptions, baseIndex: Int = 0) throws -> (Data, PanelSummary) {
        let options = options.forSourceCount(data.count)
        guard !data.isEmpty && data.count <= PanelLimits.maxBoardPositions else {
            throw PanelValidation.invalid(
                "KiCadPanelEngine.compose.data", "1...\(PanelLimits.maxBoardPositions) boards")
        }
        try PanelRouting.validate(options)
        let roots = try data.map { try parseRoot(normalizeLayers(data: $0)) }
        let shapes = try roots.map { try shape(root: $0) }
        let layout = try PanelCompositionLayout(bounds: shapes.map(\.bounds), options: options)
        let routing = try PanelRouting.plan(
            boards: layout.placedContours(shapes), arrayBounds: layout.arrayBounds, options: options)
        guard roots.indices.contains(baseIndex) else { throw KiCadPanelError.noEdgeCuts }
        /// EN: Return copper layer names in front-to-back definition order. Compare these arrays to check layer
        ///     stacks.
        ///
        /// JA: 銅箔レイヤー名を表面から裏面の定義順で返す。この配列の一致で層構成を比較する。
        ///
        /// DE: Kupferlagennamen in definierter Reihenfolge von vorne nach hinten zurückgeben. Diese Arrays zum
        ///     Vergleich des Lagenaufbaus verwenden.
        func copperLayers(_ root: [SExpression]) -> [String] {
            guard case .list(let table) = root.first(where: { $0.head == "layers" }) else { return [] }
            return table.dropFirst().compactMap { $0.scalar(at: 1) }.filter { $0.hasSuffix(".Cu") }
        }
        let stack = copperLayers(roots[baseIndex])
        guard roots.allSatisfy({ copperLayers($0) == stack }) else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "All boards in one panel must have the same copper layer stack. Match the copper layer count and order before combining them.",
                    "同じパネルに配置する基板は銅箔の層構成を揃えてください。銅箔の層数と順序が異なる基板は統合できません。",
                    "Alle Leiterplatten in einem Nutzen müssen denselben Kupferlagenaufbau haben. Gleichen Sie vor dem Zusammenfügen die Anzahl und Reihenfolge der Kupferlagen an."
                ))
        }
        let versions: [Int] = roots.map { root in
            let node = root.first { $0.head == "version" }
            return Int(node?.scalar(at: 1) ?? "0") ?? 0
        }
        let version = versions.max() ?? 20260206
        // EN: KiCad stopped serializing numeric net codes in format 20251028.
        // JA: KiCadは形式バージョン20251028から数値のネット番号を書き出さなくなった。
        // DE: Seit Formatversion 20251028 schreibt KiCad keine numerischen Netznummern mehr.
        let namedNets = version >= 20251028
        let nonGeometry: Set<String> = ["net", "embedded_files", "embedded_fonts", "layers"]
        var output = roots[baseIndex].filter {
            !geometryHeads.contains($0.head ?? "") && !nonGeometry.contains($0.head ?? "")
        }
        if let i = output.firstIndex(where: { $0.head == "version" }) {
            output[i] = .list([.atom("version"), .atom(String(version))])
        }
        // EN: Layer IDs changed between KiCad releases. Geometry uses layer names, so use the newest input's table
        //     while retaining the base board setup.
        // JA: KiCadの版によってレイヤーIDが異なる。図形はレイヤー名を使うため、基準基板の設定を保持しつつ、最も新しい入力のレイヤー表を使う。
        // DE: Lagen-IDs unterscheiden sich zwischen KiCad-Versionen. Da die Geometrie Lagennamen verwendet, die
        //     Tabelle der neuesten Eingabe nutzen und die Einstellungen der Basisplatine beibehalten.
        let newest =
            roots.firstIndex { root in root.first(where: { $0.head == "version" })?.scalar(at: 1) == String(version) }
            ?? baseIndex
        var layerRows: [SExpression] = []
        if case .list(let layers) = roots[newest].first(where: { $0.head == "layers" }) {
            layerRows = Array(layers.dropFirst())
        }
        var layerNames = Set(layerRows.compactMap { $0.scalar(at: 1) })
        for root in roots {
            if case .list(let table) = root.first(where: { $0.head == "layers" }) {
                for row in table.dropFirst() where !layerNames.contains(row.scalar(at: 1) ?? "") {
                    guard !layerRows.contains(where: { $0.scalar(at: 0) == row.scalar(at: 0) }) else {
                        throw KiCadPanelError.invalidBoard(
                            L10n.text(
                                "Custom layer IDs conflict between these boards. Save them with the same KiCad version and layer configuration.",
                                "基板間でカスタムレイヤーの番号が衝突しています。同じKiCadバージョンとレイヤー設定で保存してください。",
                                "Die benutzerdefinierten Layer-IDs dieser Leiterplatten stehen im Konflikt. Speichern Sie die Dateien mit derselben KiCad-Version und Layerkonfiguration."
                            ))
                    }
                    layerRows.append(row); if let name = row.scalar(at: 1) { layerNames.insert(name) }
                }
            }
        }
        let layerPosition = output.firstIndex { $0.head == "setup" } ?? output.count
        output.insert(.list([.atom("layers")] + layerRows), at: layerPosition)
        var netDeclarations: [SExpression] = [], geometry: [SExpression] = [], embedded: [SExpression] = []
        var embeddedByName: [String: String] = [:]
        var nextNet = 1
        if !namedNets { netDeclarations.append(.list([.atom("net"), .atom("0"), .string("")])) }
        for (instance, placement) in layout.placements.enumerated() {
            let index = placement.sourceIndex, root = roots[index]
            let prefix = "B\(instance + 1)/"
            var oldCodes: [String: String] = ["0": ""]
            for item in root where item.head == "net" {
                if let code = item.scalar(at: 1), let name = item.scalar(at: 2) { oldCodes[code] = name }
            }
            var codes: [String: Int] = [:]
            /// EN: Resolve old net codes or names in the new format. Throw on undefined net codes.
            ///
            /// JA: 旧ネット番号または新形式の名前を解決する。未定義のネット番号は例外とする。
            ///
            /// DE: Alte Netznummern oder Namen des neuen Formats auflösen. Bei nicht definierten Netznummern einen
            ///     Fehler auslösen.
            func netName(_ expression: SExpression) throws -> String? {
                guard case .list(let values) = expression, values.first?.scalar == "net", values.count >= 2 else {
                    return nil
                }
                if values.count >= 3 { return values[2].scalar }
                if case .atom(let value) = values[1], Int(value) != nil {
                    guard let name = oldCodes[value] else {
                        throw KiCadPanelError.invalidBoard(
                            L10n.text(
                                "A board item refers to an undefined net code.", "未定義のネット番号を参照する基板要素があります。",
                                "Ein Leiterplattenelement verweist auf eine undefinierte Netznummer."))
                    }
                    return name
                }
                return values[1].scalar
            }
            /// EN: Recursively convert net references in copied items. Validate undefined references before
            ///     rewriting.
            ///
            /// JA: コピーした要素のネット参照を再帰変換する。未定義参照を検証してから書き換える。
            ///
            /// DE: Netzverweise in kopierten Elementen rekursiv umwandeln. Vor dem Umschreiben auf undefinierte
            ///     Verweise prüfen.
            func rewrite(_ expression: inout SExpression) throws {
                guard case .list(var values) = expression else { return }
                if let name = try netName(expression) {
                    let full = name.isEmpty ? "" : prefix + name
                    if namedNets {
                        expression = .list([.atom("net"), .string(full)])
                    } else {
                        var code = 0
                        if !full.isEmpty {
                            if let existing = codes[full] {
                                code = existing
                            } else {
                                code = nextNet; nextNet += 1; codes[full] = code;
                                netDeclarations.append(.list([.atom("net"), .atom(String(code)), .string(full)]))
                            }
                        }
                        // EN: Pads carry the name; tracks/zones use only the code.
                        // JA: パッドにはネット名を持たせる。配線とゾーンではネット番号だけを使う。
                        // DE: Pads enthalten den Netznamen; Leiterbahnen und Zonen verwenden nur die Netznummer.
                        expression = .list(
                            [.atom("net"), .atom(String(code))] + (values.count > 2 ? [.string(full)] : []))
                    }
                    return
                }
                if values.first?.scalar == "net_name", values.count > 1, let name = values[1].scalar {
                    values[1] = .string(name.isEmpty ? "" : prefix + name)
                }
                for i in values.indices { try rewrite(&values[i]) }
                expression = .list(values)
            }
            // EN: Remap the entire board at once so group member UUIDs still point to the corresponding copied
            //     footprints, tracks and graphics.
            // JA: 基板全体を一度に再対応付けし、グループメンバーのUUIDが対応するコピー済みフットプリント・配線・図形を参照する状態を保つ。
            // DE: Die gesamte Platine auf einmal neu zuordnen, damit Gruppenmitglieder weiterhin auf die
            //     entsprechenden kopierten Footprints, Leiterbahnen und Grafiken verweisen.
            var items = SExpression.list(
                root.filter {
                    geometryHeads.contains($0.head ?? "") && $0.directList("layer")?.scalar(at: 1) != "Edge.Cuts"
                })
            replaceUUIDs(&items)
            try rewrite(&items)
            if case .list(var parts) = items {
                for i in parts.indices {
                    let isFootprint = parts[i].head == "footprint"
                    translate(&parts[i], dx: placement.offset.x, dy: placement.offset.y, footprint: isFootprint)
                    if isFootprint { disambiguateReference(&parts[i], suffix: "_B\(instance + 1)") }
                }
                geometry += parts
            }
            if case .list(let files) = root.first(where: { $0.head == "embedded_files" }) {
                for file in files.dropFirst() {
                    let name = file.scalar(at: 1) ?? file.directList("name")?.scalar(at: 1) ?? file.render()
                    let content = file.render()
                    if let existing = embeddedByName[name] {
                        guard existing == content else {
                            throw KiCadPanelError.invalidBoard(
                                L10n.text(
                                    "Different embedded files share the name \(name). Rename one in KiCad before combining these boards.",
                                    "内容の異なる埋め込みファイルに同じ名前（\(name)）が使われています。KiCadで片方の名前を変更してから統合してください。",
                                    "Verschiedene eingebettete Dateien haben denselben Namen \(name). Benennen Sie vor dem Zusammenfügen eine davon in KiCad um."
                                ))
                        }
                    } else {
                        embeddedByName[name] = content; embedded.append(file)
                    }
                }
            }
        }
        geometry += routing.segments.map {
            makeLine(
                start: BoardPoint(x: $0.a.x, y: $0.a.y), end: BoardPoint(x: $0.b.x, y: $0.b.y),
                width: max(0.05, options.dimensionLineWidthMM), layer: "Edge.Cuts")
        }
        geometry += try layout.guides(options: options).map {
            makeLine(
                start: BoardPoint(x: $0.a.x, y: $0.a.y), end: BoardPoint(x: $0.b.x, y: $0.b.y),
                width: options.vScoreLineWidthMM, layer: "Dwgs.User")
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
        for (index, hole) in holes.enumerated() {
            var item = makeMountingHole(
                at: BoardPoint(x: hole.0.x, y: hole.0.y), diameter: hole.1, reference: "PANEL_H\(index + 1)")
            if case .list(var fields) = item {
                for i in fields.indices where fields[i].head == "property" {
                    if case .list(var property) = fields[i] {
                        property.append(.list([.atom("hide"), .atom("yes")])); fields[i] = .list(property)
                    }
                }
                item = .list(fields)
            }
            geometry.append(item)
        }
        output += netDeclarations + geometry
        if !embedded.isEmpty { output.append(.list([.atom("embedded_files")] + embedded)) }
        if roots.contains(where: { $0.contains(where: { $0.head == "embedded_fonts" && $0.scalar(at: 1) == "yes" }) }) {
            output.append(.list([.atom("embedded_fonts"), .atom("yes")]))
        }
        let b = layout.panelBounds
        let summary = PanelSummary(
            boardWidthMM: layout.arrayBounds.maxX, boardHeightMM: layout.arrayBounds.maxY,
            panelWidthMM: b.maxX - b.minX, panelHeightMM: b.maxY - b.minY, columns: options.columns,
            rows: layout.rowCount, dimensionLineWidthMM: options.dimensionLineWidthMM)
        let serialized = Data((SExpression.list(output).render() + "\n").utf8)
        return try PanelValidation.output(normalizeLayers(data: serialized), summary: summary, options: options)
    }

    /// EN: Return routing segments [mm] from validated Edge.Cuts elements. Throw on unsupported shapes.
    ///
    /// JA: 検証済みのEdge.Cuts要素から加工用線分 [mm] を返す。未対応形状は例外。
    ///
    /// DE: Frässegmente [mm] aus geprüften Edge.Cuts-Elementen zurückgeben. Bei nicht unterstützten Formen einen
    ///     Fehler auslösen.
    private static func routingSegments(_ expression: SExpression) throws -> [RouteSegment] {
        /// EN: Return the specified outline coordinates [mm]. Return nil for missing elements so the caller can
        ///     validate them.
        ///
        /// JA: 指定された外形座標 [mm] を返す。要素欠落はnilとして上位で検証する。
        ///
        /// DE: Angegebene Konturkoordinaten [mm] zurückgeben. Bei fehlenden Elementen nil zur Prüfung durch den
        ///     Aufrufer zurückgeben.
        func p(_ key: String) -> RoutePoint? {
            guard let list = expression.directList(key), let x = list.scalar(at: 1).flatMap(Double.init),
                let y = list.scalar(at: 2).flatMap(Double.init)
            else { return nil }
            return RoutePoint(x: x, y: y)
        }
        /// EN: Convert validated approximation points to consecutive segments. Return an empty array for fewer than
        ///     two points.
        ///
        /// JA: 検証済みの近似点を連続線分へ変換する。点が2個未満なら空。
        ///
        /// DE: Geprüfte Näherungspunkte in aufeinanderfolgende Segmente umwandeln. Bei weniger als zwei Punkten ein
        ///     leeres Array zurückgeben.
        func chain(_ points: [RoutePoint]) -> [RouteSegment] {
            zip(points, points.dropFirst()).map { RouteSegment(a: $0, b: $1) }
        }
        switch expression.head {
        case "gr_line": if let a = p("start"), let b = p("end") { return [RouteSegment(a: a, b: b)] }
        case "gr_arc":
            if let a = p("start"), let m = p("mid"), let b = p("end") {
                return chain(try PanelRouting.threePointArc(start: a, mid: m, end: b))
            }
        case "gr_rect":
            if let a = p("start"), let b = p("end") {
                return PanelRouting.edges(
                    RouteRect(minX: min(a.x, b.x), minY: min(a.y, b.y), maxX: max(a.x, b.x), maxY: max(a.y, b.y)).points
                )
            }
        case "gr_circle":
            if let center = p("center"), let end = p("end") {
                return chain(try PanelRouting.arc(center: center, start: end, sweep: 2 * .pi))
            }
        case "gr_poly":
            if case .list(let values) = expression.directList("pts") {
                let points = values.compactMap { v -> RoutePoint? in
                    guard v.head == "xy", let x = v.scalar(at: 1).flatMap(Double.init),
                        let y = v.scalar(at: 2).flatMap(Double.init)
                    else { return nil }
                    return RoutePoint(x: x, y: y)
                }
                return PanelRouting.edges(points)
            }
        default: break
        }
        throw RoutingError.invalid(
            L10n.text(
                "Unsupported Edge.Cuts geometry for tab routing.", "タブ生成に未対応のEdge.Cuts形状です。直線・円弧・円・矩形・ポリゴンを使用してください。",
                "Diese Edge.Cuts-Geometrie wird für Stege nicht unterstützt. Verwenden Sie Linien, Kreisbögen, Kreise, Rechtecke oder Polygone."
            ))
    }

    /// EN: Return outline endpoints and arc extrema [mm]. Numeric values were already validated by parseRoot.
    ///
    /// JA: 外形の端点と円弧の極値 [mm] を返す。数値自体はparseRootで検証済み。
    ///
    /// DE: Konturendpunkte und Kreisbogenextrema [mm] zurückgeben. Zahlenwerte wurden bereits durch parseRoot
    ///     geprüft.
    private static func geometryPoints(_ expression: SExpression) -> [BoardPoint] {
        guard case .list(let parts) = expression else { return [] }
        var points: [BoardPoint] = []
        collectPoints(parts.dropFirst(), into: &points)
        if expression.head == "gr_arc", points.count >= 3 {
            points += arcBounds(start: points[0], mid: points[1], end: points[2])
        }
        if expression.head == "gr_circle", points.count >= 2 {
            let center = points[0], edge = points[1]
            let radius = hypot(center.x - edge.x, center.y - edge.y)
            points += [
                BoardPoint(x: center.x - radius, y: center.y - radius),
                BoardPoint(x: center.x + radius, y: center.y + radius),
            ]
        }
        return points
    }

    /// EN: Collect coordinate elements from validated S-expressions. Do not treat angles or identifiers as
    ///     coordinates.
    ///
    /// JA: 検証済みS式から座標要素を収集する。角度・識別子を座標として扱わない。
    ///
    /// DE: Koordinatenelemente aus geprüften S-Ausdrücken sammeln. Winkel und Kennungen nicht als Koordinaten
    ///     behandeln.
    private static func collectPoints<S: Sequence>(_ expressions: S, into points: inout [BoardPoint])
    where S.Element == SExpression {
        for expression in expressions {
            guard case .list(let values) = expression else { continue }
            if let key = values.first?.scalar, coordinateHeads.contains(key), values.count >= 3,
                let x = values[1].number, let y = values[2].number
            {
                points.append(BoardPoint(x: x, y: y))
            } else {
                collectPoints(values.dropFirst(), into: &points)
            }
        }
    }

    /// EN: Return extrema within the arc defined by start, midpoint and end [mm].
    ///
    /// JA: 開始・中間・終了点 [mm] から、円弧区間に含まれる極値点を返す。
    ///
    /// DE: Extrempunkte innerhalb des durch Start-, Mittel- und Endpunkt [mm] definierten Kreisbogens zurückgeben.
    private static func arcBounds(start: BoardPoint, mid: BoardPoint, end: BoardPoint) -> [BoardPoint] {
        let determinant = 2 * (start.x * (mid.y - end.y) + mid.x * (end.y - start.y) + end.x * (start.y - mid.y))
        guard abs(determinant) > 1e-12 else { return [] }
        let s2 = start.x * start.x + start.y * start.y
        let m2 = mid.x * mid.x + mid.y * mid.y
        let e2 = end.x * end.x + end.y * end.y
        let cx = (s2 * (mid.y - end.y) + m2 * (end.y - start.y) + e2 * (start.y - mid.y)) / determinant
        let cy = (s2 * (end.x - mid.x) + m2 * (start.x - end.x) + e2 * (mid.x - start.x)) / determinant
        let radius = hypot(start.x - cx, start.y - cy)
        let angles = [start, mid, end].map { atan2($0.y - cy, $0.x - cx) }
        let ccwEnd = positiveAngle(angles[2] - angles[0])
        let ccwMid = positiveAngle(angles[1] - angles[0])
        let ccw = ccwMid <= ccwEnd
        return [0.0, .pi / 2, .pi, 3 * .pi / 2].compactMap { angle in
            let delta = positiveAngle(angle - angles[0])
            let contains =
                ccw ? delta <= ccwEnd : positiveAngle(angles[0] - angle) <= positiveAngle(angles[0] - angles[2])
            guard contains else { return nil }
            return BoardPoint(x: cx + radius * cos(angle), y: cy + radius * sin(angle))
        }
    }

    /// EN: Normalize a finite angle [rad] to [0, 2π). Finiteness was checked at the call boundary.
    ///
    /// JA: 有限角度 [rad] を0以上2π未満へ正規化する。入力の有限性は呼び出し境界で確認済み。
    ///
    /// DE: Einen endlichen Winkel [rad] auf [0, 2π) normalisieren. Die Endlichkeit wurde an der Aufrufgrenze geprüft.
    private static func positiveAngle(_ value: Double) -> Double {
        let full = 2 * Double.pi
        return (value.truncatingRemainder(dividingBy: full) + full).truncatingRemainder(dividingBy: full)
    }

    /// EN: Apply validated placement offsets [mm]. Do not translate footprint-local coordinates twice.
    ///
    /// JA: 検証済み配置量 [mm] を反映する。フットプリントの内部座標は二重に移動しない。
    ///
    /// DE: Geprüfte Platzierungsversätze [mm] anwenden. Lokale Footprint-Koordinaten nicht doppelt verschieben.
    private static func translate(_ expression: inout SExpression, dx: Double, dy: Double, footprint: Bool) {
        guard case .list(var parts) = expression else { return }
        if footprint {
            if let atIndex = parts.firstIndex(where: { $0.head == "at" }) {
                shiftPointList(&parts[atIndex], dx: dx, dy: dy)
            }
        } else {
            for index in parts.indices {
                guard case .list = parts[index] else { continue }
                if let head = parts[index].head, coordinateHeads.contains(head) {
                    shiftPointList(&parts[index], dx: dx, dy: dy)
                } else {
                    translate(&parts[index], dx: dx, dy: dy, footprint: false)
                }
            }
        }
        expression = .list(parts)
    }

    /// EN: Add translation [mm] to coordinate lists. Reparse the final output to validate coordinate ranges.
    ///
    /// JA: 座標リストに移動量 [mm] を加える。最終出力は再解析で座標範囲を検証する。
    ///
    /// DE: Die Verschiebung [mm] zu Koordinatenlisten addieren. Die fertige Ausgabe zur Prüfung der
    ///     Koordinatenbereiche erneut parsen.
    private static func shiftPointList(_ expression: inout SExpression, dx: Double, dy: Double) {
        guard case .list(var parts) = expression, parts.count >= 3,
            let x = parts[1].number, let y = parts[2].number
        else { return }
        parts[1] = .atom(numberString(x + dx))
        parts[2] = .atom(numberString(y + dy))
        expression = .list(parts)
    }

    /// EN: Make internal references unique while preserving original visible silkscreen text.
    ///
    /// JA: 内部参照名を一意にし、見えるシルクは元の文字列で保持する。
    ///
    /// DE: Interne Referenzen eindeutig machen und sichtbaren Bestückungsdruck im Original erhalten.
    private static func disambiguateReference(_ expression: inout SExpression, row: Int, column: Int) {
        disambiguateReference(&expression, suffix: "_R\(row)C\(column)")
    }

    /// EN: Make internal references unique while preserving original visible silkscreen text.
    ///
    /// JA: 内部参照名を一意にし、見えるシルクは元の文字列で保持する。
    ///
    /// DE: Interne Referenzen eindeutig machen und sichtbaren Bestückungsdruck im Original erhalten.
    private static func disambiguateReference(_ expression: inout SExpression, suffix: String) {
        guard case .list(var parts) = expression else { return }
        let oldReference: String? =
            parts.compactMap { part in
                guard part.head == "property", part.scalar(at: 1) == "Reference" else { return nil }
                return part.scalar(at: 2)
            }.first
            ?? parts.compactMap { part in
                guard part.head == "fp_text", part.scalar(at: 1) == "reference" else { return nil }
                return part.scalar(at: 2)
            }.first
        guard let oldReference, !oldReference.isEmpty else { return }
        let newReference = oldReference + suffix
        var fixedLabels: [SExpression] = []
        for index in parts.indices {
            // EN: The reference remains unique for KiCad's object model. Its visible label becomes ordinary footprint
            //     text with the original spelling and the same local position, layer and effects.
            // JA: KiCadのオブジェクトモデル用の参照名は一意に保つ。表示ラベルは、元の文字列・ローカル位置・レイヤー・効果を保持した通常のフットプリントテキストへ変換する。
            // DE: Die Referenz bleibt im KiCad-Objektmodell eindeutig. Ihre sichtbare Beschriftung wird zu normalem
            //     Footprint-Text mit ursprünglichem Wortlaut, lokaler Position, Lage und Texteffekten.
            if case .list(var label) = parts[index] {
                let isProperty = label.first?.scalar == "property" && label.count > 2 && label[1].scalar == "Reference"
                let isLegacy = label.first?.scalar == "fp_text" && label.count > 2 && label[1].scalar == "reference"
                if isProperty || isLegacy {
                    if !label.contains(where: { $0.head == "layer" }) {
                        let back = parts.first(where: { $0.head == "layer" })?.scalar(at: 1) == "B.Cu"
                        label.append(.list([.atom("layer"), .string(back ? "B.SilkS" : "F.SilkS")]))
                    }
                    let hidden = label.contains {
                        $0.scalar == "hide" || ($0.head == "hide" && $0.scalar(at: 1) != "no")
                    }
                    if !hidden {
                        var fixed = SExpression.list(
                            [.atom("fp_text"), .atom("user"), .string(oldReference)] + Array(label.dropFirst(3)))
                        replaceUUIDs(&fixed)
                        fixedLabels.append(fixed)
                    }
                    if !hidden {
                        label.append(isProperty ? .list([.atom("hide"), .atom("yes")]) : .atom("hide"))
                    }
                    parts[index] = .list(label)
                }
            }
            freezeReferenceVariables(&parts[index], reference: oldReference)
            replaceReference(&parts[index], oldValue: oldReference, newValue: newReference)
        }
        expression = .list(parts + fixedLabels)
    }

    /// EN: Freeze reference variables to their original display values. Change only validated string data.
    ///
    /// JA: 参照名変数を元の表示値へ固定する。検証済みの文字列データのみを変更する。
    ///
    /// DE: Referenzvariablen auf ihre ursprünglichen Anzeigewerte festsetzen. Nur geprüfte Zeichenkettendaten ändern.
    private static func freezeReferenceVariables(_ expression: inout SExpression, reference: String) {
        guard case .list(var parts) = expression else { return }
        let textIndex: Int?
        switch parts.first?.scalar {
        case "fp_text", "property": textIndex = 2
        case "fp_text_box": textIndex = 1
        default: textIndex = nil
        }
        if let index = textIndex, parts.indices.contains(index), let text = parts[index].scalar {
            parts[index] = .string(text.replacingOccurrences(of: "${REFERENCE}", with: reference))
        }
        for index in parts.indices { freezeReferenceVariables(&parts[index], reference: reference) }
        expression = .list(parts)
    }

    /// EN: Replace reference strings in S-expressions. Preserve positions, text sizes and layers.
    ///
    /// JA: S式中の参照文字列を置換する。位置・文字サイズ・レイヤーを変更しない。
    ///
    /// DE: Referenzzeichenketten in S-Ausdrücken ersetzen. Positionen, Schriftgrößen und Lagen beibehalten.
    private static func replaceReference(_ expression: inout SExpression, oldValue: String, newValue: String) {
        guard case .list(var parts) = expression else { return }
        if parts.first?.scalar == "property", parts.count > 2, parts[1].scalar == "Reference",
            parts[2].scalar == oldValue
        {
            parts[2] = .string(newValue)
        }
        if parts.first?.scalar == "fp_text", parts.count > 2, parts[1].scalar == "reference",
            parts[2].scalar == oldValue
        {
            parts[2] = .string(newValue)
        }
        if parts.first?.scalar == "reference", parts.count > 1, parts[1].scalar == oldValue {
            parts[1] = .string(newValue)
        }
        for index in parts.indices { replaceReference(&parts[index], oldValue: oldValue, newValue: newValue) }
        expression = .list(parts)
    }

    /// EN: Build a UUID map for the entire copy and update references within groups at the same time.
    ///
    /// JA: コピー全体のUUID対応表を作り、グループ内の参照先も同時に更新する。
    ///
    /// DE: Eine UUID-Zuordnung für die gesamte Kopie erstellen und gleichzeitig Verweise innerhalb von Gruppen
    ///     aktualisieren.
    private static func replaceUUIDs(_ expression: inout SExpression) {
        var replacements: [String: String] = [:]
        collectUUIDs(expression, into: &replacements)
        applyUUIDs(&expression, replacements: replacements)
    }

    /// EN: Collect mappings from existing to new UUIDs. Recursion depth was checked on input.
    ///
    /// JA: 既存UUIDと新UUIDの対応を収集する。再帰深度は入力時に検証済み。
    ///
    /// DE: Zuordnungen vorhandener zu neuen UUIDs sammeln. Die Rekursionstiefe wurde beim Einlesen geprüft.
    private static func collectUUIDs(_ expression: SExpression, into replacements: inout [String: String]) {
        guard case .list(let parts) = expression else { return }
        if ["uuid", "tstamp"].contains(parts.first?.scalar ?? ""), let old = parts.dropFirst().first?.scalar {
            replacements[old] = UUID().uuidString.lowercased()
        }
        for part in parts { collectUUIDs(part, into: &replacements) }
    }

    /// EN: Rewrite identifiers and their references consistently using the map.
    ///
    /// JA: 対応表を使い識別子とその参照を同じ値へ書き換える。
    ///
    /// DE: Kennungen und ihre Verweise mithilfe der Zuordnung konsistent umschreiben.
    private static func applyUUIDs(_ expression: inout SExpression, replacements: [String: String]) {
        guard case .list(var parts) = expression else { return }
        if ["uuid", "tstamp"].contains(parts.first?.scalar ?? ""), parts.count > 1, let old = parts[1].scalar,
            let replacement = replacements[old]
        {
            parts[1] = .string(replacement)
        }
        for index in parts.indices {
            if let value = parts[index].scalar, let replacement = replacements[value] {
                parts[index] = .string(replacement)
            } else {
                applyUUIDs(&parts[index], replacements: replacements)
            }
        }
        expression = .list(parts)
    }

    /// EN: Create an outline rectangle from validated coordinates and line width [mm]. Revalidate output numbers
    ///     before saving.
    ///
    /// JA: 検証済み座標・線幅 [mm] から外形矩形を作る。出力の数値は保存前に再検証する。
    ///
    /// DE: Ein Konturrechteck aus geprüften Koordinaten und einer Linienbreite [mm] erstellen. Ausgabewerte vor dem
    ///     Speichern erneut prüfen.
    private static func makeRectangle(minX: Double, minY: Double, maxX: Double, maxY: Double, width: Double)
        -> SExpression
    {
        .list([
            .atom("gr_rect"), point("start", x: minX, y: minY), point("end", x: maxX, y: maxY),
            .list([
                .atom("stroke"), .list([.atom("width"), .atom(numberString(width))]),
                .list([.atom("type"), .atom("default")]),
            ]),
            .list([.atom("fill"), .atom("none")]), .list([.atom("layer"), .string("Edge.Cuts")]), uuidNode(),
        ])
    }

    /// EN: Create a segment with a layer from validated endpoints [mm] and line width [mm].
    ///
    /// JA: 検証済み端点 [mm] と線幅 [mm] からレイヤー付き線分を作る。
    ///
    /// DE: Ein Segment mit Lage aus geprüften Endpunkten [mm] und einer Linienbreite [mm] erstellen.
    private static func makeLine(start: BoardPoint, end: BoardPoint, width: Double, layer: String) -> SExpression {
        .list([
            .atom("gr_line"), point("start", x: start.x, y: start.y), point("end", x: end.x, y: end.y),
            .list([
                .atom("stroke"), .list([.atom("width"), .atom(numberString(width))]),
                .list([.atom("type"), .atom("solid")]),
            ]),
            .list([.atom("layer"), .string(layer)]), uuidNode(),
        ])
    }

    /// EN: Create an NPTH footprint from a validated center [mm] and diameter [mm].
    ///
    /// JA: 検証済み中心 [mm] と直径 [mm] からNPTHフットプリントを作る。
    ///
    /// DE: Einen NPTH-Footprint aus geprüftem Mittelpunkt [mm] und Durchmesser [mm] erstellen.
    private static func makeMountingHole(at point: BoardPoint, diameter: Double, reference: String) -> SExpression {
        .list([
            .atom("footprint"), .string("MountingHole:MountingHole_\(numberString(diameter))mm"),
            .list([.atom("layer"), .string("F.Cu")]), uuidNode(),
            .list([.atom("at"), .atom(numberString(point.x)), .atom(numberString(point.y))]),
            .list([
                .atom("property"), .string("Reference"), .string(reference),
                .list([.atom("at"), .atom("0"), .atom("0"), .atom("0")]), .list([.atom("layer"), .string("F.SilkS")]),
                uuidNode(),
                .list([
                    .atom("effects"),
                    .list([
                        .atom("font"), .list([.atom("size"), .atom("1"), .atom("1")]),
                        .list([.atom("thickness"), .atom("0.15")]),
                    ]),
                ]),
            ]),
            .list([
                .atom("property"), .string("Value"), .string("MountingHole"),
                .list([.atom("at"), .atom("0"), .atom("0"), .atom("0")]), .list([.atom("layer"), .string("F.Fab")]),
                uuidNode(),
                .list([
                    .atom("effects"),
                    .list([
                        .atom("font"), .list([.atom("size"), .atom("1"), .atom("1")]),
                        .list([.atom("thickness"), .atom("0.15")]),
                    ]),
                ]),
            ]),
            .list([.atom("attr"), .atom("exclude_from_pos_files"), .atom("exclude_from_bom")]),
            .list([
                .atom("pad"), .string(""), .atom("np_thru_hole"), .atom("circle"),
                .list([.atom("at"), .atom("0"), .atom("0")]),
                .list([.atom("size"), .atom(numberString(diameter)), .atom(numberString(diameter))]),
                .list([.atom("drill"), .atom(numberString(diameter))]),
                .list([.atom("layers"), .string("*.Cu"), .string("*.Mask")]), uuidNode(),
            ]),
        ])
    }

    /// EN: Convert validated coordinates [mm] to an S-expression using the specified coordinate tag.
    ///
    /// JA: 検証済みmm座標を、指定した座標タグのS式に変換する。
    ///
    /// DE: Geprüfte Koordinaten [mm] mit dem angegebenen Koordinaten-Tag in einen S-Ausdruck umwandeln.
    private static func point(_ head: String, x: Double, y: Double) -> SExpression {
        .list([.atom(head), .atom(numberString(x)), .atom(numberString(y))])
    }
    /// EN: Return an S-expression element with a new UUID, distinct from the source board's UUIDs.
    ///
    /// JA: 新しいUUIDを持つS式要素を返す。元基板のUUIDと共有しない。
    ///
    /// DE: Ein S-Ausdruck-Element mit einer neuen UUID zurückgeben, die sich von denen der Quellplatine
    ///     unterscheidet.
    private static func uuidNode() -> SExpression { .list([.atom("uuid"), .string(UUID().uuidString.lowercased())]) }
    /// EN: Format validated numbers independently of locale. Do not use a decimal comma.
    ///
    /// JA: 検証済み数値をロケール非依存の表記へ変換する。小数点にカンマを使わない。
    ///
    /// DE: Geprüfte Zahlen unabhängig von der Spracheinstellung formatieren. Kein Dezimalkomma verwenden.
    private static func numberString(_ value: Double) -> String {
        String(format: "%.9g", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}

struct PanelPreviewDrill {
    let center: RoutePoint
    let width: Double
    let height: Double
    let angle: Double
    let front: Bool
    let back: Bool
}

struct BoardPoint { let x: Double; let y: Double }

enum KiCadPanelError: LocalizedError {
    case invalidBoard(String)
    case noEdgeCuts
    var errorDescription: String? {
        switch self {
        case .invalidBoard(let reason):
            return L10n.text(
                "Cannot panelize the KiCad board: \(reason)", "KiCad基板を面付けできません: \(reason)",
                "Die KiCad-Leiterplatte kann nicht zu einem Nutzen angeordnet werden: \(reason)")
        case .noEdgeCuts:
            return L10n.text(
                "No board outline was found on Edge.Cuts (lines, arcs or polygons).",
                "Edge.Cutsレイヤーに基板外形（線、円弧、ポリゴン）がありません。",
                "Auf Edge.Cuts wurde keine Leiterplattenkontur gefunden (Linien, Kreisbögen oder Polygone).")
        }
    }
}

private indirect enum SExpression {
    case atom(String)
    case string(String)
    case list([SExpression])

    var scalar: String? {
        switch self {
        case .atom(let value), .string(let value): return value;
        case .list: return nil
        }
    }
    var head: String? {
        guard case .list(let items) = self else { return nil }
        return items.first?.scalar
    }
    /// EN: Return the string at the given index, or nil for an out-of-range index or a list value.
    ///
    /// JA: 指定位置の文字列を返す。配列範囲外やリスト値ならnilを返す。
    ///
    /// DE: Die Zeichenkette am angegebenen Index zurückgeben; bei ungültigem Index oder Listenwert nil zurückgeben.
    func scalar(at index: Int) -> String? {
        guard case .list(let items) = self, items.indices.contains(index) else { return nil }
        return items[index].scalar
    }
    var number: Double? { scalar.flatMap(Double.init) }
    /// EN: Return the immediate child list with the specified name, or nil if none exists.
    ///
    /// JA: 指定名の直下リストを返す。該当要素がなければnil。
    ///
    /// DE: Die direkte untergeordnete Liste mit dem angegebenen Namen zurückgeben, andernfalls nil.
    func directList(_ name: String) -> SExpression? {
        guard case .list(let items) = self else { return nil }
        return items.dropFirst().first { $0.head == name }
    }
    /// EN: Return a copy of an S-expression value. The parsed tree's depth is already limited.
    ///
    /// JA: S式の値を複製して返す。解析済みツリーの深度は制限済み。
    ///
    /// DE: Eine Kopie eines S-Ausdruck-Wertes zurückgeben. Die Tiefe des geparsten Baums ist bereits begrenzt.
    func deepCopy() -> SExpression {
        switch self {
        case .atom(let value): return .atom(value)
        case .string(let value): return .string(value)
        case .list(let items): return .list(items.map { $0.deepCopy() })
        }
    }
    /// EN: Serialize a depth-limited S-expression in KiCad format, escaping reserved string characters.
    ///
    /// JA: 深度制限済みS式をKiCad形式に直列化する。文字列の予約文字はエスケープする。
    ///
    /// DE: Einen tiefenbegrenzten S-Ausdruck im KiCad-Format serialisieren und reservierte Zeichen in Zeichenketten
    ///     maskieren.
    func render(depth: Int = 0) -> String {
        switch self {
        case .atom(let value): return value
        case .string(let value):
            return "\""
                + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n") + "\""
        case .list(let items):
            guard !items.isEmpty else { return "()" }
            if items.allSatisfy({ $0.scalar != nil }) {
                return "(" + items.map { $0.render(depth: depth) }.joined(separator: " ") + ")"
            }
            var prefix: [SExpression] = []
            var rest: [SExpression] = []
            for item in items {
                if rest.isEmpty && item.scalar != nil { prefix.append(item) } else { rest.append(item) }
            }
            let firstLine = "(" + prefix.map { $0.render(depth: depth) }.joined(separator: " ")
            let childIndent = String(repeating: "\t", count: depth + 1)
            let body = rest.map { childIndent + $0.render(depth: depth + 1) }.joined(separator: "\n")
            return firstLine + (body.isEmpty ? ")" : "\n" + body + "\n" + String(repeating: "\t", count: depth) + ")")
        }
    }
}

private struct SExpressionParser {
    private let characters: [Character]
    private var index = 0
    /// EN: Syntax element count [items]. Limit large sibling sets that a depth limit alone cannot prevent.
    ///
    /// JA: 構文要素数 [個]。深度だけで防げない、大量の兄弟要素も制限する。
    ///
    /// DE: Anzahl der Syntaxelemente [Elemente]. Große Mengen von Geschwisterelementen begrenzen, die eine reine
    ///     Tiefenbegrenzung nicht verhindert.
    private var nodeCount = 0
    init(_ source: String) {
        let normalized = source.first == "\u{feff}" ? String(source.dropFirst()) : source
        characters = Array(normalized)
    }

    /// EN: Read exactly one root and verify that only whitespace or comments follow it before returning.
    ///
    /// JA: ルートを1個だけ読み、末尾が空白・コメントだけであることを検証して返す。
    ///
    /// DE: Genau eine Wurzel lesen und vor der Rückgabe prüfen, dass danach nur Leerraum oder Kommentare folgen.
    mutating func parseDocument() throws -> SExpression {
        skipWhitespaceAndComments()
        let expression = try parseExpression()
        skipWhitespaceAndComments()
        guard index == characters.count else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "Unexpected data after the KiCad board root.", "KiCad基板のルート要素の後に余分なデータがあります。",
                    "Unerwartete Daten nach dem Wurzelelement der KiCad-Leiterplatte."))
        }
        return expression
    }

    /// EN: Return an S-expression from the current position, checking depth, node count and array bounds each time.
    ///
    /// JA: 現在の読み取り位置からS式を返す。深度・ノード数・配列境界を毎回確認する。
    ///
    /// DE: Ab der aktuellen Position einen S-Ausdruck lesen und dabei stets Tiefe, Knotenanzahl und Array-Grenzen
    ///     prüfen.
    private mutating func parseExpression(depth: Int = 0) throws -> SExpression {
        guard depth <= PanelLimits.maxParserDepth else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "The KiCad file is nested too deeply.", "KiCadファイルの入れ子が深すぎます。",
                    "Die KiCad-Datei ist zu tief verschachtelt."))
        }
        nodeCount += 1
        guard nodeCount <= PanelLimits.maxSyntaxNodes else {
            throw PanelValidation.invalid("SExpressionParser.nodeCount", "1...\(PanelLimits.maxSyntaxNodes)")
        }
        skipWhitespaceAndComments()
        guard index < characters.count else {
            throw KiCadPanelError.invalidBoard(
                L10n.text("Unexpected end of file.", "ファイル末尾が予期しない位置です。", "Unerwartetes Dateiende."))
        }
        if characters[index] == "(" {
            index += 1
            var items: [SExpression] = []
            while true {
                skipWhitespaceAndComments()
                guard index < characters.count else {
                    throw KiCadPanelError.invalidBoard(
                        L10n.text(
                            "A closing parenthesis is missing.", "閉じ括弧が不足しています。", "Eine schließende Klammer fehlt."))
                }
                if characters[index] == ")" { index += 1; return .list(items) }
                items.append(try parseExpression(depth: depth + 1))
            }
        }
        if characters[index] == "\"" { return .string(try parseQuoted()) }
        let start = index
        while index < characters.count && !characters[index].isWhitespace && characters[index] != "("
            && characters[index] != ")" && characters[index] != ";"
        { index += 1 }
        guard index > start else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    "Cannot parse an S-expression token.", "S式トークンを解析できません。",
                    "Ein Token des S-Ausdrucks kann nicht gelesen werden."))
        }
        return .atom(String(characters[start..<index]))
    }

    /// EN: Decode and return a quoted string. Throw if the closing quote is missing.
    ///
    /// JA: 引用符付き文字列を復号して返す。閉じ引用符がない場合は例外。
    ///
    /// DE: Eine Zeichenkette in Anführungszeichen dekodieren und zurückgeben. Bei fehlendem Schlusszeichen einen
    ///     Fehler auslösen.
    private mutating func parseQuoted() throws -> String {
        index += 1
        var result = ""
        while index < characters.count {
            let character = characters[index]
            index += 1
            if character == "\"" { return result }
            if character == "\\", index < characters.count {
                let escaped = characters[index]
                index += 1
                switch escaped {
                case "n": result.append("\n");
                case "r": result.append("\r");
                case "t": result.append("\t");
                default: result.append(escaped)
                }
            } else {
                result.append(character)
            }
        }
        throw KiCadPanelError.invalidBoard(
            L10n.text(
                "A quoted string is unterminated.", "引用符が閉じていません。",
                "Eine Zeichenfolge wurde nicht mit einem Anführungszeichen abgeschlossen."))
    }

    /// EN: Advance to the next token without reading beyond the character buffer.
    ///
    /// JA: 読み取り位置を次のトークンへ進める。文字数を超えて参照しない。
    ///
    /// DE: Zum nächsten Token vorrücken, ohne über das Ende des Zeichenpuffers hinaus zu lesen.
    private mutating func skipWhitespaceAndComments() {
        while index < characters.count {
            if characters[index].isWhitespace { index += 1; continue }
            if characters[index] == ";" {
                while index < characters.count && characters[index] != "\n" { index += 1 }
                continue
            }
            break
        }
    }
}
