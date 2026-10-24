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

// EN: Compile alongside the engine, routing and composition sources. Fixtures cover document parsing, output
//     geometry, language selection and failure handling.
// JA: エンジン・加工線・配置処理のソースと一緒にコンパイルする。フィクスチャで文書解析・出力形状・言語選択・エラー処理を確認する。
// DE: Zusammen mit den Engine-, Fräs- und Anordnungsquellen kompilieren. Die Testdaten decken Dokumentparsing,
//     Ausgabegeometrie, Sprachauswahl und Fehlerbehandlung ab.
@main
struct ParserRegression {
    static func main() async throws {
        if CommandLine.arguments.contains("--expect-en") {
            precondition(L10n.text("English", "日本語", "Deutsch") == "English")
        }
        if CommandLine.arguments.contains("--expect-ja") {
            precondition(L10n.text("English", "日本語", "Deutsch") == "日本語")
        }
        if CommandLine.arguments.contains("--expect-de") {
            precondition(L10n.text("English", "日本語", "Deutsch") == "Deutsch")
        }
        try verifyInputValidation()
        try verifySafetyFixes()
        try verifyContracts()
        try verifyMultilayerPanels()
        await verifyPreviewCancellation()
        if CommandLine.arguments.contains("--input-validation-only") { return }
        try verifySilkPreservation()
        if CommandLine.arguments.contains("--samples") { try verifySampleExports() }
        let eagle = """
            <?xml version="1.0" encoding="UTF-8"?>
            <eagle version="9.6.2"><drawing>
              <settings><setting alwaysvectorfont="yes"/></settings>
              <grid distance="1"/>
              <board><plain>
                <wire x1="0" y1="0" x2="20" y2="0" width="0" layer="20"/>
                <wire x1="20" y1="0" x2="20" y2="30" width="0" layer="20"/>
                <wire x1="20" y1="30" x2="0" y2="30" width="0" layer="20"/>
                <wire x1="0" y1="30" x2="0" y2="0" width="0" layer="20"/>
              </plain><elements><element name="U1" x="5" y="6"/></elements>
              <signals><signal name="GND"><contactref element="U1" pad="1"/></signal></signals>
              </board></drawing></eagle>
            """
        let (eagleOutput, eagleSummary) = try EaglePanelEngine.panelize(data: Data(eagle.utf8), options: PanelOptions())
        precondition(eagleSummary.boardWidthMM == 20 && eagleSummary.boardHeightMM == 30)
        let document = try XMLDocument(data: eagleOutput)
        let boards = try document.nodes(forXPath: "/eagle/drawing/board")
        let grids = try document.nodes(forXPath: "/eagle/drawing/grid")
        precondition(boards.count == 1 && grids.count == 1)
        let elements = try document.nodes(forXPath: "/eagle/drawing/board/elements/element")
        precondition(elements.count == 4)
        let names = Set(elements.compactMap { ($0 as? XMLElement)?.attribute(forName: "name")?.stringValue })
        for reference in try document.nodes(forXPath: "/eagle/drawing/board/signals/signal/contactref") {
            let target = (reference as! XMLElement).attribute(forName: "element")!.stringValue!
            precondition(names.contains(target))
        }

        let kicad = """
            (kicad_pcb (version 20260206) (generator "pcbnew")
              (footprint "Fixture" (at 12 22)
                (uuid "11111111-1111-4111-8111-111111111111")
                (property "Reference" "U1" (at 0 -2))
                (pad "1" smd rect (at 1 2) (size 1 1) (layers "F.Cu")))
              (gr_rect (start 10 20) (end 30 50) (layer "Edge.Cuts")
                (uuid "22222222-2222-4222-8222-222222222222")))
            """
        let (kiCadOutput, kiCadSummary) = try KiCadPanelEngine.panelize(data: Data(kicad.utf8), options: PanelOptions())
        precondition(kiCadSummary.boardWidthMM == 20 && kiCadSummary.boardHeightMM == 30)
        precondition(kiCadSummary.panelWidthMM == 40 && kiCadSummary.panelHeightMM == 60)
        let outputText = String(decoding: kiCadOutput, as: UTF8.self)
        precondition(
            outputText.components(separatedBy: "(at 1 2)").count - 1 == 4,
            "Pad positions must remain local to their footprints")
        let (_, roundTripSummary) = try KiCadPanelEngine.panelize(
            data: kiCadOutput, options: PanelOptions(columns: 1, rows: 1))
        precondition(roundTripSummary.boardWidthMM == 40 && roundTripSummary.boardHeightMM == 60)
        var routedOptions = PanelOptions()
        routedOptions.panelCornerRadiusMM = 0
        routedOptions.horizontalFrameMM = 5; routedOptions.verticalFrameMM = 5
        routedOptions.frameGapMM = 2; routedOptions.columnGapMM = 3; routedOptions.rowGapMM = 3
        routedOptions.addTabs = true; routedOptions.tabWidthMM = 2; routedOptions.tabsPerEdge = 1
        let bounds = RouteRect(minX: 0, minY: 0, maxX: 20, maxY: 30)
        let routed = try PanelRouting.make(contours: [bounds.points], bounds: bounds, options: routedOptions)
        let loops = try PanelRouting.closedLoops(routed)
        func solid(_ p: RoutePoint) -> Bool { loops.filter { PanelRouting.pointInside(p, loop: $0) }.count % 2 == 1 }
        precondition(solid(RoutePoint(x: -4, y: 15)), "Frame rail must retain material")
        precondition(solid(RoutePoint(x: -1, y: 15)), "The tab must connect across the frame clearance")
        precondition(!solid(RoutePoint(x: -1, y: 5)), "The frame clearance must be routed away from tabs")
        precondition(solid(RoutePoint(x: 21.5, y: 15)), "Adjacent board tabs must retain material")
        precondition(!solid(RoutePoint(x: 21.5, y: 5)), "Board gaps must be routed away from tabs")
        let area = routed.reduce(0.0) { $0 + ($1.a.x * $1.b.y - $1.b.x * $1.a.y) / 2 }
        precondition(abs(area - 3696) < 0.0001, "Routing must preserve the exact frame, board and tab area")
        let hole = RouteRect(minX: 0.5, minY: 14.5, maxX: 1.5, maxY: 15.5)
        let withHole = try PanelRouting.make(
            contours: [bounds.points, hole.points], bounds: bounds, options: routedOptions)
        let holeLoops = try PanelRouting.closedLoops(withHole)
        precondition(
            holeLoops.filter { PanelRouting.pointInside(RoutePoint(x: 1, y: 15), loop: $0) }.count % 2 == 0,
            "Tabs must not fill board cutouts")
        let (_, routedSummary) = try KiCadPanelEngine.panelize(data: Data(kicad.utf8), options: routedOptions)
        precondition(routedSummary.panelWidthMM == 57 && routedSummary.panelHeightMM == 77)
        let perforated = try PanelRouting.plan(contours: [bounds.points], bounds: bounds, options: routedOptions)
        precondition(
            perforated.mouseBites.count == 72, "Each bridge needs two perforation rows with the configured pitch")
        precondition(perforated.mouseBites.contains(RoutePoint(x: -2, y: 15)))
        precondition(perforated.mouseBites.contains(RoutePoint(x: 0, y: 15)))
        precondition(perforated.mouseBites.contains(RoutePoint(x: 20, y: 15)))
        var unperforated = routedOptions; unperforated.perforateTabs = false
        precondition(tryPlan(bounds: bounds, options: unperforated).mouseBites.isEmpty)
        var roundedOptions = routedOptions; roundedOptions.panelCornerRadiusMM = 2
        let rounded = try PanelRouting.plan(contours: [bounds.points], bounds: bounds, options: roundedOptions)
        let roundedLoops = try PanelRouting.closedLoops(rounded.segments)
        precondition(
            roundedLoops.filter { PanelRouting.pointInside(RoutePoint(x: -6.9, y: -6.9), loop: $0) }.count % 2 == 0)
        precondition(
            roundedLoops.filter { PanelRouting.pointInside(RoutePoint(x: -5, y: -6.9), loop: $0) }.count % 2 == 1)
        let roundedArea = rounded.segments.reduce(0.0) { $0 + ($1.a.x * $1.b.y - $1.b.x * $1.a.y) / 2 }
        precondition(
            abs(roundedArea - (3696 - 4 * (4 - Double.pi))) < 0.1, "R2 corners must remove the expected corner area")
        let (roundedBoard, _) = try KiCadPanelEngine.panelize(data: Data(kicad.utf8), options: roundedOptions)
        let roundedText = String(decoding: roundedBoard, as: UTF8.self)
        precondition(roundedText.components(separatedBy: "np_thru_hole").count - 1 == 72)
        let (eagleWithHoles, _) = try EaglePanelEngine.panelize(data: Data(eagle.utf8), options: roundedOptions)
        let holeXML = try XMLDocument(data: eagleWithHoles)
        let biteHoles = try holeXML.nodes(forXPath: "/eagle/drawing/board/plain/hole[@drill='0.5']")
        precondition(biteHoles.count == 72)
        print("PASS: mouse-bite positions, NPTH/XML drill outputs and R2 corner geometry")
        print("PASS: routing topology, frame/board clearance, bridge material, dimensions and area")
        print(
            "PASS: EAGLE XML siblings, component references, KiCad root, layout, local coordinates and output re-reading"
        )
    }

    static func verifyInputValidation() throws {
        let board = "(kicad_pcb (version 20260206) (gr_rect (start 0 0) (end 20 30) (layer \"Edge.Cuts\")))"
        var failures: [String] = []
        func rejects(_ name: String, _ operation: () throws -> Void) {
            do { try operation(); failures.append(name); print("FAIL: " + name) } catch { print("PASS: " + name) }
        }
        rejects("reject trailing tokens") { _ = try KiCadPanelEngine.shape(data: Data((board + " garbage").utf8)) }
        rejects("reject a second root board") { _ = try KiCadPanelEngine.shape(data: Data((board + board).utf8)) }
        rejects("reject invalid UTF-8 without replacing text") {
            var bytes = Data("(kicad_pcb (title_block (title \"broken".utf8)
            bytes.append(0xff)
            bytes.append(contentsOf: "\")) (gr_rect (start 0 0) (end 20 30) (layer \"Edge.Cuts\")))".utf8)
            _ = try KiCadPanelEngine.shape(data: bytes)
        }
        rejects("reject excessive parser nesting") {
            let nested =
                "(kicad_pcb " + String(repeating: "(nested ", count: 300) + "x" + String(repeating: ")", count: 300)
                + ")"
            _ = try KiCadPanelEngine.normalizeLayers(data: Data(nested.utf8))
        }
        rejects("reject non-finite layout measurements") {
            var options = PanelOptions(); options.columnGapMM = .nan
            try PanelRouting.validate(options)
        }
        rejects("reject zero rows before creating a range") {
            var options = PanelOptions(); options.rows = 0
            try PanelRouting.validate(options)
        }
        rejects("reject overflowing array counts") {
            var options = PanelOptions(); options.columns = Int.max; options.rows = 2
            try PanelRouting.validate(options)
        }
        rejects("reject unbounded perforation density") {
            var options = PanelOptions(); options.addTabs = true
            options.verticalFrameMM = 5; options.horizontalFrameMM = 5; options.frameGapMM = 2
            options.columnGapMM = 2; options.rowGapMM = 2
            options.mouseBiteDiameterMM = 1e-309; options.mouseBitePitchMM = 2e-309
            try PanelRouting.validate(options)
        }
        if !failures.isEmpty { print("Input validation failures: \(failures.count)"); exit(1) }
    }

    static func verifySafetyFixes() throws {
        let fm = FileManager.default
        let directory = fm.temporaryDirectory.appendingPathComponent("SwiftPCBPanelizer-safety-" + UUID().uuidString)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: directory) }
        let original = directory.appendingPathComponent("Board.kicad_pcb")
        let hardLink = directory.appendingPathComponent("other-name.kicad_pcb")
        let symbolic = directory.appendingPathComponent("symbolic.kicad_pcb")
        try Data("source board".utf8).write(to: original)
        try fm.linkItem(at: original, to: hardLink)
        try fm.createSymbolicLink(at: symbolic, withDestinationURL: original)
        precondition(
            PanelFileAccess.isSameFile(original, hardLink), "Hard-linked inputs must not be output destinations")
        precondition(PanelFileAccess.isSameFile(original, symbolic), "Symbolic links must not bypass source protection")
        precondition(!PanelFileAccess.isSameFile(original, directory.appendingPathComponent("new.kicad_pcb")))
        let variant = directory.appendingPathComponent("board.kicad_pcb")
        if fm.fileExists(atPath: variant.path) { precondition(PanelFileAccess.isSameFile(original, variant)) }
        print("PASS: source-file identity, hard links, symbolic links and available case aliases")

        let bounds = RouteRect(minX: 0, minY: 0, maxX: 20, maxY: 30)
        var automatic = PanelOptions(); automatic.rows = 0
        let layout = try PanelCompositionLayout(bounds: [bounds, bounds], options: automatic)
        precondition(layout.rowCount == 1 && layout.placements.count == 2)
        do {
            _ = try PanelRouting.arc(center: RoutePoint(x: 0, y: 0), start: RoutePoint(x: 10, y: 0), sweep: .infinity)
            preconditionFailure("Non-finite arc angles must be rejected")
        } catch is RoutingError {}
        do {
            _ = try PanelRouting.arc(center: RoutePoint(x: 0, y: 0), start: RoutePoint(x: 10, y: 0), sweep: 1e300)
            preconditionFailure("Huge arc angles must not reach Int conversion")
        } catch is RoutingError {}
        do {
            _ = try PanelRouting.closedLoops(
                [RouteSegment(a: RoutePoint(x: .nan, y: 0), b: RoutePoint(x: 1, y: 1))]
                    + PanelRouting.edges(bounds.points))
            preconditionFailure("Invalid geometry must not be silently discarded")
        } catch is RoutingError {}
        // EN: Tab capacity used to convert this enormous quotient directly to Int.
        // JA: 以前はタブの収容数の計算で、この極端に大きな商を直接Intへ変換していた。
        // DE: Bei der Stegkapazitätsberechnung wurde dieser extrem große Quotient früher direkt in Int umgewandelt.
        var tiny = PanelOptions(); tiny.columns = 1; tiny.rows = 1
        tiny.addTabs = true; tiny.perforateTabs = false; tiny.tabWidthMM = 1e-100
        tiny.horizontalFrameMM = 5; tiny.verticalFrameMM = 5; tiny.frameGapMM = 2
        do {
            _ = try PanelRouting.plan(boards: [[bounds.points]], arrayBounds: bounds, options: tiny)
            preconditionFailure("Sub-tolerance tabs must not be treated as material connections")
        } catch is RoutingError {}
        print("PASS: automatic rows, arc-angle rejection, invalid coordinates and tiny tab widths")

        let worker = Process()
        worker.executableURL = URL(fileURLWithPath: "/bin/sh")
        worker.arguments = ["-c", "trap '' TERM; printf ready; while :; do :; done"]
        let ready = Pipe(); worker.standardOutput = ready
        let finished = DispatchSemaphore(value: 0)
        worker.terminationHandler = { _ in finished.signal() }
        try worker.run()
        defer { if worker.isRunning { KiCadImporter.terminateAndWait(worker, finished: finished, gracePeriod: 0.05) } }
        _ = try ready.fileHandleForReading.read(upToCount: 5)
        KiCadImporter.terminateAndWait(worker, finished: finished, gracePeriod: 0.05)
        precondition(!worker.isRunning, "A timed-out child must exit before deleting its temporary directory")
        print("PASS: terminate and reap a child that ignores SIGTERM")
    }

    static func verifyPreviewCancellation() async {
        let (gate, continuation) = AsyncStream<Void>.makeStream()
        let worker = Task.detached { () -> Bool in
            for await _ in gate {}

            let bounds = RouteRect(minX: 0, minY: 0, maxX: 20, maxY: 30)
            var options = PanelOptions(); options.columns = 1; options.rows = 1
            do {
                _ = try PanelRouting.plan(boards: [[bounds.points]], arrayBounds: bounds, options: options)
                return false
            } catch is CancellationError { return true } catch { return false }
        }
        worker.cancel(); continuation.finish()
        let cancelled = await worker.value
        precondition(cancelled, "Obsolete preview geometry jobs must stop when cancelled")
        print("PASS: cancellation propagates to background routing work")
    }

    /// EN: Check that threshold boundaries and inconsistent return values can be caught as errors.
    ///
    /// JA: 閾値の境界・戻り値の不整合を、例外として捕捉できるか確認する。
    ///
    /// DE: Prüfen, dass Grenzwertfälle und inkonsistente Rückgabewerte als Fehler abgefangen werden können.
    static func verifyContracts() throws {
        func rejects(_ operation: () throws -> Void) {
            do { try operation(); preconditionFailure("An invalid function contract was accepted") } catch {}
        }
        rejects { try PanelValidation.document(Data(), field: "empty.input") }
        rejects {
            try PanelValidation.rectangle(RouteRect(minX: 20, minY: 0, maxX: 10, maxY: 10), field: "reversed.bounds")
        }
        let invalid = PanelSummary(
            boardWidthMM: 20, boardHeightMM: 10, panelWidthMM: 5, panelHeightMM: 10, columns: 1, rows: 1,
            dimensionLineWidthMM: 0.05)
        rejects { try PanelValidation.summary(invalid) }
        let invalidHole = PanelPreviewDrill(
            center: RoutePoint(x: 0, y: 0), width: .infinity, height: 1, angle: 0, front: true, back: true)
        rejects { try PanelValidation.drills([invalidHole]) }
        var options = PanelOptions(); options.addMountingHoles = true
        rejects { try PanelValidation.mountingHoles(width: 20, height: 20, options: options) }
        options.mountingHoleOffsetXMM = 2; options.mountingHoleOffsetYMM = 2
        try PanelValidation.mountingHoles(width: 20, height: 20, options: options)
        let boundary = RouteRect(minX: 0, minY: 0, maxX: 20, maxY: 20)
        let invalidRoute = RoutingPlan(
            segments: PanelRouting.edges(boundary.points), mouseBites: [RoutePoint(x: 100, y: 100)])
        rejects { try PanelValidation.routing(invalidRoute, inside: boundary) }
        let lower = RoutePoint(x: -PanelLimits.maxCoordinateMM, y: -PanelLimits.maxCoordinateMM)
        let upper = RoutePoint(x: PanelLimits.maxCoordinateMM, y: PanelLimits.maxCoordinateMM)
        try PanelRouting.validatePoints([lower, upper])
        rejects { try PanelRouting.validatePoints([RoutePoint(x: PanelLimits.maxCoordinateMM + 1, y: 0)]) }
        let malformedEagle =
            #"<eagle><drawing><board><plain><text x="nan" y="0" size="1">bad</text></plain></board></drawing></eagle>"#
        do {
            _ = try EaglePanelEngine.preparedForKiCadImport(data: Data(malformedEagle.utf8))
            preconditionFailure("Non-finite EAGLE coordinates must be rejected")
        } catch {
            precondition(
                error.localizedDescription.contains("EAGLE.xMM"),
                "The original field-level validation error must be retained")
        }
        print("PASS: unit-specific thresholds, boundary values and invalid function results")
    }

    /// EN: Preserve inner-layer tracks in 4-/6-layer boards and reject merging different layer counts or orders.
    ///
    /// JA: 4/6層の内層配線を保持し、異なる層数・順序の統合を拒否する。
    ///
    /// DE: Leiterbahnen auf Innenlagen von 4-/6-lagigen Platinen erhalten und das Zusammenführen unterschiedlicher
    ///     Lagenanzahlen oder -reihenfolgen ablehnen.
    static func verifyMultilayerPanels() throws {
        func fixtures(_ count: Int, reversed: Bool = false) -> (PanelSource, PanelSource) {
            let eagleLayers = count == 4 ? [1, 2, 15, 16] : [1, 2, 3, 14, 15, 16]
            let table = eagleLayers.map {
                "<layer number=\"\($0)\" name=\"L\($0)\" color=\"1\" fill=\"1\" visible=\"yes\" active=\"yes\"/>"
            }.joined()
            let wires = eagleLayers.dropFirst().dropLast().map {
                "<wire x1=\"2\" y1=\"2\" x2=\"8\" y2=\"2\" width=\"0.2\" layer=\"\($0)\"/>"
            }.joined()
            let setup = "(" + eagleLayers.map(String.init).joined(separator: "*") + ")"
            let eagle = """
                <eagle version="9.6.2"><drawing><layers>\(table)<layer number="20" name="Dimension" color="15" fill="1" visible="yes" active="yes"/></layers>
                <board><plain><wire x1="0" y1="0" x2="20" y2="0" width="0" layer="20"/><wire x1="20" y1="0" x2="20" y2="10" width="0" layer="20"/><wire x1="20" y1="10" x2="0" y2="10" width="0" layer="20"/><wire x1="0" y1="10" x2="0" y2="0" width="0" layer="20"/></plain><libraries/><elements/><signals><signal name="GND">\(wires)</signal></signals><designrules name="default"><param name="layerSetup" value="\(setup)"/></designrules></board></drawing></eagle>
                """
            let names = (1...(count - 2)).map { "In\($0).Cu" }
            var rows = names.enumerated().map { "(\(4+$0.offset*2) \"\($0.element)\" signal)" }
            if reversed { rows.reverse() }
            let tracks = names.map {
                "(segment (start 2 2) (end 8 2) (width 0.2) (layer \"\($0)\") (net \"GND\") (uuid \"\(UUID().uuidString)\"))"
            }.joined(separator: "\n")
            let kicad = """
                (kicad_pcb (version 20260206) (generator "pcbnew") (general (thickness 1.6)) (paper "A4")
                  (layers (0 "F.Cu" signal) \(rows.joined(separator: " ")) (2 "B.Cu" signal) (25 "Edge.Cuts" user))
                  (setup) \(tracks)
                  (gr_rect (start 0 0) (end 20 10) (stroke (width 0.05) (type default)) (fill none) (layer "Edge.Cuts") (uuid "\(UUID().uuidString)")))
                """
            return (
                PanelSource(name: "fixture\(count).brd", data: Data(eagle.utf8), kind: .eagle),
                PanelSource(name: "fixture\(count).kicad_pcb", data: Data(kicad.utf8), kind: .kicad)
            )
        }
        var options = PanelOptions(); options.rows = 1; options.columns = 2
        for count in [4, 6] {
            let (eagle, kicad) = fixtures(count)
            let nativeEagle = try PanelComposer.compose(sources: [eagle, eagle], options: options)
            let xml = try XMLDocument(data: nativeEagle.data)
            let innerWires = try xml.nodes(forXPath: "/eagle/drawing/board/signals/signal/wire[@layer='2']")
            precondition(innerWires.count == 2, "EAGLE inner-layer traces must be duplicated")
            let nativeKiCad = try PanelComposer.compose(sources: [kicad, kicad], options: options)
            let text = String(decoding: nativeKiCad.data, as: UTF8.self)
            for layer in 1...(count - 2) {
                precondition(text.components(separatedBy: "(layer \"In\(layer).Cu\")").count - 1 == 2)
            }
            if CommandLine.arguments.contains("--samples") {
                let nativeEagleKiCad = try KiCadImporter.convertEagle(
                    PanelSource(name: "native-panel.brd", data: nativeEagle.data, kind: .eagle))
                try verifyKiCadReload(nativeEagleKiCad, label: "multilayer-EAGLE")
                try verifyKiCadReload(nativeKiCad.data, label: "multilayer-KiCad")
                let mixed = try PanelComposer.compose(sources: [eagle, kicad], options: options)
                try verifyKiCadReload(mixed.data, label: "multilayer-mixed")
                let mixedText = String(decoding: mixed.data, as: UTF8.self)
                for layer in 1...(count - 2) {
                    precondition(
                        mixedText.components(separatedBy: "(layer \"In\(layer).Cu\")").count - 1 == 2,
                        "Mixed conversion must keep each inner copper trace")
                }
            }
            print("PASS: \(count)-layer native panels and inner copper preservation")
        }
        let (e4, k4) = fixtures(4); let (e6, k6) = fixtures(6)
        do {
            _ = try PanelComposer.compose(sources: [e4, e6], options: options);
            preconditionFailure("Incompatible EAGLE stacks must be rejected")
        } catch is RoutingError {}
        do {
            _ = try PanelComposer.compose(sources: [k4, k6], options: options);
            preconditionFailure("Incompatible KiCad layer counts must be rejected")
        } catch is KiCadPanelError {}
        let (_, reversed) = fixtures(4, reversed: true)
        do {
            _ = try PanelComposer.compose(sources: [k4, reversed], options: options);
            preconditionFailure("Different copper order must be rejected")
        } catch is KiCadPanelError {}
        print("PASS: mismatched copper layer counts and order are rejected")
    }

    /// EN: Check that KiCad itself can load the returned multilayer board and generate SVGs of its inner layers.
    ///
    /// JA: 返却された多層基板をKiCad自身で読み込み、内層のSVGを生成できるか確認する。
    ///
    /// DE: Prüfen, dass KiCad selbst die zurückgegebene mehrlagige Platine laden und SVGs ihrer Innenlagen erzeugen
    ///     kann.
    static func verifyKiCadReload(_ data: Data, label: String) throws {
        guard let executable = KiCadImporter.executable else {
            preconditionFailure("KiCad is required for sample checks")
        }
        let fm = FileManager.default
        let directory = fm.temporaryDirectory.appendingPathComponent(
            "SwiftPCBPanelizer-multilayer-" + UUID().uuidString)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: directory) }
        let board = directory.appendingPathComponent("panel.kicad_pcb")
        let svg = directory.appendingPathComponent("inner.svg")
        let log = directory.appendingPathComponent("kicad.log")
        try data.write(to: board)
        _ = fm.createFile(atPath: log.path, contents: nil)
        let handle = try FileHandle(forWritingTo: log)
        defer { try? handle.close() }
        let process = Process()
        process.executableURL = executable
        process.arguments = [
            "pcb", "export", "svg", "--layers", "In1.Cu", "--mode-single", "--exclude-drawing-sheet", "--output",
            svg.path, board.path,
        ]
        process.standardOutput = handle
        process.standardError = handle
        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in finished.signal() }
        try process.run()
        if finished.wait(timeout: .now() + 120) == .timedOut {
            KiCadImporter.terminateAndWait(process, finished: finished)
            preconditionFailure("KiCad multilayer reload timed out")
        }
        let details = (try? String(contentsOf: log, encoding: .utf8)) ?? ""
        precondition(process.terminationStatus == 0 && fm.fileExists(atPath: svg.path), label + ": " + details)
    }

    static func verifySampleExports() throws {
        let args = CommandLine.arguments
        guard let e = args.firstIndex(of: "--eagle"), e + 1 < args.count,
            let k = args.firstIndex(of: "--kicad"), k + 1 < args.count,
            let executable = KiCadImporter.executable
        else {
            fatalError("--samples requires --eagle path, --kicad path and installed KiCad")
        }
        let eagle = PanelSource(
            name: "EAGLE.brd", data: try Data(contentsOf: URL(fileURLWithPath: args[e + 1])), kind: .eagle)
        let kicad = PanelSource(
            name: "KiCad.kicad_pcb", data: try Data(contentsOf: URL(fileURLWithPath: args[k + 1])), kind: .kicad)
        let fm = FileManager.default
        let directory = fm.temporaryDirectory.appendingPathComponent("SwiftPCBPanelizer-export-" + UUID().uuidString)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: directory) }
        var options = PanelOptions(); options.horizontalFrameMM = 5; options.verticalFrameMM = 5
        options.frameGapMM = 2; options.columnGapMM = 2; options.rowGapMM = 2
        options.addTabs = true; options.tabsPerEdge = 1; options.tabWidthMM = 2
        options.addMountingHoles = true; options.mountingHoleOffsetXMM = 2.5; options.mountingHoleOffsetYMM = 2.5
        for (name, sources) in [("EAGLE", [eagle]), ("KiCad", [kicad]), ("mixed", [eagle, kicad])] {
            let output = try PanelComposer.compose(sources: sources, options: options)
            let data =
                output.fileExtension == "brd"
                ? try KiCadImporter.convertEagle(PanelSource(name: "panel.brd", data: output.data, kind: .eagle))
                : output.data
            let board = directory.appendingPathComponent(name + ".kicad_pcb")
            let svg = directory.appendingPathComponent(name + ".svg")
            try data.write(to: board)
            let process = Process(); process.executableURL = executable
            process.arguments = [
                "pcb", "export", "svg", "--layers", "Edge.Cuts", "--mode-single", "--exclude-drawing-sheet", "--output",
                svg.path, board.path,
            ]
            let log = directory.appendingPathComponent(name + ".log")
            _ = fm.createFile(atPath: log.path, contents: nil)
            let handle = try FileHandle(forWritingTo: log); defer { try? handle.close() }
            process.standardOutput = handle; process.standardError = handle
            let finished = DispatchSemaphore(value: 0); process.terminationHandler = { _ in finished.signal() }
            try process.run()
            if finished.wait(timeout: .now() + 120) == .timedOut {
                KiCadImporter.terminateAndWait(process, finished: finished)
                preconditionFailure("KiCad sample export timed out")
            }
            let details = (try? String(contentsOf: log, encoding: .utf8)) ?? ""
            precondition(
                process.terminationStatus == 0 && fm.fileExists(atPath: svg.path),
                "KiCad rejected " + name + " output: " + details)
            print("PASS: real " + name + " sample panel, tabs, drills and KiCad reload / SVG export")
        }
    }

    static func tryPlan(bounds: RouteRect, options: PanelOptions) -> RoutingPlan {
        try! PanelRouting.plan(contours: [bounds.points], bounds: bounds, options: options)
    }

    static func verifySilkPreservation() throws {
        let eagle = """
            <eagle version="9.6.2"><drawing><board><plain>
              <wire x1="0" y1="0" x2="20" y2="30" width="0" layer="20"/>
            </plain><libraries>
              <library name="A"><packages><package name="P">
                <text x="1" y="2" size="1" layer="25" font="vector" ratio="17">&gt;NAME</text>
                <text x="0" y="-1" size="1" layer="27">&gt;VALUE</text>
              </package></packages></library>
              <library name="B"><packages><package name="P">
                <text x="3" y="4" size="2" layer="25">&gt;NAME</text>
              </package></packages></library>
            </libraries><elements>
              <element name="U1" library="A" package="P" value="VALUE1" x="5" y="6" rot="R90"/>
              <element name="U2" x="8" y="9" smashed="yes">
                <attribute name="NAME" x="9.25" y="12.5" size="1.2" layer="26" font="vector" ratio="20" rot="MR270" align="bottom-right"/>
              </element>
              <element name="U3" x="1" y="1" smashed="yes">
                <attribute name="NAME" x="1" y="1" size="1" layer="25" display="off"/>
              </element>
              <element name="U4" x="2" y="2" smashed="yes"/>
              <element name="U5" library="B" package="P" x="7" y="9"/>
              <element name="U6" x="3" y="3" smashed="yes">
                <attribute name="NAME" x="3" y="3" size="1" layer="25" display="name"/>
              </element>
              <element name="U7" x="4" y="4" smashed="yes">
                <attribute name="NAME" x="4" y="4" size="1" layer="25" display="both"/>
              </element>
            </elements><signals><signal name="GND"><contactref element="U2" pad="1"/></signal></signals>
            </board></drawing></eagle>
            """
        let (eagleOutput, _) = try EaglePanelEngine.panelize(data: Data(eagle.utf8), options: PanelOptions())
        let xml = try XMLDocument(data: eagleOutput)
        let texts = try xml.nodes(forXPath: "/eagle/drawing/board/plain/text").compactMap { $0 as? XMLElement }
        for text in ["U1", "U2", "U5", "VALUE1", "NAME", "NAME = U7"] {
            precondition(texts.filter { $0.stringValue == text }.count == 4)
        }
        precondition(!texts.contains { ["U3", "U4"].contains($0.stringValue ?? "") })
        for label in texts.filter({ $0.stringValue == "U2" }) {
            precondition(label.attribute(forName: "layer")?.stringValue == "26")
            precondition(label.attribute(forName: "rot")?.stringValue == "MR270")
            precondition(label.attribute(forName: "size")?.stringValue == "1.2")
            precondition(label.attribute(forName: "align")?.stringValue == "bottom-right")
            let x = Double(label.attribute(forName: "x")!.stringValue!)!,
                y = Double(label.attribute(forName: "y")!.stringValue!)!
            precondition([9.25, 29.25].contains(x) && [12.5, 42.5].contains(y))
        }
        for label in texts.filter({ $0.stringValue == "U5" }) {
            precondition(label.attribute(forName: "size")?.stringValue == "2")
        }
        let dynamicNames = try xml.nodes(forXPath: "/eagle/drawing/board/elements/element/attribute[@name='NAME']")
        precondition(dynamicNames.isEmpty, "EAGLE NAME attributes must not render suffixed identities")
        let elements = try xml.nodes(forXPath: "/eagle/drawing/board/elements/element")
        let names = elements.compactMap { ($0 as? XMLElement)?.attribute(forName: "name")?.stringValue }
        precondition(names.count == 28 && Set(names).count == 28)

        let kicad = """
            (kicad_pcb (version 20260206) (generator "pcbnew")
              (footprint "Visible" (at 12 22 90)
                (property "Reference" "U1" (at 0 -2 90) (layer "F.SilkS")
                  (uuid "11111111-1111-4111-8111-111111111111") (effects (font (size 1 1) (thickness 0.15))))
                (fp_text user "ID=${REFERENCE}" (at 1 2 90) (layer "B.SilkS")
                  (effects (font (size 1 1) (thickness 0.15)) (justify mirror))))
              (footprint "Hidden" (at 15 25)
                (property "Reference" "U2" (at 0 -2) (layer "F.SilkS") (hide yes)))
              (footprint "Legacy" (at 16 26 180)
                (fp_text reference "U3" (at -1 2 180) (layer "B.SilkS")
                  (effects (font (size 1 1) (thickness 0.15)) (justify mirror))))
              (gr_rect (start 10 20) (end 30 50) (layer "Edge.Cuts")))
            """
        let (output, _) = try KiCadPanelEngine.panelize(data: Data(kicad.utf8), options: PanelOptions())
        let text = String(decoding: output, as: UTF8.self)
        func count(_ value: String) -> Int { text.components(separatedBy: value).count - 1 }
        precondition(count("(fp_text user \"U1\"") == 3)
        precondition(count("(fp_text user \"U3\"") == 3)
        precondition(count("(fp_text user \"U2\"") == 0, "Hidden references must stay hidden")
        precondition(count("(fp_text user \"ID=U1\"") == 3, "Reference variables must use the source spelling")
        precondition(count("(property \"Reference\" \"U1_R1C2\"") == 1)
        precondition(count("(at 0 -2 90)") == 7 && count("(at -1 2 180)") == 7)
        precondition(count("(justify mirror)") == 11)
        print(
            "PASS: original silk text, hidden/mirrored labels, moved EAGLE names, library lookup, values and unique component identities"
        )
    }
}
