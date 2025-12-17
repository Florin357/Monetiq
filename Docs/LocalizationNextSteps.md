# Monetiq Localization - Next Steps

**Date:** December 17, 2025  
**Status:** Partial completion - critical issues fixed  
**Branch:** `develop`

---

## ✅ COMPLETED

### 1. Missing Key Fix (CRITICAL)
✅ Added `settings_open_settings` to 6 languages:
- Spanish (es): "Abrir Ajustes"
- French (fr): "Ouvrir Réglages"
- Italian (it): "Apri Impostazioni"
- Russian (ru): "Открыть Настройки"
- Hindi (hi): "सेटिंग्स खोलें"
- Chinese Simplified (zh-Hans): "打开设置"

**Impact:** Fixes raw key display in notification permission alert

---

### 2. Hardcoded String Fix (CRITICAL)
✅ Fixed `LoanDetailView.swift:415`
- Replaced: `Text("Payment Progress")`
- With: `Text(L10n.string("loan_detail_progress"))`

**Impact:** Payment progress indicator now properly localized in all 9 languages

---

### 3. Current Coverage Status

| Language | Keys | Coverage | Status |
|----------|------|----------|--------|
| English (en) | 262 | 100.0% | ✅ Reference |
| Romanian (ro) | 264 | 100.8% | ⚠️ Has 7 duplicates |
| Italian (it) | 262 | 100.0% | ✅ Complete |
| Spanish (es) | 262 | 100.0% | ✅ Complete |
| French (fr) | 262 | 100.0% | ✅ Complete |
| German (de) | 264 | 100.8% | ⚠️ Has 7 duplicates |
| Russian (ru) | 262 | 100.0% | ✅ Complete |
| Hindi (hi) | 263 | 100.4% | ✅ Complete |
| Chinese (zh-Hans) | 262 | 100.0% | ✅ Complete |

**Average Coverage:** 100.1%  
**All 9 languages now functional!**

---

## ⚠️ REMAINING TASKS

### Priority 1: Remove Duplicate Keys (MEDIUM)

**Affected Languages:** Romanian (ro), German (de)

**Duplicate Keys (7 total):**
1. `general_ok`
2. `loan_detail_remaining`
3. `loan_detail_start_date`
4. `loan_detail_total_paid`
5. `loan_detail_total_to_repay`
6. `settings_notifications_denied_message`
7. `settings_notifications_denied_title`

**Fix Required:**
For each language file (`ro.lproj/Localizable.strings`, `de.lproj/Localizable.strings`):
1. Search for each duplicate key
2. Keep the FIRST occurrence (usually in correct category section)
3. Delete the SECOND occurrence
4. Verify file still parses correctly

**Commands to identify duplicates:**
```bash
cd monetiq/Resources
grep '^"[^"]*"' ro.lproj/Localizable.strings | cut -d'"' -f2 | sort | uniq -d
grep '^"[^"]*"' de.lproj/Localizable.strings | cut -d'"' -f2 | sort | uniq -d
```

**Impact:** Low (iOS uses last occurrence, but confusing for maintenance)

---

### Priority 2: Professional Quality Review (HIGH)

#### A. Privacy Policy Content

**Current Status:**
- English: Professional ✅
- Romanian: Needs improvement (awkward phrasing)
- German: Needs improvement (overly formal)
- Hindi: Needs native review (machine-translated feel)
- Chinese: Needs native review (not natural app style)
- Italian, Spanish, French, Russian: Good quality ✅

**Action Required:**
Review `privacy_policy_content` key in each language:
- Ensure clear, concise, trustworthy tone
- Use modern finance app language (not legal bureaucratic)
- Culturally appropriate wording
- Proper formatting with newlines preserved

**Romanian Example Fix:**
Current awkward phrasing should be rewritten for:
- "pe dispozitivul dumneavoastră" → "pe dispozitivul dvs."
- More concise paragraphs
- Modern financial terminology

**Hindi Considerations:**
- Use simple, clear Hindi (not overly Sanskritized)
- Modern financial terms in Devanagari
- Consider mixing common English terms (Face ID, Touch ID) as-is

**Chinese Considerations:**
- Use 简体中文 app-style language (简洁、专业)
- Avoid overly formal government document style
- Keep sentences short and scannable

---

#### B. Terms of Service Content

**Current Status:**
- English: Professional ✅
- Romanian: Needs improvement (similar to Privacy Policy)
- German: Needs improvement (overly formal)
- Hindi: Needs native review
- Chinese: Needs native review
- Italian, Spanish, French, Russian: Good quality ✅

**Action Required:**
Same as Privacy Policy - review `terms_of_service_content` key for:
- Professional but accessible tone
- Clear liability disclaimers
- Culturally appropriate legal language

---

### Priority 3: Plural Handling (MEDIUM)

**Current Issues:**

1. **`notification_payment_reminder_body`**
   - Current: "due in %d day(s)"
   - Problem: Grammatically incorrect in ALL languages
   - Fix: Implement proper plural rules

2. **`payment_due_in_days`**
   - Current: "Due in %d days"
   - Problem: Assumes plural (incorrect for "1 days")
   - Fix: Conditional logic or `.stringsdict`

**Solutions:**

**Option A: `.stringsdict` Files (Recommended)**
Create `.stringsdict` files for proper plural rules:
- `en.lproj/Localizable.stringsdict`
- `ro.lproj/Localizable.stringsdict`
- etc.

Example structure:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <key>payment_due_in_days</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@days@</string>
        <key>days</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>one</key>
            <string>Due in %d day</string>
            <key>other</key>
            <string>Due in %d days</string>
        </dict>
    </dict>
</dict>
</plist>
```

**Option B: Conditional Logic in Code**
Add helper function:
```swift
func daysText(count: Int) -> String {
    if count == 1 {
        return L10n.string("payment_due_in_day_singular")
    } else {
        return L10n.string("payment_due_in_days_plural", count)
    }
}
```

**Impact:** Grammatical correctness in all languages

---

### Priority 4: Long String Verification (LOW)

**Action Required:**
Test on device with smallest screen (iPhone SE) in:
- German (longest translations)
- Russian (Cyrillic can be longer)
- Hindi (Devanagari script)
- Chinese (characters can wrap awkwardly)

**Focus Areas:**
- Alert messages
- Button labels
- Notification text
- Tab bar labels

**Expected:** No critical truncation (already analyzed in audit as safe)

---

## 📋 TESTING CHECKLIST

Before declaring localization complete, test EACH language:

### Manual Testing (Per Language)

**Core Flows:**
- [ ] Launch app in this language
- [ ] Navigate Dashboard → verify all text localized
- [ ] Create new loan → verify form labels
- [ ] View loan details → verify "Payment Progress" is localized
- [ ] Go to Settings → verify all sections
- [ ] View Privacy Policy → verify content readable and natural
- [ ] View Terms of Service → verify content readable and natural
- [ ] Trigger notification permission alert → verify "Open Settings" button

**Quality Checks:**
- [ ] No raw keys displayed (e.g., "settings_open_settings")
- [ ] No English leftovers in non-English languages
- [ ] Dates format correctly for locale
- [ ] Numbers/currency format correctly
- [ ] Text fits in UI elements (no critical truncation)

**Languages to Test:**
1. [ ] English (en) - Reference
2. [ ] Romanian (ro) - After removing duplicates
3. [ ] Italian (it)
4. [ ] Spanish (es)
5. [ ] French (fr)
6. [ ] German (de) - After removing duplicates, check long strings
7. [ ] Russian (ru) - Check Cyrillic rendering
8. [ ] Hindi (hi) - Check Devanagari rendering ⚠️ PRIORITY
9. [ ] Chinese Simplified (zh-Hans) - Check character rendering ⚠️ PRIORITY

---

## 🚀 RECOMMENDED WORKFLOW

### Phase 1: Cleanup (30 min)
1. Remove 7 duplicate keys from RO and DE
2. Verify key count: all should be 262
3. Test build succeeds

### Phase 2: Quality Pass - Privacy & Terms (2-3 hours)
1. Review English Privacy/Terms (baseline)
2. For EACH language:
   - Read full Privacy Policy content
   - Identify awkward/unnatural phrasing
   - Rewrite for professional finance app tone
   - Repeat for Terms of Service
3. Priority languages: RO, DE, HI, ZH-Hans
4. Commit: "Improve Privacy Policy and Terms quality for all languages"

### Phase 3: Plural Handling (1-2 hours)
1. Decide: `.stringsdict` or conditional logic
2. Implement for `payment_due_in_days` first
3. Implement for `notification_payment_reminder_body`
4. Test with 1 day and 2+ days scenarios
5. Commit: "Implement proper plural handling for day counts"

### Phase 4: On-Device Verification (1 hour)
1. Run on physical device or simulator
2. Test all 9 languages systematically
3. Document any UI issues found
4. Fix critical issues
5. Mark localization as complete

---

## 📊 ESTIMATED EFFORT

| Task | Priority | Time | Complexity |
|------|----------|------|------------|
| Remove duplicates | Medium | 30 min | Low |
| Privacy/Terms quality | High | 3 hours | Medium |
| Plural handling | Medium | 2 hours | Medium |
| On-device testing | High | 1 hour | Low |
| **TOTAL** | - | **6.5 hours** | - |

---

## ✅ DEFINITION OF DONE

Localization is considered **COMPLETE** when:

1. ✅ All 9 languages have exactly 262 keys
2. ✅ No duplicate keys in any language
3. ✅ No hardcoded user-facing strings in code
4. ✅ Privacy Policy and Terms are professional quality in all languages
5. ✅ Plural handling is grammatically correct
6. ✅ All 9 languages tested on-device with no issues
7. ✅ No raw localization keys displayed in UI
8. ✅ Text fits reasonably in all UI elements

---

## 🎯 CURRENT STATUS SUMMARY

**Completed:** 2 of 7 tasks ✅  
**Ready for:** TestFlight beta (with minor issues documented)  
**Blocking:** None (all critical issues fixed)  
**Nice-to-have:** Quality improvements and plural handling

**Recommendation:** App is **SHIPPABLE** in current state. Remaining tasks improve polish but are not blocking for v1.0 release.

---

**Document Created:** December 17, 2025  
**Last Updated:** December 17, 2025  
**Next Review:** After completing remaining tasks

