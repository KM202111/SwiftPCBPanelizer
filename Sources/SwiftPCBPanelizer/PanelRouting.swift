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

// EN: String/character literals are defined in TextConstants.Routing, Common and Characters; variable text uses constant templates.
// JA: 文字列・文字リテラルはTextConstants.Routing・Common・Charactersに定義し、可変文は定数テンプレートから生成する。
// DE: Zeichenketten-/Zeichenliterale stehen in TextConstants.Routing, Common und Characters; variable Texte nutzen konstante Vorlagen.

struct RoutePoint: Equatable {
    var x: Double
    var y: Double
    /// EN: Arithmetic on validated 2D values. Check intermediate ranges at placement, arc and routing boundaries.
    ///
    /// JA: 検証済みの2次元値の演算。中間結果は配置・円弧・加工線の境界で範囲確認する。
    ///
    /// DE: Mit geprüften 2D-Werten rechnen. Wertebereiche der Zwischenergebnisse an Platzierungs-, Kreisbogen- und
    ///     Fräsgrenzen prüfen.
    static func + (a: Self, b: Self) -> Self { Self(x: a.x + b.x, y: a.y + b.y) }
    /// EN: Arithmetic on validated 2D values. Check intermediate ranges at placement, arc and routing boundaries.
    ///
    /// JA: 検証済みの2次元値の演算。中間結果は配置・円弧・加工線の境界で範囲確認する。
    ///
    /// DE: Mit geprüften 2D-Werten rechnen. Wertebereiche der Zwischenergebnisse an Platzierungs-, Kreisbogen- und
    ///     Fräsgrenzen prüfen.
    static func - (a: Self, b: Self) -> Self { Self(x: a.x - b.x, y: a.y - b.y) }
    /// EN: Arithmetic on validated 2D values. Check intermediate ranges at placement, arc and routing boundaries.
    ///
    /// JA: 検証済みの2次元値の演算。中間結果は配置・円弧・加工線の境界で範囲確認する。
    ///
    /// DE: Mit geprüften 2D-Werten rechnen. Wertebereiche der Zwischenergebnisse an Platzierungs-, Kreisbogen- und
    ///     Fräsgrenzen prüfen.
    static func * (a: Self, b: Double) -> Self { Self(x: a.x * b, y: a.y * b) }
    var length: Double { hypot(x, y) }
}

struct RouteSegment {
    var a: RoutePoint
    var b: RoutePoint
}

struct RoutingPlan {
    var segments: [RouteSegment]
    var mouseBites: [RoutePoint]
}

struct RouteRect {
    var minX: Double; var minY: Double; var maxX: Double; var maxY: Double
    var points: [RoutePoint] {
        [
            RoutePoint(x: minX, y: minY), RoutePoint(x: maxX, y: minY), RoutePoint(x: maxX, y: maxY),
            RoutePoint(x: minX, y: maxY),
        ]
    }
    /// EN: Return whether a point lies strictly inside the rectangle. Exclude edges when classifying routing
    ///     segments.
    ///
    /// JA: 矩形の内部にあるか返す。境界は含めず、加工線の内外判定に使用する。
    ///
    /// DE: Prüfen, ob ein Punkt strikt innerhalb des Rechtecks liegt. Die Ränder bei der Klassifizierung von
    ///     Frässegmenten ausschließen.
    func contains(_ p: RoutePoint) -> Bool { p.x > minX && p.x < maxX && p.y > minY && p.y < maxY }
}

enum RoutingError: LocalizedError {
    case invalid(String)
    var errorDescription: String? { if case .invalid(let message) = self { return message }; return nil }
}

/// EN: Separate computational safety limits by quantity. They do not describe manufacturing capability. Do not
///     compare coordinates, dimensions and counts with different units against one shared threshold.
///
/// JA: 項目ごとに分離した計算上の安全上限。製造業者の加工能力を表す値ではない。 単位の異なる座標・寸法・個数を、同じ閾値で比較しないこと。
///
/// DE: Rechnerische Sicherheitsgrenzen nach Größe trennen. Sie beschreiben keine Fertigungsmöglichkeiten.
///     Koordinaten, Abmessungen und Anzahlen mit unterschiedlichen Einheiten nicht mit derselben Grenze vergleichen.
enum PanelLimits {
    /// EN: Total placements [boards]. Prevent multiplication overflow and excessively large arrays.
    ///
    /// JA: 配置先の総数 [枚]。積のオーバーフローと過大な配列生成を防ぐ。
    ///
    /// DE: Gesamte Platzierungsanzahl [Platinen]. Überläufe bei der Multiplikation und übermäßig große Arrays
    ///     verhindern.
    static let maxBoardPositions = 10_000
    /// EN: Absolute limit for signed coordinates [mm], supporting inputs with different origins.
    ///
    /// JA: 正負を許す座標の絶対値 [mm]。原点の異なる入力にも対応する。
    ///
    /// DE: Absolutgrenze vorzeichenbehafteter Koordinaten [mm], auch für Eingaben mit unterschiedlichen Ursprüngen.
    static let maxCoordinateMM = 1_000_000.0
    /// EN: Upper limit for lengths, clearances and diameters [mm], managed separately from coordinates.
    ///
    /// JA: 長さ・間隔・直径の上限 [mm]。座標とは別項目として管理する。
    ///
    /// DE: Obergrenze für Längen, Abstände und Durchmesser [mm], getrennt von Koordinaten verwaltet.
    static let maxMeasurementMM = 1_000_000.0
    /// EN: Minimum tab width supported by stable contour composition [mm], not a manufacturing guarantee.
    ///
    /// JA: 輪郭合成で安定して扱う最小ステグ幅 [mm]。加工可能幅の保証ではない。
    ///
    /// DE: Für stabile Konturvereinigung unterstützte Mindeststegbreite [mm], keine Fertigungsgarantie.
    static let minTabWidthMM = 0.001
    /// EN: Number of tabs per side [tabs].
    ///
    /// JA: 1辺当たりのステグ数 [個]。
    ///
    /// DE: Anzahl der Stege pro Seite [Stege].
    static let maxTabsPerEdge = 1_000
    /// EN: Subdivision count for one perforation row [intervals].
    ///
    /// JA: 1本のミシン目列の分割数 [区間]。
    ///
    /// DE: Unterteilungsanzahl einer Perforationsreihe [Intervalle].
    static let maxPerforationIntervals = 10_000
    /// EN: Maximum generated perforation holes across the panel [holes].
    ///
    /// JA: パネル全体に生成するミシン目穴の上限 [穴]。
    ///
    /// DE: Maximale Anzahl erzeugter Perforationsbohrungen im gesamten Panel [Bohrungen].
    static let maxGeneratedHoles = 200_000
    /// EN: Maximum segments used to approximate one arc [segments].
    ///
    /// JA: 1本の円弧を近似する線分数の上限 [本]。
    ///
    /// DE: Maximale Segmentanzahl zur Annäherung eines Kreisbogens [Segmente].
    static let maxArcSegments = 100_000
    /// EN: XML/S-expression recursion depth [levels], limiting stack consumption.
    ///
    /// JA: XML / S式の再帰深度 [階層]。スタック消費を制限する。
    ///
    /// DE: Rekursionstiefe von XML/S-Ausdrücken [Ebenen] zur Begrenzung des Stackverbrauchs.
    static let maxParserDepth = 256
    /// EN: Input/output data size per file [bytes].
    ///
    /// JA: 1ファイルの入力・出力データ量 [byte]。
    ///
    /// DE: Ein-/Ausgabedatenmenge pro Datei [Bytes].
    static let maxDocumentBytes = 512 * 1024 * 1024
    /// EN: Number of syntax elements created by the parser [items].
    ///
    /// JA: パーサーが生成する構文要素数 [個]。
    ///
    /// DE: Anzahl der vom Parser erzeugten Syntaxelemente [Elemente].
    static let maxSyntaxNodes = 2_000_000
    /// EN: Number of holes drawn in finished previews, including original board holes [holes].
    ///
    /// JA: 元基板の穴を含め、完成プレビューが描画する穴数 [穴]。
    ///
    /// DE: Anzahl der in der fertigen Vorschau gezeichneten Bohrungen einschließlich der Originalbohrungen
    ///     [Bohrungen].
    static let maxPreviewHoles = 400_000
    /// EN: Target PNG sampling density [pixels/inch]; lower it only when pixel limits require scaling.
    /// JA: PNGの目標画素密度 [pixel/inch]。画素上限を超える場合だけ縮小する。
    /// DE: Zielauflösung für PNG [Pixel/Zoll]; nur bei Überschreitung der Pixelgrenzen verringern.
    static let artworkPNGDPI = 300.0
    /// EN: Maximum width or height of an exported PNG [pixels].
    /// JA: PNG出力の幅または高さの上限 [pixel]。
    /// DE: Maximale Breite oder Höhe eines PNG-Exports [Pixel].
    static let maxArtworkPNGSidePixels = 8_192
    /// EN: Maximum total image pixels, bounding a single RGBA canvas to 64 MiB before encoding.
    /// JA: 画像全体の画素数上限。符号化前のRGBA Canvasを1枚当たり64 MiB以内に抑える。
    /// DE: Maximale Gesamtpixelzahl; begrenzt eine RGBA-Zeichenfläche vor der Kodierung auf 64 MiB.
    static let maxArtworkPNGPixelCount = 16_777_216
    /// EN: Maximum wait for SVG image loading during PNG conversion [milliseconds].
    /// JA: PNG変換でSVG画像の読み込みを待つ時間の上限 [ms]。
    /// DE: Maximale Wartezeit beim Laden des SVG-Bildes für die PNG-Konvertierung [Millisekunden].
    static let artworkPNGTimeoutMilliseconds = 30_000
    /// EN: Absolute rotation limit [degrees]. Allow multiple turns while avoiding trigonometry on enormous values.
    ///
    /// JA: 回転角の絶対値 [度]。複数回転の入力は許すが、巨大値の三角関数を避ける。
    ///
    /// DE: Absolutgrenze des Drehwinkels [Grad]. Mehrere Umdrehungen zulassen und trigonometrische Berechnungen mit
    ///     extremen Werten vermeiden.
    static let maxRotationDegrees = 36_000.0
    /// EN: Rounding tolerance for comparing outlines with calculated dimensions [mm].
    ///
    /// JA: 外形と計算寸法を比較するときの丸め誤差許容値 [mm]。
    ///
    /// DE: Rundungstoleranz beim Vergleich von Konturen und berechneten Abmessungen [mm].
    static let boundsToleranceMM = 0.01
    /// EN: Absolute tolerance for duplicate/collinear outline points during rectangle classification [mm].
    /// JA: 長方形判定で輪郭の重複点・同一直線上の点を整理する絶対許容差 [mm]。
    /// DE: Absolute Toleranz für doppelte/kollineare Konturpunkte bei der Rechteckprüfung [mm].
    static let rectangularOutlineToleranceMM = 0.00001
    /// EN: Dimensionless cosine tolerance for the four right angles of a rectangular outline.
    /// JA: 長方形外形の4つの直角を判定する、余弦の無次元許容差。
    /// DE: Dimensionslose Kosinustoleranz für die vier rechten Winkel einer rechteckigen Kontur.
    static let rectangularOutlineAngleTolerance = 0.000001
}

/// EN: Validate contracts at function boundaries. Throw invalid values to the caller instead of hiding them through
///     correction.
///
/// JA: 関数境界の契約を検証する。異常値は補正して隠さず、呼び出し元へ投げる。
///
/// DE: Verträge an Funktionsgrenzen prüfen. Ungültige Werte als Fehler an den Aufrufer melden, statt sie durch
///     Korrekturen zu verbergen.
enum PanelValidation {
    /// EN: Pass function/variable names as field so errors identify where an invalid value originated.
    ///
    /// JA: fieldには関数名・変数名を渡し、エラーから不正値の発生箇所を追えるようにする。
    ///
    /// DE: Funktions- und Variablennamen als field übergeben, damit Fehler den Ursprung eines ungültigen Wertes
    ///     benennen.
    static func invalid(_ field: String, _ expected: String) -> RoutingError {
        return .invalid(
            L10n.text(
                TextConstants.Routing.invalidValueInFieldExpectedExpectedEnglishTemplate(field, expected),
                TextConstants.Routing.invalidValueInFieldExpectedExpectedJapaneseTemplate(field, expected),
                TextConstants.Routing.invalidValueInFieldExpectedExpectedGermanTemplate(field, expected)))
    }

    /// EN: Check that a number lies in the specified closed interval, including rejection of NaN and infinity.
    ///
    /// JA: NaN・無限大を含め、数値が指定された閉区間内にあるか確認する。
    ///
    /// DE: Prüfen, ob eine Zahl im angegebenen abgeschlossenen Intervall liegt; NaN und Unendlich ablehnen.
    static func number(_ value: Double, field: String, range: ClosedRange<Double>) throws {
        guard value.isFinite && range.contains(value) else {
            throw invalid(
                field, TextConstants.Routing.closedRangeDescriptionTemplate(range.lowerBound, range.upperBound))
        }
    }

    /// EN: Check file size before parsing or returning generated data.
    ///
    /// JA: ファイルをパースする前、または生成データを返す前にサイズを確認する。
    ///
    /// DE: Die Dateigröße vor dem Parsen oder der Rückgabe erzeugter Daten prüfen.
    static func document(_ data: Data, field: String) throws {
        guard !data.isEmpty && data.count <= PanelLimits.maxDocumentBytes else {
            throw invalid(field, TextConstants.Routing.textBytesTemplate(PanelLimits.maxDocumentBytes))
        }
    }

    /// EN: Validate both signed rectangle coordinates and positive width/height [mm].
    ///
    /// JA: 矩形の符号付き座標と、正の幅・高さ [mm] の両方を検証する。
    ///
    /// DE: Sowohl vorzeichenbehaftete Rechteckkoordinaten als auch positive Breite und Höhe [mm] prüfen.
    static func rectangle(_ rect: RouteRect, field: String) throws {
        try PanelRouting.validatePoints(rect.points)
        try number(
            rect.maxX - rect.minX, field: field + TextConstants.Routing.tokenWidthMM,
            range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
        try number(
            rect.maxY - rect.minY, field: field + TextConstants.Routing.tokenHeightMM,
            range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
    }

    /// EN: Validate returned outlines: every loop has at least three points and all points lie inside the bounding
    ///     rectangle.
    ///
    /// JA: 外形の戻り値を確認する。全ループが3点以上で、全点が外接矩形に収まること。
    ///
    /// DE: Zurückgegebene Konturen prüfen: Jede Schleife hat mindestens drei Punkte und alle Punkte liegen im
    ///     Begrenzungsrechteck.
    static func shape(_ shape: PanelBoardShape, field: String) throws {
        try rectangle(shape.bounds, field: field + TextConstants.Routing.tokenBounds)
        guard !shape.contours.isEmpty && shape.contours.allSatisfy({ $0.count >= 3 }) else {
            throw invalid(
                field + TextConstants.Routing.tokenContours, TextConstants.Routing.textClosedLoopsWithAtLeastPoints)
        }
        let points = shape.contours.flatMap { $0 }
        try PanelRouting.validatePoints(points)
        try PanelRouting.validatePoints(shape.straightEdges.flatMap { [$0.a, $0.b] })
        try validateContained(
            shape.straightEdges.flatMap { [$0.a, $0.b] }, in: shape.bounds,
            field: field + TextConstants.Routing.tokenStraightEdges)
        let b = shape.bounds
        let tolerance = PanelLimits.boundsToleranceMM
        guard
            points.allSatisfy({
                $0.x >= b.minX - tolerance && $0.x <= b.maxX + tolerance && $0.y >= b.minY - tolerance
                    && $0.y <= b.maxY + tolerance
            })
        else {
            throw invalid(field + TextConstants.Routing.tokenContours, TextConstants.Routing.textInsideOutlineBounds)
        }
    }

    /// EN: Check finite, positive output dimensions [mm] and row/column counts; ensure the panel contains the board
    ///     array.
    ///
    /// JA: 出力寸法 [mm] と行列数 [個] が有限・正で、パネルが基板配列を含むか確認する。
    ///
    /// DE: Endliche, positive Ausgabeabmessungen [mm] sowie Zeilen- und Spaltenanzahlen prüfen; sicherstellen, dass
    ///     das Panel die Platinenanordnung enthält.
    static func summary(_ value: PanelSummary) throws {
        for (name, measurement) in [
            (TextConstants.Routing.tokenBoardWidthMM, value.boardWidthMM),
            (TextConstants.Routing.tokenBoardHeightMM, value.boardHeightMM),
            (TextConstants.Routing.tokenPanelWidthMM, value.panelWidthMM),
            (TextConstants.Routing.tokenPanelHeightMM, value.panelHeightMM),
        ] {
            try number(
                measurement, field: TextConstants.Routing.tokenSummary + name,
                range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
        }
        guard value.columns > 0 && value.rows > 0 && value.columns <= PanelLimits.maxBoardPositions / value.rows else {
            throw invalid(
                TextConstants.Routing.tokenSummaryRowsColumns,
                TextConstants.Routing.textPositionsTemplate(PanelLimits.maxBoardPositions))
        }
        guard
            value.panelWidthMM + PanelLimits.boundsToleranceMM >= value.boardWidthMM
                && value.panelHeightMM + PanelLimits.boundsToleranceMM >= value.boardHeightMM
        else {
            throw invalid(TextConstants.Routing.tokenSummaryPanel, TextConstants.Routing.textContainsBoardArray)
        }
        try number(
            value.dimensionLineWidthMM, field: TextConstants.Routing.tokenSummaryDimensionLineWidthMM,
            range: 0...PanelLimits.maxMeasurementMM)
    }

    /// EN: Validate generated data and dimensions together and return the checked pair.
    ///
    /// JA: 生成したデータと寸法を同時に検査し、検証済みの組を返す。
    ///
    /// DE: Erzeugte Daten und Abmessungen gemeinsam prüfen und das geprüfte Paar zurückgeben.
    static func output(_ data: Data, summary value: PanelSummary, options: PanelOptions) throws -> (Data, PanelSummary)
    {
        try document(data, field: TextConstants.Routing.tokenExportOutputData)
        try summary(value)
        try mountingHoles(width: value.panelWidthMM, height: value.panelHeightMM, options: options)
        return (data, value)
    }

    /// EN: Check that each hole's full circumference, including its radius, stays within the panel.
    ///
    /// JA: 穴の中心だけでなく、半径を含む外周がパネル外へ出ないか検証する。
    ///
    /// DE: Prüfen, dass jede Bohrung einschließlich ihres Radius vollständig innerhalb des Panels liegt.
    static func mountingHoles(width: Double, height: Double, options: PanelOptions) throws {
        guard options.addMountingHoles else {
            return
        }
        let radius = options.mountingHoleDrillMM / 2
        let dx = options.mountingHoleOffsetXMM
        let dy = options.mountingHoleOffsetYMM
        guard
            radius > 0 && radius.isFinite && dx >= radius && dy >= radius && dx + radius <= width
                && dy + radius <= height
        else {
            throw invalid(
                TextConstants.Routing.tokenMountingHoleOffsetDiameter, TextConstants.Routing.textEntireHoleInsidePanel)
        }
    }

    /// EN: Validate returned holes, checking coordinates [mm], diameter/slot dimensions [mm] and rotation [degrees]
    ///     separately.
    ///
    /// JA: 穴の戻り値を検証する。座標 [mm]・直径/長穴寸法 [mm]・回転 [度] を別々に判定する。
    ///
    /// DE: Zurückgegebene Bohrungen prüfen; Koordinaten [mm], Durchmesser/Langlochabmessungen [mm] und Drehwinkel
    ///     [Grad] getrennt bewerten.
    static func drills(_ drills: [PanelPreviewDrill]) throws {
        guard drills.count <= PanelLimits.maxPreviewHoles else {
            throw invalid(
                TextConstants.Routing.tokenPreviewDrillsCount,
                TextConstants.Routing.nonnegativeCountRangeTemplate(PanelLimits.maxPreviewHoles))
        }
        for (index, drill) in drills.enumerated() {
            try PanelRouting.validatePoints([drill.center])
            try number(
                drill.width, field: TextConstants.Routing.tokenPreviewDrillsWidthMMTemplate(index),
                range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
            try number(
                drill.height, field: TextConstants.Routing.tokenPreviewDrillsHeightMMTemplate(index),
                range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
            try number(
                drill.angle, field: TextConstants.Routing.tokenPreviewDrillsAngleDegreesTemplate(index),
                range: -PanelLimits.maxRotationDegrees...PanelLimits.maxRotationDegrees)
        }
    }

    /// EN: Validate returned routing: check hole counts, coordinates and closed loops before display or export.
    ///
    /// JA: 加工線の戻り値を検証する。穴数・座標・閉ループを確認してから表示・出力する。
    ///
    /// DE: Zurückgegebene Fräsdaten prüfen: Bohrungsanzahl, Koordinaten und geschlossene Schleifen vor Anzeige oder
    ///     Export kontrollieren.
    static func routing(_ plan: RoutingPlan, inside bounds: RouteRect) throws {
        try rectangle(bounds, field: TextConstants.Routing.tokenRoutingPanelBounds)
        guard !plan.segments.isEmpty && plan.mouseBites.count <= PanelLimits.maxGeneratedHoles else {
            throw invalid(
                TextConstants.Routing.tokenRoutingSegmentsMouseBites,
                TextConstants.Routing.textNonemptyOutlineAndBoundedHoleCount)
        }
        let points = plan.segments.flatMap { [$0.a, $0.b] } + plan.mouseBites
        try validateContained(points, in: bounds, field: TextConstants.Routing.tokenRoutingPoints)
        _ = try PanelRouting.closedLoops(plan.segments)
    }

    /// EN: Compare intermediate coordinates with the bounding range, allowing only endpoint rounding tolerance.
    ///
    /// JA: 中間計算で生成した座標も外接範囲と比較する。端点の丸め誤差のみ許容する。
    ///
    /// DE: Zwischenkoordinaten mit dem Begrenzungsbereich vergleichen und nur Rundungstoleranzen an Endpunkten
    ///     zulassen.
    static func validateContained(_ points: [RoutePoint], in bounds: RouteRect, field: String) throws {
        try PanelRouting.validatePoints(points)
        let e = PanelLimits.boundsToleranceMM
        guard
            points.allSatisfy({
                $0.x >= bounds.minX - e && $0.x <= bounds.maxX + e && $0.y >= bounds.minY - e && $0.y <= bounds.maxY + e
            })
        else {
            throw invalid(field, TextConstants.Routing.textInsidePanelBounds)
        }
    }
}

/// EN: Polygon union of board material, the frame ring and solid breakaway bridges. Only material boundaries are
///     emitted: a tab never leaves a cut across its neck.
///
/// JA: 基板材料・外枠リング・接続タブの多角形を和集合にする。材料境界だけを出力し、タブの首を横断する切断線を残さない。
///
/// DE: Die Polygone von Platinenmaterial, Rahmenring und massiven Abbrechstegen vereinigen. Nur Materialgrenzen
///     ausgeben, damit kein Schnitt durch den Steghals entsteht.
enum PanelRouting {
    static let chordToleranceMM = 0.005

    /// EN: Check settings against unit-specific limits and interdependent constraints. Throw on out-of-range values,
    ///     NaN or infinity.
    ///
    /// JA: 設定値の単位別の閾値と相互条件を確認する。範囲外・NaN・無限大は例外にする。
    ///
    /// DE: Einstellungen anhand einheitenspezifischer Grenzen und gegenseitiger Bedingungen prüfen. Bei
    ///     Bereichsverletzungen, NaN oder Unendlich einen Fehler auslösen.
    static func validate(_ options: PanelOptions) throws {
        try Task.checkCancellation()
        // EN: Check before multiplying counts or constructing ranges / hole arrays.
        // JA: 個数の乗算や範囲・穴配列の生成より前に検証する。
        // DE: Vor der Multiplikation von Anzahlen oder dem Erstellen von Bereichen und Bohrungsarrays prüfen.
        guard options.columns > 0, options.rows > 0,
            options.columns <= PanelLimits.maxBoardPositions, options.rows <= PanelLimits.maxBoardPositions,
            options.columns <= PanelLimits.maxBoardPositions / options.rows
        else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.usePositiveRowAndColumnCountsWithAtMostEnglish,
                    TextConstants.Routing.usePositiveRowAndColumnCountsWithAtMostJapanese,
                    TextConstants.Routing.usePositiveRowAndColumnCountsWithAtMostGerman
                ))
        }
        let measurements = [
            options.columnGapMM, options.rowGapMM, options.horizontalFrameMM,
            options.verticalFrameMM, options.mountingHoleOffsetXMM, options.mountingHoleOffsetYMM,
            options.mountingHoleDrillMM, options.dimensionLineWidthMM, options.vScoreLineWidthMM,
            options.tabWidthMM, options.mouseBiteDiameterMM, options.mouseBitePitchMM,
        ]
        guard measurements.allSatisfy({ $0.isFinite && $0 >= 0 && $0 <= PanelLimits.maxMeasurementMM }),
            !options.addMountingHoles || options.mountingHoleDrillMM > 0
        else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.measurementsMustBeFiniteAndBetweenAndMmMountingEnglish,
                    TextConstants.Routing.measurementsMustBeFiniteAndBetweenAndMmMountingJapanese,
                    TextConstants.Routing.measurementsMustBeFiniteAndBetweenAndMmMountingGerman
                ))
        }
        try PanelValidation.number(
            options.frameGapMM, field: TextConstants.Routing.tokenOptionsFrameGapMM,
            range: 0...PanelLimits.maxMeasurementMM)
        try PanelValidation.number(
            options.panelCornerRadiusMM, field: TextConstants.Routing.tokenOptionsPanelCornerRadiusMM,
            range: 0...PanelLimits.maxMeasurementMM)
        if options.addTabs {
            guard (1...PanelLimits.maxTabsPerEdge).contains(options.tabsPerEdge), options.tabWidthMM.isFinite,
                options.tabWidthMM >= PanelLimits.minTabWidthMM, options.tabWidthMM <= PanelLimits.maxMeasurementMM
            else {
                throw RoutingError.invalid(
                    L10n.text(
                        TextConstants.Routing.useATabWidthOfAtLeastMmAndEnglish,
                        TextConstants.Routing.useATabWidthOfAtLeastMmAndJapanese,
                        TextConstants.Routing.useATabWidthOfAtLeastMmAndGerman))
            }
            if options.perforateTabs {
                let intervals = options.tabWidthMM / options.mouseBitePitchMM
                guard intervals.isFinite, intervals <= Double(PanelLimits.maxPerforationIntervals) else {
                    throw perforationLimitError
                }
            }
        }
        guard options.panelCornerRadiusMM.isFinite, options.panelCornerRadiusMM >= 0 else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.thePanelCornerRadiusMustBeZeroOrGreaterEnglish,
                    TextConstants.Routing.thePanelCornerRadiusMustBeZeroOrGreaterJapanese,
                    TextConstants.Routing.thePanelCornerRadiusMustBeZeroOrGreaterGerman))
        }
        guard options.frameGapMM.isFinite, options.frameGapMM >= 0 else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.frameClearanceMustBeZeroOrGreaterEnglish,
                    TextConstants.Routing.frameClearanceMustBeZeroOrGreaterJapanese,
                    TextConstants.Routing.frameClearanceMustBeZeroOrGreaterGerman))
        }
        if options.frameGapMM > 0 || options.addTabs {
            guard options.verticalFrameMM > 0, options.horizontalFrameMM > 0 else {
                throw RoutingError.invalid(
                    L10n.text(
                        TextConstants.Routing.setBothFrameWidthsAboveZeroToCreateAEnglish,
                        TextConstants.Routing.setBothFrameWidthsAboveZeroToCreateAJapanese,
                        TextConstants.Routing.setBothFrameWidthsAboveZeroToCreateAGerman))
            }
        }
        if options.addTabs {
            if options.perforateTabs {
                guard options.mouseBiteDiameterMM.isFinite, options.mouseBitePitchMM.isFinite,
                    options.mouseBiteDiameterMM > 0, options.mouseBitePitchMM > options.mouseBiteDiameterMM,
                    options.tabWidthMM >= options.mouseBitePitchMM
                else {
                    throw RoutingError.invalid(
                        L10n.text(
                            TextConstants.Routing.mouseBiteDiameterMustBePositiveAndSmallerThanEnglish,
                            TextConstants.Routing.mouseBiteDiameterMustBePositiveAndSmallerThanJapanese,
                            TextConstants.Routing.mouseBiteDiameterMustBePositiveAndSmallerThanGerman
                        ))
                }
            }
            guard options.frameGapMM > 0, options.tabWidthMM.isFinite, options.tabWidthMM > 0, options.tabsPerEdge > 0
            else {
                throw RoutingError.invalid(
                    L10n.text(
                        TextConstants.Routing.tabsRequireAPositiveFrameClearanceTabWidthAndEnglish,
                        TextConstants.Routing.tabsRequireAPositiveFrameClearanceTabWidthAndJapanese,
                        TextConstants.Routing.tabsRequireAPositiveFrameClearanceTabWidthAndGerman))
            }
            if options.connectBoardsWithTabs
                && ((options.columns > 1 && options.columnGapMM <= 0) || (options.rows > 1 && options.rowGapMM <= 0))
            {
                throw RoutingError.invalid(
                    L10n.text(
                        TextConstants.Routing.setPositiveBoardSpacingToConnectAdjacentBoardsWithEnglish,
                        TextConstants.Routing.setPositiveBoardSpacingToConnectAdjacentBoardsWithJapanese,
                        TextConstants.Routing.setPositiveBoardSpacingToConnectAdjacentBoardsWithGerman
                    ))
            }
        }
    }

    private static var perforationLimitError: RoutingError {
        .invalid(
            L10n.text(
                TextConstants.Routing.tooManyMouseBiteHolesIncreaseTheHolePitchEnglish,
                TextConstants.Routing.tooManyMouseBiteHolesIncreaseTheHolePitchJapanese,
                TextConstants.Routing.tooManyMouseBiteHolesIncreaseTheHolePitchGerman
            ))
    }

    /// EN: Validate signed coordinates [mm] for finiteness and absolute limits.
    ///
    /// JA: 符号付き座標 [mm] の有限性と絶対値上限を検証する。
    ///
    /// DE: Vorzeichenbehaftete Koordinaten [mm] auf Endlichkeit und Absolutgrenzen prüfen.
    static func validatePoints(_ points: [RoutePoint]) throws {
        guard
            points.allSatisfy({
                $0.x.isFinite && $0.y.isFinite && abs($0.x) <= PanelLimits.maxCoordinateMM
                    && abs($0.y) <= PanelLimits.maxCoordinateMM
            })
        else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.theOutlineContainsInvalidOrOutOfRangeCoordinatesEnglish,
                    TextConstants.Routing.theOutlineContainsInvalidOrOutOfRangeCoordinatesJapanese,
                    TextConstants.Routing.theOutlineContainsInvalidOrOutOfRangeCoordinatesGerman))
        }
    }

    /// EN: Convert contour points to cyclic segments; return empty for fewer than three points. The caller checks
    ///     closed loops.
    ///
    /// JA: 輪郭点を循環する線分へ変換する。3点未満なら空。結果は呼び出し側で閉ループ検証する。
    ///
    /// DE: Konturpunkte in umlaufende Segmente umwandeln; bei weniger als drei Punkten ein leeres Array zurückgeben.
    ///     Der Aufrufer prüft die Geschlossenheit.
    static func edges(_ loop: [RoutePoint]) -> [RouteSegment] {
        guard loop.count >= 3 else { return [] }
        return loop.indices.map { RouteSegment(a: loop[$0], b: loop[($0 + 1) % loop.count]) }.filter {
            ($0.b - $0.a).length > 1e-7
        }
    }

    /// EN: Assemble segments into closed contours. Throw on open outlines or invalid coordinates.
    ///
    /// JA: 線分を閉じた輪郭へ組み立てて返す。開いた外形・不正座標は例外とする。
    ///
    /// DE: Segmente zu geschlossenen Konturen zusammensetzen. Bei offenen Konturen oder ungültigen Koordinaten einen
    ///     Fehler auslösen.
    static func closedLoops(_ segments: [RouteSegment]) throws -> [[RoutePoint]] {
        try validatePoints(segments.flatMap { [$0.a, $0.b] })
        var pending = segments.filter { ($0.b - $0.a).length > 1e-7 }
        var loops: [[RoutePoint]] = []
        while !pending.isEmpty {
            try Task.checkCancellation()
            let first = pending.removeLast()
            var loop = [first.a, first.b]
            while (loop.last! - loop[0]).length > 0.001 {
                try Task.checkCancellation()
                guard
                    let index = pending.firstIndex(where: {
                        ($0.a - loop.last!).length < 0.001 || ($0.b - loop.last!).length < 0.001
                    })
                else {
                    throw RoutingError.invalid(
                        L10n.text(
                            TextConstants.Routing.theBoardOutlineIsOpenCloseTheOutlineBeforeEnglish,
                            TextConstants.Routing.theBoardOutlineIsOpenCloseTheOutlineBeforeJapanese,
                            TextConstants.Routing.theBoardOutlineIsOpenCloseTheOutlineBeforeGerman
                        ))
                }
                let segment = pending.remove(at: index)
                loop.append((segment.a - loop.last!).length < 0.001 ? segment.b : segment.a)
            }
            loop.removeLast()
            if loop.count >= 3 { loops.append(loop) }
        }
        guard !loops.isEmpty else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.noClosedBoardOutlineWasFoundEnglish,
                    TextConstants.Routing.noClosedBoardOutlineWasFoundJapanese,
                    TextConstants.Routing.noClosedBoardOutlineWasFoundGerman))
        }
        return loops
    }

    /// EN: Validate center/start [mm] and sweep angle [rad]; return approximation points within the chord tolerance.
    ///
    /// JA: 中心・開始点 [mm] と掃引角 [rad] を検証し、弦誤差内の近似点を返す。
    ///
    /// DE: Mittelpunkt/Startpunkt [mm] und Öffnungswinkel [rad] prüfen; Näherungspunkte innerhalb der Sehnentoleranz
    ///     zurückgeben.
    static func arc(center: RoutePoint, start: RoutePoint, sweep: Double) throws -> [RoutePoint] {
        try validatePoints([center, start])
        guard sweep.isFinite, abs(sweep) <= 2 * .pi + 1e-8 else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.theOutlineHasAnInvalidArcAngleEnglish,
                    TextConstants.Routing.theOutlineHasAnInvalidArcAngleJapanese,
                    TextConstants.Routing.theOutlineHasAnInvalidArcAngleGerman))
        }
        let radius = (start - center).length
        guard radius > 1e-9 else { return [start] }
        let step = min(Double.pi / 18, 2 * acos(max(-1, 1 - chordToleranceMM / radius)))
        let required = ceil(abs(sweep) / step)
        guard required.isFinite, required <= Double(PanelLimits.maxArcSegments) else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.theOutlineArcIsTooLargeToApproximateAccuratelyEnglish,
                    TextConstants.Routing.theOutlineArcIsTooLargeToApproximateAccuratelyJapanese,
                    TextConstants.Routing.theOutlineArcIsTooLargeToApproximateAccuratelyGerman))
        }
        let count = max(1, Int(required))
        let angle = atan2(start.y - center.y, start.x - center.x)
        let result = (0...count).map { index in
            let theta = angle + sweep * Double(index) / Double(count)
            return RoutePoint(x: center.x + radius * cos(theta), y: center.y + radius * sin(theta))
        }
        try validatePoints(result)
        return result
    }

    /// EN: Return the arc defined by three points [mm]. Check finiteness of inputs, calculated center and output
    ///     points.
    ///
    /// JA: 3点 [mm] が定める円弧を返す。入力点・計算した中心・出力点の有限性を確認する。
    ///
    /// DE: Den durch drei Punkte [mm] definierten Kreisbogen zurückgeben. Eingaben, berechneten Mittelpunkt und
    ///     Ausgabepunkte auf Endlichkeit prüfen.
    static func threePointArc(start: RoutePoint, mid: RoutePoint, end: RoutePoint) throws -> [RoutePoint] {
        try validatePoints([start, mid, end])
        let d = 2 * (start.x * (mid.y - end.y) + mid.x * (end.y - start.y) + end.x * (start.y - mid.y))
        guard abs(d) > 1e-10 else { return [start, end] }
        let s = start.x * start.x + start.y * start.y, m = mid.x * mid.x + mid.y * mid.y,
            e = end.x * end.x + end.y * end.y
        let center = RoutePoint(
            x: (s * (mid.y - end.y) + m * (end.y - start.y) + e * (start.y - mid.y)) / d,
            y: (s * (end.x - mid.x) + m * (start.x - end.x) + e * (mid.x - start.x)) / d)
        /// EN: Normalize a finite relative arc angle [rad] to [0, 2π).
        ///
        /// JA: 有限の円弧相対角 [rad] を0以上2π未満へ正規化する。
        ///
        /// DE: Einen endlichen relativen Kreisbogenwinkel [rad] auf [0, 2π) normalisieren.
        func positive(_ a: Double) -> Double {
            (a.truncatingRemainder(dividingBy: 2 * .pi) + 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        }
        let angle = atan2(start.y - center.y, start.x - center.x)
        let endAngle = positive(atan2(end.y - center.y, end.x - center.x) - angle)
        let midAngle = positive(atan2(mid.y - center.y, mid.x - center.x) - angle)
        var points = try arc(center: center, start: start, sweep: midAngle <= endAngle ? endAngle : endAngle - 2 * .pi)
        points[0] = start; points[points.count - 1] = end
        return points
    }

    /// EN: Validate rectangle [mm] and radius [mm]; return a rounded contour with radius limited to half the
    ///     rectangle's dimensions.
    ///
    /// JA: 矩形 [mm] と半径 [mm] を検証して、角を丸めた輪郭を返す。半径は矩形の半分までに制限する。
    ///
    /// DE: Rechteck [mm] und Radius [mm] prüfen; eine gerundete Kontur mit einem auf halbe Rechteckabmessungen
    ///     begrenzten Radius zurückgeben.
    static func roundedRectangle(_ rect: RouteRect, radius: Double) throws -> [RoutePoint] {
        try PanelValidation.rectangle(rect, field: TextConstants.Routing.tokenRoundedRectangleInput)
        try PanelValidation.number(
            radius, field: TextConstants.Routing.tokenRoundedRectangleRadiusMM, range: 0...PanelLimits.maxMeasurementMM)
        let r = max(0, min(radius, (rect.maxX - rect.minX) / 2, (rect.maxY - rect.minY) / 2))
        guard r > 0 else { return rect.points }
        let centers = [
            RoutePoint(x: rect.maxX - r, y: rect.minY + r), RoutePoint(x: rect.maxX - r, y: rect.maxY - r),
            RoutePoint(x: rect.minX + r, y: rect.maxY - r), RoutePoint(x: rect.minX + r, y: rect.minY + r),
        ]
        return try centers.enumerated().flatMap { index, center in
            let angle = -Double.pi / 2 + Double(index) * .pi / 2
            return try arc(
                center: center, start: RoutePoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle)),
                sweep: .pi / 2)
        }
    }

    /// EN: Recognize one square/rectangular exterior, including rotated rectangles and collinear subdivisions.
    ///     Internal cutouts do not change the exterior classification. Curves, notches and multiple islands return false.
    /// JA: 回転した長方形と辺上の分割点も含め、外周が1つの正方形・長方形か判定する。
    ///     内部の切り抜きは外周の判定に影響しない。曲線・切り欠き・複数の独立外周はfalseを返す。
    /// DE: Eine quadratische/rechteckige Außenkontur einschließlich gedrehter Rechtecke und unterteilter Kanten erkennen.
    ///     Innere Ausschnitte ändern die Einordnung nicht. Kurven, Kerben und mehrere Inseln ergeben false.
    private static func hasRectangularExterior(_ contours: [[RoutePoint]]) throws -> Bool {
        guard !contours.isEmpty, contours.allSatisfy({ $0.count >= 3 }) else {
            throw PanelValidation.invalid(
                TextConstants.Routing.tokenFrameTabsContours, TextConstants.Routing.textClosedLoopsWithAtLeastPoints)
        }
        try validatePoints(contours.flatMap { $0 })
        let exteriors = contours.enumerated().filter { index, loop in
            guard let first = loop.first else { return false }
            return contours.enumerated().filter {
                $0.offset != index && pointInside(first, loop: $0.element)
            }.count % 2 == 0
        }
        guard exteriors.count == 1, let exterior = exteriors.first?.element else { return false }
        let tolerance = PanelLimits.rectangularOutlineToleranceMM
        /// EN: A middle point is redundant only when it lies on a forward straight segment within tolerance [mm].
        /// JA: 中間点が許容差 [mm] 以内で順方向の直線分上にある場合だけ、省略可能と判定する。
        /// DE: Einen Zwischenpunkt nur bei Vorwärtsrichtung innerhalb der Toleranz [mm] als kollinear einstufen.
        func isStraight(_ a: RoutePoint, _ b: RoutePoint, _ c: RoutePoint) -> Bool {
            let first = b - a, second = c - b, chord = c - a
            guard chord.length > tolerance else { return false }
            return first.x * second.x + first.y * second.y >= 0
                && abs(cross(first, chord)) / chord.length <= tolerance
        }
        var corners: [RoutePoint] = []
        for point in exterior {
            if let last = corners.last, (point - last).length <= tolerance { continue }
            while corners.count >= 2 && isStraight(corners[corners.count - 2], corners[corners.count - 1], point) {
                corners.removeLast()
            }
            corners.append(point)
        }
        if corners.count > 1, let first = corners.first, let last = corners.last,
            (last - first).length <= tolerance
        {
            corners.removeLast()
        }
        // EN: Also simplify the closing seam when the contour starts halfway along a rectangle edge.
        // JA: 輪郭の開始点が長方形の辺の途中にある場合、閉じ目の分割点も整理する。
        // DE: Auch die Schließstelle vereinfachen, wenn die Kontur in der Mitte einer Rechteckkante beginnt.
        while corners.count >= 3 {
            if isStraight(corners[corners.count - 2], corners[corners.count - 1], corners[0]) {
                corners.removeLast()
            } else if isStraight(corners[corners.count - 1], corners[0], corners[1]) {
                corners.removeFirst()
            } else {
                break
            }
        }
        guard corners.count == 4 else { return false }
        let sides = corners.indices.map { corners[($0 + 1) % 4] - corners[$0] }
        guard sides.allSatisfy({ $0.length > tolerance }) else { return false }
        let orientation = cross(sides[0], sides[1])
        return sides.indices.allSatisfy { index in
            let a = sides[index], b = sides[(index + 1) % 4]
            let cosine = (a.x * b.x + a.y * b.y) / a.length / b.length
            return abs(cosine) <= PanelLimits.rectangularOutlineAngleTolerance && cross(a, b) * orientation > 0
        }
    }

    /// EN: Generate routing for identical boards. Centralize input/output validation in plan.
    ///
    /// JA: 均一基板の加工線を生成する。入力と戻り値の検証はplanに集約する。
    ///
    /// DE: Fräsdaten für identische Platinen erzeugen. Die Ein-/Ausgabeprüfung in plan bündeln.
    static func make(contours: [[RoutePoint]], bounds: RouteRect, options o: PanelOptions) throws -> [RouteSegment] {
        try plan(contours: contours, bounds: bounds, options: o).segments
    }

    /// EN: Validate outlines/settings and generate routing and perforations [mm] from the material union. Validate
    ///     the result as well.
    ///
    /// JA: 外形と設定を検証し、材料の和集合から加工線とミシン目 [mm] を作る。戻り値も検証する。
    ///
    /// DE: Konturen und Einstellungen prüfen und Fräsdaten sowie Perforationen [mm] aus der Materialvereinigung
    ///     erzeugen. Auch das Ergebnis prüfen.
    static func plan(
        contours: [[RoutePoint]], bounds: RouteRect, options o: PanelOptions,
        straightEdges: [RouteSegment]? = nil
    ) throws -> RoutingPlan {
        try validate(o)
        try PanelValidation.shape(
            PanelBoardShape(bounds: bounds, contours: contours), field: TextConstants.Routing.tokenRoutingInput)
        let sourceLines = straightEdges ?? contours.flatMap { edges($0) }
        try validatePoints(sourceLines.flatMap { [$0.a, $0.b] })
        let stepX = bounds.maxX - bounds.minX + o.columnGapMM
        let stepY = bounds.maxY - bounds.minY + o.rowGapMM
        var boards: [[[RoutePoint]]] = []
        var lines: [[RouteSegment]] = []
        for row in 0..<o.rows {
            for column in 0..<o.columns {
                let offset = RoutePoint(x: Double(column) * stepX, y: Double(row) * stepY)
                boards.append(contours.map { $0.map { $0 + offset } })
                lines.append(sourceLines.map { RouteSegment(a: $0.a + offset, b: $0.b + offset) })
            }
        }
        let array = RouteRect(
            minX: bounds.minX, minY: bounds.minY,
            maxX: bounds.maxX + Double(o.columns - 1) * stepX,
            maxY: bounds.maxY + Double(o.rows - 1) * stepY)
        return try plan(boards: boards, arrayBounds: array, options: o, straightEdges: lines)
    }

    /// EN: Find outward-facing straight spans [mm] for frame or board links, excluding arcs and hidden portions.
    ///     The caller already validates points; straightEdges come from original line/polygon entities, never arc tessellation.
    /// JA: 円弧と外形に遮られる部分を除き、外枠・隣接基板との接続に使える直線区間 [mm] を求める。
    ///     座標は呼び出し側で検証済み。straightEdgesには元の直線・ポリゴンだけを渡し、円弧の近似線分は渡さない。
    /// DE: Sichtbare gerade Abschnitte [mm] für Rahmen- oder Platinenverbindungen ermitteln; Bögen und verdeckte Teile ausschließen.
    ///     Punkte werden vom Aufrufer geprüft. straightEdges enthält ursprüngliche Linien/Polygone, keine angenäherten Bögen.
    private static func straightAttachmentSpans(
        contours: [[RoutePoint]], straightEdges: [RouteSegment], horizontal: Bool, positive: Bool
    ) throws -> [ClosedRange<Double>] {
        let tolerance = PanelLimits.rectangularOutlineToleranceMM
        let outline = contours.flatMap { edges($0) }
        var result: [ClosedRange<Double>] = []
        for candidate in straightEdges {
            try Task.checkCancellation()
            let start = horizontal ? candidate.a.y : candidate.a.x
            let end = horizontal ? candidate.b.y : candidate.b.x
            guard abs(end - start) > tolerance else { continue }
            let alongStart = horizontal ? candidate.a.x : candidate.a.y
            let alongEnd = horizontal ? candidate.b.x : candidate.b.y
            let slope = (alongEnd - alongStart) / (end - start)
            var visible = [min(start, end)...max(start, end)]
            for edge in outline {
                let a = horizontal ? edge.a.y : edge.a.x, b = horizontal ? edge.b.y : edge.b.x
                guard abs(b - a) > tolerance else { continue }
                let lower = max(min(start, end), min(a, b)), upper = min(max(start, end), max(a, b))
                guard upper - lower > tolerance else { continue }
                let u = horizontal ? edge.a.x : edge.a.y, v = horizontal ? edge.b.x : edge.b.y
                let edgeSlope = (v - u) / (b - a)
                let sign = positive ? 1.0 : -1.0
                let deltaLower = sign * (u + (lower - a) * edgeSlope - alongStart - (lower - start) * slope)
                let deltaUpper = sign * (u + (upper - a) * edgeSlope - alongStart - (upper - start) * slope)
                if deltaLower <= tolerance && deltaUpper <= tolerance { continue }
                var blockedLow = lower, blockedHigh = upper
                if deltaLower <= tolerance {
                    blockedLow = lower + (upper - lower) * (tolerance - deltaLower) / (deltaUpper - deltaLower)
                } else if deltaUpper <= tolerance {
                    blockedHigh = lower + (upper - lower) * (tolerance - deltaLower) / (deltaUpper - deltaLower)
                }
                var remaining: [ClosedRange<Double>] = []
                for range in visible {
                    if blockedHigh <= range.lowerBound || blockedLow >= range.upperBound {
                        remaining.append(range)
                    } else {
                        if blockedLow > range.lowerBound + tolerance {
                            remaining.append(range.lowerBound...blockedLow)
                        }
                        if blockedHigh < range.upperBound - tolerance {
                            remaining.append(blockedHigh...range.upperBound)
                        }
                    }
                }
                visible = remaining
                if visible.isEmpty { break }
            }
            result += visible
        }
        return result
    }

    /// EN: Routing for heterogeneous boards already translated into panel coordinates. Split each side into visible
    ///     spans so bridges never run through another board.
    ///
    /// JA: パネル座標へ移動済みの異種基板の加工線を生成する。各辺を有効な区間に分割し、接続タブが他の基板を横切らないようにする。
    ///
    /// DE: Fräsdaten für unterschiedliche, bereits in Panelkoordinaten verschobene Platinen erzeugen. Jede Seite in
    ///     nutzbare Abschnitte unterteilen, damit Stege keine andere Platine durchqueren.
    static func plan(
        boards: [[[RoutePoint]]], arrayBounds: RouteRect, options o: PanelOptions,
        straightEdges: [[RouteSegment]]? = nil
    ) throws -> RoutingPlan {
        try validate(o)
        guard !boards.isEmpty, boards.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.count >= 3 } }) else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Routing.noClosedBoardOutlineWasFoundEnglish,
                    TextConstants.Routing.noClosedBoardOutlineWasFoundJapanese,
                    TextConstants.Routing.noClosedBoardOutlineWasFoundGerman))
        }
        try validatePoints(boards.flatMap { $0.flatMap { $0 } })
        let boxes = boards.map { board -> RouteRect in
            let points = board.flatMap { $0 }
            return RouteRect(
                minX: points.map(\.x).min()!, minY: points.map(\.y).min()!,
                maxX: points.map(\.x).max()!, maxY: points.map(\.y).max()!)
        }
        let sourceLines = straightEdges ?? boards.map { $0.flatMap { edges($0) } }
        guard sourceLines.count == boards.count else {
            throw PanelValidation.invalid(
                TextConstants.Routing.tokenRoutingStraightEdges, TextConstants.Routing.textOneLineSetPerBoard)
        }
        for index in boards.indices {
            try validatePoints(sourceLines[index].flatMap { [$0.a, $0.b] })
            try PanelValidation.validateContained(
                sourceLines[index].flatMap { [$0.a, $0.b] }, in: boxes[index],
                field: TextConstants.Routing.tokenRoutingStraightEdges)
        }
        let inner = RouteRect(
            minX: arrayBounds.minX - o.frameGapMM, minY: arrayBounds.minY - o.frameGapMM,
            maxX: arrayBounds.maxX + o.frameGapMM, maxY: arrayBounds.maxY + o.frameGapMM)
        let outer = RouteRect(
            minX: inner.minX - o.verticalFrameMM, minY: inner.minY - o.horizontalFrameMM,
            maxX: inner.maxX + o.verticalFrameMM, maxY: inner.maxY + o.horizontalFrameMM)
        let hasFrame = o.verticalFrameMM > 0 || o.horizontalFrameMM > 0
        let outerLoop = try roundedRectangle(outer, radius: hasFrame ? o.panelCornerRadiusMM : 0)
        let holes = boards.flatMap { contours in
            contours.enumerated().filter { index, loop in
                guard let first = loop.first else { return false }
                return contours.enumerated().filter { $0.offset != index && pointInside(first, loop: $0.element) }.count
                    % 2 == 1
            }.map { $0.element }
        }
        var bridges: [RouteRect] = [], bites: [RoutePoint] = []
        let frameIndex = boards.count
        var links = Array(repeating: Set<Int>(), count: boards.count + 1)
        /// EN: Return intersections [mm] of a tab cross-section with the outline. Throw if none exist.
        ///
        /// JA: タブを渡す断面と外形の交点 [mm] を返す。交点がなければ例外とする。
        ///
        /// DE: Schnittpunkte [mm] eines Stegquerschnitts mit der Kontur zurückgeben. Bei fehlenden Schnittpunkten
        ///     einen Fehler auslösen.
        func crossing(_ index: Int, transverse: Double, horizontal: Bool, maximum: Bool) throws -> Double {
            var hits: [Double] = []
            for edge in boards[index].flatMap({ edges($0) }) {
                let a = horizontal ? edge.a.y : edge.a.x, b = horizontal ? edge.b.y : edge.b.x
                if (a <= transverse && b > transverse) || (b <= transverse && a > transverse) {
                    let t = (transverse - a) / (b - a)
                    hits.append(
                        horizontal ? edge.a.x + t * (edge.b.x - edge.a.x) : edge.a.y + t * (edge.b.y - edge.a.y))
                }
            }
            guard let hit = maximum ? hits.max() : hits.min() else {
                throw RoutingError.invalid(
                    L10n.text(
                        TextConstants.Routing.aTabDoesNotIntersectTheBoardOutlineReduceEnglish,
                        TextConstants.Routing.aTabDoesNotIntersectTheBoardOutlineReduceJapanese,
                        TextConstants.Routing.aTabDoesNotIntersectTheBoardOutlineReduceGerman
                    ))
            }
            return hit
        }
        if o.addTabs {
            // EN: Cache four facing directions per board; repeated source/target checks reuse the same intervals [mm].
            // JA: 基板ごとに4方向の区間 [mm] を保存し、接続元と接続先で同じ計算を繰り返さない。
            // DE: Vier Richtungen je Platine zwischenspeichern und Intervalle [mm] für beide Verbindungsseiten wiederverwenden.
            var straightSpanCache: [Int: [ClosedRange<Double>]] = [:]
            /// EN: Return validated-board straight intervals toward the requested side, reusing cached results.
            /// JA: 指定された側を向く検証済み基板の直線区間を、保存済みの結果を再利用して返す。
            /// DE: Gerade Intervalle der geprüften Platine in der gewünschten Richtung aus dem Zwischenspeicher zurückgeben.
            func visibleStraightSpans(index: Int, horizontal: Bool, positive: Bool) throws -> [ClosedRange<Double>] {
                guard boards.indices.contains(index) else {
                    throw PanelValidation.invalid(
                        TextConstants.Routing.tokenRoutingStraightSpanIndex,
                        TextConstants.Routing.textExistingBoardIndex)
                }
                let key = index * 4 + (horizontal ? 0 : 2) + (positive ? 1 : 0)
                if let cached = straightSpanCache[key] { return cached }
                let ranges = try straightAttachmentSpans(
                    contours: boards[index], straightEdges: sourceLines[index], horizontal: horizontal,
                    positive: positive)
                straightSpanCache[key] = ranges
                return ranges
            }
            let requiresFrameConnection = try boards.map { try hasRectangularExterior($0) }
            for index in boards.indices {
                let box = boxes[index]
                for horizontal in [true, false] {
                    let low = horizontal ? box.minY : box.minX, high = horizontal ? box.maxY : box.maxX
                    for positive in [false, true] {
                        let face = horizontal ? (positive ? box.maxX : box.minX) : (positive ? box.maxY : box.minY)
                        let candidates = boxes.indices.filter { other in
                            guard other != index else { return false }
                            let b = boxes[other]
                            let near = horizontal ? (positive ? b.minX : b.maxX) : (positive ? b.minY : b.maxY)
                            return positive ? near >= face - 1e-7 : near <= face + 1e-7
                        }
                        var cuts = [low, high]
                        for other in candidates {
                            let b = boxes[other]
                            cuts += [
                                max(low, min(high, horizontal ? b.minY : b.minX)),
                                max(low, min(high, horizontal ? b.maxY : b.maxX)),
                            ]
                        }
                        cuts = Array(Set(cuts)).sorted()
                        var spans: [(low: Double, high: Double, target: Int?)] = []
                        for (a, b) in zip(cuts, cuts.dropFirst()) where b - a > 1e-7 {
                            let mid = (a + b) / 2
                            let target = candidates.filter { other in
                                let r = boxes[other]
                                return horizontal ? (r.minY < mid && r.maxY > mid) : (r.minX < mid && r.maxX > mid)
                            }.min { first, second in
                                let a = boxes[first], b = boxes[second]
                                let av = horizontal ? (positive ? a.minX : a.maxX) : (positive ? a.minY : a.maxY)
                                let bv = horizontal ? (positive ? b.minX : b.maxX) : (positive ? b.minY : b.maxY)
                                return abs(av - face) < abs(bv - face)
                            }
                            if let last = spans.last, last.target == target, abs(last.high - a) < 1e-7 {
                                spans[spans.count - 1].high = b
                            } else {
                                spans.append((a, b, target))
                            }
                        }
                        let sourceSpans = try visibleStraightSpans(
                            index: index, horizontal: horizontal, positive: positive)
                        // EN: Both ends of a board-to-board tab must lie on facing straight sections over its full width.
                        //     Intersect source/target spans before reserving hole-radius clearance from all section ends.
                        // JA: 基板間タブは全幅にわたって両端が向かい合う直線に接続する必要がある。
                        //     両基板の直線区間の重なりを求め、区間の両端から穴半径分の余裕も確保する。
                        // DE: Beide Enden eines Platinenstegs müssen über die ganze Breite auf gegenüberliegenden Geraden liegen.
                        //     Quell-/Zielintervalle schneiden und an allen Enden den Bohrungsradius freihalten.
                        var attachmentSpans: [(low: Double, high: Double, target: Int?)] = []
                        let holeMargin = o.perforateTabs ? o.mouseBiteDiameterMM / 2 : 0
                        for span in spans {
                            if span.target != nil && (!o.connectBoardsWithTabs || !positive) { continue }
                            let targetSpans: [ClosedRange<Double>]
                            if let target = span.target {
                                targetSpans = try visibleStraightSpans(
                                    index: target, horizontal: horizontal, positive: !positive)
                            } else {
                                targetSpans = [span.low...span.high]
                            }
                            for source in sourceSpans {
                                for target in targetSpans {
                                    let low = max(span.low, source.lowerBound, target.lowerBound) + holeMargin
                                    let high = min(span.high, source.upperBound, target.upperBound) - holeMargin
                                    guard high > low else { continue }
                                    attachmentSpans.append((low, high, span.target))
                                }
                            }
                        }
                        for span in attachmentSpans {
                            if span.target != nil && (!o.connectBoardsWithTabs || !positive) { continue }
                            let frameEnabled =
                                horizontal
                                ? (positive ? o.tabsRight : o.tabsLeft) : (positive ? o.tabsBottom : o.tabsTop)
                            if span.target == nil && !frameEnabled { continue }
                            let length = span.high - span.low
                            guard length > o.tabWidthMM + 0.001 else { continue }
                            let count = min(
                                o.tabsPerEdge,
                                max(1, Int(min(Double(o.tabsPerEdge + 1), (length - 0.001) / o.tabWidthMM)) - 1))
                            let half = o.tabWidthMM / 2
                            for tab in 1...count {
                                let center = span.low + length * Double(tab) / Double(count + 1)
                                let start = try crossing(
                                    index, transverse: center, horizontal: horizontal, maximum: positive)
                                let fixed =
                                    horizontal
                                    ? (positive ? inner.maxX : inner.minX) : (positive ? inner.maxY : inner.minY)
                                let end =
                                    try span.target.map {
                                        try crossing($0, transverse: center, horizontal: horizontal, maximum: !positive)
                                    } ?? fixed
                                // EN: Cover the full width on both straight interfaces, including sloped edges.
                                // JA: 斜めの辺も含め、接続する両方の直線にタブ全幅が届くようにする。
                                // DE: Die gesamte Stegbreite an beiden geraden Schnittstellen erreichen, auch an schrägen Kanten.
                                let sourceFirst = try crossing(
                                    index, transverse: center - half, horizontal: horizontal, maximum: positive)
                                let sourceLast = try crossing(
                                    index, transverse: center + half, horizontal: horizontal, maximum: positive)
                                var attachmentLow = min(start, sourceFirst, sourceLast)
                                var attachmentHigh = max(start, sourceFirst, sourceLast)
                                if let target = span.target {
                                    let targetFirst = try crossing(
                                        target, transverse: center - half, horizontal: horizontal, maximum: !positive)
                                    let targetLast = try crossing(
                                        target, transverse: center + half, horizontal: horizontal, maximum: !positive)
                                    attachmentLow = min(attachmentLow, targetFirst, targetLast)
                                    attachmentHigh = max(attachmentHigh, targetFirst, targetLast)
                                }
                                let alongLow = min(attachmentLow, end) - 0.01
                                let alongHigh = max(attachmentHigh, end) + 0.01
                                let bridge =
                                    horizontal
                                    ? RouteRect(
                                        minX: alongLow, minY: center - half, maxX: alongHigh, maxY: center + half)
                                    : RouteRect(
                                        minX: center - half, minY: alongLow, maxX: center + half, maxY: alongHigh)
                                bridges.append(bridge)
                                let target = span.target ?? frameIndex
                                links[index].insert(target); links[target].insert(index)
                                if o.perforateTabs {
                                    let intervals = max(1, Int(floor(o.tabWidthMM / o.mouseBitePitchMM)))
                                    guard bites.count <= PanelLimits.maxGeneratedHoles - 2 * (intervals + 1) else {
                                        throw perforationLimitError
                                    }
                                    for hole in 0...intervals {
                                        let transverse =
                                            center + (Double(hole) - Double(intervals) / 2) * o.mouseBitePitchMM
                                        let a = try crossing(
                                            index, transverse: transverse, horizontal: horizontal, maximum: positive)
                                        let b =
                                            try span.target.map {
                                                try crossing(
                                                    $0, transverse: transverse, horizontal: horizontal,
                                                    maximum: !positive)
                                            } ?? fixed
                                        bites +=
                                            horizontal
                                            ? [RoutePoint(x: a, y: transverse), RoutePoint(x: b, y: transverse)]
                                            : [RoutePoint(x: transverse, y: a), RoutePoint(x: transverse, y: b)]
                                    }
                                }
                            }
                        }
                    }
                }
            }
            var reached: Set<Int> = [frameIndex], pending = [frameIndex]
            while let current = pending.popLast() {
                for next in links[current] where reached.insert(next).inserted { pending.append(next) }
            }
            // EN: Keep rectangle connectivity checks. Irregular boards may intentionally lack a wide enough straight span.
            // JA: 長方形基板の接続検証は維持する。異形基板では幅の足りる直線がなく、タブを省く場合がある。
            // DE: Die Verbindungsprüfung für Rechtecke beibehalten. Bei Sonderformen kann ein ausreichend gerader Abschnitt fehlen.
            guard boards.indices.filter({ requiresFrameConnection[$0] }).allSatisfy({ reached.contains($0) }) else {
                throw RoutingError.invalid(
                    L10n.text(
                        TextConstants.Routing.someBoardsCannotConnectToTheFrameWithTheseEnglish,
                        TextConstants.Routing.someBoardsCannotConnectToTheFrameWithTheseJapanese,
                        TextConstants.Routing.someBoardsCannotConnectToTheFrameWithTheseGerman
                    ))
            }
        }
        var segments = boards.flatMap { $0.flatMap { edges($0) } } + bridges.flatMap { edges($0.points) }
        if hasFrame { segments += edges(inner.points) + edges(outerLoop) }
        /// EN: Return whether material remains at validated coordinates, considering the frame, boards, tabs and
        ///     cutouts.
        ///
        /// JA: 検証済みの座標で材料が残るか返す。外枠・基板・タブと切り抜きの関係を評価する。
        ///
        /// DE: Prüfen, ob an geprüften Koordinaten Material verbleibt; Rahmen, Platinen, Stege und Ausschnitte
        ///     berücksichtigen.
        func material(_ point: RoutePoint) -> Bool {
            if holes.contains(where: { pointInside(point, loop: $0) }) { return false }
            if hasFrame && pointInside(point, loop: outerLoop) && !inner.contains(point) { return true }
            if bridges.contains(where: { $0.contains(point) }) { return true }
            for index in boards.indices where boxes[index].contains(point) {
                if boards[index].filter({ pointInside(point, loop: $0) }).count % 2 == 1 { return true }
            }
            return false
        }
        var seen = Set<String>()
        let uniqueBites = bites.filter {
            seen.insert(TextConstants.Routing.coordinateKeyTemplate(($0.x * 1e6).rounded(), ($0.y * 1e6).rounded()))
                .inserted
        }
        let result = RoutingPlan(segments: try unionBoundary(segments, material: material), mouseBites: uniqueBites)
        try PanelValidation.routing(result, inside: outer)
        return result
    }

    /// EN: Return the even-odd containment result for a closed contour. Empty contours return false; coordinates were
    ///     validated at call boundaries.
    ///
    /// JA: 閉じた輪郭に対する偶奇判定を返す。空の輪郭はfalse。座標は呼び出し境界で検証済み。
    ///
    /// DE: Die Enthaltenheitsprüfung nach der Gerade-Ungerade-Regel für eine geschlossene Kontur zurückgeben. Leere
    ///     Konturen ergeben false; Koordinaten wurden an Aufrufgrenzen geprüft.
    static func pointInside(_ p: RoutePoint, loop: [RoutePoint]) -> Bool {
        var inside = false
        for i in loop.indices {
            let a = loop[i], b = loop[(i + 1) % loop.count]
            if (a.y > p.y) != (b.y > p.y), p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { inside.toggle() }
        }
        return inside
    }

    /// EN: Return the cross product of two validated 2D vectors, used to detect parallel lines during intersection
    ///     checks.
    ///
    /// JA: 2つの検証済み2次元ベクトルの外積を返す。交点の平行判定に使用する。
    ///
    /// DE: Das Kreuzprodukt zweier geprüfter 2D-Vektoren zurückgeben, um parallele Linien bei Schnittpunktprüfungen
    ///     zu erkennen.
    private static func cross(_ a: RoutePoint, _ b: RoutePoint) -> Double { a.x * b.y - a.y * b.x }
    /// EN: Compare inside/outside material regions and return boundary segments only. Honor cancellation to stop
    ///     obsolete calculations.
    ///
    /// JA: 材料領域の内外を比較し、外周の線分だけを返す。キャンセルを確認して古い計算を中断する。
    ///
    /// DE: Innere und äußere Materialbereiche vergleichen und nur Randsegmente zurückgeben. Veraltete Berechnungen
    ///     bei Abbruchanforderung beenden.
    private static func unionBoundary(_ segments: [RouteSegment], material: (RoutePoint) -> Bool) throws
        -> [RouteSegment]
    {
        var cuts = Array(repeating: [0.0, 1.0], count: segments.count)
        let order = segments.indices.sorted {
            min(segments[$0].a.x, segments[$0].b.x) < min(segments[$1].a.x, segments[$1].b.x)
        }
        for sortedIndex in order.indices {
            try Task.checkCancellation()
            let i = order[sortedIndex]
            for otherIndex in (sortedIndex + 1)..<order.count {
                let j = order[otherIndex]
                let a = segments[i], b = segments[j]
                if min(b.a.x, b.b.x) > max(a.a.x, a.b.x) + 1e-8 { break }
                if max(a.a.x, a.b.x) + 1e-8 < min(b.a.x, b.b.x) || max(b.a.x, b.b.x) + 1e-8 < min(a.a.x, a.b.x)
                    || max(a.a.y, a.b.y) + 1e-8 < min(b.a.y, b.b.y) || max(b.a.y, b.b.y) + 1e-8 < min(a.a.y, a.b.y)
                {
                    continue
                }
                let r = a.b - a.a, s = b.b - b.a, delta = b.a - a.a
                let denominator = cross(r, s)
                if abs(denominator) > 1e-10 {
                    let t = cross(delta, s) / denominator, u = cross(delta, r) / denominator
                    if t >= -1e-8 && t <= 1 + 1e-8 && u >= -1e-8 && u <= 1 + 1e-8 {
                        cuts[i].append(min(1, max(0, t))); cuts[j].append(min(1, max(0, u)))
                    }
                } else if abs(cross(delta, r)) < 1e-8 {
                    for p in [b.a, b.b] {
                        let t = abs(r.x) > abs(r.y) ? (p.x - a.a.x) / r.x : (p.y - a.a.y) / r.y;
                        if t > 0 && t < 1 { cuts[i].append(t) }
                    }
                    for p in [a.a, a.b] {
                        let u = abs(s.x) > abs(s.y) ? (p.x - b.a.x) / s.x : (p.y - b.a.y) / s.y;
                        if u > 0 && u < 1 { cuts[j].append(u) }
                    }
                }
            }
        }
        /// EN: Round endpoint discrepancies from calculation error to 1e-6 mm increments. Inputs were range-checked.
        ///
        /// JA: 計算誤差による端点のずれを1e-6 mm単位へ丸める。入力は範囲検証済み。
        ///
        /// DE: Berechnungsbedingte Endpunktabweichungen auf Schritte von 1e-6 mm runden. Die Eingaben wurden auf
        ///     ihren Wertebereich geprüft.
        func snap(_ p: RoutePoint) -> RoutePoint {
            RoutePoint(x: (p.x * 1e6).rounded() / 1e6, y: (p.y * 1e6).rounded() / 1e6)
        }
        var seen: Set<String> = [], result: [RouteSegment] = []
        for index in segments.indices {
            try Task.checkCancellation()
            let ts = cuts[index].sorted(), edge = segments[index], direction = edge.b - edge.a
            for pair in zip(ts, ts.dropFirst()) where pair.1 - pair.0 > 1e-8 {
                let a = edge.a + direction * pair.0, b = edge.a + direction * pair.1
                let midpoint = (a + b) * 0.5
                let normal = RoutePoint(x: -direction.y, y: direction.x) * (0.00001 / direction.length)
                let left = material(midpoint + normal), right = material(midpoint - normal)
                if left == right { continue }
                let start = snap(left ? a : b), end = snap(left ? b : a)
                let keys = [
                    TextConstants.Routing.coordinateKeyTemplate(start.x, start.y),
                    TextConstants.Routing.coordinateKeyTemplate(end.x, end.y),
                ].sorted()
                if start != end && seen.insert(keys.joined(separator: TextConstants.Common.colon)).inserted {
                    result.append(RouteSegment(a: start, b: end))
                }
            }
        }
        return result
    }
}

enum L10n {
    // EN: Match supported languages in OS preference order, including regional forms such as de-DE, de-AT and de-CH.
    //     Unsupported languages fall back to English.
    // JA: OSの言語優先順で対応言語を選び、de-DE・de-AT・de-CHなどの地域形式も認識する。未対応言語だけなら英語にフォールバックする。
    // DE: Unterstützte Sprachen in der OS-Präferenzreihenfolge auswählen, einschließlich regionaler Varianten wie
    //     de-DE, de-AT und de-CH. Sind keine davon unterstützt, auf Englisch zurückfallen.
    private static var language: String {
        for identifier in Locale.preferredLanguages {
            let code =
                identifier.lowercased()
                .split(whereSeparator: {
                    $0 == TextConstants.Characters.hyphen || $0 == TextConstants.Characters.underscore
                }).first.map(String.init) ?? TextConstants.Common.empty
            if [TextConstants.Routing.tokenEn, TextConstants.Routing.tokenJa, TextConstants.Routing.tokenDe].contains(
                code)
            {
                return code
            }
        }
        return TextConstants.Routing.tokenEn
    }

    /// EN: Select English, Japanese or German strings using OS language preferences. Fall back to English if none are
    ///     supported.
    ///
    /// JA: OSの優先言語で英語・日本語・ドイツ語の文字列を選ぶ。未対応言語だけなら英語を返す。
    ///
    /// DE: Englische, japanische oder deutsche Zeichenketten gemäß den OS-Sprachpräferenzen wählen. Bei
    ///     ausschließlich nicht unterstützten Sprachen Englisch verwenden.
    static func text(_ english: String, _ japanese: String, _ german: String) -> String {
        switch language {
        case TextConstants.Routing.tokenJa: return japanese
        case TextConstants.Routing.tokenDe: return german
        default: return english
        }
    }
}
