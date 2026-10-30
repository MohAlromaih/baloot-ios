#if canImport(UIKit)
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case ar, en
    var id: String { rawValue }
    var layoutDirection: LayoutDirection { self == .ar ? .rightToLeft : .leftToRight }
    var locale: Locale { Locale(identifier: self == .ar ? "ar" : "en") }

    /// First launch: use device language if supported, otherwise Arabic.
    static var deviceDefault: AppLanguage {
        let code = Locale.preferredLanguages.first?.prefix(2).lowercased() ?? "ar"
        return code == "en" ? .en : .ar
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// All interface strings. Custom team names are never translated.
struct L10n {
    let lang: AppLanguage
    private var ar: Bool { lang == .ar }

    var appTitle: String { ar ? "حاسبة البلوت" : "Baloot Calculator" }
    var defaultTeamA: String { ar ? "لنا" : "Us" }
    var defaultTeamB: String { ar ? "لهم" : "Them" }
    var addHand: String { ar ? "إضافة يد" : "Add hand" }
    var total: String { ar ? "المجموع" : "Total" }
    var remaining: String { ar ? "المتبقي" : "Remaining" }
    var handHistory: String { ar ? "سجل الأيدي" : "Hand history" }
    var undo: String { ar ? "تراجع" : "Undo" }
    var edit: String { ar ? "تعديل" : "Edit" }
    var delete: String { ar ? "حذف" : "Delete" }
    var newMatch: String { ar ? "مباراة جديدة" : "New match" }
    var previousMatches: String { ar ? "المباريات السابقة" : "Previous matches" }
    var targetScore: String { ar ? "هدف المباراة" : "Target score" }
    var pts: String { ar ? "نقطة" : "pts" }
    var hand: String { ar ? "يد" : "Hand" }
    func teamWins(_ name: String) -> String { ar ? "فاز فريق \(name)" : "\(name) wins" }
    var tieContinue: String { ar ? "تعادل — يستمر اللعب" : "Tie — continue playing" }
    var matchLocked: String {
        ar ? "انتهت المباراة. ابدأ مباراة جديدة للعب مجددًا."
           : "Match completed. Start a new match to play again."
    }
    func pointsOf(_ name: String) -> String { ar ? "نقاط \(name)" : "\(name) points" }

    // Validation
    var enterBoth: String { ar ? "أدخل نقاط الفريقين" : "Enter points for both teams" }
    var invalidNumber: String { ar ? "أدخل عددًا صحيحًا صفرًا أو أكبر" : "Enter a whole number of zero or more" }
    var bothZero: String { ar ? "لا يمكن أن تكون نقاط الفريقين صفرًا" : "Both teams cannot score 0 in the same hand" }
    var saveFailed: String {
        ar ? "تعذّر الحفظ في ذاكرة الجهاز. لم تُحفظ اليد — حاول مرة أخرى."
           : "Could not save to device storage. The hand was NOT saved — please try again."
    }
    var storageCorrupted: String {
        ar ? "تعذّرت قراءة البيانات المحفوظة (تالفة). تم بدء مباراة جديدة."
           : "Saved data could not be read (corrupted). A new match was started."
    }

    // Common
    var cancel: String { ar ? "إلغاء" : "Cancel" }
    var save: String { ar ? "حفظ" : "Save" }
    var done: String { ar ? "تم" : "Done" }
    var close: String { ar ? "إغلاق" : "Close" }

    // New match
    var newMatchConfirm: String {
        ar ? "سيتم أرشفة المباراة الحالية في المباريات السابقة وبدء مباراة جديدة."
           : "The current match will be archived in previous matches and a new one started."
    }
    var teamAName: String { ar ? "اسم الفريق الأول" : "Team 1 name" }
    var teamBName: String { ar ? "اسم الفريق الثاني" : "Team 2 name" }
    var startMatch: String { ar ? "بدء المباراة" : "Start match" }
    var resetNames: String { ar ? "استعادة الأسماء الافتراضية" : "Reset to default names" }

    // Delete / edit
    var deleteHandTitle: String { ar ? "حذف اليد" : "Delete hand" }
    func deleteHandMsg(_ n: Int) -> String {
        ar ? "هل تريد حذف اليد رقم \(n)؟ سيُعاد احتساب المجموع." : "Delete hand #\(n)? Totals will be recalculated."
    }
    func editHandTitle(_ n: Int) -> String { ar ? "تعديل اليد رقم \(n)" : "Edit hand #\(n)" }

    // Conflict
    var conflictTitle: String { ar ? "فوز مبكر بعد التصحيح" : "Earlier win after correction" }
    func conflictMsg(team: String, hand: Int, count: Int) -> String {
        ar ? "بعد هذا التصحيح يفوز فريق \(team) في اليد رقم \(hand). يوجد \(count) يد مسجلة بعدها ويجب حذفها لتطبيق التصحيح."
           : "After this correction, \(team) wins at hand #\(hand). There are \(count) later hand(s) that must be removed to apply it."
    }
    var conflictRemove: String { ar ? "حذف الأيدي اللاحقة وتطبيق" : "Remove later hands & apply" }
    var conflictCancel: String { ar ? "إلغاء التصحيح" : "Cancel correction" }
    var flagged: String { ar ? "ستُحذف" : "Will be removed" }

    // Settings
    var settings: String { ar ? "الإعدادات" : "Settings" }
    var language: String { ar ? "اللغة" : "Language" }
    var appearance: String { ar ? "المظهر" : "Appearance" }
    var themeSystem: String { ar ? "تلقائي" : "System" }
    var themeLight: String { ar ? "فاتح" : "Light" }
    var themeDark: String { ar ? "داكن" : "Dark" }
    var keypad: String { ar ? "لوحة الأرقام المدمجة" : "Built-in keypad" }
    var keypadDesc: String {
        ar ? "لوحة أرقام تحت خانات النقاط. اكتب النقاط ثم اضغط اسم الفريق لإضافتها له مباشرة."
           : "Keypad under the score boxes. Type points then tap a team to add them directly."
    }
    var keypadHint: String { ar ? "اكتب النقاط ثم اضغط اسم الفريق" : "Type points, then tap a team" }
    var targetLocked: String {
        ar ? "يمكن تغيير الهدف قبل تسجيل أول يد فقط." : "Target can only change before the first hand."
    }
    var defaultTargetLabel: String { ar ? "الهدف الافتراضي للمباريات الجديدة" : "Default target for new matches" }
    var rulesTitle: String { ar ? "قواعد إنهاء المباراة" : "Match completion rules" }
    var rules: [String] {
        ar ? [
            "إذا لم يصل أي فريق للهدف يستمر اللعب.",
            "إذا وصل فريق للهدف أو تجاوزه يفوز.",
            "إذا وصل الفريقان في نفس اليد يفوز صاحب المجموع الأعلى.",
            "إذا تعادلا عند الهدف أو أعلى يستمر اللعب حتى يُكسر التعادل.",
            "بعد إعلان الفائز لا تُقبل أيدٍ جديدة.",
        ] : [
            "If neither team reaches the target, play continues.",
            "A team that reaches or exceeds the target wins.",
            "If both cross in the same hand, the higher total wins.",
            "If tied at or above the target, play continues until the tie is broken.",
            "No new hands are accepted after a winner is declared.",
        ]
    }
    var storageTitle: String { ar ? "التخزين المحلي" : "Local storage" }
    var storageDesc: String {
        ar ? "تُحفظ المباريات داخل جهازك فقط وتعمل بدون إنترنت. لا تتم مزامنتها بين الأجهزة، وحذف التطبيق يحذفها."
           : "Matches are stored only on this device and work offline. They do not sync across devices; deleting the app deletes them."
    }

    // Saved
    var noSaved: String { ar ? "لا توجد مباريات سابقة" : "No previous matches" }
    var noHands: String { ar ? "لم تُسجل أي يد بعد" : "No hands recorded yet" }
    var hands: String { ar ? "أيدٍ" : "hands" }
    var noWinner: String { ar ? "بدون فائز" : "No winner" }
    var rename: String { ar ? "تعديل الاسم" : "Rename" }
}
#endif
