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
                "Invalid value in \(field). Expected: \(expected).", "\(field)の値が不正です。許容範囲: \(expected)。",
                "Ungültiger Wert in \(field). Erwartet: \(expected)."))
    }

    /// EN: Check that a number lies in the specified closed interval, including rejection of NaN and infinity.
    ///
    /// JA: NaN・無限大を含め、数値が指定された閉区間内にあるか確認する。
    ///
    /// DE: Prüfen, ob eine Zahl im angegebenen abgeschlossenen Intervall liegt; NaN und Unendlich ablehnen.
    static func number(_ value: Double, field: String, range: ClosedRange<Double>) throws {
        guard value.isFinite && range.contains(value) else {
            throw invalid(field, "\(range.lowerBound)...\(range.upperBound)")
        }
    }

    /// EN: Check file size before parsing or returning generated data.
    ///
    /// JA: ファイルをパースする前、または生成データを返す前にサイズを確認する。
    ///
    /// DE: Die Dateigröße vor dem Parsen oder der Rückgabe erzeugter Daten prüfen.
    static func document(_ data: Data, field: String) throws {
        guard !data.isEmpty && data.count <= PanelLimits.maxDocumentBytes else {
            throw invalid(field, "1...\(PanelLimits.maxDocumentBytes) bytes")
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
            rect.maxX - rect.minX, field: field + ".widthMM",
            range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
        try number(
            rect.maxY - rect.minY, field: field + ".heightMM",
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
        try rectangle(shape.bounds, field: field + ".bounds")
        guard !shape.contours.isEmpty && shape.contours.allSatisfy({ $0.count >= 3 }) else {
            throw invalid(field + ".contours", "closed loops with at least 3 points")
        }
        let points = shape.contours.flatMap { $0 }
        try PanelRouting.validatePoints(points)
        let b = shape.bounds
        let tolerance = PanelLimits.boundsToleranceMM
        guard
            points.allSatisfy({
                $0.x >= b.minX - tolerance && $0.x <= b.maxX + tolerance && $0.y >= b.minY - tolerance
                    && $0.y <= b.maxY + tolerance
            })
        else {
            throw invalid(field + ".contours", "inside outline bounds")
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
            ("boardWidthMM", value.boardWidthMM), ("boardHeightMM", value.boardHeightMM),
            ("panelWidthMM", value.panelWidthMM), ("panelHeightMM", value.panelHeightMM),
        ] {
            try number(
                measurement, field: "summary." + name,
                range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
        }
        guard value.columns > 0 && value.rows > 0 && value.columns <= PanelLimits.maxBoardPositions / value.rows else {
            throw invalid("summary.rows/columns", "1...\(PanelLimits.maxBoardPositions) positions")
        }
        guard
            value.panelWidthMM + PanelLimits.boundsToleranceMM >= value.boardWidthMM
                && value.panelHeightMM + PanelLimits.boundsToleranceMM >= value.boardHeightMM
        else {
            throw invalid("summary.panel", "contains board array")
        }
        try number(
            value.dimensionLineWidthMM, field: "summary.dimensionLineWidthMM", range: 0...PanelLimits.maxMeasurementMM)
    }

    /// EN: Validate generated data and dimensions together and return the checked pair.
    ///
    /// JA: 生成したデータと寸法を同時に検査し、検証済みの組を返す。
    ///
    /// DE: Erzeugte Daten und Abmessungen gemeinsam prüfen und das geprüfte Paar zurückgeben.
    static func output(_ data: Data, summary value: PanelSummary, options: PanelOptions) throws -> (Data, PanelSummary)
    {
        try document(data, field: "export.outputData")
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
            throw invalid("mountingHoleOffset/diameter", "entire hole inside panel")
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
            throw invalid("previewDrills.count", "0...\(PanelLimits.maxPreviewHoles)")
        }
        for (index, drill) in drills.enumerated() {
            try PanelRouting.validatePoints([drill.center])
            try number(
                drill.width, field: "previewDrills[\(index)].widthMM",
                range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
            try number(
                drill.height, field: "previewDrills[\(index)].heightMM",
                range: Double.leastNonzeroMagnitude...PanelLimits.maxMeasurementMM)
            try number(
                drill.angle, field: "previewDrills[\(index)].angleDegrees",
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
        try rectangle(bounds, field: "routing.panelBounds")
        guard !plan.segments.isEmpty && plan.mouseBites.count <= PanelLimits.maxGeneratedHoles else {
            throw invalid("routing.segments/mouseBites", "nonempty outline and bounded hole count")
        }
        let points = plan.segments.flatMap { [$0.a, $0.b] } + plan.mouseBites
        try validateContained(points, in: bounds, field: "routing.points")
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
            throw invalid(field, "inside panel bounds")
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
                    "Use positive row and column counts with at most 10,000 board positions.",
                    "行数・列数は1以上、配置数は合計10,000枚以下にしてください。",
                    "Zeilen- und Spaltenanzahl müssen positiv sein und dürfen zusammen höchstens 10.000 Leiterplattenpositionen ergeben."
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
                    "Measurements must be finite and between 0 and 1,000,000 mm; mounting-hole diameter must be positive.",
                    "寸法は有限の0〜1,000,000 mm、取付穴径は0より大きい値にしてください。",
                    "Maße müssen endlich sein und zwischen 0 und 1.000.000 mm liegen; der Durchmesser der Befestigungsbohrung muss positiv sein."
                ))
        }
        try PanelValidation.number(
            options.frameGapMM, field: "options.frameGapMM", range: 0...PanelLimits.maxMeasurementMM)
        try PanelValidation.number(
            options.panelCornerRadiusMM, field: "options.panelCornerRadiusMM", range: 0...PanelLimits.maxMeasurementMM)
        if options.addTabs {
            guard (1...PanelLimits.maxTabsPerEdge).contains(options.tabsPerEdge), options.tabWidthMM.isFinite,
                options.tabWidthMM >= PanelLimits.minTabWidthMM, options.tabWidthMM <= PanelLimits.maxMeasurementMM
            else {
                throw RoutingError.invalid(
                    L10n.text(
                        "Use a tab width of at least 0.001 mm and between 1 and 1,000 tabs per edge.",
                        "タブ幅は0.001 mm以上、各辺のタブ数は1〜1,000にしてください。",
                        "Verwenden Sie eine Stegbreite von mindestens 0,001 mm und 1 bis 1.000 Stege pro Kante."))
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
                    "The panel corner radius must be zero or greater.", "パネル角のRは0以上にしてください。",
                    "Der Eckenradius des Nutzens muss mindestens 0 betragen."))
        }
        guard options.frameGapMM.isFinite, options.frameGapMM >= 0 else {
            throw RoutingError.invalid(
                L10n.text(
                    "Frame clearance must be zero or greater.", "外枠と基板の隙間は0以上にしてください。",
                    "Der Abstand zum Rahmen muss mindestens 0 betragen."))
        }
        if options.frameGapMM > 0 || options.addTabs {
            guard options.verticalFrameMM > 0, options.horizontalFrameMM > 0 else {
                throw RoutingError.invalid(
                    L10n.text(
                        "Set both frame widths above zero to create a frame and clearance.",
                        "隙間のある外枠を作るには、左右・上下の外枠幅を両方とも0より大きくしてください。",
                        "Stellen Sie beide Rahmenbreiten größer als 0 ein, um einen Rahmen mit Abstand zu erstellen."))
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
                            "Mouse-bite diameter must be positive and smaller than the pitch. The pitch must not exceed the tab width.",
                            "ミシン目の穴径は0より大きく、穴ピッチより小さくしてください。穴ピッチはタブ幅以下にしてください。",
                            "Der Durchmesser der Sollbruchbohrungen muss größer als 0 und kleiner als der Lochabstand sein. Der Lochabstand darf die Stegbreite nicht überschreiten."
                        ))
                }
            }
            guard options.frameGapMM > 0, options.tabWidthMM.isFinite, options.tabWidthMM > 0, options.tabsPerEdge > 0
            else {
                throw RoutingError.invalid(
                    L10n.text(
                        "Tabs require a positive frame clearance, tab width and tab count.",
                        "タブを作るには、外枠との隙間・タブ幅・タブ数を0より大きくしてください。",
                        "Stege erfordern einen Rahmenabstand, eine Stegbreite und eine Steganzahl größer als 0."))
            }
            if options.connectBoardsWithTabs
                && ((options.columns > 1 && options.columnGapMM <= 0) || (options.rows > 1 && options.rowGapMM <= 0))
            {
                throw RoutingError.invalid(
                    L10n.text(
                        "Set positive board spacing to connect adjacent boards with tabs.",
                        "基板間をタブで接続する場合は、列・行の基板間隔も0より大きくしてください。",
                        "Stellen Sie positive Leiterplattenabstände ein, um benachbarte Leiterplatten mit Stegen zu verbinden."
                    ))
            }
        }
    }

    private static var perforationLimitError: RoutingError {
        .invalid(
            L10n.text(
                "Too many mouse-bite holes. Increase the hole pitch or reduce the tab width/count.",
                "ミシン目の穴が多すぎます。穴ピッチを大きくするか、タブ幅・タブ数を減らしてください。",
                "Zu viele Sollbruchbohrungen. Vergrößern Sie den Lochabstand oder verringern Sie die Stegbreite bzw. Steganzahl."
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
                    "The outline contains invalid or out-of-range coordinates.", "外形に不正または範囲外の座標があります。",
                    "Die Kontur enthält ungültige Koordinaten oder Koordinaten außerhalb des zulässigen Bereichs."))
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
                            "The board outline is open. Close the outline before creating routed clearances and tabs.",
                            "基板外形が閉じていません。外形を閉じてから隙間・タブを作成してください。",
                            "Die Leiterplattenkontur ist offen. Schließen Sie die Kontur, bevor Sie Frässpalte und Stege erstellen."
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
                    "No closed board outline was found.", "閉じた基板外形が見つかりません。",
                    "Es wurde keine geschlossene Leiterplattenkontur gefunden."))
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
                    "The outline has an invalid arc angle.", "外形の円弧角度が不正です。",
                    "Die Kontur enthält einen ungültigen Kreisbogenwinkel."))
        }
        let radius = (start - center).length
        guard radius > 1e-9 else { return [start] }
        let step = min(Double.pi / 18, 2 * acos(max(-1, 1 - chordToleranceMM / radius)))
        let required = ceil(abs(sweep) / step)
        guard required.isFinite, required <= Double(PanelLimits.maxArcSegments) else {
            throw RoutingError.invalid(
                L10n.text(
                    "The outline arc is too large to approximate accurately.", "外形の円弧が大きすぎるため、指定精度で近似できません。",
                    "Der Kreisbogen ist zu groß für eine ausreichend genaue Näherung."))
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
        try PanelValidation.rectangle(rect, field: "roundedRectangle.input")
        try PanelValidation.number(radius, field: "roundedRectangle.radiusMM", range: 0...PanelLimits.maxMeasurementMM)
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
    static func plan(contours: [[RoutePoint]], bounds: RouteRect, options o: PanelOptions) throws -> RoutingPlan {
        try validate(o)
        try PanelValidation.shape(PanelBoardShape(bounds: bounds, contours: contours), field: "routing.input")
        let stepX = bounds.maxX - bounds.minX + o.columnGapMM, stepY = bounds.maxY - bounds.minY + o.rowGapMM
        let arrayMaxX = bounds.maxX + Double(o.columns - 1) * stepX,
            arrayMaxY = bounds.maxY + Double(o.rows - 1) * stepY
        let inner = RouteRect(
            minX: bounds.minX - o.frameGapMM, minY: bounds.minY - o.frameGapMM,
            maxX: arrayMaxX + o.frameGapMM, maxY: arrayMaxY + o.frameGapMM)
        let outer = RouteRect(
            minX: inner.minX - o.verticalFrameMM, minY: inner.minY - o.horizontalFrameMM,
            maxX: inner.maxX + o.verticalFrameMM, maxY: inner.maxY + o.horizontalFrameMM)
        let outerLoop = try roundedRectangle(outer, radius: o.panelCornerRadiusMM)
        var boards: [[[RoutePoint]]] = []
        for row in 0..<o.rows {
            for column in 0..<o.columns {
                let offset = RoutePoint(x: Double(column) * stepX, y: Double(row) * stepY)
                boards.append(contours.map { $0.map { $0 + offset } })
            }
        }
        var bridges: [RouteRect] = []
        var mouseBites: [RoutePoint] = []
        let sourceHoles = contours.enumerated().filter { index, loop in
            guard let first = loop.first else { return false }
            return contours.enumerated().filter { $0.offset != index && pointInside(first, loop: $0.element) }.count % 2
                == 1
        }.map { $0.element }
        var holes: [[RoutePoint]] = []
        for row in 0..<o.rows {
            for column in 0..<o.columns {
                let offset = RoutePoint(x: Double(column) * stepX, y: Double(row) * stepY)
                holes += sourceHoles.map { $0.map { $0 + offset } }
            }
        }
        if o.addTabs {
            let half = o.tabWidthMM / 2
            /// EN: Return intersections [mm] of a tab cross-section with the outline. Throw if none exist.
            ///
            /// JA: タブを渡す断面と外形の交点 [mm] を返す。交点がなければ例外とする。
            ///
            /// DE: Schnittpunkte [mm] eines Stegquerschnitts mit der Kontur zurückgeben. Bei fehlenden Schnittpunkten
            ///     einen Fehler auslösen.
            func crossing(_ board: [[RoutePoint]], value: Double, horizontal: Bool, maximum: Bool) throws -> Double {
                var intersections: [Double] = []
                for edge in board.flatMap({ edges($0) }) {
                    let a = horizontal ? edge.a.y : edge.a.x, b = horizontal ? edge.b.y : edge.b.x
                    if (a <= value && b > value) || (b <= value && a > value) {
                        let t = (value - a) / (b - a)
                        intersections.append(
                            horizontal ? edge.a.x + t * (edge.b.x - edge.a.x) : edge.a.y + t * (edge.b.y - edge.a.y))
                    }
                }
                guard let result = maximum ? intersections.max() : intersections.min() else {
                    throw RoutingError.invalid(
                        L10n.text(
                            "A tab position does not intersect the board. Reduce the tab count or change the outline.",
                            "タブ位置が基板と交差しません。タブ数または基板外形を調整してください。",
                            "Eine Stegposition schneidet die Leiterplatte nicht. Verringern Sie die Steganzahl oder ändern Sie die Kontur."
                        ))
                }
                return result
            }
            /// EN: Generate hole centers at the configured pitch [mm]. Limit subdivision and total hole counts before
            ///     integer conversion.
            ///
            /// JA: 設定済みピッチ [mm] で穴中心を生成する。整数変換前に分割数と総穴数を制限する。
            ///
            /// DE: Bohrungsmittelpunkte im eingestellten Mittenabstand [mm] erzeugen. Unterteilungen und
            ///     Gesamtbohrungsanzahl vor der Ganzzahlumwandlung begrenzen.
            func perforate(board: [[RoutePoint]]?, center: Double, horizontal: Bool, maximum: Bool, fixed: Double = 0)
                throws
            {
                guard o.perforateTabs else { return }
                let intervals = max(1, Int(floor(o.tabWidthMM / o.mouseBitePitchMM)))
                guard mouseBites.count <= PanelLimits.maxGeneratedHoles - intervals - 1 else {
                    throw perforationLimitError
                }
                for i in 0...intervals {
                    let transverse = center + (Double(i) - Double(intervals) / 2) * o.mouseBitePitchMM
                    let along =
                        try board.map { try crossing($0, value: transverse, horizontal: horizontal, maximum: maximum) }
                        ?? fixed
                    mouseBites.append(
                        horizontal ? RoutePoint(x: along, y: transverse) : RoutePoint(x: transverse, y: along))
                }
            }
            for row in 0..<o.rows {
                for column in 0..<o.columns {
                    let board = boards[row * o.columns + column]
                    for index in 1...o.tabsPerEdge {
                        let fraction = Double(index) / Double(o.tabsPerEdge + 1)
                        let y = bounds.minY + Double(row) * stepY + (bounds.maxY - bounds.minY) * fraction
                        let x = bounds.minX + Double(column) * stepX + (bounds.maxX - bounds.minX) * fraction
                        if half >= min(bounds.maxX - bounds.minX, bounds.maxY - bounds.minY) / Double(o.tabsPerEdge + 1)
                            / 2
                        {
                            throw RoutingError.invalid(
                                L10n.text(
                                    "The tabs are too wide for this board and tab count.", "この基板寸法とタブ数に対してタブ幅が大きすぎます。",
                                    "Die Stege sind für diese Leiterplattenabmessungen und Steganzahl zu breit."))
                        }
                        if column == 0 && o.tabsLeft {
                            bridges.append(
                                RouteRect(
                                    minX: inner.minX - 0.01, minY: y - half,
                                    maxX: try crossing(board, value: y, horizontal: true, maximum: false)
                                        + o.tabWidthMM, maxY: y + half))
                        }
                        if column == o.columns - 1 && o.tabsRight {
                            bridges.append(
                                RouteRect(
                                    minX: try crossing(board, value: y, horizontal: true, maximum: true) - o.tabWidthMM,
                                    minY: y - half, maxX: inner.maxX + 0.01, maxY: y + half))
                        }
                        if row == 0 && o.tabsTop {
                            bridges.append(
                                RouteRect(
                                    minX: x - half, minY: inner.minY - 0.01, maxX: x + half,
                                    maxY: try crossing(board, value: x, horizontal: false, maximum: false)
                                        + o.tabWidthMM))
                        }
                        if row == o.rows - 1 && o.tabsBottom {
                            bridges.append(
                                RouteRect(
                                    minX: x - half,
                                    minY: try crossing(board, value: x, horizontal: false, maximum: true)
                                        - o.tabWidthMM, maxX: x + half, maxY: inner.maxY + 0.01))
                        }
                        if o.connectBoardsWithTabs && column + 1 < o.columns {
                            let next = boards[row * o.columns + column + 1]
                            bridges.append(
                                RouteRect(
                                    minX: try crossing(board, value: y, horizontal: true, maximum: true) - o.tabWidthMM,
                                    minY: y - half,
                                    maxX: try crossing(next, value: y, horizontal: true, maximum: false) + o.tabWidthMM,
                                    maxY: y + half))
                        }
                        if o.connectBoardsWithTabs && row + 1 < o.rows {
                            let next = boards[(row + 1) * o.columns + column]
                            bridges.append(
                                RouteRect(
                                    minX: x - half,
                                    minY: try crossing(board, value: x, horizontal: false, maximum: true)
                                        - o.tabWidthMM,
                                    maxX: x + half,
                                    maxY: try crossing(next, value: x, horizontal: false, maximum: false) + o.tabWidthMM
                                ))
                        }
                        if column == 0 && o.tabsLeft {
                            try perforate(board: board, center: y, horizontal: true, maximum: false)
                            try perforate(board: nil, center: y, horizontal: true, maximum: false, fixed: inner.minX)
                        }
                        if column == o.columns - 1 && o.tabsRight {
                            try perforate(board: board, center: y, horizontal: true, maximum: true)
                            try perforate(board: nil, center: y, horizontal: true, maximum: true, fixed: inner.maxX)
                        }
                        if row == 0 && o.tabsTop {
                            try perforate(board: board, center: x, horizontal: false, maximum: false)
                            try perforate(board: nil, center: x, horizontal: false, maximum: false, fixed: inner.minY)
                        }
                        if row == o.rows - 1 && o.tabsBottom {
                            try perforate(board: board, center: x, horizontal: false, maximum: true)
                            try perforate(board: nil, center: x, horizontal: false, maximum: true, fixed: inner.maxY)
                        }
                        if o.connectBoardsWithTabs && column + 1 < o.columns {
                            try perforate(board: board, center: y, horizontal: true, maximum: true)
                            try perforate(
                                board: boards[row * o.columns + column + 1], center: y, horizontal: true, maximum: false
                            )
                        }
                        if o.connectBoardsWithTabs && row + 1 < o.rows {
                            try perforate(board: board, center: x, horizontal: false, maximum: true)
                            try perforate(
                                board: boards[(row + 1) * o.columns + column], center: x, horizontal: false,
                                maximum: false)
                        }
                    }
                }
            }
        }
        let segments =
            boards.flatMap { $0.flatMap { edges($0) } } + edges(inner.points) + edges(outerLoop)
            + bridges.flatMap { edges($0.points) }
        let boardBoxes = boards.map { board -> RouteRect in
            let points = board.flatMap { $0 }
            return RouteRect(
                minX: points.map(\.x).min()!, minY: points.map(\.y).min()!, maxX: points.map(\.x).max()!,
                maxY: points.map(\.y).max()!)
        }
        /// EN: Return whether material remains at validated coordinates, considering the frame, boards, tabs and
        ///     cutouts.
        ///
        /// JA: 検証済みの座標で材料が残るか返す。外枠・基板・タブと切り抜きの関係を評価する。
        ///
        /// DE: Prüfen, ob an geprüften Koordinaten Material verbleibt; Rahmen, Platinen, Stege und Ausschnitte
        ///     berücksichtigen.
        func material(_ p: RoutePoint) -> Bool {
            if holes.contains(where: { pointInside(p, loop: $0) }) { return false }
            guard pointInside(p, loop: outerLoop) else { return false }
            if !inner.contains(p) { return true }
            if bridges.contains(where: { $0.contains(p) }) { return true }
            for index in boards.indices where boardBoxes[index].contains(p) {
                let board = boards[index]
                var inside = false
                for loop in board where pointInside(p, loop: loop) { inside.toggle() }
                if inside { return true }
            }
            return false
        }
        var seen: Set<String> = []
        let uniqueHoles = mouseBites.filter {
            seen.insert("\(($0.x * 1e6).rounded()),\(($0.y * 1e6).rounded())").inserted
        }
        let result = RoutingPlan(segments: try unionBoundary(segments, material: material), mouseBites: uniqueHoles)
        try PanelValidation.routing(result, inside: outer)
        return result
    }

    /// EN: Routing for heterogeneous boards already translated into panel coordinates. Split each side into visible
    ///     spans so bridges never run through another board.
    ///
    /// JA: パネル座標へ移動済みの異種基板の加工線を生成する。各辺を有効な区間に分割し、接続タブが他の基板を横切らないようにする。
    ///
    /// DE: Fräsdaten für unterschiedliche, bereits in Panelkoordinaten verschobene Platinen erzeugen. Jede Seite in
    ///     nutzbare Abschnitte unterteilen, damit Stege keine andere Platine durchqueren.
    static func plan(boards: [[[RoutePoint]]], arrayBounds: RouteRect, options o: PanelOptions) throws -> RoutingPlan {
        try validate(o)
        guard !boards.isEmpty, boards.allSatisfy({ !$0.isEmpty && $0.allSatisfy { $0.count >= 3 } }) else {
            throw RoutingError.invalid(
                L10n.text(
                    "No closed board outline was found.", "閉じた基板外形が見つかりません。",
                    "Es wurde keine geschlossene Leiterplattenkontur gefunden."))
        }
        try validatePoints(boards.flatMap { $0.flatMap { $0 } })
        let boxes = boards.map { board -> RouteRect in
            let points = board.flatMap { $0 }
            return RouteRect(
                minX: points.map(\.x).min()!, minY: points.map(\.y).min()!,
                maxX: points.map(\.x).max()!, maxY: points.map(\.y).max()!)
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
                        "A tab does not intersect the board outline. Reduce the tab width or change the layout.",
                        "タブが基板外形と交差しません。タブ幅を小さくするか、配置を変更してください。",
                        "Ein Steg schneidet die Leiterplattenkontur nicht. Verringern Sie die Stegbreite oder ändern Sie die Anordnung."
                    ))
            }
            return hit
        }
        if o.addTabs {
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
                        for span in spans {
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
                                let alongLow = min(start, end) - 0.01, alongHigh = max(start, end) + 0.01
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
            guard boards.indices.allSatisfy({ reached.contains($0) }) else {
                throw RoutingError.invalid(
                    L10n.text(
                        "Some boards cannot connect to the frame with these tabs. Enable more frame sides, connect adjacent boards, or reduce the tab width.",
                        "現在のタブ設定では外枠に繋がらない基板があります。接続辺や基板間タブを有効にするか、タブ幅を小さくしてください。",
                        "Einige Leiterplatten können mit diesen Stegen nicht mit dem Rahmen verbunden werden. Aktivieren Sie weitere Rahmenseiten oder Verbindungen zwischen Leiterplatten, oder verringern Sie die Stegbreite."
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
        let uniqueBites = bites.filter { seen.insert("\(($0.x * 1e6).rounded()),\(($0.y * 1e6).rounded())").inserted }
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
                let keys = ["\(start.x),\(start.y)", "\(end.x),\(end.y)"].sorted()
                if start != end && seen.insert(keys.joined(separator: ":")).inserted {
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
                .split(whereSeparator: { $0 == "-" || $0 == "_" }).first.map(String.init) ?? ""
            if ["en", "ja", "de"].contains(code) { return code }
        }
        return "en"
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
        case "ja": return japanese
        case "de": return german
        default: return english
        }
    }
}
