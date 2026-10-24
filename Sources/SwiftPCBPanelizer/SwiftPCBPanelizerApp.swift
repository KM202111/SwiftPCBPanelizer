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

import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct SwiftPCBPanelizerApp: App {
    @NSApplicationDelegateAdaptor(PanelizerApplicationDelegate.self) private var applicationDelegate
    var body: some Scene {
        WindowGroup("SwiftPCBPanelizer") {
            PanelizerHomeView()
                .frame(minWidth: 1080, minHeight: 760)
                .interfaceTypography()
        }
        .windowToolbarStyle(.unified)
        Settings {
            InterfaceTextSettingsView()
        }
    }
}

/// EN: Load the bundled artwork directly so the sidebar does not depend on the system's cached file icon.
///     Use the same immutable image for the sidebar and the running app's Dock tile.
///
/// JA: 同梱の画像を直接読み込み、サイドバーがシステム側のファイルアイコンのキャッシュに依存しないようにする。
///     サイドバーと起動中アプリのDockに同じ固定画像を使用する。
///
/// DE: Die mitgelieferte Grafik direkt laden, damit die Seitenleiste nicht vom zwischengespeicherten Dateisymbol abhängt.
///     Für Seitenleiste und Dock-Kachel der laufenden App dasselbe unveränderliche Bild verwenden.
@MainActor
private enum PanelizerIcon {
    static let image: NSImage = {
        if let artwork = NSImage(named: NSImage.Name("PanelizerArtwork")), artwork.isValid,
            artwork.size.width.isFinite, artwork.size.width > 0,
            artwork.size.height.isFinite, artwork.size.height > 0
        {
            return artwork
        }
        // EN: If the dedicated artwork cannot be loaded, read the bundled ICNS before falling back to AppKit.
        // JA: 専用画像を読み込めない場合は、同梱ICNSを試してからAppKitの既定アイコンに戻す。
        // DE: Bei fehlender Grafik zuerst die mitgelieferte ICNS-Datei laden, danach auf AppKit zurückfallen.
        if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
            let bundledIcon = NSImage(contentsOf: url), bundledIcon.isValid,
            bundledIcon.size.width.isFinite, bundledIcon.size.width > 0,
            bundledIcon.size.height.isFinite, bundledIcon.size.height > 0
        {
            return bundledIcon
        }
        return NSApplication.shared.applicationIconImage
    }()
}

@MainActor
private final class PanelizerApplicationDelegate: NSObject, NSApplicationDelegate {
    /// EN: Explicitly refresh the running app's Dock icon from bundled artwork after launch.
    ///     This also avoids depending on a stale Launch Services icon when building repeatedly at the same path.
    ///
    /// JA: 起動完了時に同梱画像でDockアイコンを明示的に更新する。
    ///     同じパスで繰り返しビルドした際も、Launch Services側の古いアイコンに依存しない。
    ///
    /// DE: Nach dem Start das Dock-Symbol der laufenden App ausdrücklich aus der mitgelieferten Grafik aktualisieren.
    ///     So wird bei wiederholten Builds am selben Pfad kein veraltetes Launch-Services-Symbol verwendet.
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.applicationIconImage = PanelizerIcon.image
    }
}

private struct BoardDocument: Identifiable {
    let id = UUID()
    let url: URL
    let data: Data
    let summary: PanelSummary
    let kind: BoardKind
    let shape: PanelBoardShape
}

private extension BoardKind {
    var color: Color { self == .eagle ? .orange : .teal }
}

private struct PanelizerHomeView: View {
    @Environment(\.interfaceTextScale) private var textScale
    @State private var documents: [BoardDocument] = []
    @State private var options = PanelOptions()
    @State private var showFilePicker = false
    @State private var isDropTargeted = false
    @State private var notice: String?
    @State private var isShowingNotice = false
    @State private var isProcessing = false
    @State private var previewSelection: UUID?
    @State private var isGeneratingArtwork = false
    @State private var artworkStatus = ""

    private var isMixedPanel: Bool { documents.count > 1 }
    private var includesBothFormats: Bool {
        documents.contains { $0.kind == .eagle } && documents.contains { $0.kind == .kicad }
    }
    private var previewLayout: PanelCompositionLayout? {
        try? PanelCompositionLayout(bounds: documents.map { $0.shape.bounds }, options: options)
    }
    private var boardCount: Int { isMixedPanel ? documents.count : options.columns * options.rows }
    private var displayedRows: Int {
        isMixedPanel ? (documents.count + max(1, options.columns) - 1) / max(1, options.columns) : options.rows
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            ZStack {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        boardImportStrip
                        layoutSection
                        panelSection
                        previewSection
                        exportFooter
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 28)
                    .frame(maxWidth: 1120 * textScale)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) { InterfaceTextSizeControl() }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.data, .xml], allowsMultipleSelection: true) {
            result in
            if case .success(let urls) = result { importBoards(urls) }
            if case .failure(let error) = result { present(error.localizedDescription) }
        }
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted, perform: acceptDrop)
        .alert("SwiftPCBPanelizer", isPresented: $isShowingNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(notice ?? "")
        }
        .overlay {
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.24).ignoresSafeArea()
                    VStack(spacing: 14) {
                        ProgressView()
                        Text(
                            L10n.text(
                                "Duplicating board data…", "基板データを複製しています…", "Leiterplattendaten werden dupliziert…"))
                    }
                    .padding(26)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Image(nsImage: PanelizerIcon.image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("SwiftPCBPanelizer").interfaceFont(.headline)
                    Text(L10n.text("PCB panelization", "基板面付け", "Leiterplattennutzen")).interfaceFont(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(18)

            HStack {
                Text(L10n.text("Board files", "基板ファイル", "Leiterplattendateien")).interfaceFont(
                    .caption, weight: .semibold
                ).foregroundStyle(.secondary)
                Spacer()
                Text("\(documents.count)").interfaceFont(.caption, weight: .medium, monospaced: true).foregroundStyle(
                    .secondary)
            }
            .padding(.horizontal, 18).padding(.bottom, 8)

            if documents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus").font(.system(size: 28)).foregroundStyle(.tertiary)
                    Text(L10n.text("No files added", "まだファイルがありません", "Keine Dateien hinzugefügt")).interfaceFont(
                        .subheadline
                    ).foregroundStyle(.secondary)
                    Text(
                        L10n.text(
                            "Add .kicad_pcb or .brd files", ".kicad_pcb または .brd を追加",
                            ".kicad_pcb- oder .brd-Dateien hinzufügen")
                    )
                    .interfaceFont(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $previewSelection) {
                    ForEach(documents) { document in
                        HStack(spacing: 10) {
                            Image(systemName: document.kind == .kicad ? "cpu" : "doc.text.magnifyingglass")
                                .foregroundStyle(document.kind.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(document.url.lastPathComponent).lineLimit(1).truncationMode(.middle)
                                Text(
                                    String(
                                        format: "%.1f × %.1f mm", document.summary.boardWidthMM,
                                        document.summary.boardHeightMM)
                                )
                                .interfaceFont(.caption2, monospaced: true).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 4)
                        .tag(document.id)
                        .contextMenu {
                            Button(L10n.text("Remove from list", "リストから削除", "Aus Liste entfernen"), role: .destructive)
                            { remove(document) }
                        }
                    }
                    .onDelete { offsets in documents.remove(atOffsets: offsets) }
                }
                .listStyle(.sidebar)
            }

            Button {
                showFilePicker = true
            } label: {
                Label(L10n.text("Add boards", "基板を追加", "Leiterplatten hinzufügen"), systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .padding(14)
        }
        .frame(minWidth: 280, idealWidth: 300 + (textScale - 1) * 80)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.45))
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text(L10n.text("Arrange boards in a panel", "基板をパネルに配置", "Leiterplatten zu einem Nutzen anordnen"))
                    .interfaceFont(.hero, weight: .bold, design: .rounded)
                Text(
                    L10n.text(
                        "Create panel boards from EAGLE and KiCad designs.", "EAGLEとKiCadの基板データを複製し、製造用のパネル基板を作成します。",
                        "Nutzen aus EAGLE- und KiCad-Leiterplatten erstellen.")
                )
                .interfaceFont(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 7) {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                Text(L10n.text("Processed locally", "ローカル処理", "Lokale Verarbeitung")).interfaceFont(
                    .caption, weight: .medium)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.green.opacity(0.08), in: Capsule())
        }
    }

    private var boardImportStrip: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.down.doc.fill")
                .interfaceFont(.title2).foregroundStyle(.indigo)
                .frame(width: 46, height: 46).background(.indigo.opacity(0.09), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.text("Import board files", "基板データを読み込む", "Leiterplattendateien importieren")).interfaceFont(
                    .subheadline, weight: .semibold)
                Text(
                    L10n.text(
                        "KiCad .kicad_pcb / EAGLE .brd · Multiple files and drag & drop",
                        "KiCad .kicad_pcb / EAGLE .brd · 複数ファイル・ドラッグ＆ドロップ対応",
                        "KiCad .kicad_pcb / EAGLE .brd · Mehrere Dateien und Drag-and-drop")
                )
                .interfaceFont(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(L10n.text("Choose files", "ファイルを選択", "Dateien auswählen")) { showFilePicker = true }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(
                isDropTargeted ? Color.indigo : Color.primary.opacity(0.06), lineWidth: isDropTargeted ? 2 : 1))
    }

    private var layoutSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionHeading(
                "01", title: L10n.text("Array and spacing", "配列と間隔", "Anordnung und Abstände"),
                subtitle: isMixedPanel
                    ? L10n.text(
                        "Each file is placed once in one panel. Columns control wrapping; rows are calculated automatically.",
                        "各ファイルを1枚ずつ同じパネルに配置します。列数で折り返し、行数は自動計算します。",
                        "Jede Datei wird einmal im selben Nutzen platziert. Die Spaltenanzahl bestimmt den Umbruch; die Zeilenanzahl wird automatisch berechnet."
                    )
                    : L10n.text(
                        "Arrange boards using their outline dimensions", "基板外形を基準に行列へ並べます",
                        "Leiterplatten anhand ihrer Konturabmessungen anordnen"))
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200 * textScale), spacing: 14)], alignment: .leading, spacing: 14
            ) {
                settingCard(title: L10n.text("Columns", "列数", "Spalten"), symbol: "rectangle.split.3x1") {
                    Stepper(value: $options.columns, in: 1...20) {
                        Text(
                            L10n.text(
                                "\(options.columns) columns", "\(options.columns) 列",
                                "\(options.columns) \(options.columns == 1 ? "Spalte" : "Spalten")")
                        ).interfaceFont(.title3, weight: .semibold, monospaced: true)
                    }
                }
                settingCard(title: L10n.text("Rows", "行数", "Zeilen"), symbol: "rectangle.split.1x3") {
                    if isMixedPanel {
                        Text(
                            L10n.text(
                                "\(displayedRows) rows · Auto", "\(displayedRows) 行・自動",
                                "\(displayedRows) \(displayedRows == 1 ? "Zeile" : "Zeilen") · Automatisch")
                        ).interfaceFont(.title3, weight: .semibold, monospaced: true)
                    } else {
                        Stepper(value: $options.rows, in: 1...20) {
                            Text(
                                L10n.text(
                                    "\(options.rows) rows", "\(options.rows) 行",
                                    "\(options.rows) \(options.rows == 1 ? "Zeile" : "Zeilen")")
                            ).interfaceFont(.title3, weight: .semibold, monospaced: true)
                        }
                    }
                }
                settingCard(
                    title: L10n.text("Column spacing", "横方向の間隔", "Spaltenabstand"), symbol: "arrow.left.and.right"
                ) {
                    measurementField(value: $options.columnGapMM)
                }
                settingCard(title: L10n.text("Row spacing", "縦方向の間隔", "Zeilenabstand"), symbol: "arrow.up.and.down") {
                    measurementField(value: $options.rowGapMM)
                }
            }
        }
    }

    private var pairedSettingsColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 20, alignment: .topLeading),
            GridItem(.flexible(), spacing: 20, alignment: .topLeading),
        ]
    }

    private var panelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeading(
                "02", title: L10n.text("Frame and routing", "外枠と加工ガイド", "Rahmen und Bearbeitung"),
                subtitle: L10n.text(
                    "Set up the frame, connecting tabs and machining features", "外枠・接続タブ・加工ガイド・取付穴を設定します",
                    "Rahmen, Verbindungsstege und Bearbeitungsmerkmale einstellen"))
            frameSettingsCard
            tabSettingsCard
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 280 * textScale), spacing: 16, alignment: .topLeading)],
                alignment: .leading, spacing: 16
            ) {
                guideSettingsCard
                mountingHoleSettingsCard
            }
        }
    }

    private var frameSettingsCard: some View {
        routingCard(
            title: L10n.text("Frame", "外枠", "Rahmen"),
            subtitle: L10n.text(
                "Rail widths, board clearance and corner shape", "外枠の幅、基板との隙間、角の形状",
                "Rahmenbreiten, Leiterplattenabstand und Eckenform"), symbol: "rectangle"
        ) {
            LazyVGrid(columns: pairedSettingsColumns, alignment: .leading, spacing: 18) {
                labeledMeasurement(
                    L10n.text("Left/right frame width", "左右の外枠幅", "Rahmenbreite links/rechts"),
                    value: $options.verticalFrameMM)
                labeledMeasurement(
                    L10n.text("Top/bottom frame width", "上下の外枠幅", "Rahmenbreite oben/unten"),
                    value: $options.horizontalFrameMM)
                labeledMeasurement(
                    L10n.text("Frame clearance", "外枠と基板の隙間", "Abstand zum Rahmen"), value: $options.frameGapMM)
                labeledMeasurement(
                    L10n.text("Panel corner radius", "パネル角のR", "Eckenradius des Nutzens"),
                    value: $options.panelCornerRadiusMM)
            }
            Divider()
            HStack(alignment: .center, spacing: 20) {
                labeledMeasurement(
                    L10n.text("Outline line width", "外形線幅", "Konturlinienbreite"), value: $options.dimensionLineWidthMM)
                Text(
                    L10n.text(
                        "Frame width is the material left around the boards. Clearance is the routed gap beside it.",
                        "外枠幅は残す材料の幅、隙間は基板との間を切り抜く幅です。",
                        "Die Rahmenbreite ist das Material, das um die Leiterplatten stehen bleibt. Der Abstand ist der daneben ausgefräste Spalt."
                    )
                )
                .interfaceFont(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var tabSettingsCard: some View {
        routingCard(
            title: L10n.text("Breakaway tabs", "接続タブ", "Verbindungsstege"),
            subtitle: L10n.text(
                "Bridge boards to the frame and neighboring boards", "基板と外枠、隣接する基板どうしをつなぎます",
                "Leiterplatten mit dem Rahmen und benachbarten Leiterplatten verbinden"), symbol: "link",
            isEnabled: $options.addTabs
        ) {
            LazyVGrid(columns: pairedSettingsColumns, alignment: .leading, spacing: 18) {
                labeledMeasurement(L10n.text("Tab width", "タブ幅", "Stegbreite"), value: $options.tabWidthMM)
                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.text("Tabs per edge", "各辺のタブ数", "Stege pro Kante")).interfaceFont(.caption)
                        .foregroundStyle(.secondary)
                    Stepper(value: $options.tabsPerEdge, in: 1...8) {
                        Text("\(options.tabsPerEdge)").monospacedDigit()
                    }
                    .accessibilityLabel(L10n.text("Tabs per edge", "各辺のタブ数", "Stege pro Kante"))
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.text("Connect to frame edges", "外枠と接続する辺", "Mit Rahmenseiten verbinden")).interfaceFont(
                    .caption
                ).foregroundStyle(.secondary)
                LazyVGrid(columns: pairedSettingsColumns, alignment: .leading, spacing: 10) {
                    Toggle(L10n.text("Left", "左辺", "Links"), isOn: $options.tabsLeft)
                    Toggle(L10n.text("Right", "右辺", "Rechts"), isOn: $options.tabsRight)
                    Toggle(L10n.text("Top", "上辺", "Oben"), isOn: $options.tabsTop)
                    Toggle(L10n.text("Bottom", "下辺", "Unten"), isOn: $options.tabsBottom)
                }.toggleStyle(.checkbox)
            }
            Toggle(
                L10n.text(
                    "Also connect adjacent boards", "隣接する基板どうしもタブで接続", "Auch benachbarte Leiterplatten verbinden"),
                isOn: $options.connectBoardsWithTabs
            )
            .toggleStyle(.checkbox)
            VStack(alignment: .leading, spacing: 14) {
                Toggle(
                    L10n.text("Add mouse-bite perforations", "切り取り用のミシン目", "Sollbruchbohrungen hinzufügen"),
                    isOn: $options.perforateTabs
                )
                .toggleStyle(.checkbox)
                if options.perforateTabs {
                    LazyVGrid(columns: pairedSettingsColumns, alignment: .leading, spacing: 18) {
                        labeledMeasurement(
                            L10n.text("Hole diameter", "ミシン目の穴径", "Lochdurchmesser"),
                            value: $options.mouseBiteDiameterMM)
                        labeledMeasurement(
                            L10n.text("Hole pitch", "穴ピッチ", "Lochabstand"), value: $options.mouseBitePitchMM)
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: options.addTabs) { _, enabled in
            if enabled {
                if options.verticalFrameMM == 0 { options.verticalFrameMM = 5 }
                if options.horizontalFrameMM == 0 { options.horizontalFrameMM = 5 }
                if options.frameGapMM == 0 { options.frameGapMM = 2 }
                if options.columnGapMM == 0 { options.columnGapMM = 2 }
                if options.rowGapMM == 0 { options.rowGapMM = 2 }
            }
        }
    }

    private var guideSettingsCard: some View {
        routingCard(
            title: L10n.text("Separation guides", "分割ガイド線", "Trennhilfslinien"),
            subtitle: L10n.text(
                "Mark the board separation positions", "基板を分割する位置にガイド線を追加",
                "Trennpositionen der Leiterplatten markieren"), symbol: "scissors",
            isEnabled: $options.addVScoreSeparators
        ) {
            labeledMeasurement(
                L10n.text("Guide line width", "ガイド線幅", "Hilfslinienbreite"), value: $options.vScoreLineWidthMM)
        }
    }

    private var mountingHoleSettingsCard: some View {
        routingCard(
            title: L10n.text("Mounting holes", "取付穴", "Befestigungsbohrungen"),
            subtitle: L10n.text(
                "Hole diameter and edge insets at the four corners", "パネル四隅の穴径と端からの距離",
                "Lochdurchmesser und Randabstände an den vier Ecken"), symbol: "circle.dotted",
            isEnabled: $options.addMountingHoles
        ) {
            LazyVGrid(columns: pairedSettingsColumns, alignment: .leading, spacing: 18) {
                labeledMeasurement(
                    L10n.text("X inset", "左右端から", "Abstand zum linken/rechten Rand"),
                    value: $options.mountingHoleOffsetXMM)
                labeledMeasurement(
                    L10n.text("Y inset", "上下端から", "Abstand zum oberen/unteren Rand"),
                    value: $options.mountingHoleOffsetYMM)
                labeledMeasurement(
                    L10n.text("Drill diameter", "ドリル径", "Bohrdurchmesser"), value: $options.mountingHoleDrillMM)
            }
        }
        .onChange(of: options.addMountingHoles) { _, enabled in
            if enabled {
                // EN: Initialize newly enabled hole centers at least one radius from the edge [mm].
                // JA: 新規に有効化した穴の中心を、端から半径以上離して初期化する [mm]。
                // DE: Mittelpunkte neu aktivierter Bohrungen mit mindestens einem Radius Abstand zum Rand
                //     initialisieren [mm].
                let inset = max(5, options.mountingHoleDrillMM / 2)
                if options.mountingHoleOffsetXMM == 0 {
                    options.mountingHoleOffsetXMM = inset
                }
                if options.mountingHoleOffsetYMM == 0 {
                    options.mountingHoleOffsetYMM = inset
                }
            }
        }
    }

    /// EN: Build frame/tab settings controls. Checkboxes toggle each feature.
    ///
    /// JA: 外枠・タブ等の設定表示を構築する。チェックボックスで有効・無効を切り替える。
    ///
    /// DE: Bedienelemente für Rahmen und Stege erstellen. Kontrollkästchen schalten die Funktionen ein und aus.
    private func routingCard<Content: View>(
        title: String, subtitle: String, symbol: String, isEnabled: Binding<Bool>? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: symbol)
                    .interfaceFont(.title3, weight: .semibold).foregroundStyle(.indigo)
                    .frame(width: 36, height: 36)
                    .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).interfaceFont(.headline)
                    Text(subtitle).interfaceFont(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if let isEnabled {
                    Toggle(title, isOn: isEnabled).labelsHidden().toggleStyle(.switch)
                        .accessibilityLabel(title)
                }
            }
            if isEnabled?.wrappedValue ?? true {
                Divider()
                content()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.07), lineWidth: 1))
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 16) {
                sectionHeading(
                    "03", title: L10n.text("Panel preview", "パネルプレビュー", "Nutzenvorschau"),
                    subtitle: L10n.text(
                        "Review board positions, routed outlines and connecting tabs", "基板の配置、加工後の外形、接続タブの位置を確認します",
                        "Leiterplattenpositionen, Fräskonturen und Verbindungsstege prüfen"))
                Spacer(minLength: 0)
                if let layout = previewLayout {
                    Text(
                        String(
                            format: "%.1f × %.1f mm", layout.panelBounds.maxX - layout.panelBounds.minX,
                            layout.panelBounds.maxY - layout.panelBounds.minY)
                    )
                    .interfaceFont(.caption, weight: .semibold, monospaced: true).foregroundStyle(.indigo)
                    .fixedSize()
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(.indigo.opacity(0.08), in: Capsule())
                }
            }
            VStack(spacing: 0) {
                PanelLayoutPreview(documents: documents, options: options, selection: previewSelection)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 360)
                Divider()
                HStack(alignment: .center, spacing: 16) {
                    if isGeneratingArtwork { ProgressView().controlSize(.small) }
                    VStack(alignment: .leading, spacing: 5) {
                        Text(L10n.text("Artwork preview", "完成プレビュー", "Fertigungsansicht")).interfaceFont(
                            .subheadline, weight: .semibold)
                        Text(
                            isGeneratingArtwork
                                ? artworkStatus
                                : L10n.text(
                                    "View copper, pads, silk and drill holes in a separate window.",
                                    "配線・パッド・シルク・穴を別ウィンドウで確認できます。",
                                    "Kupfer, Pads, Bestückungsdruck und Bohrungen in einem separaten Fenster anzeigen.")
                        )
                        .interfaceFont(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        Text(
                            L10n.text(
                                "Generated on request · Requires KiCad 10 or later", "ボタンを押した時だけ生成 · KiCad 10以降が必要",
                                "Erstellung auf Anfrage · Erfordert KiCad 10 oder neuer")
                        )
                        .interfaceFont(.caption2).foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Button {
                        openArtworkPreview()
                    } label: {
                        Label(
                            L10n.text("Open artwork preview", "完成プレビューを開く", "Fertigungsansicht öffnen"),
                            systemImage: "eye")
                    }
                    .buttonStyle(.bordered)
                    .fixedSize(horizontal: true, vertical: false)
                    .help(
                        L10n.text(
                            "Generate a new preview using the current panel settings", "現在の面付け設定で新しいプレビューを生成します",
                            "Eine neue Vorschau mit den aktuellen Nutzeneinstellungen erstellen")
                    )
                    .disabled(documents.isEmpty || previewLayout == nil || isProcessing || isGeneratingArtwork)
                }
                .padding(18)
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.07), lineWidth: 1))
        }
    }

    private var exportFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        L10n.text(
                            "Create one panel of \(boardCount) boards", "\(boardCount) 枚を1枚のパネルに配置",
                            "Einen Nutzen mit \(boardCount) \(boardCount == 1 ? "Leiterplatte" : "Leiterplatten") erstellen"
                        )
                    ).interfaceFont(.subheadline, weight: .semibold)
                    Text(
                        documents.isEmpty
                            ? L10n.text(
                                "Add a board file to begin", "基板ファイルを追加してください",
                                "Fügen Sie zunächst eine Leiterplattendatei hinzu")
                            : L10n.text(
                                "Export one panel file. Source files are preserved.", "1つの面付けファイルを出力します。元データは変更されません。",
                                "Eine Nutzendatei exportieren. Die Quelldateien bleiben erhalten.")
                    )
                    .interfaceFont(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    exportPanels()
                } label: {
                    Label(
                        L10n.text("Export panel", "面付け基板を書き出す", "Nutzen exportieren"),
                        systemImage: "square.and.arrow.down.fill"
                    )
                    .interfaceFont(.subheadline, weight: .semibold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent).tint(.indigo)
                .disabled(documents.isEmpty || isProcessing || isGeneratingArtwork || previewLayout == nil)
            }
            if includesBothFormats {
                Label(
                    L10n.text(
                        "EAGLE + KiCad → one .kicad_pcb panel. Conversion uses installed KiCad 10 or later.",
                        "EAGLE + KiCad → 1つの.kicad_pcbに統合します。形式変換にはインストール済みのKiCad 10以降を使用します。",
                        "EAGLE + KiCad → ein .kicad_pcb-Nutzen. Die Konvertierung verwendet das installierte KiCad 10 oder neuer."
                    ), systemImage: "arrow.triangle.merge"
                )
                .interfaceFont(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(17)
        .background(.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 15))
    }

    /// EN: Build a settings section from its number, title and description.
    ///
    /// JA: 見出し番号・タイトル・説明から設定セクションの表示を構築する。
    ///
    /// DE: Einen Einstellungsabschnitt aus Nummer, Titel und Beschreibung erstellen.
    private func sectionHeading(_ number: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).interfaceFont(.caption, weight: .bold, monospaced: true).foregroundStyle(.indigo)
                .padding(.horizontal, 8).padding(.vertical, 5).background(.indigo.opacity(0.1), in: Capsule())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).interfaceFont(.headline)
                Text(subtitle).interfaceFont(.caption).foregroundStyle(.secondary)
            }
        }
    }

    /// EN: Arrange a title and child View as a settings card. Numeric validation occurs at the engine boundary.
    ///
    /// JA: 指定タイトルと内部Viewを設定カードとして配置する。数値の検証はエンジン境界で行う。
    ///
    /// DE: Titel und untergeordnete View als Einstellungskarte anordnen. Zahlen werden an der Engine-Grenze geprüft.
    private func settingCard<Content: View>(title: String, symbol: String, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: symbol).interfaceFont(.caption).foregroundStyle(.secondary).fixedSize(
                horizontal: false, vertical: true)
            content()
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    /// EN: Build an input field in mm. Preserve input and report range violations through preview/export validation.
    ///
    /// JA: mm単位の入力欄を構築する。入力値は保持し、範囲違反をプレビュー・出力の検証で知らせる。
    ///
    /// DE: Ein Eingabefeld in mm erstellen. Den Eingabewert erhalten und Bereichsverletzungen über die
    ///     Vorschau-/Exportprüfung melden.
    private func measurementField(value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            TextField("0", value: value, format: .number.precision(.fractionLength(0...3)))
                .textFieldStyle(.roundedBorder).frame(width: 82 * textScale)
            Text("mm").interfaceFont(.caption).foregroundStyle(.secondary)
        }
    }

    /// EN: Return a View combining a label and an input field in mm.
    ///
    /// JA: 項目名とmm入力欄を組み合わせたViewを返す。
    ///
    /// DE: Eine View aus Beschriftung und Eingabefeld in mm zurückgeben.
    private func labeledMeasurement(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).interfaceFont(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            measurementField(value: value)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// EN: Collect file URLs in their original read order, regardless of asynchronous completion order.
    ///
    /// JA: ファイルURLを読み取り順に回収する。非同期取得の完了順で並べ替えない。
    ///
    /// DE: Datei-URLs in ihrer ursprünglichen Einlesereihenfolge sammeln, unabhängig von der Abschlussreihenfolge
    ///     asynchroner Abrufe.
    private func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        let candidates = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !candidates.isEmpty else { return false }
        let batch = DroppedBoardURLs()
        let group = DispatchGroup()
        for (index, provider) in candidates.enumerated() {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                let url: URL?
                if let data = item as? Data {
                    url = URL(dataRepresentation: data, relativeTo: nil)
                } else {
                    url = item as? URL
                }
                if let url { batch.append(url, at: index) }
            }
        }
        group.notify(queue: .main) { importBoards(batch.orderedURLs) }
        return true
    }

    /// EN: Check supported format, duplicates and parse results before adding to the list. Show failed filenames and
    ///     reasons.
    ///
    /// JA: 対応形式・重複・解析結果を確認して一覧へ追加する。失敗ファイル名と理由を表示する。
    ///
    /// DE: Unterstütztes Format, Duplikate und Parsergebnisse vor dem Hinzufügen prüfen. Fehlgeschlagene Dateinamen
    ///     mit Ursache anzeigen.
    private func importBoards(_ urls: [URL]) {
        var imported: [BoardDocument] = [], failures: [String] = []
        var known = Set(documents.map { $0.url.standardizedFileURL })
        for url in urls {
            guard let kind = boardKind(for: url), !known.contains(url.standardizedFileURL) else { continue }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let shape = try kind == .eagle ? EaglePanelEngine.shape(data: data) : KiCadPanelEngine.shape(data: data)
                let b = shape.bounds
                let summary = PanelSummary(
                    boardWidthMM: b.maxX - b.minX, boardHeightMM: b.maxY - b.minY, panelWidthMM: b.maxX - b.minX,
                    panelHeightMM: b.maxY - b.minY, columns: 1, rows: 1,
                    dimensionLineWidthMM: options.dimensionLineWidthMM)
                imported.append(BoardDocument(url: url, data: data, summary: summary, kind: kind, shape: shape))
                known.insert(url.standardizedFileURL)
            } catch { failures.append("\(url.lastPathComponent): \(error.localizedDescription)") }
        }
        documents.append(contentsOf: imported)
        previewSelection = imported.first?.id ?? documents.first?.id
        if imported.isEmpty && failures.isEmpty {
            present(
                L10n.text(
                    "No new supported boards were found. Already imported files are skipped.",
                    "新しい対応基板ファイルがありません。読み込み済みファイルは追加されません。",
                    "Keine neuen unterstützten Leiterplatten gefunden. Bereits importierte Dateien werden übersprungen."
                ))
        } else {
            var message = L10n.text(
                "Imported \(imported.count) boards. All listed boards will be combined into one panel.",
                "\(imported.count) 個の基板を読み込みました。リスト内の基板を1枚のパネルに統合します。",
                "\(imported.count) \(imported.count == 1 ? "Leiterplatte" : "Leiterplatten") importiert. Alle aufgelisteten Leiterplatten werden zu einem Nutzen zusammengefügt."
            )
            if !failures.isEmpty { message += "\n\n" + failures.joined(separator: "\n") }
            present(message)
        }
    }

    /// EN: Prevent input overwrites and atomically save only validated output.
    ///
    /// JA: 入力の上書きを防ぎ、検証済みの出力だけをアトミックに保存する。
    ///
    /// DE: Das Überschreiben von Eingaben verhindern und nur geprüfte Ausgaben atomar speichern.
    private func exportPanels() {
        guard let first = documents.first else { return }
        let outputExtension = documents.contains { $0.kind == .kicad } ? "kicad_pcb" : "brd"
        let chooser = NSSavePanel()
        chooser.title = L10n.text("Export one panel board", "1枚の面付け基板を書き出す", "Einen Leiterplattennutzen exportieren")
        chooser.prompt = L10n.text("Export", "書き出す", "Exportieren")
        chooser.canCreateDirectories = true
        chooser.allowedContentTypes = [UTType(filenameExtension: outputExtension) ?? .data]
        chooser.isExtensionHidden = false
        let stem = first.url.deletingPathExtension().lastPathComponent
        chooser.nameFieldStringValue =
            isMixedPanel
            ? "PCBPanel_\(documents.count)boards.\(outputExtension)"
            : "\(stem)_panel_\(options.columns)x\(options.rows).\(outputExtension)"
        guard chooser.runModal() == .OK, let destination = chooser.url else { return }
        guard !documents.contains(where: { PanelFileAccess.isSameFile($0.url, destination) }) else {
            present(
                L10n.text(
                    "Choose a different output filename to keep the source board unchanged.",
                    "元の基板ファイルを維持するため、別の出力ファイル名を選択してください。",
                    "Wählen Sie einen anderen Ausgabedateinamen, damit die ursprüngliche Leiterplattendatei unverändert bleibt."
                ))
            return
        }
        let hasAccess = destination.startAccessingSecurityScopedResource()
        isProcessing = true
        let sources = documents.map { PanelSource(name: $0.url.lastPathComponent, data: $0.data, kind: $0.kind) }
        let currentOptions = options.forSourceCount(sources.count)
        DispatchQueue.global(qos: .userInitiated).async {
            defer { if hasAccess { destination.stopAccessingSecurityScopedResource() } }
            do {
                let result = try PanelComposer.compose(sources: sources, options: currentOptions)
                try result.data.write(to: destination, options: .atomic)
                DispatchQueue.main.async {
                    isProcessing = false
                    present(
                        L10n.text(
                            "Exported one panel board.\n\(destination.path)", "1枚の面付け基板を書き出しました。\n\(destination.path)",
                            "Ein Leiterplattennutzen wurde exportiert.\n\(destination.path)"))
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false; present(error.localizedDescription)
                }
            }
        }
    }

    /// EN: Snapshot current inputs/settings and generate finished artwork off the main thread; deliver
    ///     success/failure on the main thread.
    ///
    /// JA: 現在の入力・設定を固定して別処理で完成画像を作る。成功・失敗をメインスレッドへ戻す。
    ///
    /// DE: Aktuelle Eingaben und Einstellungen festhalten, die fertige Darstellung außerhalb des Hauptthreads
    ///     erzeugen und Erfolg oder Fehler auf dem Hauptthread zurückmelden.
    private func openArtworkPreview() {
        let sources = documents.map { PanelSource(name: $0.url.lastPathComponent, data: $0.data, kind: $0.kind) }
        guard !sources.isEmpty, !isGeneratingArtwork else { return }
        let configuration = options.forSourceCount(sources.count)
        isGeneratingArtwork = true
        artworkStatus = L10n.text("Preparing artwork…", "完成プレビューを準備しています…", "Fertigungsansicht wird vorbereitet…")
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let artwork = try PanelArtworkRenderer.generate(sources: sources, options: configuration) { status in
                    DispatchQueue.main.async { artworkStatus = status }
                }
                DispatchQueue.main.async {
                    isGeneratingArtwork = false
                    PanelArtworkWindowController.show(artwork)
                }
            } catch {
                DispatchQueue.main.async {
                    isGeneratingArtwork = false; present(error.localizedDescription)
                }
            }
        }
    }

    /// EN: Return the supported board format for an extension, or nil for an unsupported format.
    ///
    /// JA: 拡張子から対応する基板形式を返す。未対応形式はnil。
    ///
    /// DE: Das unterstützte Platinenformat zur Dateiendung zurückgeben, bei nicht unterstütztem Format nil.
    private func boardKind(for url: URL) -> BoardKind? {
        switch url.pathExtension.lowercased() {
        case "brd": return .eagle
        case "kicad_pcb": return .kicad
        default: return nil
        }
    }

    /// EN: Remove the board with the specified ID and update preview selection.
    ///
    /// JA: 指定IDの基板を一覧から削除し、プレビューの選択を更新する。
    ///
    /// DE: Die Platine mit der angegebenen ID entfernen und die Vorschauauswahl aktualisieren.
    private func remove(_ document: BoardDocument) {
        documents.removeAll { $0.id == document.id }
        if previewSelection == document.id { previewSelection = documents.first?.id }
    }

    /// EN: Show the operation result or validation error to the user.
    ///
    /// JA: ユーザーへ処理結果または検証エラーを表示する。
    ///
    /// DE: Das Verarbeitungsergebnis oder den Validierungsfehler anzeigen.
    private func present(_ text: String) { notice = text; isShowingNotice = true }
}

private final class DroppedBoardURLs {
    private let lock = NSLock()
    private var values: [Int: URL] = [:]
    /// EN: Store retrieved file URLs with their original sequence numbers under mutual exclusion.
    ///
    /// JA: 取得したファイルURLを元の順序番号とともに排他制御して保存する。
    ///
    /// DE: Abgerufene Datei-URLs unter gegenseitigem Ausschluss mit ihrer ursprünglichen Reihenfolgenummer speichern.
    func append(_ url: URL, at index: Int) {
        lock.lock(); defer { lock.unlock() }
        values[index] = url
    }
    var orderedURLs: [URL] {
        lock.lock(); defer { lock.unlock() }
        return values.keys.sorted().compactMap { values[$0] }
    }
}

private struct PanelPreviewRequest: Equatable {
    let ids: [UUID]
    let options: PanelOptions
}

private struct RenderedPanel {
    let sourceIDs: [UUID]
    let options: PanelOptions
    let layout: PanelCompositionLayout
    let contours: [[[RoutePoint]]]
    let materialLoops: [[RoutePoint]]
    let routing: RoutingPlan
    let guides: [RouteSegment]
    let flipY: Bool
}

private struct PanelLayoutPreview: View {
    @Environment(\.interfaceTextScale) private var textScale
    let documents: [BoardDocument]
    let options: PanelOptions
    let selection: UUID?
    @State private var rendered: RenderedPanel?
    @State private var error: String?
    @State private var isUpdating = false

    var body: some View {
        ZStack(alignment: .center) {
            if documents.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 34)).foregroundStyle(.tertiary)
                    Text(L10n.text("Panel layout preview", "面付けレイアウトのプレビュー", "Vorschau der Nutzenanordnung"))
                        .interfaceFont(.title3, weight: .semibold)
                    Text(
                        L10n.text(
                            "Add board files to display the panel layout here.", "基板を追加すると、ここに面付け後の配置を表示します。",
                            "Fügen Sie Leiterplattendateien hinzu, um hier die Nutzenanordnung anzuzeigen.")
                    )
                    .interfaceFont(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else if let rendered, rendered.sourceIDs == documents.map(\.id) {
                drawing(rendered)
                    .padding(.vertical, 34)
            } else if isUpdating {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .overlay(alignment: .bottom) {
            if let rendered, rendered.sourceIDs == documents.map(\.id), !documents.isEmpty {
                let displayedOptions = rendered.options
                HStack(spacing: 12) {
                    Label(L10n.text("Board outlines", "基板外形", "Leiterplattenkonturen"), systemImage: "rectangle")
                        .foregroundStyle(.teal)
                    Label(
                        L10n.text("Panel routing", "パネル加工線", "Fräskontur des Nutzens"), systemImage: "rectangle.dashed"
                    ).foregroundStyle(.indigo)
                    if displayedOptions.addTabs {
                        Label(L10n.text("Breakaway tabs", "接続タブ", "Verbindungsstege"), systemImage: "link")
                            .foregroundStyle(.secondary)
                    }
                    if displayedOptions.perforateTabs && displayedOptions.addTabs {
                        Label(L10n.text("Mouse bites", "ミシン目", "Sollbruchbohrungen"), systemImage: "circle.dotted")
                            .foregroundStyle(.secondary)
                    }
                }
                .interfaceFont(.caption2)
                .padding(.horizontal, 16).padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .overlay(alignment: .topLeading) {
            if let error {
                Text(error).interfaceFont(.caption).foregroundStyle(.orange)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay(alignment: .topTrailing) {
            if isUpdating && rendered != nil { ProgressView().controlSize(.small).padding(12) }
        }
        .task(id: PanelPreviewRequest(ids: documents.map(\.id), options: options)) {
            guard !documents.isEmpty else { rendered = nil; error = nil; isUpdating = false; return }
            isUpdating = true
            // EN: Debounce edits and cancel obsolete geometry work when settings change, rather than letting detached
            //     jobs accumulate.
            // JA: 設定変更をまとめて反映し、古くなった形状計算をキャンセルする。独立した計算タスクの蓄積を防ぐ。
            // DE: Einstellungsänderungen verzögert bündeln und veraltete Geometrieberechnungen abbrechen, damit sich
            //     keine unabhängigen Aufgaben ansammeln.
            do { try await Task.sleep(for: .milliseconds(150)) } catch { return }
            let boards = documents, configuration = options.forSourceCount(documents.count)
            let worker = Task.detached(priority: .userInitiated) { () -> Result<RenderedPanel, Error> in
                Result {
                    let isCrossFormat = boards.contains { $0.kind == .kicad } && boards.contains { $0.kind == .eagle }
                    let shapes = boards.map { document -> PanelBoardShape in
                        let shape = document.shape
                        guard isCrossFormat && document.kind == .eagle else { return shape }
                        // EN: EAGLE's Y axis points up; KiCad's EAGLE importer reflects it into KiCad's downward Y
                        //     axis.
                        // JA: EAGLEのY軸は上向き。KiCadのEAGLEインポーターはこれを反転し、KiCadの下向きY軸へ変換する。
                        // DE: Die Y-Achse von EAGLE zeigt nach oben. Der EAGLE-Importer von KiCad spiegelt sie auf
                        //     die nach unten gerichtete Y-Achse von KiCad.
                        let b = shape.bounds
                        return PanelBoardShape(
                            bounds: RouteRect(minX: b.minX, minY: -b.maxY, maxX: b.maxX, maxY: -b.minY),
                            contours: shape.contours.map { $0.map { RoutePoint(x: $0.x, y: -$0.y) } })
                    }
                    let layout = try PanelCompositionLayout(bounds: shapes.map(\.bounds), options: configuration)
                    var routingOptions = configuration
                    let flip = boards.allSatisfy { $0.kind == .eagle }
                    if flip {
                        routingOptions.tabsTop = configuration.tabsBottom;
                        routingOptions.tabsBottom = configuration.tabsTop
                    }
                    let placed = try layout.placedContours(shapes)
                    let routing = try PanelRouting.plan(
                        boards: placed, arrayBounds: layout.arrayBounds, options: routingOptions)
                    let loops = try PanelRouting.closedLoops(routing.segments)
                    return RenderedPanel(
                        sourceIDs: boards.map(\.id), options: configuration, layout: layout, contours: placed,
                        materialLoops: loops, routing: routing, guides: try layout.guides(options: configuration),
                        flipY: flip)
                }
            }
            let result = await withTaskCancellationHandler(
                operation: { await worker.value }, onCancel: { worker.cancel() })
            guard !Task.isCancelled else { return }
            isUpdating = false
            switch result {
            case .success(let panel): rendered = panel; error = nil
            case .failure(let failure): rendered = nil; error = failure.localizedDescription
            }
        }
    }

    /// EN: Draw placements, outlines and holes from the same generation on Canvas. Keep source [mm] and screen
    ///     [points] separate.
    ///
    /// JA: 同じ生成世代の配置・外形・穴をCanvasへ描く。元データ [mm] と画面 [point] を分離する。
    ///
    /// DE: Platzierungen, Konturen und Bohrungen desselben Erzeugungsstands auf das Canvas zeichnen. Quelldaten [mm]
    ///     und Bildschirmwerte [Points] getrennt halten.
    private func drawing(_ panel: RenderedPanel) -> some View {
        let options = panel.options
        return Canvas { context, size in
            let bounds = panel.layout.panelBounds
            let width = bounds.maxX - bounds.minX, height = bounds.maxY - bounds.minY
            guard width > 0, height > 0, size.width > 48, size.height > 48 else { return }
            let scale = min((size.width - 48) / width, (size.height - 48) / height)
            let origin = CGPoint(x: (size.width - width * scale) / 2, y: (size.height - height * scale) / 2)
            /// EN: Convert validated coordinates [mm] to screen points using the scale and origin from the same
            ///     drawing snapshot.
            ///
            /// JA: 検証済みmm座標を画面上のpointへ変換する。倍率と原点は同じ描画スナップショットを使う。
            ///
            /// DE: Geprüfte Koordinaten [mm] mit Skalierung und Ursprung desselben Zeichenschnappschusses in
            ///     Bildschirm-Points umwandeln.
            func screen(_ point: RoutePoint) -> CGPoint {
                CGPoint(
                    x: origin.x + (point.x - bounds.minX) * scale,
                    y: origin.y + (panel.flipY ? bounds.maxY - point.y : point.y - bounds.minY) * scale)
            }
            /// EN: Convert validated contours to closed Canvas paths. Ignore empty loops.
            ///
            /// JA: 検証済みの輪郭をCanvasの閉じたパスへ変換する。空ループは無視する。
            ///
            /// DE: Geprüfte Konturen in geschlossene Canvas-Pfade umwandeln. Leere Schleifen ignorieren.
            func path(_ loops: [[RoutePoint]]) -> Path {
                var result = Path()
                for loop in loops {
                    guard let first = loop.first else { continue }
                    result.move(to: screen(first))
                    for point in loop.dropFirst() { result.addLine(to: screen(point)) }
                    result.closeSubpath()
                }
                return result
            }
            let material = path(panel.materialLoops)
            context.fill(material, with: .color(.indigo.opacity(0.14)), style: FillStyle(eoFill: true))
            context.stroke(material, with: .color(.indigo.opacity(0.8)), lineWidth: 1.2)
            let palette: [Color] = [.teal, .blue, .orange, .pink, .purple]
            for (index, placement) in panel.layout.placements.enumerated() {
                guard documents.indices.contains(placement.sourceIndex), panel.contours.indices.contains(index) else {
                    continue
                }
                let document = documents[placement.sourceIndex]
                let color = palette[placement.sourceIndex % palette.count]
                let selected = document.id == selection
                let boardPath = path(panel.contours[index])
                context.fill(
                    boardPath, with: .color(color.opacity(selected ? 0.32 : 0.15)), style: FillStyle(eoFill: true))
                context.stroke(
                    boardPath, with: .color(color.opacity(selected ? 1 : 0.5)),
                    style: StrokeStyle(lineWidth: selected ? 1.8 : 0.8, dash: [3, 2]))
                let b = placement.bounds
                let center = screen(RoutePoint(x: (b.minX + b.maxX) / 2, y: (b.minY + b.maxY) / 2))
                let pixels = min((b.maxX - b.minX) * scale, (b.maxY - b.minY) * scale)
                let availableWidth = (b.maxX - b.minX) * scale - 12
                if pixels > 28 * textScale && availableWidth > 48 * textScale {
                    let fontSize = min(13 * textScale, max(9 * textScale, pixels / 8))
                    let capacity = max(3, Int(availableWidth / (fontSize * 0.8)))
                    let fullLabel =
                        "\(placement.sourceIndex + 1) · " + document.url.deletingPathExtension().lastPathComponent
                    let title = fullLabel.count > capacity ? String(fullLabel.prefix(capacity - 1)) + "…" : fullLabel
                    let label = context.resolve(
                        Text(title).font(.system(size: fontSize, weight: selected ? .bold : .medium)).foregroundColor(
                            .primary))
                    context.draw(label, at: center)
                }
            }
            for guide in panel.guides {
                var line = Path(); line.move(to: screen(guide.a)); line.addLine(to: screen(guide.b))
                context.stroke(line, with: .color(.orange), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
            /// EN: Draw validated hole centers and diameters [mm] as circles discernible on screen.
            ///
            /// JA: 検証済みの穴中心・直径 [mm] を、画面上で判別できる円として描く。
            ///
            /// DE: Geprüfte Bohrungsmittelpunkte und Durchmesser [mm] als auf dem Bildschirm erkennbare Kreise
            ///     zeichnen.
            func drawHole(_ point: RoutePoint, diameter: Double) {
                let p = screen(point), radius = max(0.65, diameter * scale / 2)
                let circle = Path(
                    ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
                context.fill(circle, with: .color(Color(nsColor: .windowBackgroundColor)))
                context.stroke(circle, with: .color(.secondary), lineWidth: 0.5)
            }
            for hole in panel.routing.mouseBites { drawHole(hole, diameter: options.mouseBiteDiameterMM) }
            if options.addMountingHoles {
                let dx = options.mountingHoleOffsetXMM, dy = options.mountingHoleOffsetYMM
                for point in [
                    RoutePoint(x: bounds.minX + dx, y: bounds.minY + dy),
                    RoutePoint(x: bounds.maxX - dx, y: bounds.minY + dy),
                    RoutePoint(x: bounds.minX + dx, y: bounds.maxY - dy),
                    RoutePoint(x: bounds.maxX - dx, y: bounds.maxY - dy),
                ] { drawHole(point, diameter: options.mountingHoleDrillMM) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
