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

enum InterfaceTypography {
    static let storageKey = "interfaceTextSizePercent"
    static let defaultPercent = 115
    static let range = 100...160

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
    @AppStorage(InterfaceTypography.storageKey) private var percent = InterfaceTypography.defaultPercent

    /// EN: Return a View with the validated display scale applied. Do not treat this value as a board coordinate.
    ///
    /// JA: 検証済みの表示倍率を適用したViewを返す。数値を基板座標として扱わない。
    ///
    /// DE: Eine View mit der geprüften Anzeigeskalierung zurückgeben. Diesen Wert nicht als Platinenkoordinate
    ///     behandeln.
    func body(content: Content) -> some View {
        let scale = InterfaceTypography.scale(for: percent)
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

struct InterfaceTextSizeControl: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label(L10n.text("Text size", "文字サイズ", "Textgröße"), systemImage: "textformat.size")
        }
        // EN: Keep the popover anchor's metrics stable when the rest of the UI resizes.
        // JA: 他のUIのサイズが変わっても、ポップオーバーのアンカー寸法は一定に保つ。
        // DE: Die Abmessungen des Popover-Ankers bei Größenänderungen der übrigen UI stabil halten.
        .font(InterfaceTextStyle.body.font(scale: 1))
        .controlSize(.regular)
        .help(
            L10n.text(
                "Adjust text size in all app windows", "すべてのウィンドウの文字サイズを調整", "Textgröße in allen App-Fenstern anpassen")
        )
        .popover(isPresented: $isPresented) {
            InterfaceTextSettingsView()
        }
    }
}

struct InterfaceTextSettingsView: View {
    @AppStorage(InterfaceTypography.storageKey) private var percent = InterfaceTypography.defaultPercent
    @State private var draftPercent = Double(InterfaceTypography.defaultPercent)
    @State private var isEditing = false
    private var current: Int { InterfaceTypography.clamped(draftPercent) }
    private let panelScale = InterfaceTypography.scale(for: InterfaceTypography.defaultPercent)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(L10n.text("Text size", "文字サイズ", "Textgröße")).interfaceFont(.headline)
                Spacer()
                Text("\(current)%").monospacedDigit().frame(width: 64, alignment: .trailing)
            }
            // EN: Track locally and continuously. Persist once on release so dragging never rebuilds the parent
            //     window or moves the popover's anchor.
            // JA: ドラッグ中はローカル値を連続更新し、離した時に1回だけ保存する。ドラッグで親ウィンドウが再構築されたり、ポップオーバーのアンカーが移動したりするのを防ぐ。
            // DE: Während des Ziehens den lokalen Wert kontinuierlich aktualisieren und beim Loslassen einmal
            //     speichern. So werden weder das übergeordnete Fenster neu aufgebaut noch der Popover-Anker
            //     verschoben.
            Slider(
                value: $draftPercent,
                in: Double(InterfaceTypography.range.lowerBound)...Double(InterfaceTypography.range.upperBound),
                onEditingChanged: { editing in
                    isEditing = editing
                    if !editing { commitDraft() }
                }
            )
            .accessibilityLabel(L10n.text("Text size", "文字サイズ", "Textgröße"))
            .accessibilityValue("\(current)%")
            HStack {
                Text(L10n.text("Small", "小", "Klein"))
                Spacer()
                Text(L10n.text("Large", "大", "Groß"))
            }.interfaceFont(.caption).foregroundStyle(.secondary)
            Text(
                L10n.text(
                    "Release the slider to apply text size to all windows. Your choice is saved automatically.",
                    "スライダーを離すと文字サイズをすべてのウィンドウに反映し、設定を保存します。",
                    "Lassen Sie den Schieberegler los, um die Textgröße in allen Fenstern anzuwenden. Ihre Auswahl wird automatisch gespeichert."
                )
            )
            .interfaceFont(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Button(L10n.text("Reset to default (115%)", "標準に戻す（115%）", "Auf Standard (115 %) zurücksetzen")) {
                draftPercent = Double(InterfaceTypography.defaultPercent)
                commitDraft()
            }
            .disabled(current == InterfaceTypography.defaultPercent)
        }
        .padding(22)
        .frame(width: 360)
        // EN: Resizing this editor while it owns the mouse gesture can dismiss an AppKit toolbar popover. Its
        //     typography remains constant during edits.
        // JA: このエディターがマウス操作を保持している間にサイズが変わると、AppKitのツールバーポップオーバーが閉じる場合がある。編集中の文字サイズは一定に保つ。
        // DE: Eine Größenänderung dieses Editors während seiner Mausgeste kann das AppKit-Werkzeugleisten-Popover
        //     schließen. Die Schriftgröße bleibt während der Bearbeitung konstant.
        .environment(\.interfaceTextScale, panelScale)
        .font(InterfaceTextStyle.body.font(scale: panelScale))
        .controlSize(.regular)
        .onAppear { draftPercent = Double(InterfaceTypography.clamped(percent)) }
        .onChange(of: draftPercent) { _, _ in
            // EN: Keyboard and accessibility adjustments may not start a drag.
            // JA: キーボードやアクセシビリティからの調整では、ドラッグが開始されない場合がある。
            // DE: Änderungen per Tastatur oder Bedienungshilfe lösen unter Umständen keinen Ziehvorgang aus.
            if !isEditing { commitDraft() }
        }
        .onChange(of: percent) { _, saved in
            if !isEditing { draftPercent = Double(InterfaceTypography.clamped(saved)) }
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
        let value = current
        if percent != value { percent = value }
    }
}
