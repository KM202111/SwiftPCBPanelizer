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

// EN: String/character literals are defined in TextConstants.KiCad, Common and Characters; variable text uses constant templates.
// JA: 文字列・文字リテラルはTextConstants.KiCad・Common・Charactersに定義し、可変文は定数テンプレートから生成する。
// DE: Zeichenketten-/Zeichenliterale stehen in TextConstants.KiCad, Common und Characters; variable Texte nutzen konstante Vorlagen.

enum KiCadPanelEngine {
    private static let geometryHeads: Set<String> = [
        TextConstants.KiCad.tokenFootprint, TextConstants.KiCad.tokenSegment, TextConstants.KiCad.tokenVia,
        TextConstants.KiCad.tokenArc, TextConstants.KiCad.tokenZone, TextConstants.KiCad.tokenGrLine,
        TextConstants.KiCad.tokenGrArc, TextConstants.KiCad.tokenGrRect,
        TextConstants.KiCad.tokenGrPoly, TextConstants.KiCad.tokenGrCircle, TextConstants.KiCad.tokenGrCurve,
        TextConstants.KiCad.tokenGrText, TextConstants.KiCad.tokenGrTextBox, TextConstants.KiCad.tokenDimension,
        TextConstants.KiCad.tokenTarget, TextConstants.KiCad.tokenImage, TextConstants.KiCad.tokenGroup,
        TextConstants.KiCad.tokenTable, TextConstants.KiCad.tokenBarcode, TextConstants.KiCad.tokenPoint,
        TextConstants.KiCad.tokenGenerated,
    ]
    private static let coordinateHeads: Set<String> = [
        TextConstants.KiCad.tokenAt, TextConstants.KiCad.tokenStart, TextConstants.KiCad.tokenEnd,
        TextConstants.KiCad.tokenMid, TextConstants.KiCad.tokenCenter, TextConstants.KiCad.tokenXy,
        TextConstants.KiCad.tokenXy1, TextConstants.KiCad.tokenXy2, TextConstants.KiCad.tokenOrigin,
        TextConstants.KiCad.tokenPosition,
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
                    TextConstants.Common.columnsAndRowsMustBeAtLeastOneEnglish,
                    TextConstants.KiCad.columnsAndRowsMustBeAtLeastOneJapanese,
                    TextConstants.Common.columnsAndRowsMustBeAtLeastOneGerman))
        }
        let measurements = [
            options.columnGapMM, options.rowGapMM, options.horizontalFrameMM,
            options.verticalFrameMM, options.mountingHoleOffsetXMM, options.mountingHoleOffsetYMM,
            options.dimensionLineWidthMM, options.vScoreLineWidthMM,
        ]
        guard measurements.allSatisfy({ $0 >= 0 }), !options.addMountingHoles || options.mountingHoleDrillMM > 0 else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    TextConstants.KiCad.spacingAndFrameWidthsMustBeNonnegativeTheDrillEnglish,
                    TextConstants.KiCad.spacingAndFrameWidthsMustBeNonnegativeTheDrillJapanese,
                    TextConstants.KiCad.spacingAndFrameWidthsMustBeNonnegativeTheDrillGerman
                ))
        }
        let boardOutline = root.compactMap { expression -> [BoardPoint]? in
            guard let head = expression.head,
                [
                    TextConstants.KiCad.tokenGrLine, TextConstants.KiCad.tokenGrArc, TextConstants.KiCad.tokenGrRect,
                    TextConstants.KiCad.tokenGrPoly, TextConstants.KiCad.tokenGrCircle,
                    TextConstants.KiCad.tokenGrCurve,
                ].contains(head),
                expression.directList(TextConstants.Common.tokenLayer)?.scalar(at: 1)
                    == TextConstants.KiCad.tokenEdgeCuts
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
                    root.filter {
                        $0.directList(TextConstants.Common.tokenLayer)?.scalar(at: 1)
                            == TextConstants.KiCad.tokenEdgeCuts
                    }.flatMap {
                        try routingSegments($0)
                    }), bounds: RouteRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY), options: options,
                straightEdges: root.filter {
                    $0.directList(TextConstants.Common.tokenLayer)?.scalar(at: 1) == TextConstants.KiCad.tokenEdgeCuts
                        && [
                            TextConstants.KiCad.tokenGrLine, TextConstants.KiCad.tokenGrRect,
                            TextConstants.KiCad.tokenGrPoly,
                        ].contains($0.head ?? TextConstants.Common.empty)
                }.flatMap { try routingSegments($0) })
            : RoutingPlan(segments: [], mouseBites: [])
        let routedEdges = routingPlan.segments

        var rebuilt: [SExpression] = []
        var insertedGeometry = false
        for expression in root {
            if routed
                && expression.directList(TextConstants.Common.tokenLayer)?.scalar(at: 1)
                    == TextConstants.KiCad.tokenEdgeCuts
            {
                continue
            }
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
                            &copy, dx: Double(column) * xStep, dy: Double(row) * yStep,
                            footprint: head == TextConstants.KiCad.tokenFootprint)
                        if !isOriginalCell {
                            replaceUUIDs(&copy)
                            if head == TextConstants.KiCad.tokenFootprint {
                                disambiguateReference(&copy, row: row + 1, column: column + 1)
                            }
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
                            &copy, dx: Double(column) * xStep, dy: Double(row) * yStep,
                            footprint: head == TextConstants.KiCad.tokenFootprint)
                        if !isOriginalCell {
                            replaceUUIDs(&copy)
                            if head == TextConstants.KiCad.tokenFootprint {
                                disambiguateReference(&copy, row: row + 1, column: column + 1)
                            }
                        }
                        rebuilt.append(copy)
                    }
                }
            }
        }

        guard insertedGeometry else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    TextConstants.KiCad.noBoardItemsAreAvailableToDuplicateEnglish,
                    TextConstants.KiCad.noBoardItemsAreAvailableToDuplicateJapanese,
                    TextConstants.KiCad.noBoardItemsAreAvailableToDuplicateGerman))
        }
        let outline = makeRectangle(
            minX: panelMinX, minY: panelMinY, maxX: panelMaxX, maxY: panelMaxY,
            width: max(0.05, options.dimensionLineWidthMM))
        if routed {
            rebuilt += routedEdges.map {
                makeLine(
                    start: BoardPoint(x: $0.a.x, y: $0.a.y), end: BoardPoint(x: $0.b.x, y: $0.b.y),
                    width: max(0.05, options.dimensionLineWidthMM), layer: TextConstants.KiCad.tokenEdgeCuts)
            }
        } else if options.panelCornerRadiusMM > 0 && options.verticalFrameMM > 0 && options.horizontalFrameMM > 0 {
            let loop = try PanelRouting.roundedRectangle(
                RouteRect(minX: panelMinX, minY: panelMinY, maxX: panelMaxX, maxY: panelMaxY),
                radius: options.panelCornerRadiusMM)
            rebuilt += PanelRouting.edges(loop).map {
                makeLine(
                    start: BoardPoint(x: $0.a.x, y: $0.a.y), end: BoardPoint(x: $0.b.x, y: $0.b.y),
                    width: max(0.05, options.dimensionLineWidthMM), layer: TextConstants.KiCad.tokenEdgeCuts)
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
                            width: options.vScoreLineWidthMM, layer: TextConstants.KiCad.tokenDwgsUser))
                }
            }
            if options.rows > 1 {
                for row in 1..<options.rows {
                    let y = minY + Double(row) * yStep - max(0, options.rowGapMM) / 2
                    rebuilt.append(
                        makeLine(
                            start: BoardPoint(x: panelMinX, y: y), end: BoardPoint(x: panelMaxX, y: y),
                            width: options.vScoreLineWidthMM, layer: TextConstants.KiCad.tokenDwgsUser))
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
                    guard footprint.head == TextConstants.KiCad.tokenFootprint else { return nil }
                    return footprint.directList(TextConstants.KiCad.tokenProperty).flatMap {
                        $0.scalar(at: 1) == TextConstants.KiCad.referencePropertyName ? $0.scalar(at: 2) : nil
                    }
                })
            for (index, point) in points.enumerated() {
                var suffix = index + 1
                while usedReferences.contains(TextConstants.KiCad.tokenPHTemplate(suffix)) { suffix += 1 }
                let reference = TextConstants.KiCad.tokenPHTemplate(suffix)
                usedReferences.insert(reference)
                rebuilt.append(makeMountingHole(at: point, diameter: options.mountingHoleDrillMM, reference: reference))
            }
        }
        var usedReferences = Set(
            rebuilt.compactMap { $0.directList(TextConstants.KiCad.tokenProperty) }.filter {
                $0.scalar(at: 1) == TextConstants.KiCad.referencePropertyName
            }.compactMap {
                $0.scalar(at: 2)
            })
        var biteIndex = 1
        for point in routingPlan.mouseBites {
            while usedReferences.contains(TextConstants.KiCad.tokenPMBTemplate(biteIndex)) { biteIndex += 1 }
            let reference = TextConstants.KiCad.tokenPMBTemplate(biteIndex)
            usedReferences.insert(reference)
            var hole = makeMountingHole(
                at: BoardPoint(x: point.x, y: point.y), diameter: options.mouseBiteDiameterMM, reference: reference)
            if case .list(var items) = hole {
                for i in items.indices where items[i].head == TextConstants.KiCad.tokenProperty {
                    if case .list(var property) = items[i] {
                        property.append(
                            .list([.atom(TextConstants.KiCad.tokenHide), .atom(TextConstants.Common.tokenYes)]))
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
            Data((SExpression.list(root).render() + TextConstants.Common.newline).utf8), summary: summary,
            options: options)
    }

    /// EN: Validate UTF-8, size, trailing content, structure and numbers; return the kicad_pcb root's elements.
    ///
    /// JA: UTF-8・サイズ・末尾・構造・数値を検証し、kicad_pcbルートの要素配列を返す。
    ///
    /// DE: UTF-8, Größe, nachfolgenden Inhalt, Struktur und Zahlen prüfen; die Elemente der kicad_pcb-Wurzel
    ///     zurückgeben.
    private static func parseRoot(_ data: Data) throws -> [SExpression] {
        try PanelValidation.document(data, field: TextConstants.KiCad.tokenKiCadPanelEngineParseRootInput)
        guard let text = String(data: data, encoding: .utf8) else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    TextConstants.KiCad.theKiCadFileIsNotValidUTFEnglish,
                    TextConstants.KiCad.theKiCadFileIsNotValidUTFJapanese,
                    TextConstants.KiCad.theKiCadFileIsNotValidUTFGerman))
        }
        var parser = SExpressionParser(text)
        guard case .list(let root) = try parser.parseDocument(),
            root.first?.scalar == TextConstants.Common.tokenKicadPcb
        else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    TextConstants.KiCad.theKicadPcbRootElementIsMissingEnglish,
                    TextConstants.KiCad.theKicadPcbRootElementIsMissingJapanese,
                    TextConstants.KiCad.theKicadPcbRootElementIsMissingGerman))
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
        let name = expression.head ?? TextConstants.Common.empty
        if coordinateHeads.contains(name), values.count >= 3, values[1].scalar != nil {
            guard let x = values[1].number, let y = values[2].number else {
                throw PanelValidation.invalid(
                    TextConstants.KiCad.tokenKiCad + name, TextConstants.KiCad.textNumericXYCoordinates)
            }
            try PanelRouting.validatePoints([RoutePoint(x: x, y: y)])
            if name == TextConstants.KiCad.tokenAt, values.count > 3, let angle = values[3].number {
                try PanelValidation.number(
                    angle, field: TextConstants.KiCad.tokenKiCadAtAngleDegrees,
                    range: -PanelLimits.maxRotationDegrees...PanelLimits.maxRotationDegrees)
            }
        }
        if [
            TextConstants.Common.tokenSize, TextConstants.Common.tokenWidth, TextConstants.KiCad.tokenThickness,
            TextConstants.Common.tokenRadius, TextConstants.Common.tokenDiameter,
        ].contains(name) {
            for value in values.dropFirst() {
                if let scalar = value.scalar {
                    guard let number = Double(scalar) else {
                        throw PanelValidation.invalid(
                            TextConstants.KiCad.tokenKiCad + name, TextConstants.Common.textNumericMeasurement)
                    }
                    try PanelValidation.number(
                        number, field: TextConstants.KiCad.tokenKiCad + name + TextConstants.Common.tokenMM,
                        range: 0...PanelLimits.maxMeasurementMM)
                }
            }
        }
        if name == TextConstants.Common.tokenDrill {
            let dimensions = values.dropFirst().filter {
                $0.scalar != TextConstants.KiCad.tokenOval && $0.scalar != nil
            }
            for value in dimensions {
                guard let number = value.number else {
                    throw PanelValidation.invalid(
                        TextConstants.KiCad.tokenKiCadDrill, TextConstants.KiCad.textNumericDiameter)
                }
                try PanelValidation.number(
                    number, field: TextConstants.KiCad.tokenKiCadDrillMM,
                    range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
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
        if case .list(let table) = root.first(where: { $0.head == TextConstants.Common.tokenLayers }) {
            rows = Array(table.dropFirst())
        }
        let undefined: Set<String> = [
            TextConstants.KiCad.tokenUNDEFINED, TextConstants.KiCad.tokenUndefined, TextConstants.KiCad.tokenRescue,
            TextConstants.KiCad.tokenUNSELECTED, TextConstants.Common.empty, TextConstants.KiCad.numberMinus1,
        ]
        rows.removeAll { undefined.contains($0.scalar(at: 1) ?? TextConstants.Common.empty) }
        var declared = Set(rows.compactMap { $0.scalar(at: 1) })
        var aliases: [String: String] = [
            TextConstants.KiCad.tokenUserDrawings: TextConstants.KiCad.tokenDwgsUser,
            TextConstants.KiCad.tokenUserComments: TextConstants.KiCad.tokenCmtsUser,
            TextConstants.KiCad.tokenUserEco1: TextConstants.KiCad.tokenEco1User,
            TextConstants.KiCad.tokenUserEco2: TextConstants.KiCad.tokenEco2User,
            TextConstants.KiCad.tokenFSilkscreen: TextConstants.KiCad.tokenFSilkS,
            TextConstants.KiCad.tokenBSilkscreen: TextConstants.KiCad.tokenBSilkS,
            TextConstants.KiCad.tokenFAdhesive: TextConstants.KiCad.tokenFAdhes,
            TextConstants.KiCad.tokenBAdhesive: TextConstants.KiCad.tokenBAdhes,
            TextConstants.KiCad.tokenFCourtyard: TextConstants.KiCad.tokenFCrtYd,
            TextConstants.KiCad.tokenBCourtyard: TextConstants.KiCad.tokenBCrtYd,
        ]
        for row in rows {
            if let name = row.scalar(at: 1), let alias = row.scalar(at: 3), !alias.isEmpty, !declared.contains(alias) {
                aliases[alias] = name
            }
        }
        let modernIDs =
            rows.first(where: { $0.scalar(at: 1) == TextConstants.KiCad.tokenBCu })?.scalar(at: 0)
            == TextConstants.KiCad.number2
        let standard: [(String, Int, Int)] = [
            (TextConstants.KiCad.tokenFCu, 0, 0), (TextConstants.KiCad.tokenBCu, 2, 31),
            (TextConstants.KiCad.tokenFAdhes, 9, 33), (TextConstants.KiCad.tokenBAdhes, 11, 32),
            (TextConstants.KiCad.tokenFPaste, 13, 35), (TextConstants.KiCad.tokenBPaste, 15, 34),
            (TextConstants.KiCad.tokenFSilkS, 5, 37), (TextConstants.KiCad.tokenBSilkS, 7, 36),
            (TextConstants.KiCad.tokenFMask, 1, 39), (TextConstants.KiCad.tokenBMask, 3, 38),
            (TextConstants.KiCad.tokenDwgsUser, 17, 40), (TextConstants.KiCad.tokenCmtsUser, 19, 41),
            (TextConstants.KiCad.tokenEco1User, 21, 42), (TextConstants.KiCad.tokenEco2User, 23, 43),
            (TextConstants.KiCad.tokenEdgeCuts, 25, 44), (TextConstants.KiCad.tokenMargin, 27, 45),
            (TextConstants.KiCad.tokenFCrtYd, 31, 47), (TextConstants.KiCad.tokenBCrtYd, 29, 46),
            (TextConstants.KiCad.tokenFFab, 35, 49), (TextConstants.KiCad.tokenBFab, 33, 48),
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
            if let entry = standard.first(where: { $0.0 == name }),
                !name.hasSuffix(TextConstants.KiCad.copperLayerSuffix)
            {
                number = modernIDs ? entry.1 : entry.2
            }
            if name.hasPrefix(TextConstants.KiCad.userLayerPrefix), let index = Int(name.dropFirst(5)),
                (1...9).contains(index)
            {
                number = modernIDs ? 39 + (index - 1) * 2 : 50 + index - 1
            }
            guard let number, !rows.contains(where: { $0.scalar(at: 0) == String(number) }) else {
                throw KiCadPanelError.invalidBoard(
                    L10n.text(
                        TextConstants.KiCad.theLayerNameIsMissingFromTheBoardLayerEnglishTemplate(name),
                        TextConstants.KiCad.theLayerNameIsMissingFromTheBoardLayerJapaneseTemplate(name),
                        TextConstants.KiCad.theLayerNameIsMissingFromTheBoardLayerGermanTemplate(name)
                    ))
            }
            rows.append(.list([.atom(String(number)), .string(name), .atom(TextConstants.KiCad.userTextKind)]))
            declared.insert(name)
        }
        let graphicHeads: Set<String> = [
            TextConstants.KiCad.tokenProperty, TextConstants.KiCad.tokenFpText, TextConstants.KiCad.tokenFpTextBox,
            TextConstants.KiCad.tokenFpLine, TextConstants.KiCad.tokenFpArc, TextConstants.KiCad.tokenFpRect,
            TextConstants.KiCad.tokenFpPoly, TextConstants.KiCad.tokenFpCircle, TextConstants.KiCad.tokenFpCurve,
            TextConstants.KiCad.tokenGrText, TextConstants.KiCad.tokenGrTextBox, TextConstants.KiCad.tokenGrLine,
            TextConstants.KiCad.tokenGrArc, TextConstants.KiCad.tokenGrRect, TextConstants.KiCad.tokenGrPoly,
            TextConstants.KiCad.tokenGrCircle, TextConstants.KiCad.tokenGrCurve, TextConstants.KiCad.tokenDimension,
            TextConstants.KiCad.tokenTarget, TextConstants.KiCad.tokenImage, TextConstants.KiCad.tokenTable,
            TextConstants.KiCad.tokenTableCell, TextConstants.KiCad.tokenBarcode,
        ]
        let electricalHeads: Set<String> = [
            TextConstants.KiCad.tokenSegment, TextConstants.KiCad.tokenArc, TextConstants.KiCad.tokenVia,
            TextConstants.KiCad.tokenPad, TextConstants.KiCad.tokenZone, TextConstants.KiCad.tokenPadstack,
        ]
        let layerMasks: Set<String> = [
            TextConstants.KiCad.allCopperLayers, TextConstants.KiCad.tokenInCu, TextConstants.KiCad.tokenFBCu,
            TextConstants.KiCad.tokenAdhes, TextConstants.KiCad.tokenPaste, TextConstants.KiCad.tokenMask,
            TextConstants.KiCad.tokenSilkS, TextConstants.KiCad.tokenFab, TextConstants.KiCad.tokenCrtYd,
        ]
        /// EN: Recursively validate S-expression layer references. Apply distinct repair rules to electrical and
        ///     annotation items.
        ///
        /// JA: S式のレイヤー参照を再帰検証する。電気要素と注記要素の修復条件を区別する。
        ///
        /// DE: Lagenverweise in S-Ausdrücken rekursiv prüfen. Für elektrische Elemente und Beschriftungen
        ///     unterschiedliche Korrekturregeln anwenden.
        func walk(
            _ expression: inout SExpression, owner: String = TextConstants.Common.empty, field: String? = nil,
            back: Bool = false,
            electrical: Bool = false
        ) throws {
            guard case .list(var values) = expression, let head = values.first?.scalar else { return }
            let isElectrical = electrical || electricalHeads.contains(head)
            let side =
                head == TextConstants.KiCad.tokenFootprint
                ? values.first(where: { $0.head == TextConstants.Common.tokenLayer })?.scalar(at: 1)
                    == TextConstants.KiCad.tokenBCu : back
            let fieldName =
                head == TextConstants.KiCad.tokenProperty || head == TextConstants.KiCad.tokenFpText
                ? values.dropFirst().first?.scalar : field
            if repairImportedAnnotations,
                [
                    TextConstants.KiCad.tokenProperty, TextConstants.KiCad.tokenFpText,
                    TextConstants.KiCad.tokenFpTextBox,
                ].contains(head),
                !values.contains(where: { $0.head == TextConstants.Common.tokenLayer })
            {
                let reference =
                    fieldName == TextConstants.KiCad.referencePropertyName
                    || fieldName == TextConstants.KiCad.referenceTextKind
                let layer =
                    reference
                    ? (side ? TextConstants.KiCad.tokenBSilkS : TextConstants.KiCad.tokenFSilkS)
                    : (side ? TextConstants.KiCad.tokenBFab : TextConstants.KiCad.tokenFFab)
                values.append(.list([.atom(TextConstants.Common.tokenLayer), .string(layer)]))
            }
            if head == TextConstants.Common.tokenLayer || head == TextConstants.Common.tokenLayers {
                let indices =
                    head == TextConstants.Common.tokenLayer
                    ? Array(values.indices.dropFirst().prefix(1)) : Array(values.indices.dropFirst())
                for index in indices {
                    guard let old = values[index].scalar else { continue }
                    var name = declared.contains(old) ? old : aliases[old] ?? old
                    if layerMasks.contains(name) && head == TextConstants.Common.tokenLayers { continue }
                    if name == TextConstants.KiCad.tokenInner && owner == TextConstants.KiCad.tokenPadstack { continue }
                    if undefined.contains(name) && repairImportedAnnotations && !isElectrical
                        && graphicHeads.contains(owner)
                    {
                        if fieldName == TextConstants.KiCad.referencePropertyName
                            || fieldName == TextConstants.KiCad.referenceTextKind
                        {
                            name = side ? TextConstants.KiCad.tokenBSilkS : TextConstants.KiCad.tokenFSilkS
                        } else if fieldName == TextConstants.KiCad.tokenValue
                            || fieldName == TextConstants.Common.tokenValue
                            || owner == TextConstants.KiCad.tokenProperty
                        {
                            name = side ? TextConstants.KiCad.tokenBFab : TextConstants.KiCad.tokenFFab
                        } else {
                            name = TextConstants.KiCad.tokenCmtsUser
                        }
                    }
                    if undefined.contains(name) {
                        throw KiCadPanelError.invalidBoard(
                            L10n.text(
                                TextConstants.KiCad.anItemOfTypeOwnerUsesAnUndefinedLayerEnglishTemplate(owner, old),
                                TextConstants.KiCad.anItemOfTypeOwnerUsesAnUndefinedLayerJapaneseTemplate(owner, old),
                                TextConstants.KiCad.anItemOfTypeOwnerUsesAnUndefinedLayerGermanTemplate(owner, old)
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
        for index in root.indices where geometryHeads.contains(root[index].head ?? TextConstants.Common.empty) {
            try walk(&root[index])
        }
        // EN: A stackup and custom layer references must follow the layer table. Keep metadata in its original order
        //     and put the table before setup.
        // JA: 積層構成とカスタムレイヤー参照はレイヤー表より後に置く必要がある。メタデータの順序を維持し、setupより前にレイヤー表を置く。
        // DE: Lagenaufbau und benutzerdefinierte Lagenverweise müssen auf die Lagentabelle folgen. Die
        //     Metadatenreihenfolge beibehalten und die Tabelle vor setup einfügen.
        root.removeAll { $0.head == TextConstants.Common.tokenLayers }
        let insertion =
            root.firstIndex {
                $0.head == TextConstants.KiCad.tokenSetup
                    || geometryHeads.contains($0.head ?? TextConstants.Common.empty)
                    || $0.head == TextConstants.KiCad.tokenNet
            }
            ?? root.count
        root.insert(.list([.atom(TextConstants.Common.tokenLayers)] + rows), at: insertion)
        let result = Data((SExpression.list(root).render() + TextConstants.Common.newline).utf8)
        try PanelValidation.document(result, field: TextConstants.KiCad.tokenNormalizeLayersOutput)
        return result
    }

    /// EN: Parse Edge.Cuts and validate the returned bounding rectangle [mm] and closed contours.
    ///
    /// JA: Edge.Cutsを解析し、外接矩形 [mm] と閉ループの戻り値を検証する。
    ///
    /// DE: Edge.Cuts parsen und das zurückgegebene Begrenzungsrechteck [mm] sowie geschlossene Konturen prüfen.
    private static func shape(root: [SExpression]) throws -> PanelBoardShape {
        let outline = root.filter {
            $0.directList(TextConstants.Common.tokenLayer)?.scalar(at: 1) == TextConstants.KiCad.tokenEdgeCuts
        }
        let loops = try PanelRouting.closedLoops(outline.flatMap { try routingSegments($0) })
        let straightEdges = try outline.filter {
            [TextConstants.KiCad.tokenGrLine, TextConstants.KiCad.tokenGrRect, TextConstants.KiCad.tokenGrPoly]
                .contains($0.head ?? TextConstants.Common.empty)
        }.flatMap { try routingSegments($0) }
        let points = loops.flatMap { $0 }
        // EN: Arc cardinal points retain exact array dimensions; tessellated contours are used only for routing and
        //     have a maximum 0.005 mm chord deviation.
        // JA: 円弧の極値点で配列の正確な寸法を保持する。加工線だけに使う近似輪郭の最大弦誤差は0.005 mm。
        // DE: Kreisbogenextrema erhalten die exakten Array-Abmessungen. Polygonal angenäherte Konturen dienen nur dem
        //     Fräsen; die maximale Sehnenabweichung beträgt 0,005 mm.
        let measurements = root.filter {
            $0.directList(TextConstants.Common.tokenLayer)?.scalar(at: 1) == TextConstants.KiCad.tokenEdgeCuts
        }.flatMap {
            geometryPoints($0)
        }
        guard !points.isEmpty, !measurements.isEmpty else { throw KiCadPanelError.noEdgeCuts }
        let result = PanelBoardShape(
            bounds: RouteRect(
                minX: measurements.map(\.x).min()!, minY: measurements.map(\.y).min()!,
                maxX: measurements.map(\.x).max()!, maxY: measurements.map(\.y).max()!), contours: loops,
            straightEdges: straightEdges)
        try PanelValidation.shape(result, field: TextConstants.KiCad.tokenKiCadPanelEngineShapeOutput)
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
            let at = expression.directList(TextConstants.KiCad.tokenAt)
            return RoutePoint(
                x: at?.scalar(at: 1).flatMap(Double.init) ?? 0, y: at?.scalar(at: 2).flatMap(Double.init) ?? 0)
        }
        for item in root {
            if item.head == TextConstants.KiCad.tokenVia,
                let diameter = item.directList(TextConstants.Common.tokenDrill)?.scalar(at: 1).flatMap(Double.init),
                diameter > 0
            {
                let layers = item.directList(TextConstants.Common.tokenLayers)
                let front =
                    layers?.scalar(at: 1) == TextConstants.KiCad.tokenFCu
                    || layers?.scalar(at: 2) == TextConstants.KiCad.tokenFCu
                let back =
                    layers?.scalar(at: 1) == TextConstants.KiCad.tokenBCu
                    || layers?.scalar(at: 2) == TextConstants.KiCad.tokenBCu
                result.append(
                    PanelPreviewDrill(
                        center: position(item), width: diameter, height: diameter, angle: 0, front: front, back: back))
            }
            guard item.head == TextConstants.KiCad.tokenFootprint, case .list(let fields) = item else { continue }
            let origin = position(item)
            let degrees = item.directList(TextConstants.KiCad.tokenAt)?.scalar(at: 3).flatMap(Double.init) ?? 0
            let radians = -degrees * .pi / 180
            for pad in fields
            where pad.head == TextConstants.KiCad.tokenPad
                && [TextConstants.KiCad.tokenThruHole, TextConstants.KiCad.tokenNpThruHole].contains(
                    pad.scalar(at: 2) ?? TextConstants.Common.empty)
            {
                guard case .list(let drill) = pad.directList(TextConstants.Common.tokenDrill) else { continue }
                let oval = drill.count > 1 && drill[1].scalar == TextConstants.KiCad.tokenOval
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
                let angle = -(pad.directList(TextConstants.KiCad.tokenAt)?.scalar(at: 3).flatMap(Double.init) ?? 0)
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
                TextConstants.KiCad.tokenKiCadPanelEngineComposeData,
                TextConstants.KiCad.textBoardsTemplate(PanelLimits.maxBoardPositions))
        }
        try PanelRouting.validate(options)
        let roots = try data.map { try parseRoot(normalizeLayers(data: $0)) }
        let shapes = try roots.map { try shape(root: $0) }
        let layout = try PanelCompositionLayout(bounds: shapes.map(\.bounds), options: options)
        let routing = try PanelRouting.plan(
            boards: layout.placedContours(shapes), arrayBounds: layout.arrayBounds, options: options,
            straightEdges: layout.placedStraightEdges(shapes))
        guard roots.indices.contains(baseIndex) else { throw KiCadPanelError.noEdgeCuts }
        /// EN: Return copper layer names in front-to-back definition order. Compare these arrays to check layer
        ///     stacks.
        ///
        /// JA: 銅箔レイヤー名を表面から裏面の定義順で返す。この配列の一致で層構成を比較する。
        ///
        /// DE: Kupferlagennamen in definierter Reihenfolge von vorne nach hinten zurückgeben. Diese Arrays zum
        ///     Vergleich des Lagenaufbaus verwenden.
        func copperLayers(_ root: [SExpression]) -> [String] {
            guard case .list(let table) = root.first(where: { $0.head == TextConstants.Common.tokenLayers }) else {
                return []
            }
            return table.dropFirst().compactMap { $0.scalar(at: 1) }.filter {
                $0.hasSuffix(TextConstants.KiCad.copperLayerSuffix)
            }
        }
        let stack = copperLayers(roots[baseIndex])
        guard roots.allSatisfy({ copperLayers($0) == stack }) else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    TextConstants.KiCad.allBoardsInOnePanelMustHaveTheSameEnglish,
                    TextConstants.KiCad.allBoardsInOnePanelMustHaveTheSameJapanese,
                    TextConstants.KiCad.allBoardsInOnePanelMustHaveTheSameGerman
                ))
        }
        let versions: [Int] = roots.map { root in
            let node = root.first { $0.head == TextConstants.KiCad.tokenVersion }
            return Int(node?.scalar(at: 1) ?? TextConstants.Common.number0) ?? 0
        }
        let version = versions.max() ?? 20260206
        // EN: KiCad stopped serializing numeric net codes in format 20251028.
        // JA: KiCadは形式バージョン20251028から数値のネット番号を書き出さなくなった。
        // DE: Seit Formatversion 20251028 schreibt KiCad keine numerischen Netznummern mehr.
        let namedNets = version >= 20251028
        let nonGeometry: Set<String> = [
            TextConstants.KiCad.tokenNet, TextConstants.KiCad.tokenEmbeddedFiles,
            TextConstants.KiCad.tokenEmbeddedFonts, TextConstants.Common.tokenLayers,
        ]
        var output = roots[baseIndex].filter {
            !geometryHeads.contains($0.head ?? TextConstants.Common.empty)
                && !nonGeometry.contains($0.head ?? TextConstants.Common.empty)
        }
        if let i = output.firstIndex(where: { $0.head == TextConstants.KiCad.tokenVersion }) {
            output[i] = .list([.atom(TextConstants.KiCad.tokenVersion), .atom(String(version))])
        }
        // EN: Layer IDs changed between KiCad releases. Geometry uses layer names, so use the newest input's table
        //     while retaining the base board setup.
        // JA: KiCadの版によってレイヤーIDが異なる。図形はレイヤー名を使うため、基準基板の設定を保持しつつ、最も新しい入力のレイヤー表を使う。
        // DE: Lagen-IDs unterscheiden sich zwischen KiCad-Versionen. Da die Geometrie Lagennamen verwendet, die
        //     Tabelle der neuesten Eingabe nutzen und die Einstellungen der Basisplatine beibehalten.
        let newest =
            roots.firstIndex { root in
                root.first(where: { $0.head == TextConstants.KiCad.tokenVersion })?.scalar(at: 1) == String(version)
            }
            ?? baseIndex
        var layerRows: [SExpression] = []
        if case .list(let layers) = roots[newest].first(where: { $0.head == TextConstants.Common.tokenLayers }) {
            layerRows = Array(layers.dropFirst())
        }
        var layerNames = Set(layerRows.compactMap { $0.scalar(at: 1) })
        for root in roots {
            if case .list(let table) = root.first(where: { $0.head == TextConstants.Common.tokenLayers }) {
                for row in table.dropFirst() where !layerNames.contains(row.scalar(at: 1) ?? TextConstants.Common.empty)
                {
                    guard !layerRows.contains(where: { $0.scalar(at: 0) == row.scalar(at: 0) }) else {
                        throw KiCadPanelError.invalidBoard(
                            L10n.text(
                                TextConstants.KiCad.customLayerIDsConflictBetweenTheseBoardsSaveThemEnglish,
                                TextConstants.KiCad.customLayerIDsConflictBetweenTheseBoardsSaveThemJapanese,
                                TextConstants.KiCad.customLayerIDsConflictBetweenTheseBoardsSaveThemGerman
                            ))
                    }
                    layerRows.append(row); if let name = row.scalar(at: 1) { layerNames.insert(name) }
                }
            }
        }
        let layerPosition = output.firstIndex { $0.head == TextConstants.KiCad.tokenSetup } ?? output.count
        output.insert(.list([.atom(TextConstants.Common.tokenLayers)] + layerRows), at: layerPosition)
        var netDeclarations: [SExpression] = [], geometry: [SExpression] = [], embedded: [SExpression] = []
        var embeddedByName: [String: String] = [:]
        var nextNet = 1
        if !namedNets {
            netDeclarations.append(
                .list([
                    .atom(TextConstants.KiCad.tokenNet), .atom(TextConstants.Common.number0),
                    .string(TextConstants.Common.empty),
                ]))
        }
        for (instance, placement) in layout.placements.enumerated() {
            let index = placement.sourceIndex, root = roots[index]
            let prefix = TextConstants.KiCad.instanceReferencePrefixTemplate(instance + 1)
            var oldCodes: [String: String] = [TextConstants.Common.number0: TextConstants.Common.empty]
            for item in root where item.head == TextConstants.KiCad.tokenNet {
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
                guard case .list(let values) = expression, values.first?.scalar == TextConstants.KiCad.tokenNet,
                    values.count >= 2
                else {
                    return nil
                }
                if values.count >= 3 { return values[2].scalar }
                if case .atom(let value) = values[1], Int(value) != nil {
                    guard let name = oldCodes[value] else {
                        throw KiCadPanelError.invalidBoard(
                            L10n.text(
                                TextConstants.KiCad.aBoardItemRefersToAnUndefinedNetCodeEnglish,
                                TextConstants.KiCad.aBoardItemRefersToAnUndefinedNetCodeJapanese,
                                TextConstants.KiCad.aBoardItemRefersToAnUndefinedNetCodeGerman))
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
                    let full = name.isEmpty ? TextConstants.Common.empty : prefix + name
                    if namedNets {
                        expression = .list([.atom(TextConstants.KiCad.tokenNet), .string(full)])
                    } else {
                        var code = 0
                        if !full.isEmpty {
                            if let existing = codes[full] {
                                code = existing
                            } else {
                                code = nextNet; nextNet += 1; codes[full] = code;
                                netDeclarations.append(
                                    .list([.atom(TextConstants.KiCad.tokenNet), .atom(String(code)), .string(full)]))
                            }
                        }
                        // EN: Pads carry the name; tracks/zones use only the code.
                        // JA: パッドにはネット名を持たせる。配線とゾーンではネット番号だけを使う。
                        // DE: Pads enthalten den Netznamen; Leiterbahnen und Zonen verwenden nur die Netznummer.
                        expression = .list(
                            [.atom(TextConstants.KiCad.tokenNet), .atom(String(code))]
                                + (values.count > 2 ? [.string(full)] : []))
                    }
                    return
                }
                if values.first?.scalar == TextConstants.KiCad.tokenNetName, values.count > 1,
                    let name = values[1].scalar
                {
                    values[1] = .string(name.isEmpty ? TextConstants.Common.empty : prefix + name)
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
                    geometryHeads.contains($0.head ?? TextConstants.Common.empty)
                        && $0.directList(TextConstants.Common.tokenLayer)?.scalar(at: 1)
                            != TextConstants.KiCad.tokenEdgeCuts
                })
            replaceUUIDs(&items)
            try rewrite(&items)
            if case .list(var parts) = items {
                for i in parts.indices {
                    let isFootprint = parts[i].head == TextConstants.KiCad.tokenFootprint
                    translate(&parts[i], dx: placement.offset.x, dy: placement.offset.y, footprint: isFootprint)
                    if isFootprint {
                        disambiguateReference(
                            &parts[i], suffix: TextConstants.KiCad.instanceReferenceSuffixTemplate(instance + 1))
                    }
                }
                geometry += parts
            }
            if case .list(let files) = root.first(where: { $0.head == TextConstants.KiCad.tokenEmbeddedFiles }) {
                for file in files.dropFirst() {
                    let name =
                        file.scalar(at: 1) ?? file.directList(TextConstants.Common.tokenName)?.scalar(at: 1)
                        ?? file.render()
                    let content = file.render()
                    if let existing = embeddedByName[name] {
                        guard existing == content else {
                            throw KiCadPanelError.invalidBoard(
                                L10n.text(
                                    TextConstants.KiCad.differentEmbeddedFilesShareTheNameNameRenameOneEnglishTemplate(
                                        name),
                                    TextConstants.KiCad.differentEmbeddedFilesShareTheNameNameRenameOneJapaneseTemplate(
                                        name),
                                    TextConstants.KiCad.differentEmbeddedFilesShareTheNameNameRenameOneGermanTemplate(
                                        name)
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
                width: max(0.05, options.dimensionLineWidthMM), layer: TextConstants.KiCad.tokenEdgeCuts)
        }
        geometry += try layout.guides(options: options).map {
            makeLine(
                start: BoardPoint(x: $0.a.x, y: $0.a.y), end: BoardPoint(x: $0.b.x, y: $0.b.y),
                width: options.vScoreLineWidthMM, layer: TextConstants.KiCad.tokenDwgsUser)
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
                at: BoardPoint(x: hole.0.x, y: hole.0.y), diameter: hole.1,
                reference: TextConstants.KiCad.tokenPANELHTemplate(index + 1))
            if case .list(var fields) = item {
                for i in fields.indices where fields[i].head == TextConstants.KiCad.tokenProperty {
                    if case .list(var property) = fields[i] {
                        property.append(
                            .list([.atom(TextConstants.KiCad.tokenHide), .atom(TextConstants.Common.tokenYes)]));
                        fields[i] = .list(property)
                    }
                }
                item = .list(fields)
            }
            geometry.append(item)
        }
        output += netDeclarations + geometry
        if !embedded.isEmpty { output.append(.list([.atom(TextConstants.KiCad.tokenEmbeddedFiles)] + embedded)) }
        if roots.contains(where: {
            $0.contains(where: {
                $0.head == TextConstants.KiCad.tokenEmbeddedFonts && $0.scalar(at: 1) == TextConstants.Common.tokenYes
            })
        }) {
            output.append(.list([.atom(TextConstants.KiCad.tokenEmbeddedFonts), .atom(TextConstants.Common.tokenYes)]))
        }
        let b = layout.panelBounds
        let summary = PanelSummary(
            boardWidthMM: layout.arrayBounds.maxX, boardHeightMM: layout.arrayBounds.maxY,
            panelWidthMM: b.maxX - b.minX, panelHeightMM: b.maxY - b.minY, columns: options.columns,
            rows: layout.rowCount, dimensionLineWidthMM: options.dimensionLineWidthMM)
        let serialized = Data((SExpression.list(output).render() + TextConstants.Common.newline).utf8)
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
        case TextConstants.KiCad.tokenGrLine:
            if let a = p(TextConstants.KiCad.tokenStart), let b = p(TextConstants.KiCad.tokenEnd) {
                return [RouteSegment(a: a, b: b)]
            }
        case TextConstants.KiCad.tokenGrArc:
            if let a = p(TextConstants.KiCad.tokenStart), let m = p(TextConstants.KiCad.tokenMid),
                let b = p(TextConstants.KiCad.tokenEnd)
            {
                return chain(try PanelRouting.threePointArc(start: a, mid: m, end: b))
            }
        case TextConstants.KiCad.tokenGrRect:
            if let a = p(TextConstants.KiCad.tokenStart), let b = p(TextConstants.KiCad.tokenEnd) {
                return PanelRouting.edges(
                    RouteRect(minX: min(a.x, b.x), minY: min(a.y, b.y), maxX: max(a.x, b.x), maxY: max(a.y, b.y)).points
                )
            }
        case TextConstants.KiCad.tokenGrCircle:
            if let center = p(TextConstants.KiCad.tokenCenter), let end = p(TextConstants.KiCad.tokenEnd) {
                return chain(try PanelRouting.arc(center: center, start: end, sweep: 2 * .pi))
            }
        case TextConstants.KiCad.tokenGrPoly:
            if case .list(let values) = expression.directList(TextConstants.KiCad.tokenPts) {
                let points = values.compactMap { v -> RoutePoint? in
                    guard v.head == TextConstants.KiCad.tokenXy, let x = v.scalar(at: 1).flatMap(Double.init),
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
                TextConstants.KiCad.unsupportedEdgeCutsGeometryForTabRoutingEnglish,
                TextConstants.KiCad.unsupportedEdgeCutsGeometryForTabRoutingJapanese,
                TextConstants.KiCad.unsupportedEdgeCutsGeometryForTabRoutingGerman
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
        if expression.head == TextConstants.KiCad.tokenGrArc, points.count >= 3 {
            points += arcBounds(start: points[0], mid: points[1], end: points[2])
        }
        if expression.head == TextConstants.KiCad.tokenGrCircle, points.count >= 2 {
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
            if let atIndex = parts.firstIndex(where: { $0.head == TextConstants.KiCad.tokenAt }) {
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
        disambiguateReference(&expression, suffix: TextConstants.KiCad.tokenRCTemplate(row, column))
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
                guard part.head == TextConstants.KiCad.tokenProperty,
                    part.scalar(at: 1) == TextConstants.KiCad.referencePropertyName
                else { return nil }
                return part.scalar(at: 2)
            }.first
            ?? parts.compactMap { part in
                guard part.head == TextConstants.KiCad.tokenFpText,
                    part.scalar(at: 1) == TextConstants.KiCad.referenceTextKind
                else { return nil }
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
                let isProperty =
                    label.first?.scalar == TextConstants.KiCad.tokenProperty && label.count > 2
                    && label[1].scalar == TextConstants.KiCad.referencePropertyName
                let isLegacy =
                    label.first?.scalar == TextConstants.KiCad.tokenFpText && label.count > 2
                    && label[1].scalar == TextConstants.KiCad.referenceTextKind
                if isProperty || isLegacy {
                    if !label.contains(where: { $0.head == TextConstants.Common.tokenLayer }) {
                        let back =
                            parts.first(where: { $0.head == TextConstants.Common.tokenLayer })?.scalar(at: 1)
                            == TextConstants.KiCad.tokenBCu
                        label.append(
                            .list([
                                .atom(TextConstants.Common.tokenLayer),
                                .string(back ? TextConstants.KiCad.tokenBSilkS : TextConstants.KiCad.tokenFSilkS),
                            ]))
                    }
                    let hidden = label.contains {
                        $0.scalar == TextConstants.KiCad.tokenHide
                            || ($0.head == TextConstants.KiCad.tokenHide
                                && $0.scalar(at: 1) != TextConstants.KiCad.tokenNo)
                    }
                    if !hidden {
                        var fixed = SExpression.list(
                            [
                                .atom(TextConstants.KiCad.tokenFpText), .atom(TextConstants.KiCad.userTextKind),
                                .string(oldReference),
                            ] + Array(label.dropFirst(3)))
                        replaceUUIDs(&fixed)
                        fixedLabels.append(fixed)
                    }
                    if !hidden {
                        label.append(
                            isProperty
                                ? .list([.atom(TextConstants.KiCad.tokenHide), .atom(TextConstants.Common.tokenYes)])
                                : .atom(TextConstants.KiCad.tokenHide))
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
        case TextConstants.KiCad.tokenFpText, TextConstants.KiCad.tokenProperty: textIndex = 2
        case TextConstants.KiCad.tokenFpTextBox: textIndex = 1
        default: textIndex = nil
        }
        if let index = textIndex, parts.indices.contains(index), let text = parts[index].scalar {
            parts[index] = .string(text.replacingOccurrences(of: TextConstants.KiCad.tokenREFERENCE, with: reference))
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
        if parts.first?.scalar == TextConstants.KiCad.tokenProperty, parts.count > 2,
            parts[1].scalar == TextConstants.KiCad.referencePropertyName,
            parts[2].scalar == oldValue
        {
            parts[2] = .string(newValue)
        }
        if parts.first?.scalar == TextConstants.KiCad.tokenFpText, parts.count > 2,
            parts[1].scalar == TextConstants.KiCad.referenceTextKind,
            parts[2].scalar == oldValue
        {
            parts[2] = .string(newValue)
        }
        if parts.first?.scalar == TextConstants.KiCad.referenceTextKind, parts.count > 1, parts[1].scalar == oldValue {
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
        if [TextConstants.KiCad.tokenUuid, TextConstants.KiCad.tokenTstamp].contains(
            parts.first?.scalar ?? TextConstants.Common.empty), let old = parts.dropFirst().first?.scalar
        {
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
        if [TextConstants.KiCad.tokenUuid, TextConstants.KiCad.tokenTstamp].contains(
            parts.first?.scalar ?? TextConstants.Common.empty), parts.count > 1, let old = parts[1].scalar,
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
            .atom(TextConstants.KiCad.tokenGrRect), point(TextConstants.KiCad.tokenStart, x: minX, y: minY),
            point(TextConstants.KiCad.tokenEnd, x: maxX, y: maxY),
            .list([
                .atom(TextConstants.Common.tokenStroke),
                .list([.atom(TextConstants.Common.tokenWidth), .atom(numberString(width))]),
                .list([.atom(TextConstants.KiCad.tokenType), .atom(TextConstants.Common.tokenDefault)]),
            ]),
            .list([.atom(TextConstants.Common.tokenFill), .atom(TextConstants.Common.tokenNone)]),
            .list([.atom(TextConstants.Common.tokenLayer), .string(TextConstants.KiCad.tokenEdgeCuts)]), uuidNode(),
        ])
    }

    /// EN: Create a segment with a layer from validated endpoints [mm] and line width [mm].
    ///
    /// JA: 検証済み端点 [mm] と線幅 [mm] からレイヤー付き線分を作る。
    ///
    /// DE: Ein Segment mit Lage aus geprüften Endpunkten [mm] und einer Linienbreite [mm] erstellen.
    private static func makeLine(start: BoardPoint, end: BoardPoint, width: Double, layer: String) -> SExpression {
        .list([
            .atom(TextConstants.KiCad.tokenGrLine), point(TextConstants.KiCad.tokenStart, x: start.x, y: start.y),
            point(TextConstants.KiCad.tokenEnd, x: end.x, y: end.y),
            .list([
                .atom(TextConstants.Common.tokenStroke),
                .list([.atom(TextConstants.Common.tokenWidth), .atom(numberString(width))]),
                .list([.atom(TextConstants.KiCad.tokenType), .atom(TextConstants.KiCad.tokenSolid)]),
            ]),
            .list([.atom(TextConstants.Common.tokenLayer), .string(layer)]), uuidNode(),
        ])
    }

    /// EN: Create an NPTH footprint from a validated center [mm] and diameter [mm].
    ///
    /// JA: 検証済み中心 [mm] と直径 [mm] からNPTHフットプリントを作る。
    ///
    /// DE: Einen NPTH-Footprint aus geprüftem Mittelpunkt [mm] und Durchmesser [mm] erstellen.
    private static func makeMountingHole(at point: BoardPoint, diameter: Double, reference: String) -> SExpression {
        .list([
            .atom(TextConstants.KiCad.tokenFootprint),
            .string(TextConstants.KiCad.tokenMountingHoleMountingHoleMmTemplate(numberString(diameter))),
            .list([.atom(TextConstants.Common.tokenLayer), .string(TextConstants.KiCad.tokenFCu)]), uuidNode(),
            .list([.atom(TextConstants.KiCad.tokenAt), .atom(numberString(point.x)), .atom(numberString(point.y))]),
            .list([
                .atom(TextConstants.KiCad.tokenProperty), .string(TextConstants.KiCad.referencePropertyName),
                .string(reference),
                .list([
                    .atom(TextConstants.KiCad.tokenAt), .atom(TextConstants.Common.number0),
                    .atom(TextConstants.Common.number0), .atom(TextConstants.Common.number0),
                ]), .list([.atom(TextConstants.Common.tokenLayer), .string(TextConstants.KiCad.tokenFSilkS)]),
                uuidNode(),
                .list([
                    .atom(TextConstants.KiCad.tokenEffects),
                    .list([
                        .atom(TextConstants.KiCad.tokenFont),
                        .list([
                            .atom(TextConstants.Common.tokenSize), .atom(TextConstants.Common.number1),
                            .atom(TextConstants.Common.number1),
                        ]),
                        .list([.atom(TextConstants.KiCad.tokenThickness), .atom(TextConstants.KiCad.number0Point15)]),
                    ]),
                ]),
            ]),
            .list([
                .atom(TextConstants.KiCad.tokenProperty), .string(TextConstants.KiCad.tokenValue),
                .string(TextConstants.KiCad.tokenMountingHole),
                .list([
                    .atom(TextConstants.KiCad.tokenAt), .atom(TextConstants.Common.number0),
                    .atom(TextConstants.Common.number0), .atom(TextConstants.Common.number0),
                ]), .list([.atom(TextConstants.Common.tokenLayer), .string(TextConstants.KiCad.tokenFFab)]),
                uuidNode(),
                .list([
                    .atom(TextConstants.KiCad.tokenEffects),
                    .list([
                        .atom(TextConstants.KiCad.tokenFont),
                        .list([
                            .atom(TextConstants.Common.tokenSize), .atom(TextConstants.Common.number1),
                            .atom(TextConstants.Common.number1),
                        ]),
                        .list([.atom(TextConstants.KiCad.tokenThickness), .atom(TextConstants.KiCad.number0Point15)]),
                    ]),
                ]),
            ]),
            .list([
                .atom(TextConstants.KiCad.tokenAttr), .atom(TextConstants.KiCad.tokenExcludeFromPosFiles),
                .atom(TextConstants.KiCad.tokenExcludeFromBom),
            ]),
            .list([
                .atom(TextConstants.KiCad.tokenPad), .string(TextConstants.Common.empty),
                .atom(TextConstants.KiCad.tokenNpThruHole), .atom(TextConstants.Common.tokenCircle),
                .list([
                    .atom(TextConstants.KiCad.tokenAt), .atom(TextConstants.Common.number0),
                    .atom(TextConstants.Common.number0),
                ]),
                .list([
                    .atom(TextConstants.Common.tokenSize), .atom(numberString(diameter)), .atom(numberString(diameter)),
                ]),
                .list([.atom(TextConstants.Common.tokenDrill), .atom(numberString(diameter))]),
                .list([
                    .atom(TextConstants.Common.tokenLayers), .string(TextConstants.KiCad.allCopperLayers),
                    .string(TextConstants.KiCad.tokenMask),
                ]), uuidNode(),
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
    private static func uuidNode() -> SExpression {
        .list([.atom(TextConstants.KiCad.tokenUuid), .string(UUID().uuidString.lowercased())])
    }
    /// EN: Format validated numbers independently of locale. Do not use a decimal comma.
    ///
    /// JA: 検証済み数値をロケール非依存の表記へ変換する。小数点にカンマを使わない。
    ///
    /// DE: Geprüfte Zahlen unabhängig von der Spracheinstellung formatieren. Kein Dezimalkomma verwenden.
    private static func numberString(_ value: Double) -> String {
        String(
            format: TextConstants.KiCad.kiCadNumberFormat,
            locale: Locale(identifier: TextConstants.Common.posixLocaleIdentifier), value)
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
                TextConstants.KiCad.cannotPanelizeTheKiCadBoardReasonEnglishTemplate(reason),
                TextConstants.KiCad.cannotPanelizeTheKiCadBoardReasonJapaneseTemplate(reason),
                TextConstants.KiCad.cannotPanelizeTheKiCadBoardReasonGermanTemplate(reason))
        case .noEdgeCuts:
            return L10n.text(
                TextConstants.KiCad.noBoardOutlineWasFoundOnEdgeCutsLinesEnglish,
                TextConstants.KiCad.noBoardOutlineWasFoundOnEdgeCutsLinesJapanese,
                TextConstants.KiCad.noBoardOutlineWasFoundOnEdgeCutsLinesGerman)
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
            return TextConstants.Common.doubleQuote
                + value.replacingOccurrences(
                    of: TextConstants.KiCad.backslash, with: TextConstants.KiCad.escapedBackslash
                )
                .replacingOccurrences(
                    of: TextConstants.Common.doubleQuote, with: TextConstants.KiCad.escapedDoubleQuote
                )
                .replacingOccurrences(of: TextConstants.Common.newline, with: TextConstants.KiCad.tokenN)
                + TextConstants.Common.doubleQuote
        case .list(let items):
            guard !items.isEmpty else { return TextConstants.KiCad.emptyList }
            if items.allSatisfy({ $0.scalar != nil }) {
                return TextConstants.KiCad.openingParenthesis
                    + items.map { $0.render(depth: depth) }.joined(separator: TextConstants.Common.space)
                    + TextConstants.KiCad.closingParenthesis
            }
            var prefix: [SExpression] = []
            var rest: [SExpression] = []
            for item in items {
                if rest.isEmpty && item.scalar != nil { prefix.append(item) } else { rest.append(item) }
            }
            let firstLine =
                TextConstants.KiCad.openingParenthesis
                + prefix.map { $0.render(depth: depth) }.joined(separator: TextConstants.Common.space)
            let childIndent = String(repeating: TextConstants.KiCad.tab, count: depth + 1)
            let body = rest.map { childIndent + $0.render(depth: depth + 1) }.joined(
                separator: TextConstants.Common.newline)
            return firstLine
                + (body.isEmpty
                    ? TextConstants.KiCad.closingParenthesis
                    : TextConstants.Common.newline + body + TextConstants.Common.newline
                        + String(repeating: TextConstants.KiCad.tab, count: depth)
                        + TextConstants.KiCad.closingParenthesis)
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
        let normalized = source.first == TextConstants.Characters.byteOrderMark ? String(source.dropFirst()) : source
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
                    TextConstants.KiCad.unexpectedDataAfterTheKiCadBoardRootEnglish,
                    TextConstants.KiCad.unexpectedDataAfterTheKiCadBoardRootJapanese,
                    TextConstants.KiCad.unexpectedDataAfterTheKiCadBoardRootGerman))
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
                    TextConstants.KiCad.theKiCadFileIsNestedTooDeeplyEnglish,
                    TextConstants.KiCad.theKiCadFileIsNestedTooDeeplyJapanese,
                    TextConstants.KiCad.theKiCadFileIsNestedTooDeeplyGerman))
        }
        nodeCount += 1
        guard nodeCount <= PanelLimits.maxSyntaxNodes else {
            throw PanelValidation.invalid(
                TextConstants.KiCad.tokenSExpressionParserNodeCount,
                TextConstants.KiCad.positiveCountRangeTemplate(PanelLimits.maxSyntaxNodes))
        }
        skipWhitespaceAndComments()
        guard index < characters.count else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    TextConstants.KiCad.unexpectedEndOfFileEnglish, TextConstants.KiCad.unexpectedEndOfFileJapanese,
                    TextConstants.KiCad.unexpectedEndOfFileGerman))
        }
        if characters[index] == TextConstants.Characters.openingParenthesis {
            index += 1
            var items: [SExpression] = []
            while true {
                skipWhitespaceAndComments()
                guard index < characters.count else {
                    throw KiCadPanelError.invalidBoard(
                        L10n.text(
                            TextConstants.KiCad.aClosingParenthesisIsMissingEnglish,
                            TextConstants.KiCad.aClosingParenthesisIsMissingJapanese,
                            TextConstants.KiCad.aClosingParenthesisIsMissingGerman))
                }
                if characters[index] == TextConstants.Characters.closingParenthesis { index += 1; return .list(items) }
                items.append(try parseExpression(depth: depth + 1))
            }
        }
        if characters[index] == TextConstants.Characters.doubleQuote { return .string(try parseQuoted()) }
        let start = index
        while index < characters.count && !characters[index].isWhitespace
            && characters[index] != TextConstants.Characters.openingParenthesis
            && characters[index] != TextConstants.Characters.closingParenthesis
            && characters[index] != TextConstants.Characters.semicolon
        { index += 1 }
        guard index > start else {
            throw KiCadPanelError.invalidBoard(
                L10n.text(
                    TextConstants.KiCad.cannotParseAnSExpressionTokenEnglish,
                    TextConstants.KiCad.cannotParseAnSExpressionTokenJapanese,
                    TextConstants.KiCad.cannotParseAnSExpressionTokenGerman))
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
        var result = TextConstants.Common.empty
        while index < characters.count {
            let character = characters[index]
            index += 1
            if character == TextConstants.Characters.doubleQuote { return result }
            if character == TextConstants.Characters.backslash, index < characters.count {
                let escaped = characters[index]
                index += 1
                switch escaped {
                case TextConstants.Characters.letterLowerN: result.append(TextConstants.Common.newline);
                case TextConstants.Characters.letterLowerR: result.append(TextConstants.KiCad.carriageReturn);
                case TextConstants.Characters.letterLowerT: result.append(TextConstants.KiCad.tab);
                default: result.append(escaped)
                }
            } else {
                result.append(character)
            }
        }
        throw KiCadPanelError.invalidBoard(
            L10n.text(
                TextConstants.KiCad.aQuotedStringIsUnterminatedEnglish,
                TextConstants.KiCad.aQuotedStringIsUnterminatedJapanese,
                TextConstants.KiCad.aQuotedStringIsUnterminatedGerman))
    }

    /// EN: Advance to the next token without reading beyond the character buffer.
    ///
    /// JA: 読み取り位置を次のトークンへ進める。文字数を超えて参照しない。
    ///
    /// DE: Zum nächsten Token vorrücken, ohne über das Ende des Zeichenpuffers hinaus zu lesen.
    private mutating func skipWhitespaceAndComments() {
        while index < characters.count {
            if characters[index].isWhitespace { index += 1; continue }
            if characters[index] == TextConstants.Characters.semicolon {
                while index < characters.count && characters[index] != TextConstants.Characters.newline { index += 1 }
                continue
            }
            break
        }
    }
}
