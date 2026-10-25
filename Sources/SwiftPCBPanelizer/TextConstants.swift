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
import SwiftUI

/// EN: A constant template using %@ as ordered markers, without printf processing or recursive replacement.
///     Preserve literal percent signs, XML/HTML escaping and Swift's default interpolation for each value.
/// JA: %@を順番付きの差し込み位置として扱う定数テンプレート。printf処理や再帰的な置換は行わない。
///     通常の%記号、XML/HTMLのエスケープ、各値に対するSwift標準の文字列補間を保持する。
/// DE: Konstante Vorlage mit %@ als geordneten Platzhaltern, ohne printf oder rekursive Ersetzung.
///     Prozentzeichen, XML/HTML-Escaping und Swifts Standardinterpolation der Werte beibehalten.
struct TextTemplate {
    /// EN: Immutable literal pieces in marker order, decoded once from the constant template.
    /// JA: 定数テンプレートから一度だけ分割した、差し込み順の変更不可の文片。
    /// DE: Einmal aus der konstanten Vorlage aufgeteilte unveränderliche Textteile in Platzhalterreihenfolge.
    private let fragments: [String]

    /// EN: Split a source-defined constant once. The template and marker cannot be changed by imported board data.
    /// JA: ソースで定義した定数を一度だけ分割する。テンプレートと記号は入力基板データから変更できない。
    /// DE: Eine Quellkonstante einmal aufteilen. Importierte Platinendaten können Vorlage und Markierung nicht ändern.
    init(_ template: String) {
        fragments = template.components(separatedBy: TextConstants.interpolationMarker)
    }

    /// EN: Require one value per marker, then append each value exactly once using default String interpolation.
    ///     Marker-count mismatch is a programming error, not a user-input error. Values containing %@ remain literal data.
    /// JA: 差し込み位置ごとに1個の値を要求し、String標準の補間で各値を一度だけ連結する。
    ///     個数の不一致は入力エラーではなく実装上の誤り。値に含まれる%@を再び置換することはない。
    /// DE: Genau einen Wert je Platzhalter fordern und jeden Wert einmal mit der Standardinterpolation anhängen.
    ///     Eine falsche Anzahl ist ein Programmierfehler. %@ innerhalb von Werten bleibt unverändert.
    func callAsFunction(_ values: Any...) -> String {
        precondition(values.count + 1 == fragments.count)
        var result = String()
        for (index, value) in values.enumerated() {
            result.append(fragments[index])
            var interpolation = DefaultStringInterpolation(literalCapacity: 0, interpolationCount: 1)
            interpolation.appendInterpolation(value)
            result.append(String(stringInterpolation: interpolation))
        }
        result.append(fragments[values.count])
        return result
    }
}

/// EN: Preserve SwiftUI's integer interpolation and localization semantics for count/percentage labels.
/// JA: 個数・割合ラベルの、SwiftUIの整数補間とローカライズの意味を保持する。
/// DE: Swifts Ganzzahlinterpolation und Lokalisierungssemantik für Anzahl-/Prozentbeschriftungen erhalten.
struct LocalizedIntegerTemplate {
    /// EN: Literal text preceding the single localized integer.
    /// JA: ローカライズする整数1個の前に置く固定文。
    /// DE: Fester Text vor der einzelnen lokalisierten Ganzzahl.
    private let prefix: String
    /// EN: Literal text following the single localized integer.
    /// JA: ローカライズする整数1個の後ろに置く固定文。
    /// DE: Fester Text nach der einzelnen lokalisierten Ganzzahl.
    private let suffix: String

    /// EN: Validate that a source-defined localized template has exactly one integer position.
    /// JA: ソースで定義したローカライズ用テンプレートに、整数の位置が1個だけあることを検証する。
    /// DE: Genau eine Ganzzahlposition in einer quellseitigen lokalisierten Vorlage prüfen.
    init(_ template: String) {
        let parts = template.components(separatedBy: TextConstants.interpolationMarker)
        precondition(parts.count == 2)
        prefix = parts[0]
        suffix = parts[1]
    }

    /// EN: Rebuild the original localized key with its typed integer, avoiding type erasure or language changes.
    /// JA: 型付きの整数から元のローカライズキーを組み立て、型の消失や言語動作の変更を避ける。
    /// DE: Den ursprünglichen lokalisierten Schlüssel mit typisierter Ganzzahl ohne Typverlust neu aufbauen.
    func callAsFunction(_ value: Int) -> LocalizedStringKey {
        var interpolation = LocalizedStringKey.StringInterpolation(
            literalCapacity: prefix.utf8.count + suffix.utf8.count, interpolationCount: 1)
        interpolation.appendLiteral(prefix)
        interpolation.appendInterpolation(value)
        interpolation.appendLiteral(suffix)
        return LocalizedStringKey(stringInterpolation: interpolation)
    }
}

/// EN: Application string and character literals. Keep protocol tokens exact and language variants together.
///     %@ belongs only to TextTemplate/LocalizedIntegerTemplate; existing printf formats retain their original API.
/// JA: アプリの文字列・文字リテラルの定数。形式の識別子は厳密に保持し、多言語の表現をまとめる。
///     %@はTextTemplate/LocalizedIntegerTemplate専用。既存のprintf形式は元のAPIで使用する。
/// DE: Zeichenketten-/Zeichenkonstanten der App. Protokollkennungen exakt und Sprachvarianten zusammenhalten.
///     %@ gilt für TextTemplate/LocalizedIntegerTemplate; printf-Formate verwenden weiterhin ihre ursprüngliche API.
enum TextConstants {
    /// EN: Ordered interpolation marker in constant templates; never reparse inserted values.
    /// JA: 定数テンプレートの差し込み記号。挿入済みの値は再解析しない。
    /// DE: Geordnete Vorlagenmarkierung; eingefügte Werte nicht erneut analysieren.
    static let interpolationMarker = "%@"

    /// EN: Shared display text, separators and format identifiers.
    /// JA: 共通の表示文・区切り・形式識別子。
    /// DE: Gemeinsame Anzeigetexte, Trennzeichen und Formatkennungen.
    enum Common {
        static let columnsAndRowsMustBeAtLeastOneEnglish = "Columns and rows must be at least one."
        static let columnsAndRowsMustBeAtLeastOneGerman = "Spalten- und Zeilenanzahl müssen mindestens 1 betragen."
        static let tokenEagle = "eagle"
        static let tokenRectangle = "rectangle"
        static let tokenLayer = "layer"
        static let tokenWidth = "width"
        static let number0 = "0"
        static let tokenHeight = "height"
        static let tokenRadius = "radius"
        static let tokenDrill = "drill"
        static let tokenDiameter = "diameter"
        static let tokenSize = "size"
        static let columnSpacingEnglish = "Column spacing"
        static let columnSpacingGerman = "Spaltenabstand"
        static let rowSpacingEnglish = "Row spacing"
        static let rowSpacingGerman = "Zeilenabstand"
        static let outlineLineWidthEnglish = "Outline line width"
        static let outlineLineWidthJapanese = "外形線幅"
        static let outlineLineWidthGerman = "Konturlinienbreite"
        static let guideLineWidthEnglish = "Guide line width"
        static let guideLineWidthGerman = "Hilfslinienbreite"
        static let tokenName = "name"
        static let empty = ""
        static let tokenYes = "yes"
        static let tokenValue = "value"
        static let tokenCircle = "circle"
        static let tokenLayers = "layers"
        static let semicolon = ";"
        static let tokenDefault = "default"
        static let tokenFill = "fill"
        static let number1 = "1"
        static let posixLocaleIdentifier = "en_US_POSIX"
        static let tokenMM = "MM"
        static let textNumericMeasurement = "numeric measurement"
        static let newline = "\n"
        static let doubleQuote = "\""
        static let localizedPercentageTemplate = LocalizedIntegerTemplate("%@%")
        static let tokenKicadPcb = "kicad_pcb"
        static let tokenStroke = "stroke"
        static let tokenNone = "none"
        static let space = " "
        static let tokenBrd = "brd"
        static let tokenPcb = "pcb"
        static let tokenOutput = "--output"
        static let colon = ":"
        static let artworkPreviewEnglish = "Artwork preview"
        static let artworkPreviewJapanese = "完成プレビュー"
        static let artworkPreviewGerman = "Fertigungsansicht"
        static let tokenOKKey: LocalizedStringKey = "OK"
    }

    /// EN: Typed Character tokens for parsers and locale/number processing.
    /// JA: 解析・ロケール・数値処理で使用するCharacter型の記号。
    /// DE: Typisierte Character-Zeichen für Parser sowie Sprach-/Zahlenverarbeitung.
    enum Characters {
        static let letterUpperS: Character = "S"
        static let letterUpperM: Character = "M"
        static let letterUpperR: Character = "R"
        static let number0: Character = "0"
        static let period: Character = "."
        static let hyphen: Character = "-"
        static let byteOrderMark: Character = "\u{feff}"
        static let openingParenthesis: Character = "("
        static let closingParenthesis: Character = ")"
        static let doubleQuote: Character = "\""
        static let semicolon: Character = ";"
        static let backslash: Character = "\\"
        static let letterLowerN: Character = "n"
        static let letterLowerR: Character = "r"
        static let letterLowerT: Character = "t"
        static let newline: Character = "\n"
        static let colon: Character = ":"
        static let underscore: Character = "_"
    }

    /// EN: EAGLE XML names, serializer formats and localized diagnostics.
    /// JA: EAGLEのXML名・出力書式・多言語エラー文。
    /// DE: EAGLE-XML-Namen, Ausgabeformate und lokalisierte Diagnosen.
    enum Eagle {
        static let columnsAndRowsMustBeAtLeastOneJapanese = "列数と行数は1以上を指定してください。"
        static let nameMustBeZeroOrGreaterEnglishTemplate = TextTemplate("%@ must be zero or greater.")
        static let nameMustBeZeroOrGreaterJapaneseTemplate = TextTemplate("%@は0以上で指定してください。")
        static let nameMustBeZeroOrGreaterGermanTemplate = TextTemplate("%@ muss mindestens 0 betragen.")
        static let cannotReadEAGLEBrdXMLReasonEnglishTemplate = TextTemplate("Cannot read EAGLE .brd XML: %@")
        static let cannotReadEAGLEBrdXMLReasonJapaneseTemplate = TextTemplate("EAGLE .brd XMLを読み込めませんでした: %@")
        static let cannotReadEAGLEBrdXMLReasonGermanTemplate = TextTemplate(
            "EAGLE-.brd-XML kann nicht gelesen werden: %@")
        static let notAnEAGLEFileRootElementNameEnglishTemplate = TextTemplate("Not an EAGLE file (root element: %@).")
        static let notAnEAGLEFileRootElementNameJapaneseTemplate = TextTemplate("EAGLE形式ではありません（ルート要素: %@）。")
        static let notAnEAGLEFileRootElementNameGermanTemplate = TextTemplate("Keine EAGLE-Datei (Wurzelelement: %@).")
        static let noBoardElementWasFoundInThisEAGLEFileEnglish = "No <board> element was found in this EAGLE file."
        static let noBoardElementWasFoundInThisEAGLEFileJapanese = "このEAGLEファイルに<board>が見つかりません。"
        static let noBoardElementWasFoundInThisEAGLEFileGerman =
            "In dieser EAGLE-Datei wurde kein <board>-Element gefunden."
        static let noPlainSectionWasFoundInTheBoardEnglish = "No <plain> section was found in the board."
        static let noPlainSectionWasFoundInTheBoardJapanese = "基板内に<plain>が見つかりません。"
        static let noPlainSectionWasFoundInTheBoardGerman = "Die Leiterplatte enthält keinen <plain>-Abschnitt."
        static let noOutlineWiresWereFoundOnDimensionLayerCreateEnglish =
            "No outline wires were found on Dimension layer 20. Create the board outline on that layer."
        static let noOutlineWiresWereFoundOnDimensionLayerCreateJapanese =
            "Dimensionレイヤー（20）のwireがありません。外形をDimensionレイヤーに作成してください。"
        static let noOutlineWiresWereFoundOnDimensionLayerCreateGerman =
            "Auf dem Dimension-Layer 20 wurden keine Konturlinien gefunden. Erstellen Sie dort die Leiterplattenkontur."
        static let number20 = "20"
        static let number102 = "102"
        static let tokenDrawing = "drawing"
        static let tokenBoard = "board"
        static let tokenPlain = "plain"
        static let number41 = "41"
        static let number42 = "42"
        static let number43 = "43"
        static let tokenX1 = "x1"
        static let tokenY1 = "y1"
        static let tokenX2 = "x2"
        static let tokenY2 = "y2"
        static let aRestrictionRectangleHasInvalidCoordinatesOrRotationEnglish =
            "A restriction rectangle has invalid coordinates or rotation."
        static let aRestrictionRectangleHasInvalidCoordinatesOrRotationJapanese = "禁止領域の矩形の座標または回転角が不正です。"
        static let aRestrictionRectangleHasInvalidCoordinatesOrRotationGerman =
            "Ein Rechteck einer Sperrfläche hat ungültige Koordinaten oder einen ungültigen Drehwinkel."
        static let tokenVertex = "vertex"
        static let letterLowerX = "x"
        static let letterLowerY = "y"
        static let tokenPolygon = "polygon"
        static let tokenX3 = "x3"
        static let tokenY3 = "y3"
        static let tokenDx = "dx"
        static let tokenDy = "dy"
        static let tokenCurve = "curve"
        static let tokenSpacing = "spacing"
        static let tokenIsolate = "isolate"
        static let tokenRot = "rot"
        static let letterLowerE = "e"
        static let letterUpperE = "E"
        static let tokenPreparedForKiCadImportOutput = "preparedForKiCadImport.output"
        static let columnSpacingJapanese = "列間隔"
        static let rowSpacingJapanese = "行間隔"
        static let horizontalFrameEnglish = "Horizontal frame"
        static let horizontalFrameJapanese = "横方向の外枠"
        static let horizontalFrameGerman = "Horizontaler Rahmen"
        static let verticalFrameEnglish = "Vertical frame"
        static let verticalFrameJapanese = "縦方向の外枠"
        static let verticalFrameGerman = "Vertikaler Rahmen"
        static let mountingHoleXInsetEnglish = "Mounting hole X inset"
        static let mountingHoleXInsetJapanese = "取付穴のXオフセット"
        static let mountingHoleXInsetGerman = "Randabstand der Befestigungsbohrung in X"
        static let mountingHoleYInsetEnglish = "Mounting hole Y inset"
        static let mountingHoleYInsetJapanese = "取付穴のYオフセット"
        static let mountingHoleYInsetGerman = "Randabstand der Befestigungsbohrung in Y"
        static let guideLineWidthJapanese = "分割ガイド線幅"
        static let mountingHoleDiameterEnglish = "Mounting hole diameter"
        static let mountingHoleDiameterJapanese = "取付穴径"
        static let mountingHoleDiameterGerman = "Durchmesser der Befestigungsbohrung"
        static let tokenWire = "wire"
        static let tokenLibraries = "libraries"
        static let tokenPackages = "packages"
        static let tokenPackage = "package"
        static let slash = "/"
        static let tokenText = "text"
        static let nameTextPlaceholder = ">NAME"
        static let valueTextPlaceholder = ">VALUE"
        static let tokenElements = "elements"
        static let tokenElement = "element"
        static let tokenLibrary = "library"
        static let tokenSmashed = "smashed"
        static let tokenAttribute = "attribute"
        static let nameAttributeIdentifier = "NAME"
        static let tokenDisplay = "display"
        static let tokenOff = "off"
        static let tokenConstant = "constant"
        static let tokenBoth = "both"
        static let textNAME = "NAME = "
        static let valueAttributeIdentifier = "VALUE"
        static let tokenHole = "hole"
        static let tokenSignals = "signals"
        static let tokenEaglePanelEngineShapeOutput = "EaglePanelEngine.shape.output"
        static let tokenEaglePanelEngineComposeSources = "EaglePanelEngine.compose.sources"
        static let textEAGLESourcesTemplate = TextTemplate("1...%@ EAGLE sources")
        static let tokenDesignrules = "designrules"
        static let tokenParam = "param"
        static let tokenLayerSetup = "layerSetup"
        static let defaultTwoLayerStackSetup = "(1*16)"
        static let boardsInOneEAGLEPanelMustUseTheSameEnglish =
            "Boards in one EAGLE panel must use the same copper layer stack."
        static let boardsInOneEAGLEPanelMustUseTheSameJapanese = "同じEAGLEパネルに配置する基板は、銅箔の層構成を揃えてください。"
        static let boardsInOneEAGLEPanelMustUseTheSameGerman =
            "Alle Leiterplatten in einem EAGLE-Nutzen müssen denselben Kupferlagenaufbau haben."
        static let tokenClasses = "classes"
        static let tokenNumber = "number"
        static let tokenSignal = "signal"
        static let tokenContactref = "contactref"
        static let tokenBTemplate = TextTemplate("B%@_")
        static let theEAGLEPanelHasTooManyCustomLayersEnglish = "The EAGLE panel has too many custom layers."
        static let theEAGLEPanelHasTooManyCustomLayersJapanese = "EAGLEパネルのカスタムレイヤー数が上限を超えています。"
        static let theEAGLEPanelHasTooManyCustomLayersGerman =
            "Der EAGLE-Nutzen enthält zu viele benutzerdefinierte Layer."
        static let tokenClass = "class"
        static let thisPanelExceedsEAGLENetClassesReduceTheNumberEnglish =
            "This panel exceeds EAGLE's 16 net classes. Reduce the number of boards or classes."
        static let thisPanelExceedsEAGLENetClassesReduceTheNumberJapanese =
            "EAGLEのネットクラス数上限（16）を超えています。基板数またはクラス数を減らしてください。"
        static let thisPanelExceedsEAGLENetClassesReduceTheNumberGerman =
            "Dieser Nutzen überschreitet die EAGLE-Grenze von 16 Netzklassen. Verringern Sie die Anzahl der Leiterplatten oder Netzklassen."
        static let tokenVscore = "Vscore"
        static let tokenColor = "color"
        static let number7 = "7"
        static let tokenVisible = "visible"
        static let tokenActive = "active"
        static let tokenErrors = "errors"
        static let tokenMfgpreviewcolors = "mfgpreviewcolors"
        static let useWiresOrCirclesForTheEAGLEOutlineWhenEnglish =
            "Use wires or circles for the EAGLE outline when routing tabs."
        static let useWiresOrCirclesForTheEAGLEOutlineWhenJapanese = "タブ生成時のEAGLE外形にはwireまたはcircleを使用してください。"
        static let useWiresOrCirclesForTheEAGLEOutlineWhenGerman =
            "Verwenden Sie für die EAGLE-Kontur beim Erstellen von Stegen Linien (wire) oder Kreise (circle)."
        static let letterUpperM = "M"
        static let gridCopySuffixTemplate = TextTemplate("-%@-%@")
        static let eagleDecimalFormat = "%.10f"
        static let numberMinus0 = "-0"
        static let tokenEagleXMLParserInput = "EagleXMLParser.input"
        static let unknownXMLErrorEnglish = "Unknown XML error"
        static let unknownXMLErrorJapanese = "不明なXMLエラー"
        static let unknownXMLErrorGerman = "Unbekannter XML-Fehler"
        static let tokenEagleXMLParserDepthNodes = "EagleXMLParser.depth/nodes"
        static let textWithinParserLimits = "within parser limits"
        static let tokenEAGLE = "EAGLE."
        static let period = "."
        static let textNumericCoordinate = "numeric coordinate"
        static let tokenEAGLERot = "EAGLE.rot"
        static let textRotationInDegrees = "rotation in degrees"
        static let tokenEAGLERotDegrees = "EAGLE.rotDegrees"
        static let markupXmlVersionEncodingUTFDOCTYPEEagleSYSTEM =
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE eagle SYSTEM \"eagle.dtd\">\n"
        static let indentationUnit = "  "
        static let openingAngle = "<"
        static let xmlAttributeTemplate = TextTemplate(" %@=\"%@\"")
        static let xmlSelfClosingElementEnding = "/>\n"
        static let closingAngle = ">"
        static let markupTemplate = TextTemplate("</%@>\n")
        static let ampersand = "&"
        static let tokenAmp = "&amp;"
        static let tokenLt = "&lt;"
        static let tokenGt = "&gt;"
        static let tokenQuot = "&quot;"
    }

    /// EN: KiCad syntax tokens, serializer formats and localized diagnostics.
    /// JA: KiCadの構文識別子・出力書式・多言語エラー文。
    /// DE: KiCad-Syntaxkennungen, Ausgabeformate und lokalisierte Diagnosen.
    enum KiCad {
        static let tokenFootprint = "footprint"
        static let tokenSegment = "segment"
        static let tokenVia = "via"
        static let tokenArc = "arc"
        static let tokenZone = "zone"
        static let tokenGrLine = "gr_line"
        static let tokenGrArc = "gr_arc"
        static let tokenGrRect = "gr_rect"
        static let tokenGrPoly = "gr_poly"
        static let tokenGrCircle = "gr_circle"
        static let tokenGrCurve = "gr_curve"
        static let tokenGrText = "gr_text"
        static let tokenGrTextBox = "gr_text_box"
        static let tokenDimension = "dimension"
        static let tokenTarget = "target"
        static let tokenImage = "image"
        static let tokenGroup = "group"
        static let tokenTable = "table"
        static let tokenBarcode = "barcode"
        static let tokenPoint = "point"
        static let tokenGenerated = "generated"
        static let tokenAt = "at"
        static let tokenStart = "start"
        static let tokenEnd = "end"
        static let tokenMid = "mid"
        static let tokenCenter = "center"
        static let tokenXy = "xy"
        static let tokenXy1 = "xy1"
        static let tokenXy2 = "xy2"
        static let tokenOrigin = "origin"
        static let tokenPosition = "position"
        static let columnsAndRowsMustBeAtLeastOneJapanese = "列数と行数は1以上にしてください。"
        static let spacingAndFrameWidthsMustBeNonnegativeTheDrillEnglish =
            "Spacing and frame widths must be nonnegative; the drill diameter must be positive."
        static let spacingAndFrameWidthsMustBeNonnegativeTheDrillJapanese = "間隔と外枠は0以上、ドリル径は0より大きくしてください。"
        static let spacingAndFrameWidthsMustBeNonnegativeTheDrillGerman =
            "Abstände und Rahmenbreiten müssen mindestens 0 betragen; der Bohrdurchmesser muss größer als 0 sein."
        static let tokenEdgeCuts = "Edge.Cuts"
        static let noBoardItemsAreAvailableToDuplicateEnglish = "No board items are available to duplicate."
        static let noBoardItemsAreAvailableToDuplicateJapanese = "複製できる基板要素がありません。"
        static let noBoardItemsAreAvailableToDuplicateGerman =
            "Es sind keine Leiterplattenelemente zum Duplizieren vorhanden."
        static let tokenDwgsUser = "Dwgs.User"
        static let tokenProperty = "property"
        static let referencePropertyName = "Reference"
        static let tokenPHTemplate = TextTemplate("PH%@")
        static let tokenPMBTemplate = TextTemplate("PMB%@")
        static let tokenHide = "hide"
        static let tokenKiCadPanelEngineParseRootInput = "KiCadPanelEngine.parseRoot.input"
        static let theKiCadFileIsNotValidUTFEnglish = "The KiCad file is not valid UTF-8."
        static let theKiCadFileIsNotValidUTFJapanese = "KiCadファイルの文字コードが正しいUTF-8ではありません。"
        static let theKiCadFileIsNotValidUTFGerman = "Die KiCad-Datei ist nicht gültig UTF-8-kodiert."
        static let theKicadPcbRootElementIsMissingEnglish = "The kicad_pcb root element is missing."
        static let theKicadPcbRootElementIsMissingJapanese = "ルート要素kicad_pcbがありません。"
        static let theKicadPcbRootElementIsMissingGerman = "Das Wurzelelement kicad_pcb fehlt."
        static let tokenKiCad = "KiCad."
        static let textNumericXYCoordinates = "numeric x/y coordinates"
        static let tokenKiCadAtAngleDegrees = "KiCad.at.angleDegrees"
        static let tokenThickness = "thickness"
        static let tokenOval = "oval"
        static let tokenKiCadDrill = "KiCad.drill"
        static let textNumericDiameter = "numeric diameter"
        static let tokenKiCadDrillMM = "KiCad.drillMM"
        static let tokenUNDEFINED = "UNDEFINED"
        static let tokenUndefined = "Undefined"
        static let tokenRescue = "Rescue"
        static let tokenUNSELECTED = "UNSELECTED"
        static let numberMinus1 = "-1"
        static let tokenUserDrawings = "User.Drawings"
        static let tokenUserComments = "User.Comments"
        static let tokenCmtsUser = "Cmts.User"
        static let tokenUserEco1 = "User.Eco1"
        static let tokenEco1User = "Eco1.User"
        static let tokenUserEco2 = "User.Eco2"
        static let tokenEco2User = "Eco2.User"
        static let tokenFSilkscreen = "F.Silkscreen"
        static let tokenFSilkS = "F.SilkS"
        static let tokenBSilkscreen = "B.Silkscreen"
        static let tokenBSilkS = "B.SilkS"
        static let tokenFAdhesive = "F.Adhesive"
        static let tokenFAdhes = "F.Adhes"
        static let tokenBAdhesive = "B.Adhesive"
        static let tokenBAdhes = "B.Adhes"
        static let tokenFCourtyard = "F.Courtyard"
        static let tokenFCrtYd = "F.CrtYd"
        static let tokenBCourtyard = "B.Courtyard"
        static let tokenBCrtYd = "B.CrtYd"
        static let tokenBCu = "B.Cu"
        static let number2 = "2"
        static let tokenFCu = "F.Cu"
        static let tokenFPaste = "F.Paste"
        static let tokenBPaste = "B.Paste"
        static let tokenFMask = "F.Mask"
        static let tokenBMask = "B.Mask"
        static let tokenMargin = "Margin"
        static let tokenFFab = "F.Fab"
        static let tokenBFab = "B.Fab"
        static let copperLayerSuffix = ".Cu"
        static let userLayerPrefix = "User."
        static let theLayerNameIsMissingFromTheBoardLayerEnglishTemplate = TextTemplate(
            "The layer %@ is missing from the board's layer definitions or its ID conflicts with another layer.")
        static let theLayerNameIsMissingFromTheBoardLayerJapaneseTemplate = TextTemplate(
            "レイヤー%@の定義がないか、レイヤー番号が別の定義と衝突しています。")
        static let theLayerNameIsMissingFromTheBoardLayerGermanTemplate = TextTemplate(
            "Der Layer %@ fehlt in der Layerdefinition der Leiterplatte oder seine ID steht im Konflikt mit einem anderen Layer."
        )
        static let userTextKind = "user"
        static let tokenFpText = "fp_text"
        static let tokenFpTextBox = "fp_text_box"
        static let tokenFpLine = "fp_line"
        static let tokenFpArc = "fp_arc"
        static let tokenFpRect = "fp_rect"
        static let tokenFpPoly = "fp_poly"
        static let tokenFpCircle = "fp_circle"
        static let tokenFpCurve = "fp_curve"
        static let tokenTableCell = "table_cell"
        static let tokenPad = "pad"
        static let tokenPadstack = "padstack"
        static let allCopperLayers = "*.Cu"
        static let tokenInCu = "*In.Cu"
        static let tokenFBCu = "F&B.Cu"
        static let tokenAdhes = "*.Adhes"
        static let tokenPaste = "*.Paste"
        static let tokenMask = "*.Mask"
        static let tokenSilkS = "*.SilkS"
        static let tokenFab = "*.Fab"
        static let tokenCrtYd = "*.CrtYd"
        static let referenceTextKind = "reference"
        static let tokenInner = "Inner"
        static let tokenValue = "Value"
        static let anItemOfTypeOwnerUsesAnUndefinedLayerEnglishTemplate = TextTemplate(
            "An item of type %@ uses an undefined layer (%@). Its physical layer must be assigned before exporting the panel."
        )
        static let anItemOfTypeOwnerUsesAnUndefinedLayerJapaneseTemplate = TextTemplate(
            "%@要素に未定義レイヤー（%@）があります。基板上の所属レイヤーを指定してから出力してください。")
        static let anItemOfTypeOwnerUsesAnUndefinedLayerGermanTemplate = TextTemplate(
            "Ein Element vom Typ %@ verwendet einen undefinierten Layer (%@). Weisen Sie ihm vor dem Export die richtige Lage auf der Leiterplatte zu."
        )
        static let tokenSetup = "setup"
        static let tokenNet = "net"
        static let tokenNormalizeLayersOutput = "normalizeLayers.output"
        static let tokenKiCadPanelEngineShapeOutput = "KiCadPanelEngine.shape.output"
        static let tokenThruHole = "thru_hole"
        static let tokenNpThruHole = "np_thru_hole"
        static let tokenKiCadPanelEngineComposeData = "KiCadPanelEngine.compose.data"
        static let textBoardsTemplate = TextTemplate("1...%@ boards")
        static let allBoardsInOnePanelMustHaveTheSameEnglish =
            "All boards in one panel must have the same copper layer stack. Match the copper layer count and order before combining them."
        static let allBoardsInOnePanelMustHaveTheSameJapanese = "同じパネルに配置する基板は銅箔の層構成を揃えてください。銅箔の層数と順序が異なる基板は統合できません。"
        static let allBoardsInOnePanelMustHaveTheSameGerman =
            "Alle Leiterplatten in einem Nutzen müssen denselben Kupferlagenaufbau haben. Gleichen Sie vor dem Zusammenfügen die Anzahl und Reihenfolge der Kupferlagen an."
        static let tokenVersion = "version"
        static let tokenEmbeddedFiles = "embedded_files"
        static let tokenEmbeddedFonts = "embedded_fonts"
        static let customLayerIDsConflictBetweenTheseBoardsSaveThemEnglish =
            "Custom layer IDs conflict between these boards. Save them with the same KiCad version and layer configuration."
        static let customLayerIDsConflictBetweenTheseBoardsSaveThemJapanese =
            "基板間でカスタムレイヤーの番号が衝突しています。同じKiCadバージョンとレイヤー設定で保存してください。"
        static let customLayerIDsConflictBetweenTheseBoardsSaveThemGerman =
            "Die benutzerdefinierten Layer-IDs dieser Leiterplatten stehen im Konflikt. Speichern Sie die Dateien mit derselben KiCad-Version und Layerkonfiguration."
        static let instanceReferencePrefixTemplate = TextTemplate("B%@/")
        static let aBoardItemRefersToAnUndefinedNetCodeEnglish = "A board item refers to an undefined net code."
        static let aBoardItemRefersToAnUndefinedNetCodeJapanese = "未定義のネット番号を参照する基板要素があります。"
        static let aBoardItemRefersToAnUndefinedNetCodeGerman =
            "Ein Leiterplattenelement verweist auf eine undefinierte Netznummer."
        static let tokenNetName = "net_name"
        static let instanceReferenceSuffixTemplate = TextTemplate("_B%@")
        static let differentEmbeddedFilesShareTheNameNameRenameOneEnglishTemplate = TextTemplate(
            "Different embedded files share the name %@. Rename one in KiCad before combining these boards.")
        static let differentEmbeddedFilesShareTheNameNameRenameOneJapaneseTemplate = TextTemplate(
            "内容の異なる埋め込みファイルに同じ名前（%@）が使われています。KiCadで片方の名前を変更してから統合してください。")
        static let differentEmbeddedFilesShareTheNameNameRenameOneGermanTemplate = TextTemplate(
            "Verschiedene eingebettete Dateien haben denselben Namen %@. Benennen Sie vor dem Zusammenfügen eine davon in KiCad um."
        )
        static let tokenPANELHTemplate = TextTemplate("PANEL_H%@")
        static let tokenPts = "pts"
        static let unsupportedEdgeCutsGeometryForTabRoutingEnglish = "Unsupported Edge.Cuts geometry for tab routing."
        static let unsupportedEdgeCutsGeometryForTabRoutingJapanese = "タブ生成に未対応のEdge.Cuts形状です。直線・円弧・円・矩形・ポリゴンを使用してください。"
        static let unsupportedEdgeCutsGeometryForTabRoutingGerman =
            "Diese Edge.Cuts-Geometrie wird für Stege nicht unterstützt. Verwenden Sie Linien, Kreisbögen, Kreise, Rechtecke oder Polygone."
        static let tokenRCTemplate = TextTemplate("_R%@C%@")
        static let tokenNo = "no"
        static let tokenREFERENCE = "${REFERENCE}"
        static let tokenUuid = "uuid"
        static let tokenTstamp = "tstamp"
        static let tokenType = "type"
        static let tokenSolid = "solid"
        static let tokenMountingHoleMountingHoleMmTemplate = TextTemplate("MountingHole:MountingHole_%@mm")
        static let tokenEffects = "effects"
        static let tokenFont = "font"
        static let number0Point15 = "0.15"
        static let tokenMountingHole = "MountingHole"
        static let tokenAttr = "attr"
        static let tokenExcludeFromPosFiles = "exclude_from_pos_files"
        static let tokenExcludeFromBom = "exclude_from_bom"
        static let kiCadNumberFormat = "%.9g"
        static let cannotPanelizeTheKiCadBoardReasonEnglishTemplate = TextTemplate(
            "Cannot panelize the KiCad board: %@")
        static let cannotPanelizeTheKiCadBoardReasonJapaneseTemplate = TextTemplate("KiCad基板を面付けできません: %@")
        static let cannotPanelizeTheKiCadBoardReasonGermanTemplate = TextTemplate(
            "Die KiCad-Leiterplatte kann nicht zu einem Nutzen angeordnet werden: %@")
        static let noBoardOutlineWasFoundOnEdgeCutsLinesEnglish =
            "No board outline was found on Edge.Cuts (lines, arcs or polygons)."
        static let noBoardOutlineWasFoundOnEdgeCutsLinesJapanese = "Edge.Cutsレイヤーに基板外形（線、円弧、ポリゴン）がありません。"
        static let noBoardOutlineWasFoundOnEdgeCutsLinesGerman =
            "Auf Edge.Cuts wurde keine Leiterplattenkontur gefunden (Linien, Kreisbögen oder Polygone)."
        static let backslash = "\\"
        static let escapedBackslash = "\\\\"
        static let escapedDoubleQuote = "\\\""
        static let tokenN = "\\n"
        static let emptyList = "()"
        static let openingParenthesis = "("
        static let closingParenthesis = ")"
        static let tab = "\t"
        static let unexpectedDataAfterTheKiCadBoardRootEnglish = "Unexpected data after the KiCad board root."
        static let unexpectedDataAfterTheKiCadBoardRootJapanese = "KiCad基板のルート要素の後に余分なデータがあります。"
        static let unexpectedDataAfterTheKiCadBoardRootGerman =
            "Unerwartete Daten nach dem Wurzelelement der KiCad-Leiterplatte."
        static let theKiCadFileIsNestedTooDeeplyEnglish = "The KiCad file is nested too deeply."
        static let theKiCadFileIsNestedTooDeeplyJapanese = "KiCadファイルの入れ子が深すぎます。"
        static let theKiCadFileIsNestedTooDeeplyGerman = "Die KiCad-Datei ist zu tief verschachtelt."
        static let tokenSExpressionParserNodeCount = "SExpressionParser.nodeCount"
        static let positiveCountRangeTemplate = TextTemplate("1...%@")
        static let unexpectedEndOfFileEnglish = "Unexpected end of file."
        static let unexpectedEndOfFileJapanese = "ファイル末尾が予期しない位置です。"
        static let unexpectedEndOfFileGerman = "Unerwartetes Dateiende."
        static let aClosingParenthesisIsMissingEnglish = "A closing parenthesis is missing."
        static let aClosingParenthesisIsMissingJapanese = "閉じ括弧が不足しています。"
        static let aClosingParenthesisIsMissingGerman = "Eine schließende Klammer fehlt."
        static let cannotParseAnSExpressionTokenEnglish = "Cannot parse an S-expression token."
        static let cannotParseAnSExpressionTokenJapanese = "S式トークンを解析できません。"
        static let cannotParseAnSExpressionTokenGerman = "Ein Token des S-Ausdrucks kann nicht gelesen werden."
        static let carriageReturn = "\r"
        static let aQuotedStringIsUnterminatedEnglish = "A quoted string is unterminated."
        static let aQuotedStringIsUnterminatedJapanese = "引用符が閉じていません。"
        static let aQuotedStringIsUnterminatedGerman =
            "Eine Zeichenfolge wurde nicht mit einem Anführungszeichen abgeschlossen."
    }

    /// EN: Geometry validation, routing diagnostics and supported locale identifiers.
    /// JA: 形状検証・加工線のエラー文・対応ロケール識別子。
    /// DE: Geometrieprüfung, Fräsdiagnosen und unterstützte Sprachkennungen.
    enum Routing {
        static let invalidValueInFieldExpectedExpectedEnglishTemplate = TextTemplate(
            "Invalid value in %@. Expected: %@.")
        static let invalidValueInFieldExpectedExpectedJapaneseTemplate = TextTemplate("%@の値が不正です。許容範囲: %@。")
        static let invalidValueInFieldExpectedExpectedGermanTemplate = TextTemplate(
            "Ungültiger Wert in %@. Erwartet: %@.")
        static let closedRangeDescriptionTemplate = TextTemplate("%@...%@")
        static let textBytesTemplate = TextTemplate("1...%@ bytes")
        static let tokenWidthMM = ".widthMM"
        static let tokenHeightMM = ".heightMM"
        static let tokenBounds = ".bounds"
        static let tokenContours = ".contours"
        static let textClosedLoopsWithAtLeastPoints = "closed loops with at least 3 points"
        static let tokenStraightEdges = ".straightEdges"
        static let textInsideOutlineBounds = "inside outline bounds"
        static let tokenBoardWidthMM = "boardWidthMM"
        static let tokenBoardHeightMM = "boardHeightMM"
        static let tokenPanelWidthMM = "panelWidthMM"
        static let tokenPanelHeightMM = "panelHeightMM"
        static let tokenSummary = "summary."
        static let tokenSummaryRowsColumns = "summary.rows/columns"
        static let textPositionsTemplate = TextTemplate("1...%@ positions")
        static let tokenSummaryPanel = "summary.panel"
        static let textContainsBoardArray = "contains board array"
        static let tokenSummaryDimensionLineWidthMM = "summary.dimensionLineWidthMM"
        static let tokenExportOutputData = "export.outputData"
        static let tokenMountingHoleOffsetDiameter = "mountingHoleOffset/diameter"
        static let textEntireHoleInsidePanel = "entire hole inside panel"
        static let tokenPreviewDrillsCount = "previewDrills.count"
        static let nonnegativeCountRangeTemplate = TextTemplate("0...%@")
        static let tokenPreviewDrillsWidthMMTemplate = TextTemplate("previewDrills[%@].widthMM")
        static let tokenPreviewDrillsHeightMMTemplate = TextTemplate("previewDrills[%@].heightMM")
        static let tokenPreviewDrillsAngleDegreesTemplate = TextTemplate("previewDrills[%@].angleDegrees")
        static let tokenRoutingPanelBounds = "routing.panelBounds"
        static let tokenRoutingSegmentsMouseBites = "routing.segments/mouseBites"
        static let textNonemptyOutlineAndBoundedHoleCount = "nonempty outline and bounded hole count"
        static let tokenRoutingPoints = "routing.points"
        static let textInsidePanelBounds = "inside panel bounds"
        static let usePositiveRowAndColumnCountsWithAtMostEnglish =
            "Use positive row and column counts with at most 10,000 board positions."
        static let usePositiveRowAndColumnCountsWithAtMostJapanese = "行数・列数は1以上、配置数は合計10,000枚以下にしてください。"
        static let usePositiveRowAndColumnCountsWithAtMostGerman =
            "Zeilen- und Spaltenanzahl müssen positiv sein und dürfen zusammen höchstens 10.000 Leiterplattenpositionen ergeben."
        static let measurementsMustBeFiniteAndBetweenAndMmMountingEnglish =
            "Measurements must be finite and between 0 and 1,000,000 mm; mounting-hole diameter must be positive."
        static let measurementsMustBeFiniteAndBetweenAndMmMountingJapanese = "寸法は有限の0〜1,000,000 mm、取付穴径は0より大きい値にしてください。"
        static let measurementsMustBeFiniteAndBetweenAndMmMountingGerman =
            "Maße müssen endlich sein und zwischen 0 und 1.000.000 mm liegen; der Durchmesser der Befestigungsbohrung muss positiv sein."
        static let tokenOptionsFrameGapMM = "options.frameGapMM"
        static let tokenOptionsPanelCornerRadiusMM = "options.panelCornerRadiusMM"
        static let useATabWidthOfAtLeastMmAndEnglish =
            "Use a tab width of at least 0.001 mm and between 1 and 1,000 tabs per edge."
        static let useATabWidthOfAtLeastMmAndJapanese = "タブ幅は0.001 mm以上、各辺のタブ数は1〜1,000にしてください。"
        static let useATabWidthOfAtLeastMmAndGerman =
            "Verwenden Sie eine Stegbreite von mindestens 0,001 mm und 1 bis 1.000 Stege pro Kante."
        static let thePanelCornerRadiusMustBeZeroOrGreaterEnglish = "The panel corner radius must be zero or greater."
        static let thePanelCornerRadiusMustBeZeroOrGreaterJapanese = "パネル角のRは0以上にしてください。"
        static let thePanelCornerRadiusMustBeZeroOrGreaterGerman =
            "Der Eckenradius des Nutzens muss mindestens 0 betragen."
        static let frameClearanceMustBeZeroOrGreaterEnglish = "Frame clearance must be zero or greater."
        static let frameClearanceMustBeZeroOrGreaterJapanese = "外枠と基板の隙間は0以上にしてください。"
        static let frameClearanceMustBeZeroOrGreaterGerman = "Der Abstand zum Rahmen muss mindestens 0 betragen."
        static let setBothFrameWidthsAboveZeroToCreateAEnglish =
            "Set both frame widths above zero to create a frame and clearance."
        static let setBothFrameWidthsAboveZeroToCreateAJapanese = "隙間のある外枠を作るには、左右・上下の外枠幅を両方とも0より大きくしてください。"
        static let setBothFrameWidthsAboveZeroToCreateAGerman =
            "Stellen Sie beide Rahmenbreiten größer als 0 ein, um einen Rahmen mit Abstand zu erstellen."
        static let mouseBiteDiameterMustBePositiveAndSmallerThanEnglish =
            "Mouse-bite diameter must be positive and smaller than the pitch. The pitch must not exceed the tab width."
        static let mouseBiteDiameterMustBePositiveAndSmallerThanJapanese =
            "ミシン目の穴径は0より大きく、穴ピッチより小さくしてください。穴ピッチはタブ幅以下にしてください。"
        static let mouseBiteDiameterMustBePositiveAndSmallerThanGerman =
            "Der Durchmesser der Sollbruchbohrungen muss größer als 0 und kleiner als der Lochabstand sein. Der Lochabstand darf die Stegbreite nicht überschreiten."
        static let tabsRequireAPositiveFrameClearanceTabWidthAndEnglish =
            "Tabs require a positive frame clearance, tab width and tab count."
        static let tabsRequireAPositiveFrameClearanceTabWidthAndJapanese = "タブを作るには、外枠との隙間・タブ幅・タブ数を0より大きくしてください。"
        static let tabsRequireAPositiveFrameClearanceTabWidthAndGerman =
            "Stege erfordern einen Rahmenabstand, eine Stegbreite und eine Steganzahl größer als 0."
        static let setPositiveBoardSpacingToConnectAdjacentBoardsWithEnglish =
            "Set positive board spacing to connect adjacent boards with tabs."
        static let setPositiveBoardSpacingToConnectAdjacentBoardsWithJapanese = "基板間をタブで接続する場合は、列・行の基板間隔も0より大きくしてください。"
        static let setPositiveBoardSpacingToConnectAdjacentBoardsWithGerman =
            "Stellen Sie positive Leiterplattenabstände ein, um benachbarte Leiterplatten mit Stegen zu verbinden."
        static let tooManyMouseBiteHolesIncreaseTheHolePitchEnglish =
            "Too many mouse-bite holes. Increase the hole pitch or reduce the tab width/count."
        static let tooManyMouseBiteHolesIncreaseTheHolePitchJapanese = "ミシン目の穴が多すぎます。穴ピッチを大きくするか、タブ幅・タブ数を減らしてください。"
        static let tooManyMouseBiteHolesIncreaseTheHolePitchGerman =
            "Zu viele Sollbruchbohrungen. Vergrößern Sie den Lochabstand oder verringern Sie die Stegbreite bzw. Steganzahl."
        static let theOutlineContainsInvalidOrOutOfRangeCoordinatesEnglish =
            "The outline contains invalid or out-of-range coordinates."
        static let theOutlineContainsInvalidOrOutOfRangeCoordinatesJapanese = "外形に不正または範囲外の座標があります。"
        static let theOutlineContainsInvalidOrOutOfRangeCoordinatesGerman =
            "Die Kontur enthält ungültige Koordinaten oder Koordinaten außerhalb des zulässigen Bereichs."
        static let theBoardOutlineIsOpenCloseTheOutlineBeforeEnglish =
            "The board outline is open. Close the outline before creating routed clearances and tabs."
        static let theBoardOutlineIsOpenCloseTheOutlineBeforeJapanese = "基板外形が閉じていません。外形を閉じてから隙間・タブを作成してください。"
        static let theBoardOutlineIsOpenCloseTheOutlineBeforeGerman =
            "Die Leiterplattenkontur ist offen. Schließen Sie die Kontur, bevor Sie Frässpalte und Stege erstellen."
        static let noClosedBoardOutlineWasFoundEnglish = "No closed board outline was found."
        static let noClosedBoardOutlineWasFoundJapanese = "閉じた基板外形が見つかりません。"
        static let noClosedBoardOutlineWasFoundGerman = "Es wurde keine geschlossene Leiterplattenkontur gefunden."
        static let theOutlineHasAnInvalidArcAngleEnglish = "The outline has an invalid arc angle."
        static let theOutlineHasAnInvalidArcAngleJapanese = "外形の円弧角度が不正です。"
        static let theOutlineHasAnInvalidArcAngleGerman = "Die Kontur enthält einen ungültigen Kreisbogenwinkel."
        static let theOutlineArcIsTooLargeToApproximateAccuratelyEnglish =
            "The outline arc is too large to approximate accurately."
        static let theOutlineArcIsTooLargeToApproximateAccuratelyJapanese = "外形の円弧が大きすぎるため、指定精度で近似できません。"
        static let theOutlineArcIsTooLargeToApproximateAccuratelyGerman =
            "Der Kreisbogen ist zu groß für eine ausreichend genaue Näherung."
        static let tokenRoundedRectangleInput = "roundedRectangle.input"
        static let tokenRoundedRectangleRadiusMM = "roundedRectangle.radiusMM"
        static let tokenFrameTabsContours = "frameTabs.contours"
        static let tokenRoutingInput = "routing.input"
        static let tokenRoutingStraightEdges = "routing.straightEdges"
        static let textOneLineSetPerBoard = "one line set per board"
        static let aTabDoesNotIntersectTheBoardOutlineReduceEnglish =
            "A tab does not intersect the board outline. Reduce the tab width or change the layout."
        static let aTabDoesNotIntersectTheBoardOutlineReduceJapanese = "タブが基板外形と交差しません。タブ幅を小さくするか、配置を変更してください。"
        static let aTabDoesNotIntersectTheBoardOutlineReduceGerman =
            "Ein Steg schneidet die Leiterplattenkontur nicht. Verringern Sie die Stegbreite oder ändern Sie die Anordnung."
        static let tokenRoutingStraightSpanIndex = "routing.straightSpanIndex"
        static let textExistingBoardIndex = "existing board index"
        static let someBoardsCannotConnectToTheFrameWithTheseEnglish =
            "Some boards cannot connect to the frame with these tabs. Enable more frame sides, connect adjacent boards, or reduce the tab width."
        static let someBoardsCannotConnectToTheFrameWithTheseJapanese =
            "現在のタブ設定では外枠に繋がらない基板があります。接続辺や基板間タブを有効にするか、タブ幅を小さくしてください。"
        static let someBoardsCannotConnectToTheFrameWithTheseGerman =
            "Einige Leiterplatten können mit diesen Stegen nicht mit dem Rahmen verbunden werden. Aktivieren Sie weitere Rahmenseiten oder Verbindungen zwischen Leiterplatten, oder verringern Sie die Stegbreite."
        static let coordinateKeyTemplate = TextTemplate("%@,%@")
        static let tokenEn = "en"
        static let tokenJa = "ja"
        static let tokenDe = "de"
    }

    /// EN: Board composition, file conversion and process diagnostics.
    /// JA: 基板の合成・ファイル変換・外部処理のエラー文。
    /// DE: Platinenzusammenstellung, Dateikonvertierung und Prozessdiagnosen.
    enum Composition {
        static let tokenEAGLE = "EAGLE"
        static let tokenKiCad = "KiCad"
        static let addABoardAndSetAtLeastOneRowEnglish = "Add a board and set at least one row and column."
        static let addABoardAndSetAtLeastOneRowJapanese = "基板を追加し、列数と行数を1以上にしてください。"
        static let addABoardAndSetAtLeastOneRowGerman =
            "Fügen Sie eine Leiterplatte hinzu und stellen Sie mindestens eine Zeile und eine Spalte ein."
        static let panelMeasurementsMustBeFiniteAndNonnegativeTheMountingEnglish =
            "Panel measurements must be finite and nonnegative; the mounting drill must be positive."
        static let panelMeasurementsMustBeFiniteAndNonnegativeTheMountingJapanese =
            "パネル寸法は有限の0以上の値、取付穴径は0より大きい値にしてください。"
        static let panelMeasurementsMustBeFiniteAndNonnegativeTheMountingGerman =
            "Die Nutzenmaße müssen endlich und mindestens 0 sein; der Durchmesser der Befestigungsbohrung muss größer als 0 sein."
        static let aBoardHasInvalidOutlineDimensionsEnglish = "A board has invalid outline dimensions."
        static let aBoardHasInvalidOutlineDimensionsJapanese = "基板外形の寸法が不正です。"
        static let aBoardHasInvalidOutlineDimensionsGerman = "Eine Leiterplatte hat ungültige Konturabmessungen."
        static let tokenLayoutArrayBounds = "layout.arrayBounds"
        static let tokenLayoutPanelBounds = "layout.panelBounds"
        static let tokenPlacedContoursShapes = "placedContours.shapes"
        static let textAllPlacementSourceIndexesExist = "all placement source indexes exist"
        static let tokenPlacedContoursInput = "placedContours.input"
        static let tokenPlacedContoursOutput = "placedContours.output"
        static let tokenPlacedStraightEdgesShapes = "placedStraightEdges.shapes"
        static let tokenPlacedStraightEdgesInput = "placedStraightEdges.input"
        static let tokenPlacedStraightEdgesOutput = "placedStraightEdges.output"
        static let tokenXTemplate = TextTemplate("x%@")
        static let tokenGuidesOutput = "guides.output"
        static let addABoardFileFirstEnglish = "Add a board file first."
        static let addABoardFileFirstJapanese = "基板ファイルを追加してください。"
        static let addABoardFileFirstGerman = "Fügen Sie zuerst eine Leiterplattendatei hinzu."
        static let tokenPanelComposerOutputSummary = "PanelComposer.output.summary"
        static let textMatchesSerializedBoardOutline = "matches serialized board outline"
        static let systemApplicationsDirectory = "/Applications"
        static let applicationsFolderName = "Applications"
        static let tokenKiCadKiCadAppContentsMacOSKicadCli = "KiCad/KiCad.app/Contents/MacOS/kicad-cli"
        static let tokenKiCadAppContentsMacOSKicadCli = "KiCad.app/Contents/MacOS/kicad-cli"
        static let tokenOptHomebrewBinKicadCli = "/opt/homebrew/bin/kicad-cli"
        static let tokenUsrLocalBinKicadCli = "/usr/local/bin/kicad-cli"
        static let combiningEAGLEAndKiCadBoardsRequiresKiCadOrLaterEnglish =
            "Combining EAGLE and KiCad boards requires KiCad 10 or later. Install KiCad in Applications, then export again."
        static let combiningEAGLEAndKiCadBoardsRequiresKiCadOrLaterJapanese =
            "EAGLEとKiCadの混在面付けにはKiCad 10以降が必要です。アプリケーションフォルダーにKiCadをインストールして、再度出力してください。"
        static let combiningEAGLEAndKiCadBoardsRequiresKiCadOrLaterGerman =
            "Zum Kombinieren von EAGLE- und KiCad-Leiterplatten ist KiCad 10 oder neuer erforderlich. Installieren Sie KiCad im Ordner Programme und exportieren Sie erneut."
        static let tokenSwiftPCBPanelizerImport = "SwiftPCBPanelizer-import-"
        static let tokenSourceBrd = "source.brd"
        static let tokenConvertedKicadPcb = "converted.kicad_pcb"
        static let tokenImportLog = "import.log"
        static let tokenImport = "import"
        static let tokenFormat = "--format"
        static let kicadTookTooLongToImportSourceNameEnglishTemplate = TextTemplate("KiCad took too long to import %@.")
        static let kicadTookTooLongToImportSourceNameJapaneseTemplate = TextTemplate("%@ のKiCad変換がタイムアウトしました。")
        static let kicadTookTooLongToImportSourceNameGermanTemplate = TextTemplate(
            "Zeitüberschreitung beim KiCad-Import von %@.")
        static let cannotConvertSourceNameKiCadOrLaterWithPcbEnglishTemplate = TextTemplate(
            "Cannot convert %@. KiCad 10 or later with pcb import support is required.\n%@")
        static let cannotConvertSourceNameKiCadOrLaterWithPcbJapaneseTemplate = TextTemplate(
            "%@ を変換できません。pcb import対応のKiCad 10以降が必要です。\n%@")
        static let cannotConvertSourceNameKiCadOrLaterWithPcbGermanTemplate = TextTemplate(
            "%@ kann nicht konvertiert werden. Erforderlich ist KiCad 10 oder neuer mit Unterstützung für pcb import.\n%@"
        )
    }

    /// EN: Artwork colors, SVG/HTML/JavaScript templates and preview controls.
    /// JA: 完成画像の色・SVG/HTML/JavaScriptテンプレート・操作文。
    /// DE: Grafikfarben, SVG/HTML/JavaScript-Vorlagen und Vorschau-Bedienelemente.
    enum Artwork {
        static let frontEnglish = "Front"
        static let frontJapanese = "表面"
        static let frontGerman = "Oberseite"
        static let backViewedFromBelowEnglish = "Back (viewed from below)"
        static let backViewedFromBelowJapanese = "裏面（裏から見た向き）"
        static let backViewedFromBelowGerman = "Unterseite (von unten)"
        static let tokenPanelArtworkRendererSources = "PanelArtworkRenderer.sources"
        static let textNonemptyBoundedInput = "nonempty bounded input"
        static let detailedArtworkPreviewRequiresKiCadOrLaterInstallKiCadEnglish =
            "Detailed artwork preview requires KiCad 10 or later. Install KiCad in Applications and try again."
        static let detailedArtworkPreviewRequiresKiCadOrLaterInstallKiCadJapanese =
            "完成プレビューにはKiCad 10以降が必要です。アプリケーションフォルダーにKiCadをインストールしてから再度お試しください。"
        static let detailedArtworkPreviewRequiresKiCadOrLaterInstallKiCadGerman =
            "Die Fertigungsansicht erfordert KiCad 10 oder neuer. Installieren Sie KiCad im Ordner Programme und versuchen Sie es erneut."
        static let creatingThePanelBoardEnglish = "Creating the panel board…"
        static let creatingThePanelBoardJapanese = "面付け基板を生成しています…"
        static let creatingThePanelBoardGerman = "Leiterplattennutzen wird erstellt…"
        static let preparingEAGLEArtworkEnglish = "Preparing EAGLE artwork…"
        static let preparingEAGLEArtworkJapanese = "EAGLEの描画データを準備しています…"
        static let preparingEAGLEArtworkGerman = "EAGLE-Grafikdaten werden vorbereitet…"
        static let tokenPCBPanelBrd = "PCBPanel.brd"
        static let tokenSwiftPCBPanelizerArtwork = "SwiftPCBPanelizer-artwork-"
        static let tokenPanelKicadPcb = "panel.kicad_pcb"
        static let letterUpperF = "F"
        static let letterUpperB = "B"
        static let tokenCu = "Cu"
        static let tokenMask = "Mask"
        static let tokenSilkS = "SilkS"
        static let renderingFaceTitleLayerEnglishTemplate = TextTemplate("Rendering %@: %@…")
        static let renderingFaceTitleLayerJapaneseTemplate = TextTemplate("%@の%@を描画しています…")
        static let renderingFaceTitleLayerGermanTemplate = TextTemplate("%@ wird gerendert: %@…")
        static let tokenSvgTemplate = TextTemplate("%@-%@.svg")
        static let tokenExport = "export"
        static let tokenSvg = "svg"
        static let tokenLayers = "--layers"
        static let qualifiedLayerNameTemplate = TextTemplate("%@.%@")
        static let tokenModeSingle = "--mode-single"
        static let tokenPageSizeMode = "--page-size-mode"
        static let tokenScale = "--scale"
        static let tokenExcludeDrawingSheet = "--exclude-drawing-sheet"
        static let tokenBlackAndWhite = "--black-and-white"
        static let tokenDrillShapeOpt = "--drill-shape-opt"
        static let tokenArtworkLayers = "artwork.layers"
        static let tokenCuMaskSilkS = "Cu/Mask/SilkS"
        static let tokenArtworkFaces = "artwork.faces"
        static let tokenFrontBack = "front/back"
        static let tokenPlotLog = "plot.log"
        static let artworkRenderingTimedOutTryASmallerPanelEnglish = "Artwork rendering timed out. Try a smaller panel."
        static let artworkRenderingTimedOutTryASmallerPanelJapanese = "完成プレビューの生成がタイムアウトしました。基板数を減らしてお試しください。"
        static let artworkRenderingTimedOutTryASmallerPanelGerman =
            "Zeitüberschreitung beim Erstellen der Fertigungsansicht. Versuchen Sie einen kleineren Nutzen."
        static let kicadCouldNotRenderThePanelDetailsSuffixEnglishTemplate = TextTemplate(
            "KiCad could not render the panel.\n%@")
        static let kicadCouldNotRenderThePanelDetailsSuffixJapaneseTemplate = TextTemplate("KiCadでパネルを描画できませんでした。\n%@")
        static let kicadCouldNotRenderThePanelDetailsSuffixGermanTemplate = TextTemplate(
            "KiCad konnte den Nutzen nicht rendern.\n%@")
        static let artworkNumberFormat = "%.8g"
        static let textMTemplate = TextTemplate("M%@ %@ ")
        static let textLTemplate = TextTemplate("L%@ %@")
        static let tokenZ = " Z"
        static let markupRectXYWidthHeightRxFillTemplate = TextTemplate(
            "<rect x=\"%@\" y=\"%@\" width=\"%@\" height=\"%@\" rx=\"%@\" fill=\"%@\" stroke=\"%@\" stroke-width=\"0.035\" transform=\"rotate(%@ %@ %@)\"/>"
        )
        static let tokenAssembleShape = "assemble.shape"
        static let viewBoxTemplate = TextTemplate("%@ %@ %@ %@")
        static let colorHex358268 = "#358268"
        static let tokenCovered = "covered-"
        static let colorHexD9BA70 = "#d9ba70"
        static let tokenExposed = "exposed-"
        static let colorHexFFFFFF = "#ffffff"
        static let tokenOpenings = "openings-"
        static let colorHexF2F1DF = "#f2f1df"
        static let tokenSilk = "silk-"
        static let textTranslateScaleTemplate = TextTemplate("translate(%@ 0) scale(-1 1)")
        static let textTranslate = "translate(0 0)"
        static let finishedPanelSVGTemplate = TextTemplate(
            #"""
            <?xml version="1.0" encoding="UTF-8"?>
            <svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" width="%@mm" height="%@mm" viewBox="%@">
              <title>SwiftPCBPanelizer — %@</title>
              <defs>
                <path id="panel-material" d="%@" fill-rule="evenodd"/>
                <mask id="substrate" maskUnits="userSpaceOnUse" x="%@" y="%@" width="%@" height="%@" style="mask-type:luminance">
                  <rect x="%@" y="%@" width="%@" height="%@" fill="black"/>
                  <use xlink:href="#panel-material" fill="white"/>
                  %@
                </mask>
                <mask id="mask-openings" maskUnits="userSpaceOnUse" x="%@" y="%@" width="%@" height="%@" style="mask-type:luminance">
                  <rect x="%@" y="%@" width="%@" height="%@" fill="black"/>
                  %@
                </mask>
              </defs>
              <g transform="%@">
                <g mask="url(#substrate)">
                  <use xlink:href="#panel-material" fill="#10533f"/>
                  %@
                  <g mask="url(#mask-openings)">%@</g>
                  %@
                </g>
                <use xlink:href="#panel-material" fill="none" stroke="#9ac5aa" stroke-width="0.085" fill-rule="evenodd"/>
                %@
              </g>
            </svg>
            """#)
        static let tokenBlack = "black"
        static let colorHex183B31 = "#183b31"
        static let tokenAssembleOutputSVG = "assemble.outputSVG"
        static let tokenSVG = "SVG"
        static let tokenLayerContentsInputSVG = "layerContents.inputSVG"
        static let kicadReturnedAnInvalidSVGImageEnglish = "KiCad returned an invalid SVG image."
        static let kicadReturnedAnInvalidSVGImageJapanese = "KiCadが生成したSVGを読み込めませんでした。"
        static let kicadReturnedAnInvalidSVGImageGerman = "KiCad hat ein ungültiges SVG-Bild zurückgegeben."
        static let tokenId = "id"
        static let tokenStyle = "style"
        static let tokenTransparent = "transparent"
        static let tokenUrl = "url("
        static let markupUrlTemplate = TextTemplate("url(#%@)")
        static let hashMark = "#"
        static let tokenTitle = "title"
        static let tokenDesc = "desc"
        static let textSwiftPCBPanelizer = "SwiftPCBPanelizer — "
        static let textInitCoderIsUnavailable = "init(coder:) is unavailable"
        static let bareBoardAppearanceCopperSolderMaskSilkAndDrillsEnglish =
            "Bare-board appearance · Copper, solder mask, silk and drills"
        static let bareBoardAppearanceCopperSolderMaskSilkAndDrillsJapanese = "部品実装前の仕上がり · 銅箔・ソルダーマスク・シルク・ドリル穴"
        static let bareBoardAppearanceCopperSolderMaskSilkAndDrillsGerman =
            "Unbestückte Leiterplatte · Kupfer, Lötstoppmaske, Bestückungsdruck und Bohrungen"
        static let panelDimensionsAndBoardCountFormat = "%.1f × %.1f mm · %d"
        static let boardsEnglish = " boards"
        static let boardsJapanese = " 枚"
        static let tokenLeiterplatte = " Leiterplatte"
        static let tokenLeiterplatten = " Leiterplatten"
        static let cannotSavePNGEnglish = "Cannot save PNG"
        static let cannotSavePNGJapanese = "PNGを保存できませんでした"
        static let cannotSavePNGGerman = "PNG kann nicht gespeichert werden"
        static let sideEnglish = "Side"
        static let sideJapanese = "表示面"
        static let sideGerman = "Seite"
        static let tokenMinusMagnifyingglass = "minus.magnifyingglass"
        static let zoomOutEnglish = "Zoom out"
        static let zoomOutJapanese = "縮小"
        static let zoomOutGerman = "Verkleinern"
        static let tokenPlusMagnifyingglass = "plus.magnifyingglass"
        static let zoomInEnglish = "Zoom in"
        static let zoomInJapanese = "拡大"
        static let zoomInGerman = "Vergrößern"
        static let fitEnglish = "Fit"
        static let fitJapanese = "全体表示"
        static let fitGerman = "Einpassen"
        static let savingPNGEnglish = "Saving PNG…"
        static let savingPNGJapanese = "PNG保存中…"
        static let savingPNGGerman = "PNG wird gespeichert…"
        static let savePNGEnglish = "Save PNG"
        static let savePNGJapanese = "PNG保存"
        static let savePNGGerman = "PNG speichern"
        static let tokenSquareAndArrowDown = "square.and.arrow.down"
        static let tokenSwiftPCBPanelizerPngTemplate = TextTemplate("SwiftPCBPanelizer_%@.png")
        static let tokenPNGInputSVG = "PNG.inputSVG"
        static let tokenMm = "mm"
        static let textSVGDimensionsMm = "SVG dimensions [mm]"
        static let tokenPNGDimensionMM = "PNG.dimensionMM"
        static let tokenPNGPixelDimensions = "PNG.pixelDimensions"
        static let textBoundedImageSize = "bounded image size"
        static let theArtworkPreviewIsNotReadyOpenItAgainEnglish =
            "The artwork preview is not ready. Open it again and retry saving."
        static let theArtworkPreviewIsNotReadyOpenItAgainJapanese = "完成プレビューの準備ができていません。開き直してから保存してください。"
        static let theArtworkPreviewIsNotReadyOpenItAgainGerman =
            "Die Fertigungsansicht ist noch nicht bereit. Öffnen Sie sie erneut und speichern Sie nochmals."
        static let theArtworkCouldNotBeConvertedToPNGPleaseEnglish =
            "The artwork could not be converted to PNG. Please try again."
        static let theArtworkCouldNotBeConvertedToPNGPleaseJapanese = "完成プレビューをPNGに変換できませんでした。再度お試しください。"
        static let theArtworkCouldNotBeConvertedToPNGPleaseGerman =
            "Die Fertigungsansicht konnte nicht in PNG umgewandelt werden. Bitte versuchen Sie es erneut."
        static let pngRasterizationJavaScript = #"""
            return await new Promise((resolve, reject) => {
                const image = new Image();
                const timer = setTimeout(() => {
                    image.onload = null;
                    image.onerror = null;
                    reject(new Error(failure));
                }, timeoutMS);
                image.onerror = () => {
                    clearTimeout(timer);
                    reject(new Error(failure));
                };
                image.onload = () => {
                    clearTimeout(timer);
                    try {
                        const canvas = document.createElement('canvas');
                        canvas.width = pixelWidth;
                        canvas.height = pixelHeight;
                        const context = canvas.getContext('2d');
                        if (!context) { throw new Error(failure); }
                        context.drawImage(image, 0, 0, pixelWidth, pixelHeight);
                        const url = canvas.toDataURL('image/png');
                        if (!url.startsWith('data:image/png;base64,')) { throw new Error(failure); }
                        resolve(url.slice('data:image/png;base64,'.length));
                    } catch (error) {
                        reject(error);
                    }
                };
                image.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
            });
            """#
        static let tokenPixelWidth = "pixelWidth"
        static let tokenPixelHeight = "pixelHeight"
        static let tokenTimeoutMS = "timeoutMS"
        static let tokenFailure = "failure"
        static let tokenPNGOutput = "PNG.output"
        static let previewZoomFormat = "%.5f"
        static let markupXmlVersionEncodingUTF = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        static let artworkPreviewHTMLTemplate = TextTemplate(
            #"""
            <!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data:; font-src data:"><style>
            :root{color-scheme:light dark;--zoom:%@}*{box-sizing:border-box}html,body{margin:0;width:100%;height:100%;background:#e6e9ed}#viewport{width:100vw;height:100vh;overflow:auto;overflow-anchor:none}#stage{width:calc((100vw - 48px)*var(--zoom));height:calc((100vh - 48px)*var(--zoom));margin:24px auto}svg{display:block;width:100%;height:100%;filter:drop-shadow(0 5px 7px #0003)}@media(prefers-color-scheme:dark){html,body{background:#20252b}}
            </style></head><body><div id="viewport"><div id="stage">%@</div></div></body></html>
            """#)
        // EN: Keep the same artwork point under the pinch center when the CSS scale changes.
        // JA: CSS倍率の変更前後で、ピンチの中心にある基板上の位置を保つ。
        // DE: Beim CSS-Zoom denselben Punkt der Leiterplatte unter dem Pinch-Zentrum halten.
        static let artworkPreviewZoomJavaScriptTemplate = TextTemplate(
            #"""
            (() => {
                const zoom = %@, x = %@, y = %@;
                const viewport = document.getElementById('viewport');
                const stage = document.getElementById('stage');
                if (!viewport || !stage || !Number.isFinite(zoom) || zoom <= 0) { return; }
                const before = stage.getBoundingClientRect();
                if (before.width <= 0 || before.height <= 0) { return; }
                const u = (x - before.left) / before.width;
                const v = (y - before.top) / before.height;
                document.documentElement.style.setProperty('--zoom', zoom);
                const after = stage.getBoundingClientRect();
                viewport.scrollLeft += after.left + u * after.width - x;
                viewport.scrollTop += after.top + v * after.height - y;
            })();
            """#)
    }

    /// EN: Typography preference keys, slider labels and accessibility text.
    /// JA: 文字設定の保存キー・スライダーのラベル・アクセシビリティ文。
    /// DE: Schriftgrößen-Schlüssel, Reglerbeschriftungen und Bedienungshilfentexte.
    enum Typography {
        static let interfaceTextSizeStorageKey = "interfaceTextSizePercent"
        static let textSizeEnglish = "Text size"
        static let textSizeJapanese = "文字サイズ"
        static let textSizeGerman = "Textgröße"
        static let tokenTextformatSize = "textformat.size"
        static let adjustTextSizeInAllAppWindowsEnglish = "Adjust text size in all app windows"
        static let adjustTextSizeInAllAppWindowsJapanese = "すべてのウィンドウの文字サイズを調整"
        static let adjustTextSizeInAllAppWindowsGerman = "Textgröße in allen App-Fenstern anpassen"
        static let percentageTemplate = TextTemplate("%@%")
        static let smallEnglish = "Small"
        static let smallJapanese = "小"
        static let smallGerman = "Klein"
        static let largeEnglish = "Large"
        static let largeJapanese = "大"
        static let largeGerman = "Groß"
        static let textSizeUpdatesInAllWindowsWhileDraggingReleaseEnglish =
            "Text size updates in all windows while dragging. Release the slider to save your choice."
        static let textSizeUpdatesInAllWindowsWhileDraggingReleaseJapanese = "ドラッグ中もすべてのウィンドウの文字サイズを変更します。離すと設定を保存します。"
        static let textSizeUpdatesInAllWindowsWhileDraggingReleaseGerman =
            "Die Textgröße wird beim Ziehen in allen Fenstern aktualisiert. Beim Loslassen wird Ihre Auswahl gespeichert."
        static let resetToDefaultEnglish = "Reset to default (115%)"
        static let resetToDefaultJapanese = "標準に戻す（115%）"
        static let resetToDefaultGerman = "Auf Standard (115 %) zurücksetzen"
    }

    /// EN: Main-window controls, symbols, file names and localized status text.
    /// JA: メイン画面の操作文・シンボル・ファイル名・多言語の状態表示。
    /// DE: Hauptfenster-Bedienelemente, Symbole, Dateinamen und lokalisierte Statustexte.
    enum App {
        static let applicationNameKey: LocalizedStringKey = "SwiftPCBPanelizer"
        static let artworkAssetName = "PanelizerArtwork"
        static let appIconAssetName = "AppIcon"
        static let tokenIcns = "icns"
        static let duplicatingBoardDataEnglish = "Duplicating board data…"
        static let duplicatingBoardDataJapanese = "基板データを複製しています…"
        static let duplicatingBoardDataGerman = "Leiterplattendaten werden dupliziert…"
        static let pcbPanelizationEnglish = "PCB panelization"
        static let pcbPanelizationJapanese = "基板面付け"
        static let pcbPanelizationGerman = "Leiterplattennutzen"
        static let boardFilesEnglish = "Board files"
        static let boardFilesJapanese = "基板ファイル"
        static let boardFilesGerman = "Leiterplattendateien"
        static let localizedInterpolatedValueTemplate = LocalizedIntegerTemplate("%@")
        static let tokenDocBadgePlus = "doc.badge.plus"
        static let noFilesAddedEnglish = "No files added"
        static let noFilesAddedJapanese = "まだファイルがありません"
        static let noFilesAddedGerman = "Keine Dateien hinzugefügt"
        static let addKicadPcbOrBrdFilesEnglish = "Add .kicad_pcb or .brd files"
        static let addKicadPcbOrBrdFilesJapanese = ".kicad_pcb または .brd を追加"
        static let addKicadPcbOrBrdFilesGerman = ".kicad_pcb- oder .brd-Dateien hinzufügen"
        static let tokenCpu = "cpu"
        static let tokenDocTextMagnifyingglass = "doc.text.magnifyingglass"
        static let dimensionsMMFormat = "%.1f × %.1f mm"
        static let removeFromListEnglish = "Remove from list"
        static let removeFromListJapanese = "リストから削除"
        static let removeFromListGerman = "Aus Liste entfernen"
        static let addBoardsEnglish = "Add boards"
        static let addBoardsJapanese = "基板を追加"
        static let addBoardsGerman = "Leiterplatten hinzufügen"
        static let tokenPlus = "plus"
        static let panelizationHeadingJapanese = "基板の面付け"
        static let panelizationHeadingGerman = "Leiterplattennutzen erstellen"
        static let createPanelBoardsFromEAGLEAndKiCadDesignsEnglish =
            "Create panel boards from EAGLE and KiCad designs."
        static let createPanelBoardsFromEAGLEAndKiCadDesignsJapanese = "EAGLEとKiCadの基板データを複製し、製造用のパネル基板を作成します。"
        static let createPanelBoardsFromEAGLEAndKiCadDesignsGerman =
            "Nutzen aus EAGLE- und KiCad-Leiterplatten erstellen."
        static let tokenCheckmarkSealFill = "checkmark.seal.fill"
        static let processedLocallyEnglish = "Processed locally"
        static let processedLocallyJapanese = "ローカル処理"
        static let processedLocallyGerman = "Lokale Verarbeitung"
        static let tokenArrowDownDocFill = "arrow.down.doc.fill"
        static let importBoardFilesEnglish = "Import board files"
        static let importBoardFilesJapanese = "基板データを読み込む"
        static let importBoardFilesGerman = "Leiterplattendateien importieren"
        static let kicadKicadPcbEAGLEBrdMultipleFilesAndDragEnglish =
            "KiCad .kicad_pcb / EAGLE .brd · Multiple files and drag & drop"
        static let kicadKicadPcbEAGLEBrdMultipleFilesAndDragJapanese =
            "KiCad .kicad_pcb / EAGLE .brd · 複数ファイル・ドラッグ＆ドロップ対応"
        static let kicadKicadPcbEAGLEBrdMultipleFilesAndDragGerman =
            "KiCad .kicad_pcb / EAGLE .brd · Mehrere Dateien und Drag-and-drop"
        static let chooseFilesEnglish = "Choose files"
        static let chooseFilesJapanese = "ファイルを選択"
        static let chooseFilesGerman = "Dateien auswählen"
        static let number01 = "01"
        static let arrayAndSpacingEnglish = "Array and spacing"
        static let arrayAndSpacingJapanese = "配列と間隔"
        static let arrayAndSpacingGerman = "Anordnung und Abstände"
        static let eachFileIsPlacedOnceInOnePanelColumnsEnglish =
            "Each file is placed once in one panel. Columns control wrapping; rows are calculated automatically."
        static let eachFileIsPlacedOnceInOnePanelColumnsJapanese = "各ファイルを1枚ずつ同じパネルに配置します。列数で折り返し、行数は自動計算します。"
        static let eachFileIsPlacedOnceInOnePanelColumnsGerman =
            "Jede Datei wird einmal im selben Nutzen platziert. Die Spaltenanzahl bestimmt den Umbruch; die Zeilenanzahl wird automatisch berechnet."
        static let arrangeBoardsUsingTheirOutlineDimensionsEnglish = "Arrange boards using their outline dimensions"
        static let arrangeBoardsUsingTheirOutlineDimensionsJapanese = "基板外形を基準に行列へ並べます"
        static let arrangeBoardsUsingTheirOutlineDimensionsGerman =
            "Leiterplatten anhand ihrer Konturabmessungen anordnen"
        static let columnsEnglish = "Columns"
        static let columnsJapanese = "列数"
        static let columnsGerman = "Spalten"
        static let tokenRectangleSplitX1 = "rectangle.split.3x1"
        static let optionsColumnsColumnsEnglishTemplate = TextTemplate("%@ columns")
        static let optionsColumnsColumnsJapaneseTemplate = TextTemplate("%@ 列")
        static let optionsColumnsColumnsGermanTemplate = TextTemplate("%@ %@")
        static let tokenSpalte = "Spalte"
        static let rowsEnglish = "Rows"
        static let rowsJapanese = "行数"
        static let rowsGerman = "Zeilen"
        static let tokenRectangleSplitX3 = "rectangle.split.1x3"
        static let displayedrowsRowsAutoEnglishTemplate = TextTemplate("%@ rows · Auto")
        static let displayedrowsRowsAutoJapaneseTemplate = TextTemplate("%@ 行・自動")
        static let displayedrowsRowsAutoGermanTemplate = TextTemplate("%@ %@ · Automatisch")
        static let tokenZeile = "Zeile"
        static let optionsRowsRowsEnglishTemplate = TextTemplate("%@ rows")
        static let optionsRowsRowsJapaneseTemplate = TextTemplate("%@ 行")
        static let columnSpacingJapanese = "横方向の間隔"
        static let tokenArrowLeftAndRight = "arrow.left.and.right"
        static let rowSpacingJapanese = "縦方向の間隔"
        static let tokenArrowUpAndDown = "arrow.up.and.down"
        static let number02 = "02"
        static let frameAndRoutingEnglish = "Frame and routing"
        static let frameAndRoutingJapanese = "外枠と加工ガイド"
        static let frameAndRoutingGerman = "Rahmen und Bearbeitung"
        static let setUpTheFrameConnectingTabsAndMachiningFeaturesEnglish =
            "Set up the frame, connecting tabs and machining features"
        static let setUpTheFrameConnectingTabsAndMachiningFeaturesJapanese = "外枠・接続タブ・加工ガイド・取付穴を設定します"
        static let setUpTheFrameConnectingTabsAndMachiningFeaturesGerman =
            "Rahmen, Verbindungsstege und Bearbeitungsmerkmale einstellen"
        static let frameEnglish = "Frame"
        static let frameJapanese = "外枠"
        static let frameGerman = "Rahmen"
        static let railWidthsBoardClearanceAndCornerShapeEnglish = "Rail widths, board clearance and corner shape"
        static let railWidthsBoardClearanceAndCornerShapeJapanese = "外枠の幅、基板との隙間、角の形状"
        static let railWidthsBoardClearanceAndCornerShapeGerman = "Rahmenbreiten, Leiterplattenabstand und Eckenform"
        static let leftRightFrameWidthEnglish = "Left/right frame width"
        static let leftRightFrameWidthJapanese = "左右の外枠幅"
        static let leftRightFrameWidthGerman = "Rahmenbreite links/rechts"
        static let topBottomFrameWidthEnglish = "Top/bottom frame width"
        static let topBottomFrameWidthJapanese = "上下の外枠幅"
        static let topBottomFrameWidthGerman = "Rahmenbreite oben/unten"
        static let frameClearanceEnglish = "Frame clearance"
        static let frameClearanceJapanese = "外枠と基板の隙間"
        static let frameClearanceGerman = "Abstand zum Rahmen"
        static let panelCornerRadiusEnglish = "Panel corner radius"
        static let panelCornerRadiusJapanese = "パネル角のR"
        static let panelCornerRadiusGerman = "Eckenradius des Nutzens"
        static let frameWidthIsTheMaterialLeftAroundTheBoardsEnglish =
            "Frame width is the material left around the boards. Clearance is the routed gap beside it."
        static let frameWidthIsTheMaterialLeftAroundTheBoardsJapanese = "外枠幅は残す材料の幅、隙間は基板との間を切り抜く幅です。"
        static let frameWidthIsTheMaterialLeftAroundTheBoardsGerman =
            "Die Rahmenbreite ist das Material, das um die Leiterplatten stehen bleibt. Der Abstand ist der daneben ausgefräste Spalt."
        static let breakawayTabsEnglish = "Breakaway tabs"
        static let breakawayTabsJapanese = "接続タブ"
        static let breakawayTabsGerman = "Verbindungsstege"
        static let bridgeBoardsToTheFrameAndNeighboringBoardsEnglish =
            "Bridge boards to the frame and neighboring boards"
        static let bridgeBoardsToTheFrameAndNeighboringBoardsJapanese = "基板と外枠、隣接する基板どうしをつなぎます"
        static let bridgeBoardsToTheFrameAndNeighboringBoardsGerman =
            "Leiterplatten mit dem Rahmen und benachbarten Leiterplatten verbinden"
        static let tokenLink = "link"
        static let tabWidthEnglish = "Tab width"
        static let tabWidthJapanese = "タブ幅"
        static let tabWidthGerman = "Stegbreite"
        static let tabsPerEdgeEnglish = "Tabs per edge"
        static let tabsPerEdgeJapanese = "各辺のタブ数"
        static let tabsPerEdgeGerman = "Stege pro Kante"
        static let connectToFrameEdgesEnglish = "Connect to frame edges"
        static let connectToFrameEdgesJapanese = "外枠と接続する辺"
        static let connectToFrameEdgesGerman = "Mit Rahmenseiten verbinden"
        static let leftEnglish = "Left"
        static let leftJapanese = "左辺"
        static let leftGerman = "Links"
        static let rightEnglish = "Right"
        static let rightJapanese = "右辺"
        static let rightGerman = "Rechts"
        static let topEnglish = "Top"
        static let topJapanese = "上辺"
        static let topGerman = "Oben"
        static let bottomEnglish = "Bottom"
        static let bottomJapanese = "下辺"
        static let bottomGerman = "Unten"
        static let frameTabsUseStraightOutlineSectionsWideEnoughForEnglish =
            "Frame tabs use straight outline sections wide enough for the tabs and holes; curved sections are skipped."
        static let frameTabsUseStraightOutlineSectionsWideEnoughForJapanese = "外枠からのタブは、タブと穴が収まる直線部分に配置し、丸い部分には配置しません。"
        static let frameTabsUseStraightOutlineSectionsWideEnoughForGerman =
            "Rahmenstege nur an ausreichend breiten geraden Konturabschnitten anbringen; Rundungen auslassen."
        static let alsoConnectAdjacentBoardsEnglish = "Also connect adjacent boards"
        static let alsoConnectAdjacentBoardsJapanese = "隣接する基板どうしもタブで接続"
        static let alsoConnectAdjacentBoardsGerman = "Auch benachbarte Leiterplatten verbinden"
        static let boardToBoardTabsAlsoRequireStraightSectionsOnEnglish =
            "Board-to-board tabs also require straight sections on both boards, with enough room for the tabs and holes."
        static let boardToBoardTabsAlsoRequireStraightSectionsOnJapanese = "基板間のタブも、両方の基板でタブと穴が収まる直線部分にだけ配置します。"
        static let boardToBoardTabsAlsoRequireStraightSectionsOnGerman =
            "Platinenstege erfordern auf beiden Platinen gerade Abschnitte mit Platz für Stege und Bohrungen."
        static let addMouseBitePerforationsEnglish = "Add mouse-bite perforations"
        static let addMouseBitePerforationsJapanese = "切り取り用のミシン目"
        static let addMouseBitePerforationsGerman = "Sollbruchbohrungen hinzufügen"
        static let holeDiameterEnglish = "Hole diameter"
        static let holeDiameterJapanese = "ミシン目の穴径"
        static let holeDiameterGerman = "Lochdurchmesser"
        static let holePitchEnglish = "Hole pitch"
        static let holePitchJapanese = "穴ピッチ"
        static let holePitchGerman = "Lochabstand"
        static let separationGuidesEnglish = "Separation guides"
        static let separationGuidesJapanese = "分割ガイド線"
        static let separationGuidesGerman = "Trennhilfslinien"
        static let markTheBoardSeparationPositionsEnglish = "Mark the board separation positions"
        static let markTheBoardSeparationPositionsJapanese = "基板を分割する位置にガイド線を追加"
        static let markTheBoardSeparationPositionsGerman = "Trennpositionen der Leiterplatten markieren"
        static let tokenScissors = "scissors"
        static let guideLineWidthJapanese = "ガイド線幅"
        static let mountingHolesEnglish = "Mounting holes"
        static let mountingHolesJapanese = "取付穴"
        static let mountingHolesGerman = "Befestigungsbohrungen"
        static let holeDiameterAndEdgeInsetsAtTheFourCornersEnglish =
            "Hole diameter and edge insets at the four corners"
        static let holeDiameterAndEdgeInsetsAtTheFourCornersJapanese = "パネル四隅の穴径と端からの距離"
        static let holeDiameterAndEdgeInsetsAtTheFourCornersGerman =
            "Lochdurchmesser und Randabstände an den vier Ecken"
        static let tokenCircleDotted = "circle.dotted"
        static let xInsetEnglish = "X inset"
        static let xInsetJapanese = "左右端から"
        static let xInsetGerman = "Abstand zum linken/rechten Rand"
        static let yInsetEnglish = "Y inset"
        static let yInsetJapanese = "上下端から"
        static let yInsetGerman = "Abstand zum oberen/unteren Rand"
        static let drillDiameterEnglish = "Drill diameter"
        static let drillDiameterJapanese = "ドリル径"
        static let drillDiameterGerman = "Bohrdurchmesser"
        static let number03 = "03"
        static let panelPreviewEnglish = "Panel preview"
        static let panelPreviewJapanese = "パネルプレビュー"
        static let panelPreviewGerman = "Nutzenvorschau"
        static let reviewBoardPositionsRoutedOutlinesAndConnectingTabsEnglish =
            "Review board positions, routed outlines and connecting tabs"
        static let reviewBoardPositionsRoutedOutlinesAndConnectingTabsJapanese = "基板の配置、加工後の外形、接続タブの位置を確認します"
        static let reviewBoardPositionsRoutedOutlinesAndConnectingTabsGerman =
            "Leiterplattenpositionen, Fräskonturen und Verbindungsstege prüfen"
        static let viewCopperPadsSilkAndDrillHolesInAEnglish =
            "View copper, pads, silk and drill holes in a separate window."
        static let viewCopperPadsSilkAndDrillHolesInAJapanese = "配線・パッド・シルク・穴を別ウィンドウで確認できます。"
        static let viewCopperPadsSilkAndDrillHolesInAGerman =
            "Kupfer, Pads, Bestückungsdruck und Bohrungen in einem separaten Fenster anzeigen."
        static let generatedOnRequestRequiresKiCadOrLaterEnglish = "Generated on request · Requires KiCad 10 or later"
        static let generatedOnRequestRequiresKiCadOrLaterJapanese = "ボタンを押した時だけ生成 · KiCad 10以降が必要"
        static let generatedOnRequestRequiresKiCadOrLaterGerman =
            "Erstellung auf Anfrage · Erfordert KiCad 10 oder neuer"
        static let openArtworkPreviewEnglish = "Open artwork preview"
        static let openArtworkPreviewJapanese = "完成プレビューを開く"
        static let openArtworkPreviewGerman = "Fertigungsansicht öffnen"
        static let tokenEye = "eye"
        static let generateANewPreviewUsingTheCurrentPanelSettingsEnglish =
            "Generate a new preview using the current panel settings"
        static let generateANewPreviewUsingTheCurrentPanelSettingsJapanese = "現在の面付け設定で新しいプレビューを生成します"
        static let generateANewPreviewUsingTheCurrentPanelSettingsGerman =
            "Eine neue Vorschau mit den aktuellen Nutzeneinstellungen erstellen"
        static let createOnePanelOfBoardCountBoardsEnglishTemplate = TextTemplate("Create one panel of %@ boards")
        static let createOnePanelOfBoardCountBoardsJapaneseTemplate = TextTemplate("%@ 枚を1枚のパネルに配置")
        static let createOnePanelOfBoardCountBoardsGermanTemplate = TextTemplate("Einen Nutzen mit %@ %@ erstellen")
        static let tokenLeiterplatte = "Leiterplatte"
        static let tokenLeiterplatten = "Leiterplatten"
        static let addABoardFileToBeginEnglish = "Add a board file to begin"
        static let addABoardFileToBeginJapanese = "基板ファイルを追加してください"
        static let addABoardFileToBeginGerman = "Fügen Sie zunächst eine Leiterplattendatei hinzu"
        static let exportOnePanelFileSourceFilesArePreservedEnglish =
            "Export one panel file. Source files are preserved."
        static let exportOnePanelFileSourceFilesArePreservedJapanese = "1つの面付けファイルを出力します。元データは変更されません。"
        static let exportOnePanelFileSourceFilesArePreservedGerman =
            "Eine Nutzendatei exportieren. Die Quelldateien bleiben erhalten."
        static let exportPanelEnglish = "Export panel"
        static let exportPanelJapanese = "面付け基板を書き出す"
        static let exportPanelGerman = "Nutzen exportieren"
        static let tokenSquareAndArrowDownFill = "square.and.arrow.down.fill"
        static let eagleKiCadOneKicadPcbPanelConversionUsesInstalledEnglish =
            "EAGLE + KiCad → one .kicad_pcb panel. Conversion uses installed KiCad 10 or later."
        static let eagleKiCadOneKicadPcbPanelConversionUsesInstalledJapanese =
            "EAGLE + KiCad → 1つの.kicad_pcbに統合します。形式変換にはインストール済みのKiCad 10以降を使用します。"
        static let eagleKiCadOneKicadPcbPanelConversionUsesInstalledGerman =
            "EAGLE + KiCad → ein .kicad_pcb-Nutzen. Die Konvertierung verwendet das installierte KiCad 10 oder neuer."
        static let tokenArrowTriangleMerge = "arrow.triangle.merge"
        static let number0Key: LocalizedStringKey = "0"
        static let tokenMmKey: LocalizedStringKey = "mm"
        static let failureSummaryTemplate = TextTemplate("%@: %@")
        static let noNewSupportedBoardsWereFoundAlreadyImportedFilesEnglish =
            "No new supported boards were found. Already imported files are skipped."
        static let noNewSupportedBoardsWereFoundAlreadyImportedFilesJapanese = "新しい対応基板ファイルがありません。読み込み済みファイルは追加されません。"
        static let noNewSupportedBoardsWereFoundAlreadyImportedFilesGerman =
            "Keine neuen unterstützten Leiterplatten gefunden. Bereits importierte Dateien werden übersprungen."
        static let importedImportedCountBoardsAllListedBoardsWillBeEnglishTemplate = TextTemplate(
            "Imported %@ boards. All listed boards will be combined into one panel.")
        static let importedImportedCountBoardsAllListedBoardsWillBeJapaneseTemplate = TextTemplate(
            "%@ 個の基板を読み込みました。リスト内の基板を1枚のパネルに統合します。")
        static let importedImportedCountBoardsAllListedBoardsWillBeGermanTemplate = TextTemplate(
            "%@ %@ importiert. Alle aufgelisteten Leiterplatten werden zu einem Nutzen zusammengefügt.")
        static let blankLineSeparator = "\n\n"
        static let exportOnePanelBoardEnglish = "Export one panel board"
        static let exportOnePanelBoardJapanese = "1枚の面付け基板を書き出す"
        static let exportOnePanelBoardGerman = "Einen Leiterplattennutzen exportieren"
        static let exportEnglish = "Export"
        static let exportJapanese = "書き出す"
        static let exportGerman = "Exportieren"
        static let tokenPCBPanelBoardsTemplate = TextTemplate("PCBPanel_%@boards.%@")
        static let tokenPanelXTemplate = TextTemplate("%@_panel_%@x%@.%@")
        static let chooseADifferentOutputFilenameToKeepTheSourceEnglish =
            "Choose a different output filename to keep the source board unchanged."
        static let chooseADifferentOutputFilenameToKeepTheSourceJapanese = "元の基板ファイルを維持するため、別の出力ファイル名を選択してください。"
        static let chooseADifferentOutputFilenameToKeepTheSourceGerman =
            "Wählen Sie einen anderen Ausgabedateinamen, damit die ursprüngliche Leiterplattendatei unverändert bleibt."
        static let exportedOnePanelBoardDestinationPathEnglishTemplate = TextTemplate("Exported one panel board.\n%@")
        static let exportedOnePanelBoardDestinationPathJapaneseTemplate = TextTemplate("1枚の面付け基板を書き出しました。\n%@")
        static let exportedOnePanelBoardDestinationPathGermanTemplate = TextTemplate(
            "Ein Leiterplattennutzen wurde exportiert.\n%@")
        static let preparingArtworkEnglish = "Preparing artwork…"
        static let preparingArtworkJapanese = "完成プレビューを準備しています…"
        static let preparingArtworkGerman = "Fertigungsansicht wird vorbereitet…"
        static let tokenSquareGridX2 = "square.grid.2x2"
        static let panelLayoutPreviewEnglish = "Panel layout preview"
        static let panelLayoutPreviewJapanese = "面付けレイアウトのプレビュー"
        static let panelLayoutPreviewGerman = "Vorschau der Nutzenanordnung"
        static let addBoardFilesToDisplayThePanelLayoutHereEnglish = "Add board files to display the panel layout here."
        static let addBoardFilesToDisplayThePanelLayoutHereJapanese = "基板を追加すると、ここに面付け後の配置を表示します。"
        static let addBoardFilesToDisplayThePanelLayoutHereGerman =
            "Fügen Sie Leiterplattendateien hinzu, um hier die Nutzenanordnung anzuzeigen."
        static let boardOutlinesEnglish = "Board outlines"
        static let boardOutlinesJapanese = "基板外形"
        static let boardOutlinesGerman = "Leiterplattenkonturen"
        static let panelRoutingEnglish = "Panel routing"
        static let panelRoutingJapanese = "パネル加工線"
        static let panelRoutingGerman = "Fräskontur des Nutzens"
        static let tokenRectangleDashed = "rectangle.dashed"
        static let mouseBitesEnglish = "Mouse bites"
        static let mouseBitesJapanese = "ミシン目"
        static let mouseBitesGerman = "Sollbruchbohrungen"
        static let boardIndexCaptionTemplate = TextTemplate("%@ · ")
        static let ellipsis = "…"
    }
}
