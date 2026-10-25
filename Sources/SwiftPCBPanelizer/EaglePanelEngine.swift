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

// EN: String/character literals are defined in TextConstants.Eagle, Common and Characters; variable text uses constant templates.
// JA: 文字列・文字リテラルはTextConstants.Eagle・Common・Charactersに定義し、可変文は定数テンプレートから生成する。
// DE: Zeichenketten-/Zeichenliterale stehen in TextConstants.Eagle, Common und Characters; variable Texte nutzen konstante Vorlagen.

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
    var columnGapMM = 2.0
    /// EN: Board spacing between adjacent rows [mm]. A finite, nonnegative value.
    ///
    /// JA: 隣接行の基板間隔 [mm]。0以上の有限値。
    ///
    /// DE: Platinenabstand zwischen benachbarten Zeilen [mm]. Ein endlicher, nicht negativer Wert.
    var rowGapMM = 2.0
    /// EN: Material width retained along the panel's top and bottom edges [mm].
    ///
    /// JA: パネル上辺・下辺に残す材料幅 [mm]。
    ///
    /// DE: Verbleibende Materialbreite am oberen und unteren Panelrand [mm].
    var horizontalFrameMM = 10.0
    /// EN: Material width retained along the panel's left and right edges [mm].
    ///
    /// JA: パネル左辺・右辺に残す材料幅 [mm]。
    ///
    /// DE: Verbleibende Materialbreite am linken und rechten Panelrand [mm].
    var verticalFrameMM = 10.0
    /// EN: Distance from left/right edges to mounting hole centers [mm]. At least the hole radius when enabled.
    ///
    /// JA: 左右端から取付穴中心までの距離 [mm]。有効時は穴半径以上。
    ///
    /// DE: Abstand vom linken/rechten Rand zum Mittelpunkt der Befestigungsbohrung [mm]. Bei aktivierter Bohrung
    ///     mindestens ihr Radius.
    var mountingHoleOffsetXMM = 3.0
    /// EN: Distance from top/bottom edges to mounting hole centers [mm]. At least the hole radius when enabled.
    ///
    /// JA: 上下端から取付穴中心までの距離 [mm]。有効時は穴半径以上。
    ///
    /// DE: Abstand vom oberen/unteren Rand zum Mittelpunkt der Befestigungsbohrung [mm]. Bei aktivierter Bohrung
    ///     mindestens ihr Radius.
    var mountingHoleOffsetYMM = 3.0
    /// EN: Mounting hole diameter [mm]. Finite and positive when enabled.
    ///
    /// JA: 取付穴直径 [mm]。有効時は正の有限値。
    ///
    /// DE: Durchmesser der Befestigungsbohrung [mm]. Bei aktivierter Bohrung endlich und positiv.
    var mountingHoleDrillMM = 3.2
    /// EN: Include the four corner mounting holes in a newly opened panel.
    /// JA: 新規パネルでは四隅の取付穴を有効にする。
    /// DE: Die vier Befestigungsbohrungen an den Ecken eines neuen Panels aktivieren.
    var addMountingHoles = true
    /// EN: Output outline stroke width [mm], distinct from the array's physical dimensions.
    ///
    /// JA: 出力外形線の幅 [mm]。配列の物理寸法とは区別する。
    ///
    /// DE: Linienbreite der Ausgabekontur [mm], getrennt von den physischen Abmessungen der Anordnung.
    var dimensionLineWidthMM = 0.01
    var addVScoreSeparators = false
    var vScoreLineWidthMM = 0.1
    /// EN: Routed clearance between the board array and the inside of the frame [mm].
    ///
    /// JA: 基板配列と外枠内側の間を切り抜く隙間 [mm]。
    ///
    /// DE: Ausgefräster Abstand zwischen der Platinenanordnung und der Rahmeninnenseite [mm].
    var frameGapMM = 2.0
    /// EN: Include breakaway tabs in a newly opened panel; all four frame sides are selected below.
    /// JA: 新規パネルでは接続タブを有効にし、外枠に繋ぐ4辺も以下で選択する。
    /// DE: Verbindungsstege in einem neuen Panel aktivieren; alle vier Rahmenseiten sind unten ausgewählt.
    var addTabs = true
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
                TextConstants.Common.columnsAndRowsMustBeAtLeastOneEnglish,
                TextConstants.Eagle.columnsAndRowsMustBeAtLeastOneJapanese,
                TextConstants.Common.columnsAndRowsMustBeAtLeastOneGerman)
        case .negativeMeasurement(let name):
            return L10n.text(
                TextConstants.Eagle.nameMustBeZeroOrGreaterEnglishTemplate(name),
                TextConstants.Eagle.nameMustBeZeroOrGreaterJapaneseTemplate(name),
                TextConstants.Eagle.nameMustBeZeroOrGreaterGermanTemplate(name))
        case .malformedXML(let reason):
            return L10n.text(
                TextConstants.Eagle.cannotReadEAGLEBrdXMLReasonEnglishTemplate(reason),
                TextConstants.Eagle.cannotReadEAGLEBrdXMLReasonJapaneseTemplate(reason),
                TextConstants.Eagle.cannotReadEAGLEBrdXMLReasonGermanTemplate(reason))
        case .unsupportedRoot(let name):
            return L10n.text(
                TextConstants.Eagle.notAnEAGLEFileRootElementNameEnglishTemplate(name),
                TextConstants.Eagle.notAnEAGLEFileRootElementNameJapaneseTemplate(name),
                TextConstants.Eagle.notAnEAGLEFileRootElementNameGermanTemplate(name))
        case .noBoard:
            return L10n.text(
                TextConstants.Eagle.noBoardElementWasFoundInThisEAGLEFileEnglish,
                TextConstants.Eagle.noBoardElementWasFoundInThisEAGLEFileJapanese,
                TextConstants.Eagle.noBoardElementWasFoundInThisEAGLEFileGerman)
        case .noPlainSection:
            return L10n.text(
                TextConstants.Eagle.noPlainSectionWasFoundInTheBoardEnglish,
                TextConstants.Eagle.noPlainSectionWasFoundInTheBoardJapanese,
                TextConstants.Eagle.noPlainSectionWasFoundInTheBoardGerman)
        case .noDimension:
            return L10n.text(
                TextConstants.Eagle.noOutlineWiresWereFoundOnDimensionLayerCreateEnglish,
                TextConstants.Eagle.noOutlineWiresWereFoundOnDimensionLayerCreateJapanese,
                TextConstants.Eagle.noOutlineWiresWereFoundOnDimensionLayerCreateGerman
            )
        }
    }
}

enum EaglePanelEngine {
    private static let dimensionLayer = TextConstants.Eagle.number20
    private static let vScoreLayer = TextConstants.Eagle.number102
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
        guard source.name == TextConstants.Common.tokenEagle else { throw EaglePanelError.unsupportedRoot(source.name) }
        guard
            let board = source.child(named: TextConstants.Eagle.tokenDrawing)?.child(
                named: TextConstants.Eagle.tokenBoard)
        else { throw EaglePanelError.noBoard }
        guard let plain = board.child(named: TextConstants.Eagle.tokenPlain) else {
            throw EaglePanelError.noPlainSection
        }
        let restrictionLayers: Set<String> = [
            TextConstants.Eagle.number41, TextConstants.Eagle.number42, TextConstants.Eagle.number43,
        ]
        var changed = false
        for index in plain.children.indices {
            let rectangle = plain.children[index]
            guard rectangle.name == TextConstants.Common.tokenRectangle,
                let layer = rectangle.attributes[TextConstants.Common.tokenLayer],
                restrictionLayers.contains(layer)
            else { continue }
            guard let x1 = rectangle.number(TextConstants.Eagle.tokenX1),
                let y1 = rectangle.number(TextConstants.Eagle.tokenY1),
                let x2 = rectangle.number(TextConstants.Eagle.tokenX2),
                let y2 = rectangle.number(TextConstants.Eagle.tokenY2),
                [x1, y1, x2, y2, rectangle.rotationDegrees].allSatisfy(\.isFinite)
            else {
                throw EaglePanelError.malformedXML(
                    L10n.text(
                        TextConstants.Eagle.aRestrictionRectangleHasInvalidCoordinatesOrRotationEnglish,
                        TextConstants.Eagle.aRestrictionRectangleHasInvalidCoordinatesOrRotationJapanese,
                        TextConstants.Eagle.aRestrictionRectangleHasInvalidCoordinatesOrRotationGerman))
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
                    name: TextConstants.Eagle.tokenVertex,
                    attributes: [
                        TextConstants.Eagle.letterLowerX: numberString(center.x + dx * cos(angle) - dy * sin(angle)),
                        TextConstants.Eagle.letterLowerY: numberString(center.y + dx * sin(angle) + dy * cos(angle)),
                    ])
            }
            // EN: Zero stroke width keeps the original rectangle boundary exact. tRestrict/bRestrict prohibit copper,
            //     tracks, pads and vias on their respective face; vRestrict prohibits vias across the copper stack.
            // JA: 線幅を0にして元の矩形境界を正確に保持する。tRestrict/bRestrictは各面の銅箔・配線・パッド・ビアを禁止し、vRestrictは銅箔積層全体のビアを禁止する。
            // DE: Eine Linienbreite von null erhält die ursprüngliche Rechteckgrenze exakt. tRestrict/bRestrict
            //     sperren Kupfer, Leiterbahnen, Pads und Vias auf der jeweiligen Seite; vRestrict sperrt Vias durch
            //     den gesamten Kupferlagenaufbau.
            let polygon = EagleXMLNode(
                name: TextConstants.Eagle.tokenPolygon,
                attributes: [
                    TextConstants.Common.tokenLayer: layer,
                    TextConstants.Common.tokenWidth: TextConstants.Common.number0,
                ], children: vertices)
            polygon.parent = plain
            plain.children[index] = polygon
            changed = true
        }
        // EN: Also normalize exponent-form geometry in existing files, including panels exported by older versions.
        //     Only the temporary import copy changes; component values, names and other text remain untouched.
        // JA: 旧版が出力したパネルを含め、既存ファイルの指数表記の形状値も通常の小数へ直す。
        //     変更するのは取り込み用の一時コピーだけで、部品値・名前などの文字列は保持する。
        // DE: Exponentialwerte bestehender Geometriedaten einschließlich älterer Exporte ebenfalls normalisieren.
        //     Nur die temporäre Importkopie ändern; Bauteilwerte, Namen und andere Texte bleiben erhalten.
        let numericAttributes: Set<String> = [
            TextConstants.Eagle.letterLowerX, TextConstants.Eagle.letterLowerY, TextConstants.Eagle.tokenX1,
            TextConstants.Eagle.tokenY1, TextConstants.Eagle.tokenX2, TextConstants.Eagle.tokenY2,
            TextConstants.Eagle.tokenX3, TextConstants.Eagle.tokenY3, TextConstants.Common.tokenWidth,
            TextConstants.Common.tokenHeight, TextConstants.Common.tokenRadius, TextConstants.Common.tokenDrill,
            TextConstants.Common.tokenDiameter, TextConstants.Eagle.tokenDx, TextConstants.Eagle.tokenDy,
            TextConstants.Common.tokenSize, TextConstants.Eagle.tokenCurve, TextConstants.Eagle.tokenSpacing,
            TextConstants.Eagle.tokenIsolate, TextConstants.Eagle.tokenRot,
        ]
        /// EN: Normalize only known numeric attributes, preserving EAGLE rotation prefixes such as MR or SR.
        /// JA: 数値用の属性だけを正規化し、MRやSRなどEAGLEの回転修飾子は保持する。
        /// DE: Nur bekannte Zahlenattribute normalisieren; EAGLE-Drehpräfixe wie MR oder SR erhalten.
        func normalizeImportNumbers(_ node: EagleXMLNode) {
            for key in numericAttributes {
                guard let original = node.attributes[key] else { continue }
                let scalar =
                    key == TextConstants.Eagle.tokenRot
                    ? String(
                        original.drop(while: {
                            $0 == TextConstants.Characters.letterUpperS || $0 == TextConstants.Characters.letterUpperM
                                || $0 == TextConstants.Characters.letterUpperR
                        })) : original
                guard
                    scalar.contains(TextConstants.Eagle.letterLowerE)
                        || scalar.contains(TextConstants.Eagle.letterUpperE), let value = Double(scalar), value.isFinite
                else {
                    continue
                }
                let prefix = original.dropLast(scalar.count)
                node.attributes[key] = String(prefix) + numberString(value)
                changed = true
            }
            for child in node.children {
                normalizeImportNumbers(child)
            }
        }
        normalizeImportNumbers(source)
        let result = changed ? EagleXMLWriter.serialize(source) : data
        try PanelValidation.document(result, field: TextConstants.Eagle.tokenPreparedForKiCadImportOutput)
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
            (
                L10n.text(
                    TextConstants.Common.columnSpacingEnglish, TextConstants.Eagle.columnSpacingJapanese,
                    TextConstants.Common.columnSpacingGerman), options.columnGapMM
            ),
            (
                L10n.text(
                    TextConstants.Common.rowSpacingEnglish, TextConstants.Eagle.rowSpacingJapanese,
                    TextConstants.Common.rowSpacingGerman), options.rowGapMM
            ),
            (
                L10n.text(
                    TextConstants.Eagle.horizontalFrameEnglish, TextConstants.Eagle.horizontalFrameJapanese,
                    TextConstants.Eagle.horizontalFrameGerman), options.horizontalFrameMM
            ),
            (
                L10n.text(
                    TextConstants.Eagle.verticalFrameEnglish, TextConstants.Eagle.verticalFrameJapanese,
                    TextConstants.Eagle.verticalFrameGerman), options.verticalFrameMM
            ),
            (
                L10n.text(
                    TextConstants.Eagle.mountingHoleXInsetEnglish, TextConstants.Eagle.mountingHoleXInsetJapanese,
                    TextConstants.Eagle.mountingHoleXInsetGerman),
                options.mountingHoleOffsetXMM
            ),
            (
                L10n.text(
                    TextConstants.Eagle.mountingHoleYInsetEnglish, TextConstants.Eagle.mountingHoleYInsetJapanese,
                    TextConstants.Eagle.mountingHoleYInsetGerman),
                options.mountingHoleOffsetYMM
            ),
            (
                L10n.text(
                    TextConstants.Common.outlineLineWidthEnglish, TextConstants.Common.outlineLineWidthJapanese,
                    TextConstants.Common.outlineLineWidthGerman), options.dimensionLineWidthMM
            ),
            (
                L10n.text(
                    TextConstants.Common.guideLineWidthEnglish, TextConstants.Eagle.guideLineWidthJapanese,
                    TextConstants.Common.guideLineWidthGerman), options.vScoreLineWidthMM
            ),
        ] where value < 0 { throw EaglePanelError.negativeMeasurement(name) }
        if options.addMountingHoles, options.mountingHoleDrillMM <= 0 {
            throw EaglePanelError.negativeMeasurement(
                L10n.text(
                    TextConstants.Eagle.mountingHoleDiameterEnglish, TextConstants.Eagle.mountingHoleDiameterJapanese,
                    TextConstants.Eagle.mountingHoleDiameterGerman))
        }

        let source = try EagleXMLParser.parse(data)
        guard source.name == TextConstants.Common.tokenEagle else { throw EaglePanelError.unsupportedRoot(source.name) }
        guard let drawing = source.child(named: TextConstants.Eagle.tokenDrawing),
            let board = drawing.child(named: TextConstants.Eagle.tokenBoard)
        else {
            throw EaglePanelError.noBoard
        }
        guard let plain = board.child(named: TextConstants.Eagle.tokenPlain) else {
            throw EaglePanelError.noPlainSection
        }

        var xs: [Double] = []
        var ys: [Double] = []
        var dimensionWidth = 0.0
        for wire in plain.children
        where wire.name == TextConstants.Eagle.tokenWire
            && wire.attributes[TextConstants.Common.tokenLayer] == dimensionLayer
        {
            if let x = wire.number(TextConstants.Eagle.tokenX1) { xs.append(x) }
            if let x = wire.number(TextConstants.Eagle.tokenX2) { xs.append(x) }
            if let y = wire.number(TextConstants.Eagle.tokenY1) { ys.append(y) }
            if let y = wire.number(TextConstants.Eagle.tokenY2) { ys.append(y) }
            dimensionWidth = max(dimensionWidth, wire.number(TextConstants.Common.tokenWidth) ?? 0)
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
                    plain.children.filter { $0.attributes[TextConstants.Common.tokenLayer] == dimensionLayer }.flatMap {
                        try routingSegments($0)
                    }), bounds: RouteRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY), options: routingOptions,
                straightEdges: plain.children.filter {
                    $0.attributes[TextConstants.Common.tokenLayer] == dimensionLayer
                        && $0.name == TextConstants.Eagle.tokenWire
                        && abs($0.number(TextConstants.Eagle.tokenCurve) ?? 0) < 1e-8
                }.flatMap { try routingSegments($0) })
            : RoutingPlan(segments: [], mouseBites: [])
        let routedEdges = routingPlan.segments

        var packageLabels: [String: [EagleXMLNode]] = [:]
        for library in board.child(named: TextConstants.Eagle.tokenLibraries)?.children ?? [] {
            for package in library.child(named: TextConstants.Eagle.tokenPackages)?.children ?? []
            where package.name == TextConstants.Eagle.tokenPackage {
                let key =
                    (library.attributes[TextConstants.Common.tokenName] ?? TextConstants.Common.empty)
                    + TextConstants.Eagle.slash
                    + (package.attributes[TextConstants.Common.tokenName] ?? TextConstants.Common.empty)
                packageLabels[key] = package.descendants(named: TextConstants.Eagle.tokenText).filter {
                    [TextConstants.Eagle.nameTextPlaceholder, TextConstants.Eagle.valueTextPlaceholder].contains(
                        $0.text.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }

        let output = source.deepCopy()
        guard let outputDrawing = output.child(named: TextConstants.Eagle.tokenDrawing),
            let outputBoard = outputDrawing.child(named: TextConstants.Eagle.tokenBoard),
            let outputPlain = outputBoard.child(named: TextConstants.Eagle.tokenPlain)
        else { throw EaglePanelError.noBoard }

        var generatedNameTexts: [EagleXMLNode] = []
        let sourceElements = board.child(named: TextConstants.Eagle.tokenElements)
        var generatedElements: [EagleXMLNode] = []
        if let sourceElements {
            for sourceElement in sourceElements.children where sourceElement.name == TextConstants.Eagle.tokenElement {
                let name = sourceElement.attributes[TextConstants.Common.tokenName] ?? TextConstants.Common.empty
                let element = sourceElement.deepCopy()
                let key =
                    (sourceElement.attributes[TextConstants.Eagle.tokenLibrary] ?? TextConstants.Common.empty)
                    + TextConstants.Eagle.slash
                    + (sourceElement.attributes[TextConstants.Eagle.tokenPackage] ?? TextConstants.Common.empty)
                let isSmashed =
                    sourceElement.attributes[TextConstants.Eagle.tokenSmashed] == TextConstants.Common.tokenYes
                var labels: [EagleXMLNode] = []
                if isSmashed {
                    // EN: NAME attributes already have board coordinates and may have been moved independently of the
                    //     footprint.
                    // JA: NAME属性は既に基板座標であり、フットプリントと独立して移動されている場合がある。
                    // DE: NAME-Attribute liegen bereits in Platinenkoordinaten vor und können unabhängig vom
                    //     Footprint verschoben worden sein.
                    for attribute in sourceElement.children
                    where attribute.name == TextConstants.Eagle.tokenAttribute
                        && attribute.attributes[TextConstants.Common.tokenName]
                            == TextConstants.Eagle.nameAttributeIdentifier
                    {
                        if attribute.attributes[TextConstants.Eagle.tokenDisplay] != TextConstants.Eagle.tokenOff {
                            var attributes = attribute.attributes
                            for key in [
                                TextConstants.Common.tokenName, TextConstants.Common.tokenValue,
                                TextConstants.Eagle.tokenDisplay, TextConstants.Eagle.tokenConstant,
                            ] { attributes.removeValue(forKey: key) }
                            let text: String
                            switch attribute.attributes[TextConstants.Eagle.tokenDisplay] {
                            case TextConstants.Common.tokenName: text = TextConstants.Eagle.nameAttributeIdentifier
                            case TextConstants.Eagle.tokenBoth: text = TextConstants.Eagle.textNAME + name
                            default: text = attribute.attributes[TextConstants.Common.tokenValue] ?? name
                            }
                            labels.append(
                                EagleXMLNode(name: TextConstants.Eagle.tokenText, attributes: attributes, text: text))
                        }
                    }
                    element.children.removeAll {
                        $0.name == TextConstants.Eagle.tokenAttribute
                            && $0.attributes[TextConstants.Common.tokenName]
                                == TextConstants.Eagle.nameAttributeIdentifier
                    }
                } else if let templates = packageLabels[key], !templates.isEmpty {
                    element.attributes[TextConstants.Eagle.tokenSmashed] = TextConstants.Common.tokenYes
                    for template in templates {
                        let value =
                            template.text.trimmingCharacters(in: .whitespacesAndNewlines)
                                == TextConstants.Eagle.nameTextPlaceholder
                            ? name
                            : (sourceElement.attributes[TextConstants.Common.tokenValue] ?? TextConstants.Common.empty)
                        labels.append(makeNameLabel(from: template, element: sourceElement, fallbackName: value))
                    }
                    element.children.removeAll {
                        $0.name == TextConstants.Eagle.tokenAttribute
                            && [
                                TextConstants.Eagle.nameAttributeIdentifier,
                                TextConstants.Eagle.valueAttributeIdentifier,
                            ].contains(
                                $0.attributes[TextConstants.Common.tokenName] ?? TextConstants.Common.empty)
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
            if routed && element.attributes[TextConstants.Common.tokenLayer] == dimensionLayer { continue }
            if element.name == TextConstants.Eagle.tokenWire,
                element.attributes[TextConstants.Common.tokenLayer] == vScoreLayer
            {
                let width = element.number(TextConstants.Common.tokenWidth) ?? 0
                if let x1 = element.number(TextConstants.Eagle.tokenX1),
                    let x2 = element.number(TextConstants.Eagle.tokenX2), x1 == x2
                {
                    for column in 0..<options.columns {
                        let x = x1 + Double(column) * columnOffset
                        scoreX[x] = max(scoreX[x] ?? 0, width)
                    }
                }
                if let y1 = element.number(TextConstants.Eagle.tokenY1),
                    let y2 = element.number(TextConstants.Eagle.tokenY2), y1 == y2
                {
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
                name: TextConstants.Eagle.tokenHole,
                attributes: [
                    TextConstants.Eagle.letterLowerX: numberString(point.x),
                    TextConstants.Eagle.letterLowerY: numberString(point.y),
                    TextConstants.Common.tokenDrill: numberString(options.mouseBiteDiameterMM),
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
                        name: TextConstants.Eagle.tokenHole,
                        attributes: [
                            TextConstants.Eagle.letterLowerX: numberString(x),
                            TextConstants.Eagle.letterLowerY: numberString(y),
                            TextConstants.Common.tokenDrill: numberString(options.mountingHoleDrillMM),
                        ]))
            }
        }
        generatedPlain.append(contentsOf: generatedNameTexts)
        outputPlain.children = generatedPlain

        if let sourceElements, let destinationElements = outputBoard.child(named: TextConstants.Eagle.tokenElements) {
            destinationElements.children = generatedElements
            _ = sourceElements
        }
        if let sourceSignals = board.child(named: TextConstants.Eagle.tokenSignals),
            let destinationSignals = outputBoard.child(named: TextConstants.Eagle.tokenSignals)
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
        guard
            let plain = source.child(named: TextConstants.Eagle.tokenDrawing)?.child(
                named: TextConstants.Eagle.tokenBoard)?.child(named: TextConstants.Eagle.tokenPlain)
        else {
            throw EaglePanelError.noBoard
        }
        let outline = plain.children.filter { $0.attributes[TextConstants.Common.tokenLayer] == dimensionLayer }
        let loops = try PanelRouting.closedLoops(outline.flatMap { try routingSegments($0) })
        let straightEdges = try outline.filter {
            $0.name == TextConstants.Eagle.tokenWire && abs($0.number(TextConstants.Eagle.tokenCurve) ?? 0) < 1e-8
        }.flatMap { try routingSegments($0) }
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
        for item in plain.children where item.attributes[TextConstants.Common.tokenLayer] == dimensionLayer {
            if item.name == TextConstants.Common.tokenCircle, let x = item.number(TextConstants.Eagle.letterLowerX),
                let y = item.number(TextConstants.Eagle.letterLowerY),
                let r = item.number(TextConstants.Common.tokenRadius)
            {
                points += [RoutePoint(x: x - r, y: y - r), RoutePoint(x: x + r, y: y + r)]
            }
            if item.name == TextConstants.Eagle.tokenWire, let x1 = item.number(TextConstants.Eagle.tokenX1),
                let y1 = item.number(TextConstants.Eagle.tokenY1), let x2 = item.number(TextConstants.Eagle.tokenX2),
                let y2 = item.number(TextConstants.Eagle.tokenY2),
                let curve = item.number(TextConstants.Eagle.tokenCurve), abs(curve) > 1e-8
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
                maxY: points.map(\.y).max()!), contours: loops, straightEdges: straightEdges)
        try PanelValidation.shape(result, field: TextConstants.Eagle.tokenEaglePanelEngineShapeOutput)
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
                TextConstants.Eagle.tokenEaglePanelEngineComposeSources,
                TextConstants.Eagle.textEAGLESourcesTemplate(PanelLimits.maxBoardPositions))
        }
        let shapes = try sources.map { try shape(data: $0.data) }
        let layout = try PanelCompositionLayout(bounds: shapes.map(\.bounds), options: options)
        var routingOptions = options
        routingOptions.tabsTop = options.tabsBottom; routingOptions.tabsBottom = options.tabsTop
        let routing = try PanelRouting.plan(
            boards: layout.placedContours(shapes), arrayBounds: layout.arrayBounds, options: routingOptions,
            straightEdges: layout.placedStraightEdges(shapes))
        // EN: The existing one-board export freezes visible NAME/VALUE labels before component identifiers and
        //     library names are namespaced for the panel.
        // JA: 既存の単一基板出力で表示用NAME/VALUEラベルを固定してから、パネル用に部品識別子とライブラリ名へ名前空間を付ける。
        // DE: Der bestehende Export einer einzelnen Platine fixiert sichtbare NAME/VALUE-Beschriftungen, bevor
        //     Bauteilkennungen und Bibliotheksnamen für das Panel mit Namensräumen versehen werden.
        // EN: Copy source objects without adding the app's default frame, tabs or mounting holes at this intermediate stage.
        // JA: 中間コピーではアプリの初期設定の外枠・タブ・取付穴を付けず、元の基板要素だけを複製する。
        // DE: Beim Zwischenkopieren keine Standardrahmen, Stege oder Befestigungsbohrungen der App ergänzen.
        var sourceCopyOptions = PanelOptions(columns: 1, rows: 1)
        sourceCopyOptions.horizontalFrameMM = 0; sourceCopyOptions.verticalFrameMM = 0
        sourceCopyOptions.frameGapMM = 0; sourceCopyOptions.columnGapMM = 0; sourceCopyOptions.rowGapMM = 0
        sourceCopyOptions.addTabs = false; sourceCopyOptions.addMountingHoles = false
        let roots = try sources.map { source -> EagleXMLNode in
            let prepared = try panelize(data: source.data, options: sourceCopyOptions)
            return try EagleXMLParser.parse(prepared.0)
        }
        guard let output = roots.first?.deepCopy(), let drawing = output.child(named: TextConstants.Eagle.tokenDrawing),
            let board = drawing.child(named: TextConstants.Eagle.tokenBoard)
        else { throw EaglePanelError.noBoard }
        let sourceBoards = try roots.map { root -> EagleXMLNode in
            guard
                let board = root.child(named: TextConstants.Eagle.tokenDrawing)?.child(
                    named: TextConstants.Eagle.tokenBoard)
            else { throw EaglePanelError.noBoard }
            return board
        }
        let stacks = sourceBoards.map { source in
            source.child(named: TextConstants.Eagle.tokenDesignrules)?.children.first {
                $0.name == TextConstants.Eagle.tokenParam
                    && $0.attributes[TextConstants.Common.tokenName] == TextConstants.Eagle.tokenLayerSetup
            }?.attributes[TextConstants.Common.tokenValue] ?? TextConstants.Eagle.defaultTwoLayerStackSetup
        }
        guard Set(stacks).count == 1 else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Eagle.boardsInOneEAGLEPanelMustUseTheSameEnglish,
                    TextConstants.Eagle.boardsInOneEAGLEPanelMustUseTheSameJapanese,
                    TextConstants.Eagle.boardsInOneEAGLEPanelMustUseTheSameGerman))
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
        let plain = section(TextConstants.Eagle.tokenPlain), libraries = section(TextConstants.Eagle.tokenLibraries),
            elements = section(TextConstants.Eagle.tokenElements),
            signals = section(TextConstants.Eagle.tokenSignals), classes = section(TextConstants.Eagle.tokenClasses)
        let layers =
            drawing.child(named: TextConstants.Common.tokenLayers)
            ?? EagleXMLNode(name: TextConstants.Common.tokenLayers)
        if drawing.child(named: TextConstants.Common.tokenLayers) == nil { drawing.children.insert(layers, at: 0) }
        layers.children = []
        var usedLayers: [String: String] = [:]
        var usedNumbers = Set(
            roots.flatMap {
                $0.child(named: TextConstants.Eagle.tokenDrawing)?.child(named: TextConstants.Common.tokenLayers)?
                    .children.compactMap { $0.attributes[TextConstants.Eagle.tokenNumber] }
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
            for key in [
                TextConstants.Eagle.letterLowerX, TextConstants.Eagle.tokenX1, TextConstants.Eagle.tokenX2,
                TextConstants.Eagle.tokenX3,
            ] {
                if let value = node.number(key) { node.attributes[key] = numberString(value + offset.x) }
            }
            for key in [
                TextConstants.Eagle.letterLowerY, TextConstants.Eagle.tokenY1, TextConstants.Eagle.tokenY2,
                TextConstants.Eagle.tokenY3,
            ] {
                if let value = node.number(key) { node.attributes[key] = numberString(value + offset.y) }
            }
            if let layer = node.attributes[TextConstants.Common.tokenLayer], let replacement = layers[layer] {
                node.attributes[TextConstants.Common.tokenLayer] = replacement
            }
            if [TextConstants.Eagle.tokenElement, TextConstants.Eagle.tokenSignal].contains(node.name),
                let name = node.attributes[TextConstants.Common.tokenName]
            {
                node.attributes[TextConstants.Common.tokenName] = prefix + name
            }
            if node.name == TextConstants.Eagle.tokenContactref,
                let name = node.attributes[TextConstants.Eagle.tokenElement]
            {
                node.attributes[TextConstants.Eagle.tokenElement] = prefix + name
            }
            for child in node.children { move(child, by: offset, prefix: prefix, layers: layers) }
        }
        var copiedLibraries = Set<Int>()
        for (instance, placement) in layout.placements.enumerated() {
            let index = placement.sourceIndex, source = sourceBoards[index],
                prefix = TextConstants.Eagle.tokenBTemplate(instance + 1)
            let libraryPrefix = TextConstants.Eagle.tokenBTemplate(index + 1)
            var layerMap: [String: String] = [:]
            for layer in roots[index].child(named: TextConstants.Eagle.tokenDrawing)?.child(
                named: TextConstants.Common.tokenLayers)?.children ?? []
            {
                guard let old = layer.attributes[TextConstants.Eagle.tokenNumber] else { continue }
                var number = old
                if let oldName = usedLayers[old], oldName != layer.attributes[TextConstants.Common.tokenName],
                    (Int(old) ?? 0) >= 100
                {
                    guard let free = (100...255).first(where: { !usedNumbers.contains(String($0)) }) else {
                        throw RoutingError.invalid(
                            L10n.text(
                                TextConstants.Eagle.theEAGLEPanelHasTooManyCustomLayersEnglish,
                                TextConstants.Eagle.theEAGLEPanelHasTooManyCustomLayersJapanese,
                                TextConstants.Eagle.theEAGLEPanelHasTooManyCustomLayersGerman))
                    }
                    number = String(free); usedNumbers.insert(number)
                }
                layerMap[old] = number
                if usedLayers[number] == nil {
                    let copy = layer.deepCopy(); copy.attributes[TextConstants.Eagle.tokenNumber] = number
                    layers.children.append(copy);
                    usedLayers[number] = layer.attributes[TextConstants.Common.tokenName] ?? number
                }
            }
            for library
                in (copiedLibraries.insert(index).inserted
                ? source.child(named: TextConstants.Eagle.tokenLibraries)?.children ?? [] : [])
            {
                let copy = library.deepCopy()
                if let name = copy.attributes[TextConstants.Common.tokenName] {
                    copy.attributes[TextConstants.Common.tokenName] = libraryPrefix + name
                }
                /// EN: Rewrite layer references, including descendants, according to the validated layer map.
                ///
                /// JA: 検証済みのレイヤー対応表に従って、子要素を含むレイヤー参照を書き換える。
                ///
                /// DE: Lagenverweise einschließlich untergeordneter Elemente gemäß der geprüften Lagenzuordnung
                ///     umschreiben.
                func remapLayers(_ node: EagleXMLNode) {
                    if let old = node.attributes[TextConstants.Common.tokenLayer], let new = layerMap[old] {
                        node.attributes[TextConstants.Common.tokenLayer] = new
                    }
                    for child in node.children { remapLayers(child) }
                }
                remapLayers(copy); libraries.children.append(copy)
            }
            var classMap: [String: String] = [:]
            let sourceClasses =
                source.child(named: TextConstants.Eagle.tokenClasses)?.children.filter {
                    $0.name == TextConstants.Eagle.tokenClass
                } ?? []
            let classSignature = sourceClasses.map { EagleXMLWriter.serialize($0).base64EncodedString() }.joined(
                separator: TextConstants.Common.semicolon)
            if let existing = classSets[classSignature] {
                classMap = existing
            } else {
                for entry in sourceClasses {
                    guard let number = entry.attributes[TextConstants.Eagle.tokenNumber] else { continue }
                    guard nextClass < 16 else {
                        throw RoutingError.invalid(
                            L10n.text(
                                TextConstants.Eagle.thisPanelExceedsEAGLENetClassesReduceTheNumberEnglish,
                                TextConstants.Eagle.thisPanelExceedsEAGLENetClassesReduceTheNumberJapanese,
                                TextConstants.Eagle.thisPanelExceedsEAGLENetClassesReduceTheNumberGerman
                            ))
                    }
                    classMap[number] = String(nextClass); nextClass += 1
                }
                for entry in sourceClasses {
                    let copy = entry.deepCopy()
                    copy.attributes[TextConstants.Eagle.tokenNumber] =
                        classMap[entry.attributes[TextConstants.Eagle.tokenNumber] ?? TextConstants.Common.number0]
                    copy.attributes[TextConstants.Common.tokenName] =
                        prefix + (entry.attributes[TextConstants.Common.tokenName] ?? TextConstants.Common.tokenDefault)
                    for clearance in copy.children {
                        if let value = clearance.attributes[TextConstants.Eagle.tokenClass] {
                            clearance.attributes[TextConstants.Eagle.tokenClass] = classMap[value] ?? value
                        }
                    }
                    classes.children.append(copy)
                }
                classSets[classSignature] = classMap
            }
            for item in source.child(named: TextConstants.Eagle.tokenPlain)?.children ?? []
            where item.attributes[TextConstants.Common.tokenLayer] != dimensionLayer {
                let copy = item.deepCopy(); move(copy, by: placement.offset, prefix: prefix, layers: layerMap);
                plain.children.append(copy)
            }
            for item in source.child(named: TextConstants.Eagle.tokenElements)?.children ?? [] {
                let copy = item.deepCopy()
                if let name = copy.attributes[TextConstants.Eagle.tokenLibrary] {
                    copy.attributes[TextConstants.Eagle.tokenLibrary] = libraryPrefix + name
                }
                move(copy, by: placement.offset, prefix: prefix, layers: layerMap); elements.children.append(copy)
            }
            for item in source.child(named: TextConstants.Eagle.tokenSignals)?.children ?? [] {
                let copy = item.deepCopy()
                copy.attributes[TextConstants.Eagle.tokenClass] =
                    classMap[copy.attributes[TextConstants.Eagle.tokenClass] ?? TextConstants.Common.number0]
                    ?? TextConstants.Common.number0
                move(copy, by: placement.offset, prefix: prefix, layers: layerMap); signals.children.append(copy)
            }
        }
        if !layers.children.contains(where: { $0.attributes[TextConstants.Eagle.tokenNumber] == vScoreLayer })
            && options.addVScoreSeparators
        {
            layers.children.append(
                EagleXMLNode(
                    name: TextConstants.Common.tokenLayer,
                    attributes: [
                        TextConstants.Eagle.tokenNumber: vScoreLayer,
                        TextConstants.Common.tokenName: TextConstants.Eagle.tokenVscore,
                        TextConstants.Eagle.tokenColor: TextConstants.Eagle.number7,
                        TextConstants.Common.tokenFill: TextConstants.Common.number1,
                        TextConstants.Eagle.tokenVisible: TextConstants.Common.tokenYes,
                        TextConstants.Eagle.tokenActive: TextConstants.Common.tokenYes,
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
                name: TextConstants.Eagle.tokenHole,
                attributes: [
                    TextConstants.Eagle.letterLowerX: numberString($0.0.x),
                    TextConstants.Eagle.letterLowerY: numberString($0.0.y),
                    TextConstants.Common.tokenDrill: numberString($0.1),
                ])
        }
        board.children.removeAll {
            [TextConstants.Eagle.tokenErrors, TextConstants.Eagle.tokenMfgpreviewcolors].contains($0.name)
        }
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
        if node.name == TextConstants.Eagle.tokenWire, let x1 = node.number(TextConstants.Eagle.tokenX1),
            let y1 = node.number(TextConstants.Eagle.tokenY1), let x2 = node.number(TextConstants.Eagle.tokenX2),
            let y2 = node.number(TextConstants.Eagle.tokenY2)
        {
            let a = RoutePoint(x: x1, y: y1), b = RoutePoint(x: x2, y: y2)
            let theta = (node.number(TextConstants.Eagle.tokenCurve) ?? 0) * .pi / 180
            if abs(theta) < 1e-8 || (b - a).length < 1e-8 { return [RouteSegment(a: a, b: b)] }
            let delta = b - a, mid = (a + b) * 0.5
            let center = mid + RoutePoint(x: -delta.y, y: delta.x) * (1 / (2 * tan(theta / 2)))
            var points = try PanelRouting.arc(center: center, start: a, sweep: theta)
            points[points.count - 1] = b
            return chain(points)
        }
        if node.name == TextConstants.Common.tokenCircle, let x = node.number(TextConstants.Eagle.letterLowerX),
            let y = node.number(TextConstants.Eagle.letterLowerY),
            let radius = node.number(TextConstants.Common.tokenRadius)
        {
            return chain(
                try PanelRouting.arc(
                    center: RoutePoint(x: x, y: y), start: RoutePoint(x: x + radius, y: y), sweep: 2 * .pi))
        }
        throw RoutingError.invalid(
            L10n.text(
                TextConstants.Eagle.useWiresOrCirclesForTheEAGLEOutlineWhenEnglish,
                TextConstants.Eagle.useWiresOrCirclesForTheEAGLEOutlineWhenJapanese,
                TextConstants.Eagle.useWiresOrCirclesForTheEAGLEOutlineWhenGerman))
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
        let x = element.number(TextConstants.Eagle.letterLowerX) ?? 0
        let y = element.number(TextConstants.Eagle.letterLowerY) ?? 0
        var rotation = element.rotationDegrees
        if element.attributes[TextConstants.Eagle.tokenRot]?.contains(TextConstants.Eagle.letterUpperM) == true {
            rotation = -rotation
        }
        let localX = packageText.number(TextConstants.Eagle.letterLowerX) ?? 0
        let localY = packageText.number(TextConstants.Eagle.letterLowerY) ?? 0
        let angle = rotation * .pi / 180
        let rotatedX = localX * cos(angle) - localY * sin(angle)
        let rotatedY = localX * sin(angle) + localY * cos(angle)
        label.attributes[TextConstants.Eagle.letterLowerX] = numberString(x + rotatedX)
        label.attributes[TextConstants.Eagle.letterLowerY] = numberString(y + rotatedY)
        label.text = fallbackName
        if let rot = element.attributes[TextConstants.Eagle.tokenRot] {
            label.attributes[TextConstants.Eagle.tokenRot] = rot
        }
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
        let suffix = TextConstants.Eagle.gridCopySuffixTemplate(column, row)
        if [TextConstants.Eagle.tokenElement, TextConstants.Eagle.tokenSignal].contains(copy.name),
            let value = copy.attributes[TextConstants.Common.tokenName]
        {
            copy.attributes[TextConstants.Common.tokenName] = value + suffix
        }
        if copy.name == TextConstants.Eagle.tokenContactref,
            let value = copy.attributes[TextConstants.Eagle.tokenElement]
        {
            copy.attributes[TextConstants.Eagle.tokenElement] = value + suffix
        }
        for key in [TextConstants.Eagle.letterLowerX, TextConstants.Eagle.tokenX1, TextConstants.Eagle.tokenX2] {
            if let value = copy.number(key) {
                copy.attributes[key] = numberString(value + Double(column) * columnOffset)
            }
        }
        for key in [TextConstants.Eagle.letterLowerY, TextConstants.Eagle.tokenY1, TextConstants.Eagle.tokenY2] {
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
            name: TextConstants.Eagle.tokenWire,
            attributes: [
                TextConstants.Eagle.tokenX1: numberString(x1), TextConstants.Eagle.tokenY1: numberString(y1),
                TextConstants.Eagle.tokenX2: numberString(x2), TextConstants.Eagle.tokenY2: numberString(y2),
                TextConstants.Common.tokenWidth: numberString(width), TextConstants.Common.tokenLayer: layer,
            ])
    }

    /// EN: Serialize validated EAGLE numbers as plain decimals with at most ten fractional digits.
    ///     KiCad's EAGLE importer can treat the mantissa of exponent notation as a coordinate: a near-zero
    ///     value such as 1.33226763E-15 then becomes 1.332267 mm. Remove trailing zeros and normalize -0.
    ///
    /// JA: 検証済みのEAGLE数値を、小数部が最大10桁の通常の小数で出力する。
    ///     KiCadのEAGLE取り込みでは指数表記の仮数が座標と解釈され、ほぼ0の1.33226763E-15が
    ///     1.332267 mmへずれる場合がある。末尾の0を除き、-0も0へ正規化する。
    ///
    /// DE: Geprüfte EAGLE-Zahlen als Dezimalwerte mit höchstens zehn Nachkommastellen serialisieren.
    ///     KiCads EAGLE-Importer kann die Mantisse einer Exponentialzahl als Koordinate lesen: Aus dem fast
    ///     nullwertigen 1.33226763E-15 werden dann 1,332267 mm. Endnullen entfernen und -0 normalisieren.
    private static func numberString(_ value: Double) -> String {
        var result = String(
            format: TextConstants.Eagle.eagleDecimalFormat,
            locale: Locale(identifier: TextConstants.Common.posixLocaleIdentifier), value)
        while result.last == TextConstants.Characters.number0 {
            result.removeLast()
        }
        if result.last == TextConstants.Characters.period {
            result.removeLast()
        }
        return result == TextConstants.Eagle.numberMinus0 ? TextConstants.Common.number0 : result
    }
}

private final class EagleXMLNode {
    let name: String
    var attributes: [String: String]
    var text: String
    var children: [EagleXMLNode]
    weak var parent: EagleXMLNode?

    init(
        name: String, attributes: [String: String] = [:], text: String = TextConstants.Common.empty,
        children: [EagleXMLNode] = []
    ) {
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
        guard let rotation = attributes[TextConstants.Eagle.tokenRot] else { return 0 }
        let value = rotation.drop(while: {
            !$0.isNumber && $0 != TextConstants.Characters.hyphen && $0 != TextConstants.Characters.period
        })
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
        try PanelValidation.document(data, field: TextConstants.Eagle.tokenEagleXMLParserInput)
        let delegate = EagleXMLParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldResolveExternalEntities = false
        guard parser.parse(), let root = delegate.root else {
            if let failure = delegate.failure { throw failure }
            throw EaglePanelError.malformedXML(
                parser.parserError?.localizedDescription
                    ?? L10n.text(
                        TextConstants.Eagle.unknownXMLErrorEnglish, TextConstants.Eagle.unknownXMLErrorJapanese,
                        TextConstants.Eagle.unknownXMLErrorGerman))
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
            failure = PanelValidation.invalid(
                TextConstants.Eagle.tokenEagleXMLParserDepthNodes, TextConstants.Eagle.textWithinParserLimits)
            parser.abortParsing()
            return
        }
        // EN: EAGLE XML attributes are strings; also check that they can be converted to Double.
        // JA: EAGLEのXML属性は文字列なので、Doubleへ変換できることも確認する。
        // DE: EAGLE-XML-Attribute sind Zeichenketten; zusätzlich ihre Konvertierbarkeit zu Double prüfen.
        do {
            for (key, value) in attributeDict {
                if [
                    TextConstants.Eagle.letterLowerX, TextConstants.Eagle.tokenX1, TextConstants.Eagle.tokenX2,
                    TextConstants.Eagle.letterLowerY, TextConstants.Eagle.tokenY1, TextConstants.Eagle.tokenY2,
                ].contains(key) {
                    guard let coordinate = Double(value) else {
                        throw PanelValidation.invalid(
                            TextConstants.Eagle.tokenEAGLE + elementName + TextConstants.Eagle.period + key,
                            TextConstants.Eagle.textNumericCoordinate)
                    }
                    try PanelValidation.number(
                        coordinate, field: TextConstants.Eagle.tokenEAGLE + key + TextConstants.Common.tokenMM,
                        range: -PanelLimits.maxCoordinateMM...PanelLimits.maxCoordinateMM)
                }
                if [
                    TextConstants.Common.tokenWidth, TextConstants.Common.tokenHeight, TextConstants.Common.tokenRadius,
                    TextConstants.Common.tokenDrill, TextConstants.Eagle.tokenDx, TextConstants.Eagle.tokenDy,
                    TextConstants.Common.tokenSize,
                ].contains(key) {
                    guard let measurement = Double(value) else {
                        throw PanelValidation.invalid(
                            TextConstants.Eagle.tokenEAGLE + elementName + TextConstants.Eagle.period + key,
                            TextConstants.Common.textNumericMeasurement)
                    }
                    try PanelValidation.number(
                        measurement, field: TextConstants.Eagle.tokenEAGLE + key + TextConstants.Common.tokenMM,
                        range: 0...PanelLimits.maxMeasurementMM)
                }
                if key == TextConstants.Eagle.tokenRot {
                    let angleText = value.drop(while: {
                        $0 == TextConstants.Characters.letterUpperS || $0 == TextConstants.Characters.letterUpperM
                            || $0 == TextConstants.Characters.letterUpperR
                    })
                    guard let angle = Double(angleText) else {
                        throw PanelValidation.invalid(
                            TextConstants.Eagle.tokenEAGLERot, TextConstants.Eagle.textRotationInDegrees)
                    }
                    try PanelValidation.number(
                        angle, field: TextConstants.Eagle.tokenEAGLERotDegrees,
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
        var output = TextConstants.Eagle.markupXmlVersionEncodingUTFDOCTYPEEagleSYSTEM
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
        let indent = String(repeating: TextConstants.Eagle.indentationUnit, count: depth)
        output += indent + TextConstants.Eagle.openingAngle + node.name
        for key in node.attributes.keys.sorted() {
            output += TextConstants.Eagle.xmlAttributeTemplate(
                key, escape(node.attributes[key] ?? TextConstants.Common.empty, attribute: true))
        }
        if node.children.isEmpty && node.text.isEmpty {
            output += TextConstants.Eagle.xmlSelfClosingElementEnding
            return
        }
        output += TextConstants.Eagle.closingAngle
        if node.children.isEmpty {
            output += escape(node.text, attribute: false) + TextConstants.Eagle.markupTemplate(node.name)
        } else {
            if !node.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                output += escape(node.text, attribute: false)
            }
            output += TextConstants.Common.newline
            for child in node.children { write(child, depth: depth + 1, into: &output) }
            output += indent + TextConstants.Eagle.markupTemplate(node.name)
        }
    }

    /// EN: Return text or attribute values with reserved XML characters escaped.
    ///
    /// JA: テキストまたは属性値のXML予約文字をエスケープした文字列を返す。
    ///
    /// DE: Text oder Attributwerte mit maskierten reservierten XML-Zeichen zurückgeben.
    private static func escape(_ value: String, attribute: Bool) -> String {
        var escaped = value.replacingOccurrences(
            of: TextConstants.Eagle.ampersand, with: TextConstants.Eagle.tokenAmp
        )
        .replacingOccurrences(of: TextConstants.Eagle.openingAngle, with: TextConstants.Eagle.tokenLt)
        .replacingOccurrences(of: TextConstants.Eagle.closingAngle, with: TextConstants.Eagle.tokenGt)
        if attribute {
            escaped = escaped.replacingOccurrences(
                of: TextConstants.Common.doubleQuote, with: TextConstants.Eagle.tokenQuot)
        }
        return escaped
    }
}
