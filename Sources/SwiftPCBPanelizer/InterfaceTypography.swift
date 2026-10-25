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

// EN: String/character literals are defined in TextConstants.Typography, Common and Characters; variable text uses constant templates.
// JA: 文字列・文字リテラルはTextConstants.Typography・Common・Charactersに定義し、可変文は定数テンプレートから生成する。
// DE: Zeichenketten-/Zeichenliterale stehen in TextConstants.Typography, Common und Characters; variable Texte nutzen konstante Vorlagen.

enum InterfaceTypography {
    static let storageKey = TextConstants.Typography.interfaceTextSizeStorageKey
    static let defaultPercent = 115
    static let range = 100...160
    /// EN: Maximum live layout update rate [updates/second]; slider tracking remains continuous.
    /// JA: ドラッグ中のレイアウト更新頻度の上限 [回/秒]。スライダーの追従は連続のままにする。
    /// DE: Maximale Frequenz der Live-Layoutaktualisierung [Änderungen/Sekunde]; der Schieberegler bleibt kontinuierlich.
    static let liveUpdatesPerSecond = 30.0
    /// EN: Fixed editor dimensions [points], shared by the native popover and SwiftUI content.
    /// JA: ネイティブの調整画面とSwiftUI内容で共用する固定寸法 [point]。
    /// DE: Feste Editorabmessungen [Punkte], gemeinsam für natives Popover und SwiftUI-Inhalt.
    static let editorSize = CGSize(width: 360, height: 300)
    /// EN: Native slider layout [points]. Reserve room for its permanently visible thumb on the first layout pass.
    /// JA: ネイティブスライダーの寸法 [point]。初回配置から常時表示のつまみの領域を確保する。
    /// DE: Native Reglerabmessungen [Punkte]. Bereits beim ersten Layout Platz für den dauerhaft sichtbaren Griff vorsehen.
    static let sliderSize = CGSize(width: 316, height: 24)
    /// EN: Visible thumb diameter [points], independent of interface font scale.
    /// JA: 常時表示するつまみの直径 [point]。画面の文字倍率から独立させる。
    /// DE: Durchmesser des sichtbaren Griffs [Punkte], unabhängig von der Schriftgrößenskalierung.
    static let sliderKnobDiameter: CGFloat = 18

    /// EN: Bound continuous preview values [%] without rounding away sub-percent slider movement.
    /// JA: 1%未満の移動も保持し、連続プレビュー値 [%] を許容範囲に制限する。
    /// DE: Kontinuierliche Vorschauwerte [%] begrenzen, ohne Bewegungen unter einem Prozent zu runden.
    static func continuousPercent(_ value: Double) -> Double {
        guard value.isFinite else { return Double(defaultPercent) }
        return min(Double(range.upperBound), max(Double(range.lowerBound), value))
    }

    /// EN: Clamp display text size [%] to its allowed range. Do not use this for board dimensions.
    ///
    /// JA: 表示用の文字サイズ [%] を許容範囲へ収めて返す。基板の寸法値には使用しない。
    ///
    /// DE: Die angezeigte Schriftgröße [%] auf den zulässigen Bereich begrenzen. Nicht für Platinenabmessungen
    ///     verwenden.
    static func clamped(_ percent: Int) -> Int { min(range.upperBound, max(range.lowerBound, percent)) }
    /// EN: Validate the slider's temporary value [%] before converting to an integer. Reset NaN/infinity to the
    ///     default.
    ///
    /// JA: スライダーの一時値 [%] を整数にする前に検証する。NaN/無限大は初期値へ戻す。
    ///
    /// DE: Den temporären Schiebereglerwert [%] vor der Ganzzahlumwandlung prüfen. NaN und Unendlich auf den
    ///     Standardwert zurücksetzen.
    static func clamped(_ percent: Double) -> Int {
        guard percent.isFinite else {
            return defaultPercent
        }
        return Int(min(Double(range.upperBound), max(Double(range.lowerBound), percent.rounded())))
    }

    /// EN: Keep UI scale within 100–160%. This display setting is independent of board dimension validation.
    ///
    /// JA: UI倍率 [倍] は100〜160%の範囲へ揃える。基板寸法の検証とは独立した表示設定。
    ///
    /// DE: Die UI-Skalierung auf 100–160 % begrenzen. Diese Anzeigeeinstellung ist unabhängig von der Prüfung der
    ///     Platinenabmessungen.
    static func boundedScale(_ scale: Double) -> Double {
        guard scale.isFinite else {
            return Self.scale(for: defaultPercent)
        }
        return min(Double(range.upperBound) / 100, max(Double(range.lowerBound) / 100, scale))
    }

    /// EN: Convert validated, clamped text size [%] to a scale factor.
    ///
    /// JA: 検証・制限済みの文字サイズ [%] を倍率 [倍] に変換して返す。
    ///
    /// DE: Die geprüfte und begrenzte Schriftgröße [%] in einen Skalierungsfaktor umwandeln.
    static func scale(for percent: Int) -> Double { Double(clamped(percent)) / 100 }
}

/// EN: Share live typography in memory across windows; write preferences only when an edit ends.
/// JA: 全ウィンドウの文字サイズをメモリ上で共有し、編集終了時だけ設定へ保存する。
/// DE: Die Live-Schriftgröße im Speicher zwischen Fenstern teilen und erst am Ende einer Änderung speichern.
@MainActor
private final class InterfaceTypographyState: NSObject, ObservableObject {
    static let shared = InterfaceTypographyState()
    /// EN: Current live percentage [%], including sub-percent movement.
    /// JA: 1%未満の移動を含む、現在のライブ表示割合 [%]。
    /// DE: Aktueller Live-Prozentwert [%] einschließlich Bewegungen unter einem Prozent.
    @Published private(set) var percent: Double
    /// EN: Last persisted percentage [%], avoiding duplicate preference writes.
    /// JA: 最後に保存した割合 [%]。同じ設定の重複保存を避ける。
    /// DE: Zuletzt gespeicherter Prozentwert [%], um doppelte Schreibvorgänge zu vermeiden.
    private var savedPercent: Int
    /// EN: Latest unpublished slider percentage [%]; intermediate samples are coalesced.
    /// JA: 反映待ちの最新割合 [%]。途中の値をまとめて扱う。
    /// DE: Jüngster noch unveröffentlichter Reglerwert [%]; Zwischenwerte werden gebündelt.
    private var pendingPercent: Double?
    /// EN: At most one preview timer, scheduled in common run-loop modes.
    /// JA: 共通RunLoopモードに登録するプレビュー用タイマー。最大1個だけ保持する。
    /// DE: Höchstens ein Vorschautimer in gemeinsamen RunLoop-Modi.
    private var updateTimer: Timer?
    /// EN: Last publication time [monotonic uptime seconds], independent of wall-clock adjustments.
    /// JA: 最終反映時刻 [単調増加の稼働秒数]。時計の時刻補正には影響されない。
    /// DE: Letzte Veröffentlichung [monotone Betriebssekunden], unabhängig von Uhrzeitkorrekturen.
    private var lastUpdateTime = 0.0

    /// EN: Load and validate the persisted percentage once at launch.
    /// JA: 起動時に保存済みの割合を一度読み込み、検証する。
    /// DE: Den gespeicherten Prozentwert beim Start einmal laden und prüfen.
    private override init() {
        let saved = UserDefaults.standard.object(forKey: InterfaceTypography.storageKey) as? NSNumber
        let initial = InterfaceTypography.clamped(saved?.doubleValue ?? Double(InterfaceTypography.defaultPercent))
        percent = Double(initial)
        savedPercent = initial
        super.init()
    }

    /// EN: Coalesce the latest bounded slider value. Common run-loop modes keep updates active during mouse tracking.
    /// JA: 範囲を確認した最新値をまとめて反映する。共通RunLoopモードでマウス追跡中も更新を継続する。
    /// DE: Den jüngsten begrenzten Wert bündeln. Gemeinsame RunLoop-Modi aktualisieren auch während der Mausverfolgung.
    func preview(_ value: Double) {
        pendingPercent = InterfaceTypography.continuousPercent(value)
        guard updateTimer == nil else { return }
        let interval = 1 / InterfaceTypography.liveUpdatesPerSecond
        let remaining = interval - (ProcessInfo.processInfo.systemUptime - lastUpdateTime)
        if remaining <= 0 {
            applyPendingPreview()
        } else {
            let timer = Timer(
                timeInterval: remaining, target: self, selector: #selector(applyPendingPreview), userInfo: nil,
                repeats: false)
            updateTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    /// EN: Publish only the newest preview, without animation or disk writes, then release the timer.
    /// JA: アニメーションやディスク保存を行わず最新のプレビューだけを配信し、タイマーを解放する。
    /// DE: Nur die neueste Vorschau ohne Animation oder Dateizugriff veröffentlichen und den Timer freigeben.
    @objc private func applyPendingPreview() {
        updateTimer?.invalidate()
        updateTimer = nil
        guard let pending = pendingPercent else { return }
        pendingPercent = nil
        lastUpdateTime = ProcessInfo.processInfo.systemUptime
        let value = InterfaceTypography.continuousPercent(pending)
        if percent != value {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) { percent = value }
        }
    }

    /// EN: Cancel delayed previews, apply the exact rounded final value [%], and persist a changed preference once.
    /// JA: 遅延プレビューを取り消し、確定した割合 [%] を整数に丸めて即時反映する。変更時だけ一度保存する。
    /// DE: Verzögerte Vorschauen abbrechen, den gerundeten Endwert [%] sofort anwenden und Änderungen einmal speichern.
    func commit(_ value: Double) {
        updateTimer?.invalidate()
        updateTimer = nil
        pendingPercent = nil
        let final = InterfaceTypography.clamped(value)
        lastUpdateTime = ProcessInfo.processInfo.systemUptime
        if percent != Double(final) {
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            withTransaction(transaction) { percent = Double(final) }
        }
        if savedPercent != final {
            UserDefaults.standard.set(final, forKey: InterfaceTypography.storageKey)
            savedPercent = final
        }
    }

    /// EN: Preserve the latest pending value if the editor closes during a gesture.
    /// JA: 操作途中で調整画面が閉じても、反映待ちの最新値を確定する。
    /// DE: Beim Schließen während einer Geste den jüngsten noch ausstehenden Wert übernehmen.
    func commitLatest() { commit(pendingPercent ?? percent) }
}

private struct InterfaceTextScaleKey: EnvironmentKey {
    static let defaultValue = InterfaceTypography.scale(for: InterfaceTypography.defaultPercent)
}

extension EnvironmentValues {
    var interfaceTextScale: Double {
        get { self[InterfaceTextScaleKey.self] }
        set { self[InterfaceTextScaleKey.self] = InterfaceTypography.boundedScale(newValue) }
    }
}

enum InterfaceTextStyle {
    case body, headline, subheadline, caption, caption2, title3, title2, hero

    private var size: Double {
        switch self {
        case .body: return 13
        case .headline: return 14
        case .subheadline: return 12
        case .caption: return 11
        case .caption2: return 10
        case .title3: return 15
        case .title2: return 17
        case .hero: return 30
        }
    }

    /// EN: Validate the display scale and create a font. Board geometry is unaffected.
    ///
    /// JA: 表示倍率を検証してフォントを作る。基板の幾何寸法には影響しない。
    ///
    /// DE: Die Anzeigeskalierung prüfen und eine Schrift erstellen. Die Platinengeometrie bleibt unverändert.
    func font(scale: Double, weight: Font.Weight? = nil, monospaced: Bool = false, design: Font.Design = .default)
        -> Font
    {
        let emphasis: Font.Weight = self == .headline ? .semibold : .regular
        let font = Font.system(
            size: size * InterfaceTypography.boundedScale(scale), weight: weight ?? emphasis, design: design)
        return monospaced ? font.monospacedDigit() : font
    }
}

private struct InterfaceFontModifier: ViewModifier {
    @Environment(\.interfaceTextScale) private var scale
    let style: InterfaceTextStyle
    let weight: Font.Weight?
    let monospaced: Bool
    let design: Font.Design

    /// EN: Return a View with the validated display scale applied. Do not treat this value as a board coordinate.
    ///
    /// JA: 検証済みの表示倍率を適用したViewを返す。数値を基板座標として扱わない。
    ///
    /// DE: Eine View mit der geprüften Anzeigeskalierung zurückgeben. Diesen Wert nicht als Platinenkoordinate
    ///     behandeln.
    func body(content: Content) -> some View {
        content.font(style.font(scale: scale, weight: weight, monospaced: monospaced, design: design))
    }
}

private struct InterfaceTypographyModifier: ViewModifier {
    @ObservedObject private var typography = InterfaceTypographyState.shared

    /// EN: Return a View with the validated display scale applied. Do not treat this value as a board coordinate.
    ///
    /// JA: 検証済みの表示倍率を適用したViewを返す。数値を基板座標として扱わない。
    ///
    /// DE: Eine View mit der geprüften Anzeigeskalierung zurückgeben. Diesen Wert nicht als Platinenkoordinate
    ///     behandeln.
    func body(content: Content) -> some View {
        let scale = InterfaceTypography.continuousPercent(typography.percent) / 100
        content
            .environment(\.interfaceTextScale, scale)
            .font(InterfaceTextStyle.body.font(scale: scale))
            .controlSize(scale >= 1.35 ? .large : .regular)
    }
}

extension View {
    /// EN: Return a display View using the specified style, weight and scale.
    ///
    /// JA: 指定スタイル・太さ・倍率を使う表示用Viewを返す。
    ///
    /// DE: Eine Anzeige-View mit dem angegebenen Stil, Schriftgewicht und Skalierungsfaktor zurückgeben.
    func interfaceFont(
        _ style: InterfaceTextStyle, weight: Font.Weight? = nil,
        monospaced: Bool = false, design: Font.Design = .default
    ) -> some View {
        modifier(InterfaceFontModifier(style: style, weight: weight, monospaced: monospaced, design: design))
    }

    /// EN: Return a View with a text size environment that follows the user's preference.
    ///
    /// JA: ユーザー設定に従う文字サイズ環境を付加したViewを返す。
    ///
    /// DE: Eine View mit einer Schriftgrößenumgebung gemäß der Benutzereinstellung zurückgeben.
    func interfaceTypography() -> some View { modifier(InterfaceTypographyModifier()) }
}

@MainActor
struct InterfaceTextSizeControl: View {
    @State private var anchorView = NSView(frame: .zero)

    var body: some View {
        Button {
            InterfaceTextPopoverController.shared.toggle(from: anchorView)
        } label: {
            Label(
                L10n.text(
                    TextConstants.Typography.textSizeEnglish, TextConstants.Typography.textSizeJapanese,
                    TextConstants.Typography.textSizeGerman), systemImage: TextConstants.Typography.tokenTextformatSize)
        }
        // EN: Restore the original adaptive label while keeping live resizing independent of the popover anchor.
        // JA: 以前の表示場所に応じたラベルへ戻し、ライブ拡大縮小とポップオーバーのアンカーは独立させる。
        // DE: Die ursprüngliche adaptive Beschriftung wiederherstellen und Live-Skalierung vom Popover-Anker trennen.
        .font(InterfaceTextStyle.body.font(scale: 1))
        .controlSize(.regular)
        .help(
            L10n.text(
                TextConstants.Typography.adjustTextSizeInAllAppWindowsEnglish,
                TextConstants.Typography.adjustTextSizeInAllAppWindowsJapanese,
                TextConstants.Typography.adjustTextSizeInAllAppWindowsGerman)
        )
        .background {
            InterfaceTextPopoverAnchor(view: anchorView).allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

/// EN: Anchor the editor to the stable window content view, independent of toolbar/preview layout replacements.
/// JA: 調整画面を固定のウィンドウ内容Viewに紐付け、ツールバーやプレビューの再配置から独立させる。
/// DE: Den Editor an die stabile Fensterinhaltsansicht binden, unabhängig vom Neuaufbau der Werkzeugleiste/Vorschau.
@MainActor
private final class InterfaceTextPopoverController: NSObject, NSPopoverDelegate {
    static let shared = InterfaceTextPopoverController()
    private var popover: NSPopover?
    private weak var sourceWindow: NSWindow?

    /// EN: Toggle a fixed-size editor near its button, keeping the anchor inside the source window.
    /// JA: ボタン付近で固定サイズの調整画面を開閉し、アンカーを元ウィンドウ内に収める。
    /// DE: Einen Editor fester Größe am Knopf öffnen/schließen und den Anker im Ausgangsfenster halten.
    func toggle(from anchorView: NSView) {
        guard let window = anchorView.window, let content = window.contentView else { return }
        let wasSameWindow = sourceWindow === window
        if let popover, popover.isShown {
            popover.performClose(anchorView)
            if wasSameWindow { return }
        }
        guard content.bounds.width > 0, content.bounds.height > 0 else { return }
        let converted = anchorView.convert(anchorView.bounds, to: content)
        let width = min(converted.width, content.bounds.width)
        let height = min(converted.height, content.bounds.height)
        let anchor = NSRect(
            x: min(max(converted.minX, content.bounds.minX), content.bounds.maxX - width),
            y: min(max(converted.minY, content.bounds.minY), content.bounds.maxY - height),
            width: width, height: height)
        let editor = NSPopover()
        editor.behavior = .transient
        editor.delegate = self
        editor.contentViewController = NSHostingController(rootView: InterfaceTextSettingsView())
        editor.contentSize = InterfaceTypography.editorSize
        popover = editor
        sourceWindow = window
        editor.show(relativeTo: anchor, of: content, preferredEdge: .minY)
    }

    /// EN: Commit before the close animation, so a delayed old-popover callback cannot interrupt a newly opened editor.
    /// JA: 閉じるアニメーションの前に確定し、旧画面の遅い通知が新しく開いた調整を妨げないようにする。
    /// DE: Vor der Schließanimation übernehmen, damit verspätete alte Rückrufe einen neuen Editor nicht unterbrechen.
    func popoverWillClose(_ notification: Notification) {
        if let closing = notification.object as? NSPopover, closing === popover {
            InterfaceTypographyState.shared.commitLatest()
        }
    }

    /// EN: Release references only for the popover that actually closed.
    /// JA: 実際に閉じた調整画面の参照だけを解放する。
    /// DE: Nur die Verweise des tatsächlich geschlossenen Popovers freigeben.
    func popoverDidClose(_ notification: Notification) {
        if let closed = notification.object as? NSPopover, closed === popover {
            popover = nil
            sourceWindow = nil
        }
    }
}

private struct InterfaceTextPopoverAnchor: NSViewRepresentable {
    let view: NSView
    /// EN: Supply an invisible anchor to the original SwiftUI button without changing its label or hit testing.
    /// JA: ラベルやクリック判定を変えず、元のSwiftUIボタンに不可視のアンカーを付ける。
    /// DE: Dem ursprünglichen SwiftUI-Knopf einen unsichtbaren Anker geben, ohne Beschriftung oder Trefferprüfung zu ändern.
    func makeNSView(context: Context) -> NSView { view }
    /// EN: Retain the same anchor instance through typography updates.
    /// JA: 文字サイズの更新中も同じアンカーのインスタンスを保持する。
    /// DE: Dieselbe Ankerinstanz bei Schriftgrößenänderungen beibehalten.
    func updateNSView(_ view: NSView, context: Context) {}
}

/// EN: Let AppKit own mouse tracking so SwiftUI font/layout updates cannot interrupt the slider gesture.
/// JA: マウス追跡をAppKitが保持し、SwiftUIのフォントや配置の更新でスライダー操作が途切れないようにする。
/// DE: AppKit die Mausverfolgung überlassen, damit SwiftUI-Schrift-/Layoutänderungen die Reglergeste nicht unterbrechen.
private struct InterfaceTextSlider: NSViewRepresentable {
    @Binding var value: Double
    let onEditingChanged: (Bool) -> Void

    /// EN: Draw a thumb unconditionally, including before hover or focus. Native slider cells still handle input.
    /// JA: ホバーやフォーカス前も含め、つまみを常時描画する。操作は引き続きネイティブのスライダーセルが扱う。
    /// DE: Den Griff auch vor Mausberührung oder Fokus stets zeichnen. Die native Reglerzelle verarbeitet weiter die Eingabe.
    final class VisibleKnobCell: NSSliderCell {
        /// EN: Paint the native track, then a single visible thumb at the native value position.
        /// JA: ネイティブのバーを描画し、その値に対応する位置へ常時表示のつまみを1個描く。
        /// DE: Die native Spur und anschließend einen sichtbaren Griff an der nativen Wertposition zeichnen.
        override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
            super.draw(withFrame: cellFrame, in: controlView)
            let diameter = InterfaceTypography.sliderKnobDiameter
            guard cellFrame.width.isFinite, cellFrame.height.isFinite, cellFrame.minX.isFinite, cellFrame.midY.isFinite,
                cellFrame.width >= diameter, cellFrame.height >= diameter
            else { return }
            let nativeKnob = knobRect(flipped: controlView.isFlipped)
            let nativeCenter = nativeKnob.midX
            let fraction = min(1, max(0, (doubleValue - minValue) / max(1, maxValue - minValue)))
            let fallback = cellFrame.minX + diameter / 2 + CGFloat(fraction) * (cellFrame.width - diameter)
            let center = nativeKnob.width > 0 && nativeCenter.isFinite ? nativeCenter : fallback
            let x = min(max(center - diameter / 2, cellFrame.minX), cellFrame.maxX - diameter)
            let rect = NSRect(x: x, y: cellFrame.midY - diameter / 2, width: diameter, height: diameter)
            let thumb = NSBezierPath(ovalIn: rect.insetBy(dx: 0.75, dy: 0.75))
            NSGraphicsContext.saveGraphicsState()
            defer { NSGraphicsContext.restoreGraphicsState() }
            let shadow = NSShadow()
            shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
            shadow.shadowBlurRadius = 2
            shadow.shadowOffset = NSSize(width: 0, height: -1)
            shadow.set()
            NSColor.white.setFill()
            thumb.fill()
            let noShadow = NSShadow()
            noShadow.shadowColor = nil
            noShadow.set()
            NSColor.separatorColor.setStroke()
            thumb.lineWidth = 0.75
            thumb.stroke()
        }

        /// EN: Draw the thumb once after the track so the system's hover-only drawing never hides or duplicates it.
        /// JA: バーの後に1回だけ描くため、システムのホバー時描画でつまみが隠れたり重複したりしない。
        /// DE: Den Griff einmal nach der Spur zeichnen, damit systemabhängiges Hover-Zeichnen ihn weder versteckt noch verdoppelt.
        override func drawKnob(_ knobRect: NSRect) {}
    }

    final class TrackingSlider: NSSlider {
        var editingChanged: ((Bool) -> Void)?
        /// EN: Bracket the complete native tracking loop, including cancellation, with begin/end edit callbacks.
        /// JA: 操作の中断も含め、ネイティブ追跡ループ全体を編集開始・終了の通知で囲む。
        /// DE: Die gesamte native Verfolgung einschließlich Abbruch mit Anfangs-/Endmeldungen der Bearbeitung umschließen.
        override func mouseDown(with event: NSEvent) {
            editingChanged?(true)
            defer { editingChanged?(false) }
            super.mouseDown(with: event)
        }
    }
    final class Coordinator: NSObject {
        var parent: InterfaceTextSlider
        /// EN: Retain bindings and callbacks belonging to this slider instance.
        /// JA: このスライダーのBindingと通知先を保持する。
        /// DE: Bindungen und Rückrufe dieser Reglerinstanz halten.
        init(_ parent: InterfaceTextSlider) { self.parent = parent }
        /// EN: Validate each continuous AppKit value before forwarding it to the preview state.
        /// JA: AppKitからの連続値を検証してからプレビュー状態へ渡す。
        /// DE: Jeden kontinuierlichen AppKit-Wert vor der Übergabe an den Vorschauzustand prüfen.
        @MainActor @objc func changed(_ sender: NSSlider) {
            parent.value = InterfaceTypography.continuousPercent(sender.doubleValue)
            // EN: Redraw the custom thumb for every native tracking event, independently of throttled font updates.
            // JA: 文字サイズの反映頻度とは独立して、ネイティブの操作ごとにつまみを再描画する。
            // DE: Den eigenen Griff bei jedem nativen Verfolgungsereignis unabhängig von begrenzten Schriftupdates neu zeichnen.
            sender.needsDisplay = true
        }
    }
    /// EN: Retain the target that owns the current SwiftUI binding.
    /// JA: 現在のSwiftUIのBindingを持つ操作先を保持する。
    /// DE: Das Aktionsziel mit der aktuellen SwiftUI-Bindung halten.
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    /// EN: Configure a continuous native slider with bounded values and regular, unscaled controls.
    /// JA: 範囲を制限した連続スライダーを、拡大縮小しない標準サイズで構成する。
    /// DE: Einen kontinuierlichen nativen Regler mit begrenzten Werten und nicht skalierten Standardmaßen konfigurieren.
    func makeNSView(context: Context) -> TrackingSlider {
        let slider = TrackingSlider(frame: NSRect(origin: .zero, size: InterfaceTypography.sliderSize))
        slider.cell = VisibleKnobCell()
        slider.sliderType = .linear
        slider.isVertical = false
        slider.isEnabled = true
        slider.numberOfTickMarks = 0
        slider.allowsTickMarkValuesOnly = false
        slider.minValue = Double(InterfaceTypography.range.lowerBound)
        slider.maxValue = Double(InterfaceTypography.range.upperBound)
        slider.doubleValue = InterfaceTypography.continuousPercent(value)
        slider.controlSize = .regular
        slider.isContinuous = true
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.changed(_:))
        slider.editingChanged = onEditingChanged
        slider.setAccessibilityLabel(
            L10n.text(
                TextConstants.Typography.textSizeEnglish, TextConstants.Typography.textSizeJapanese,
                TextConstants.Typography.textSizeGerman))
        return slider
    }
    /// EN: Supply a horizontal size even before AppKit has an intrinsic frame, keeping the thumb inside the editor.
    /// JA: AppKitの実寸が決まる前から横向きのサイズを返し、つまみを調整画面内に収める。
    /// DE: Schon vor dem intrinsischen AppKit-Rahmen horizontale Maße liefern und den Griff im Editor halten.
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: TrackingSlider, context: Context) -> CGSize? {
        let proposed = proposal.width ?? InterfaceTypography.sliderSize.width
        let width = proposed.isFinite && proposed > 0 ? proposed : InterfaceTypography.sliderSize.width
        return CGSize(
            width: max(InterfaceTypography.sliderKnobDiameter, width), height: InterfaceTypography.sliderSize.height)
    }

    /// EN: Update callbacks in place without replacing the view that is tracking the mouse.
    /// JA: マウスを追跡しているViewを置き換えず、通知先と値だけを更新する。
    /// DE: Rückrufe und Werte aktualisieren, ohne die mausverfolgende Ansicht zu ersetzen.
    func updateNSView(_ view: TrackingSlider, context: Context) {
        context.coordinator.parent = self
        view.editingChanged = onEditingChanged
        let bounded = InterfaceTypography.continuousPercent(value)
        if view.doubleValue != bounded {
            view.doubleValue = bounded
            view.needsDisplay = true
        }
        view.setAccessibilityValue(TextConstants.Typography.percentageTemplate(InterfaceTypography.clamped(bounded)))
    }
}

struct InterfaceTextSettingsView: View {
    @ObservedObject private var typography = InterfaceTypographyState.shared
    @State private var draftPercent = Double(InterfaceTypography.defaultPercent)
    @State private var isEditing = false
    private var current: Int { InterfaceTypography.clamped(draftPercent) }
    private let panelScale = InterfaceTypography.scale(for: InterfaceTypography.defaultPercent)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(
                    L10n.text(
                        TextConstants.Typography.textSizeEnglish, TextConstants.Typography.textSizeJapanese,
                        TextConstants.Typography.textSizeGerman)
                ).interfaceFont(.headline)
                Spacer()
                Text(TextConstants.Common.localizedPercentageTemplate(current)).monospacedDigit().frame(
                    width: 64, alignment: .trailing)
            }
            // EN: Native tracking stays continuous; publish live previews at a bounded rate and persist on release.
            // JA: ネイティブの追従を連続に保ち、ライブ反映の頻度を制限しながら、離した時だけ保存する。
            // DE: Nativ kontinuierlich verfolgen, Live-Änderungen begrenzen und erst beim Loslassen speichern.
            InterfaceTextSlider(
                value: Binding(
                    get: { draftPercent },
                    set: { value in
                        draftPercent = InterfaceTypography.continuousPercent(value)
                        typography.preview(draftPercent)
                        // EN: Keyboard/accessibility edits may arrive without a mouse tracking loop.
                        // JA: キーボードや支援技術の編集は、マウス追跡なしに届く場合がある。
                        // DE: Tastatur-/Bedienungshilfenänderungen können ohne Mausverfolgung eintreffen.
                        if !isEditing { commitDraft() }
                    }),
                onEditingChanged: { editing in
                    isEditing = editing
                    if !editing { commitDraft() }
                }
            )
            .frame(maxWidth: .infinity)
            .frame(height: InterfaceTypography.sliderSize.height)
            .accessibilityLabel(
                L10n.text(
                    TextConstants.Typography.textSizeEnglish, TextConstants.Typography.textSizeJapanese,
                    TextConstants.Typography.textSizeGerman)
            )
            .accessibilityValue(TextConstants.Common.localizedPercentageTemplate(current))
            HStack {
                Text(
                    L10n.text(
                        TextConstants.Typography.smallEnglish, TextConstants.Typography.smallJapanese,
                        TextConstants.Typography.smallGerman))
                Spacer()
                Text(
                    L10n.text(
                        TextConstants.Typography.largeEnglish, TextConstants.Typography.largeJapanese,
                        TextConstants.Typography.largeGerman))
            }.interfaceFont(.caption).foregroundStyle(.secondary)
            Text(
                L10n.text(
                    TextConstants.Typography.textSizeUpdatesInAllWindowsWhileDraggingReleaseEnglish,
                    TextConstants.Typography.textSizeUpdatesInAllWindowsWhileDraggingReleaseJapanese,
                    TextConstants.Typography.textSizeUpdatesInAllWindowsWhileDraggingReleaseGerman
                )
            )
            .interfaceFont(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button(
                L10n.text(
                    TextConstants.Typography.resetToDefaultEnglish, TextConstants.Typography.resetToDefaultJapanese,
                    TextConstants.Typography.resetToDefaultGerman)
            ) {
                draftPercent = Double(InterfaceTypography.defaultPercent)
                commitDraft()
            }
            .disabled(current == InterfaceTypography.defaultPercent)
        }
        .padding(22)
        .frame(width: InterfaceTypography.editorSize.width, height: InterfaceTypography.editorSize.height)
        // EN: Resizing this editor while it owns the mouse gesture can dismiss an AppKit toolbar popover. Its
        //     typography remains constant during edits.
        // JA: このエディターがマウス操作を保持している間にサイズが変わると、AppKitのツールバーポップオーバーが閉じる場合がある。編集中の文字サイズは一定に保つ。
        // DE: Eine Größenänderung dieses Editors während seiner Mausgeste kann das AppKit-Werkzeugleisten-Popover
        //     schließen. Die Schriftgröße bleibt während der Bearbeitung konstant.
        .environment(\.interfaceTextScale, panelScale)
        .font(InterfaceTextStyle.body.font(scale: panelScale))
        .controlSize(.regular)
        .onAppear { draftPercent = InterfaceTypography.continuousPercent(typography.percent) }
        .onChange(of: typography.percent) { _, live in
            // EN: Synchronize other editors without feeding their programmatic updates back into persistence.
            // JA: 別の調整画面にも反映するが、同期による値の代入を保存処理へ戻さない。
            // DE: Andere Editoren synchronisieren, ohne programmgesteuerte Änderungen erneut zu speichern.
            if !isEditing { draftPercent = InterfaceTypography.continuousPercent(live) }
        }
        .onDisappear {
            if isEditing { commitDraft() }
        }
    }

    /// EN: Validate the edited value [%] and persist it only when changed.
    ///
    /// JA: 編集中の値 [%] を検証し、変更があった場合だけ保存する。
    ///
    /// DE: Den bearbeiteten Wert [%] prüfen und nur bei einer Änderung speichern.
    private func commitDraft() {
        let final = current
        draftPercent = Double(final)
        typography.commit(Double(final))
    }
}
