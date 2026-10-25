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
import Darwin

// EN: String/character literals are defined in TextConstants.Composition, Common and Characters; variable text uses constant templates.
// JA: 文字列・文字リテラルはTextConstants.Composition・Common・Charactersに定義し、可変文は定数テンプレートから生成する。
// DE: Zeichenketten-/Zeichenliterale stehen in TextConstants.Composition, Common und Characters; variable Texte nutzen konstante Vorlagen.

enum BoardKind {
    case eagle
    case kicad
    var title: String { self == .eagle ? TextConstants.Composition.tokenEAGLE : TextConstants.Composition.tokenKiCad }
}

struct PanelSource {
    let name: String
    let data: Data
    let kind: BoardKind
}

extension PanelOptions {
    /// EN: Normalize multiple inputs so each board is placed once. The caller checks the range.
    ///
    /// JA: 複数入力では各基板を1回ずつ配置する行列数へ正規化する。範囲チェックは呼び出し元で行う。
    ///
    /// DE: Mehrere Eingaben so normalisieren, dass jede Platine einmal platziert wird. Der Aufrufer prüft den
    ///     Wertebereich.
    func forSourceCount(_ count: Int) -> PanelOptions {
        guard count > 1 else { return self }
        var result = self
        result.columns = min(max(1, columns), count)
        result.rows = (count + result.columns - 1) / result.columns
        return result
    }
}

struct PanelBoardShape {
    let bounds: RouteRect
    let contours: [[RoutePoint]]
    /// EN: Original straight outline segments [mm]; exclude tessellated arcs and circles.
    /// JA: 元データの直線外形 [mm]。円弧や円を近似した線分は含めない。
    /// DE: Ursprüngliche gerade Kontursegmente [mm]; angenäherte Kreisbögen und Kreise ausschließen.
    var straightEdges: [RouteSegment] = []
}

struct PanelPlacement {
    let sourceIndex: Int
    let row: Int
    let column: Int
    let offset: RoutePoint
    let bounds: RouteRect
}

/// EN: Multiple sources are placed once each, in import order. Rows grow to fit; each row uses its tallest board and
///     each board uses its own outline width.
///
/// JA: 複数の入力基板を読み込み順に1回ずつ配置する。必要に応じて行数を増やし、行の高さはその行で最も高い基板、各基板の幅は自身の外形幅を使う。
///
/// DE: Mehrere Eingabeplatinen jeweils einmal in Einlesereihenfolge platzieren. Die Zeilenzahl wächst nach Bedarf;
///     jede Zeile nutzt die größte Platinenhöhe und jede Platine ihre eigene Konturbreite.
struct PanelCompositionLayout {
    let placements: [PanelPlacement]
    let arrayBounds: RouteRect
    let panelBounds: RouteRect
    let rowCount: Int

    init(bounds: [RouteRect], options: PanelOptions) throws {
        let options = options.forSourceCount(bounds.count)
        try PanelRouting.validate(options)
        guard !bounds.isEmpty, options.columns > 0, options.rows > 0 else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Composition.addABoardAndSetAtLeastOneRowEnglish,
                    TextConstants.Composition.addABoardAndSetAtLeastOneRowJapanese,
                    TextConstants.Composition.addABoardAndSetAtLeastOneRowGerman))
        }
        let measurements = [
            options.columnGapMM, options.rowGapMM, options.verticalFrameMM, options.horizontalFrameMM,
            options.dimensionLineWidthMM, options.vScoreLineWidthMM, options.mountingHoleOffsetXMM,
            options.mountingHoleOffsetYMM, options.mountingHoleDrillMM,
        ]
        guard measurements.allSatisfy({ $0.isFinite && $0 >= 0 }),
            !options.addMountingHoles || options.mountingHoleDrillMM > 0
        else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Composition.panelMeasurementsMustBeFiniteAndNonnegativeTheMountingEnglish,
                    TextConstants.Composition.panelMeasurementsMustBeFiniteAndNonnegativeTheMountingJapanese,
                    TextConstants.Composition.panelMeasurementsMustBeFiniteAndNonnegativeTheMountingGerman
                ))
        }
        guard
            bounds.allSatisfy({
                [$0.minX, $0.minY, $0.maxX, $0.maxY].allSatisfy(\.isFinite) && $0.maxX > $0.minX && $0.maxY > $0.minY
            })
        else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Composition.aBoardHasInvalidOutlineDimensionsEnglish,
                    TextConstants.Composition.aBoardHasInvalidOutlineDimensionsJapanese,
                    TextConstants.Composition.aBoardHasInvalidOutlineDimensionsGerman))
        }
        try PanelRouting.validatePoints(bounds.flatMap(\.points))
        let indices =
            bounds.count == 1 ? Array(repeating: 0, count: options.columns * options.rows) : Array(bounds.indices)
        let columns = min(options.columns, indices.count)
        let rows = (indices.count + columns - 1) / columns
        var placed: [PanelPlacement] = []
        var y = 0.0
        var width = 0.0
        for row in 0..<rows {
            let items = Array(indices[(row * columns)..<min(indices.count, (row + 1) * columns)])
            let height = items.map { bounds[$0].maxY - bounds[$0].minY }.max()!
            var x = 0.0
            for (column, source) in items.enumerated() {
                let b = bounds[source]
                let w = b.maxX - b.minX, h = b.maxY - b.minY
                placed.append(
                    PanelPlacement(
                        sourceIndex: source, row: row, column: column,
                        offset: RoutePoint(x: x - b.minX, y: y - b.minY),
                        bounds: RouteRect(minX: x, minY: y, maxX: x + w, maxY: y + h)))
                x += w + options.columnGapMM
            }
            width = max(width, x - options.columnGapMM)
            y += height + options.rowGapMM
        }
        placements = placed
        rowCount = rows
        arrayBounds = RouteRect(minX: 0, minY: 0, maxX: width, maxY: y - options.rowGapMM)
        panelBounds = RouteRect(
            minX: -options.verticalFrameMM - options.frameGapMM,
            minY: -options.horizontalFrameMM - options.frameGapMM,
            maxX: width + options.verticalFrameMM + options.frameGapMM,
            maxY: y - options.rowGapMM + options.horizontalFrameMM + options.frameGapMM)
        try PanelValidation.rectangle(arrayBounds, field: TextConstants.Composition.tokenLayoutArrayBounds)
        try PanelValidation.rectangle(panelBounds, field: TextConstants.Composition.tokenLayoutPanelBounds)
        try PanelValidation.mountingHoles(
            width: panelBounds.maxX - panelBounds.minX, height: panelBounds.maxY - panelBounds.minY, options: options)
    }

    /// EN: Validate outline/sourceIndex associations and ensure all transformed points lie within their placement
    ///     rectangles.
    ///
    /// JA: 入力外形とsourceIndexの対応を検証し、配置後の全点が各配置矩形内にあることを確認して返す。
    ///
    /// DE: Die Zuordnung zwischen Konturen und sourceIndex prüfen und sicherstellen, dass alle transformierten Punkte
    ///     innerhalb ihrer Platzierungsrechtecke liegen.
    ///
    /// - Parameter shapes:
    ///   EN: Outlines in source coordinates; include every board referenced by placements.
    ///   JA: 元座標系の外形。placementsが参照する全基板を含める。
    ///   DE: Konturen in Quellkoordinaten; alle von placements referenzierten Platinen einschließen.
    ///
    /// - Returns:
    ///   EN: Outlines in panel coordinates [mm], in the same order as placements.
    ///   JA: パネル座標系 [mm] の外形配列。要素順序はplacementsと同じ。
    ///   DE: Konturen in Panelkoordinaten [mm] in derselben Reihenfolge wie placements.
    func placedContours(_ shapes: [PanelBoardShape]) throws -> [[[RoutePoint]]] {
        guard placements.allSatisfy({ shapes.indices.contains($0.sourceIndex) }) else {
            throw PanelValidation.invalid(
                TextConstants.Composition.tokenPlacedContoursShapes,
                TextConstants.Composition.textAllPlacementSourceIndexesExist)
        }
        for shape in shapes {
            try PanelValidation.shape(shape, field: TextConstants.Composition.tokenPlacedContoursInput)
        }
        let result = placements.map { placement in
            shapes[placement.sourceIndex].contours.map { $0.map { $0 + placement.offset } }
        }
        for (index, contours) in result.enumerated() {
            try PanelValidation.validateContained(
                contours.flatMap { $0 }, in: placements[index].bounds,
                field: TextConstants.Composition.tokenPlacedContoursOutput)
        }
        return result
    }

    /// EN: Translate original straight segments into each placement [mm], retaining their distinction from curves.
    /// JA: 元の直線外形を各配置座標 [mm] へ移動し、曲線との区別を維持する。
    /// DE: Ursprüngliche gerade Kontursegmente in jede Platzierung [mm] verschieben und von Kurven unterscheiden.
    func placedStraightEdges(_ shapes: [PanelBoardShape]) throws -> [[RouteSegment]] {
        guard placements.allSatisfy({ shapes.indices.contains($0.sourceIndex) }) else {
            throw PanelValidation.invalid(
                TextConstants.Composition.tokenPlacedStraightEdgesShapes,
                TextConstants.Composition.textAllPlacementSourceIndexesExist)
        }
        for shape in shapes {
            try PanelValidation.shape(shape, field: TextConstants.Composition.tokenPlacedStraightEdgesInput)
        }
        return try placements.map { placement in
            let segments = shapes[placement.sourceIndex].straightEdges.map {
                RouteSegment(a: $0.a + placement.offset, b: $0.b + placement.offset)
            }
            try PanelValidation.validateContained(
                segments.flatMap { [$0.a, $0.b] }, in: placement.bounds,
                field: TextConstants.Composition.tokenPlacedStraightEdgesOutput)
            return segments
        }
    }

    /// EN: Full-panel V-score guides must stay in gaps for their entire length. Only emit a guide if no board
    ///     bounding box crosses it.
    ///
    /// JA: パネル全体を横断するVカットガイドは、全長にわたって隙間内にある必要がある。基板の外接矩形と交差しないガイドだけを出力する。
    ///
    /// DE: Durchgehende V-Nut-Hilfslinien müssen über ihre gesamte Länge in Zwischenräumen liegen. Nur Linien
    ///     ausgeben, die kein Platinenbegrenzungsrechteck schneiden.
    func guides(options: PanelOptions) throws -> [RouteSegment] {
        try PanelRouting.validate(options)
        guard options.addVScoreSeparators else { return [] }
        var result: [RouteSegment] = []
        var seen = Set<String>()
        for a in placements {
            for b in placements where b.row == a.row && b.column == a.column + 1 {
                let x = (a.bounds.maxX + b.bounds.minX) / 2
                if !placements.contains(where: { $0.bounds.minX < x - 1e-7 && $0.bounds.maxX > x + 1e-7 }),
                    seen.insert(TextConstants.Composition.tokenXTemplate(x)).inserted
                {
                    result.append(
                        RouteSegment(a: RoutePoint(x: x, y: panelBounds.minY), b: RoutePoint(x: x, y: panelBounds.maxY))
                    )
                }
            }
        }
        let rows = Dictionary(grouping: placements, by: \.row)
        for row in 0..<max(0, rowCount - 1) {
            guard let current = rows[row], let next = rows[row + 1] else { continue }
            let y = (current.map { $0.bounds.maxY }.max()! + next.map { $0.bounds.minY }.min()!) / 2
            if !placements.contains(where: { $0.bounds.minY < y - 1e-7 && $0.bounds.maxY > y + 1e-7 }) {
                result.append(
                    RouteSegment(a: RoutePoint(x: panelBounds.minX, y: y), b: RoutePoint(x: panelBounds.maxX, y: y)))
            }
        }
        try PanelValidation.validateContained(
            result.flatMap { [$0.a, $0.b] }, in: panelBounds, field: TextConstants.Composition.tokenGuidesOutput)
        return result
    }
}

enum PanelFileAccess {
    /// EN: Compare filesystem identity as well as paths: aliases differing only in case, symbolic links and hard
    ///     links must not bypass source protection.
    ///
    /// JA: パスに加えてファイル自体の同一性も比較する。大文字・小文字だけが異なるパス、シンボリックリンク、ハードリンクでも入力保護を迂回させない。
    ///
    /// DE: Zusätzlich zu Pfaden die Dateiidentität vergleichen. Abweichende Groß-/Kleinschreibung, symbolische Links
    ///     und Hardlinks dürfen den Schutz der Eingabedateien nicht umgehen.
    static func isSameFile(_ first: URL, _ second: URL) -> Bool {
        if first.resolvingSymlinksInPath().standardizedFileURL == second.resolvingSymlinksInPath().standardizedFileURL {
            return true
        }
        let keys: Set<URLResourceKey> = [.fileResourceIdentifierKey]
        guard let a = try? first.resourceValues(forKeys: keys).fileResourceIdentifier as? NSObject,
            let b = try? second.resourceValues(forKeys: keys).fileResourceIdentifier as? NSObject
        else { return false }
        return a.isEqual(b)
    }
}

enum PanelComposer {
    /// EN: Detect the input format and delegate to its engine. Reparse the output and compare dimensions before
    ///     returning.
    ///
    /// JA: 入力形式を判定し、適切なエンジンへ委譲する。返却前に出力の再解析と寸法照合を行う。
    ///
    /// DE: Das Eingabeformat erkennen und an die passende Engine übergeben. Die Ausgabe vor der Rückgabe erneut
    ///     parsen und ihre Abmessungen vergleichen.
    static func compose(sources: [PanelSource], options: PanelOptions) throws -> (
        data: Data, summary: PanelSummary, fileExtension: String
    ) {
        let options = options.forSourceCount(sources.count)
        guard !sources.isEmpty && sources.count <= PanelLimits.maxBoardPositions else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Composition.addABoardFileFirstEnglish,
                    TextConstants.Composition.addABoardFileFirstJapanese,
                    TextConstants.Composition.addABoardFileFirstGerman))
        }
        if sources.allSatisfy({ $0.kind == .eagle }) {
            let result = try EaglePanelEngine.compose(sources: sources, options: options)
            try validateExport(result.0, summary: result.1, options: options, kind: .eagle)
            return (result.0, result.1, TextConstants.Common.tokenBrd)
        }
        let converted = try sources.map { source -> Data in
            if source.kind == .kicad { return source.data }
            return try KiCadImporter.convertEagle(source)
        }
        let result = try KiCadPanelEngine.compose(
            data: converted, options: options, baseIndex: sources.firstIndex(where: { $0.kind == .kicad }) ?? 0)
        try validateExport(result.0, summary: result.1, options: options, kind: .kicad)
        return (result.0, result.1, TextConstants.Common.tokenKicadPcb)
    }
    /// EN: Reparse returned board data and compare reported dimensions with actual outline dimensions [mm].
    ///
    /// JA: 戻り値の基板データを再解析し、報告寸法と実際の外形寸法 [mm] が一致するか確認する。
    ///
    /// DE: Zurückgegebene Platinendaten erneut parsen und gemeldete Abmessungen mit den tatsächlichen
    ///     Konturabmessungen [mm] vergleichen.
    private static func validateExport(_ data: Data, summary: PanelSummary, options: PanelOptions, kind: BoardKind)
        throws
    {
        _ = try PanelValidation.output(data, summary: summary, options: options)
        let shape = try kind == .eagle ? EaglePanelEngine.shape(data: data) : KiCadPanelEngine.shape(data: data)
        let b = shape.bounds
        let tolerance = PanelLimits.boundsToleranceMM
        guard
            abs((b.maxX - b.minX) - summary.panelWidthMM) <= tolerance
                && abs((b.maxY - b.minY) - summary.panelHeightMM) <= tolerance
        else {
            throw PanelValidation.invalid(
                TextConstants.Composition.tokenPanelComposerOutputSummary,
                TextConstants.Composition.textMatchesSerializedBoardOutline)
        }
    }

}

/// EN: Use KiCad's maintained EAGLE importer for cross-format panels instead of approximating copper, pads, mirrored
///     footprints or drill features ourselves.
///
/// JA: 異種形式の面付けではKiCadが保守するEAGLEインポーターを使い、銅箔・パッド・反転フットプリント・穴を独自に近似変換しない。
///
/// DE: Für Panels aus unterschiedlichen Formaten den gepflegten EAGLE-Importer von KiCad verwenden, um Kupfer, Pads,
///     gespiegelte Footprints und Bohrungen korrekt zu übernehmen.
enum KiCadImporter {
    static var executable: URL? {
        let fm = FileManager.default
        let homes = [
            URL(fileURLWithPath: TextConstants.Composition.systemApplicationsDirectory),
            fm.homeDirectoryForCurrentUser.appendingPathComponent(TextConstants.Composition.applicationsFolderName),
        ]
        var candidates = homes.flatMap { home in
            [
                home.appendingPathComponent(TextConstants.Composition.tokenKiCadKiCadAppContentsMacOSKicadCli),
                home.appendingPathComponent(TextConstants.Composition.tokenKiCadAppContentsMacOSKicadCli),
            ]
        }
        candidates += [
            URL(fileURLWithPath: TextConstants.Composition.tokenOptHomebrewBinKicadCli),
            URL(fileURLWithPath: TextConstants.Composition.tokenUsrLocalBinKicadCli),
        ]
        return candidates.first { fm.isExecutableFile(atPath: $0.path) }
    }

    /// EN: Do not delete temporary files or close the log while the child can still write to them. Some CLI failures
    ///     ignore the initial SIGTERM.
    ///
    /// JA: 子プロセスが書き込める間は、一時ファイルを削除したりログを閉じたりしない。CLIの障害によっては最初のSIGTERMを無視する。
    ///
    /// DE: Temporäre Dateien und das Protokoll offen halten, solange der Kindprozess noch schreiben kann. Manche
    ///     CLI-Fehler ignorieren das erste SIGTERM.
    static func terminateAndWait(_ process: Process, finished: DispatchSemaphore, gracePeriod: Double = 2) {
        guard process.isRunning else { process.waitUntilExit(); return }
        // EN: Cleanup wait time [seconds]. Continue reaping the child even if the caller supplied an invalid value.
        // JA: 後始末用の待機時間 [秒]。呼び出し側の異常値でも子プロセスの回収を継続する。
        // DE: Wartezeit für die Bereinigung [Sekunden]. Den Kindprozess auch bei einem ungültigen Aufruferwert weiter
        //     einsammeln.
        let grace = gracePeriod.isFinite ? min(5, max(0, gracePeriod)) : 2
        process.terminate()
        if finished.wait(timeout: .now() + grace) == .timedOut, process.isRunning {
            _ = kill(process.processIdentifier, SIGKILL)
        }
        process.waitUntilExit()
    }

    /// EN: Convert a validated temporary EAGLE copy using KiCad. Check exit status, files and normalization before
    ///     returning.
    ///
    /// JA: 検証したEAGLEの一時コピーをKiCadで変換する。終了状態・ファイル・正規化結果を確認して返す。
    ///
    /// DE: Eine geprüfte temporäre EAGLE-Kopie mit KiCad konvertieren. Vor der Rückgabe Exitstatus, Dateien und
    ///     Normalisierung prüfen.
    static func convertEagle(_ source: PanelSource) throws -> Data {
        guard let executable else {
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Composition.combiningEAGLEAndKiCadBoardsRequiresKiCadOrLaterEnglish,
                    TextConstants.Composition.combiningEAGLEAndKiCadBoardsRequiresKiCadOrLaterJapanese,
                    TextConstants.Composition.combiningEAGLEAndKiCadBoardsRequiresKiCadOrLaterGerman
                ))
        }
        let fm = FileManager.default
        let work = fm.temporaryDirectory.appendingPathComponent(
            TextConstants.Composition.tokenSwiftPCBPanelizerImport + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: work) }
        let input = work.appendingPathComponent(TextConstants.Composition.tokenSourceBrd),
            output = work.appendingPathComponent(TextConstants.Composition.tokenConvertedKicadPcb)
        try EaglePanelEngine.preparedForKiCadImport(data: source.data).write(to: input)
        let log = work.appendingPathComponent(TextConstants.Composition.tokenImportLog)
        fm.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        defer { try? handle.close() }
        let process = Process()
        process.executableURL = executable
        process.arguments = [
            TextConstants.Common.tokenPcb, TextConstants.Composition.tokenImport, TextConstants.Composition.tokenFormat,
            TextConstants.Common.tokenEagle, TextConstants.Common.tokenOutput, output.path, input.path,
        ]
        process.standardOutput = handle
        process.standardError = handle
        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in finished.signal() }
        try process.run()
        if finished.wait(timeout: .now() + 120) == .timedOut {
            terminateAndWait(process, finished: finished)
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Composition.kicadTookTooLongToImportSourceNameEnglishTemplate(source.name),
                    TextConstants.Composition.kicadTookTooLongToImportSourceNameJapaneseTemplate(source.name),
                    TextConstants.Composition.kicadTookTooLongToImportSourceNameGermanTemplate(source.name)))
        }
        guard process.terminationStatus == 0, fm.fileExists(atPath: output.path) else {
            let reason = (try? String(contentsOf: log, encoding: .utf8)) ?? TextConstants.Common.empty
            throw RoutingError.invalid(
                L10n.text(
                    TextConstants.Composition.cannotConvertSourceNameKiCadOrLaterWithPcbEnglishTemplate(
                        source.name, reason.suffix(2000)),
                    TextConstants.Composition.cannotConvertSourceNameKiCadOrLaterWithPcbJapaneseTemplate(
                        source.name, reason.suffix(2000)),
                    TextConstants.Composition.cannotConvertSourceNameKiCadOrLaterWithPcbGermanTemplate(
                        source.name, reason.suffix(2000))
                ))
        }
        let converted = try Data(contentsOf: output)
        return try KiCadPanelEngine.normalizeLayers(data: converted, repairImportedAnnotations: true)
    }
}
