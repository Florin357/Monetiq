# Cashflow Card UX Micro-Polish

**Date:** 2025-12-22  
**Branch:** `develop`  
**Status:** ✅ Implemented (not committed yet)  
**Type:** UX polish only (no business logic changes)

---

## 📋 Overview

Applied subtle, professional UX refinements to the Cashflow card to improve readability and trust. These are fintech-style polish improvements: **subtlety > visibility, trust > flashiness**.

**Scope:** Visual-only adjustments (opacity, ordering, stroke styles, spacing)  
**No changes to:** Calculations, data sources, time windows, or business logic

---

## ✅ Improvements Applied

### 1. Net Values Ordering (Clarity Improvement)

**Problem:** Net values appeared in arbitrary order, making them harder to scan.

**Solution:** Smart ordering for predictable, scannable display.

**New ordering logic:**
```swift
let sortedCurrencies = netValues.keys.sorted { currency1, currency2 in
    let val1 = netValues[currency1] ?? 0
    let val2 = netValues[currency2] ?? 0
    
    // Positives before negatives
    if (val1 >= 0) != (val2 >= 0) {
        return val1 >= 0
    }
    // Within same sign, sort by descending absolute value
    return abs(val1) > abs(val2)
}
```

**Before:**
```
Net
-1.337,50 USD
+1.250,00 GBP
+10.808,33 RON
```

**After:**
```
Net
+10.808,33 RON    ← Positive, largest
+1.250,00 GBP     ← Positive, smaller
-1.337,50 USD     ← Negative, last
```

**Result:** Net values are easier to scan at a glance. Positive cashflow appears first (encouraging), obligations appear last (clear).

---

### 2. Receive vs Pay Visual Differentiation (Subtle)

**Problem:** Lines could be hard to distinguish at intersections.

**Solution:** Subtle visual distinction without strong contrast.

**Changes:**
- **"To Receive" line:** Solid 2.0pt, full opacity
- **"To Pay" line:** Light dash pattern (5-3), 85% opacity (was 90%)

**Code:**
```swift
// Receive line
.foregroundStyle(softGreen)
.lineStyle(StrokeStyle(lineWidth: 2.0))

// Pay line
.foregroundStyle(softOrange.opacity(0.85))  // Reduced from 0.9
.lineStyle(StrokeStyle(lineWidth: 2.0, dash: [5, 3]))  // Changed from [6, 3]
```

**Result:** Lines remain calm and non-alarming, but intersections are easier to read. The subtle opacity difference helps the eye distinguish lines without dramatic contrast.

---

### 3. Context Text Placement & Readability

**Problem:** "Based on scheduled payments" was easy to miss, appearing below the chart.

**Solution:** Moved closer to title for better context.

**Before:**
```
Cashflow              Net
Next 30 days          +1.250,00 EUR

[Chart appears here]

Based on scheduled payments  ← Too far from title
```

**After:**
```
Cashflow              Net
Next 30 days          +1.250,00 EUR
Based on scheduled payments  ← Right below title

[Chart appears here]
```

**Implementation:**
- Moved helper text into the title `VStack`
- Font: `caption2` (kept small)
- Color: `textSecondary @ 85%` (slightly more visible than before)
- Padding: `2pt` from subtitle

**Result:** Users understand the data source BEFORE interpreting the graph, building trust.

---

## 📊 Visual Impact

### Net Summary

**Ordering improvement:**
- ✅ Positive values always appear first (encouraging)
- ✅ Within positives, largest to smallest (most important first)
- ✅ Negative values last (obligations are clear but not alarming)
- ✅ Consistent, predictable ordering across all scenarios

### Chart Lines

**Subtle distinction:**
- ✅ Receive line: Solid, full opacity (primary)
- ✅ Pay line: Dashed, 85% opacity (secondary, but still clear)
- ✅ Both lines remain calm (no strong contrast)
- ✅ Intersections are easier to read

### Context Text

**Better placement:**
- ✅ Appears right below "Next 30 days"
- ✅ Small font (not headline-level)
- ✅ Subtle color (secondary, not primary)
- ✅ Provides context before user interprets data

---

## 🎯 Acceptance Criteria

**Readability:**
- ✅ Net values easier to scan (positive first, sorted)
- ✅ Lines clearly distinguishable (subtle opacity + dash)
- ✅ Context text discoverable (near title)

**Calmness:**
- ✅ No strong contrast or dramatic changes
- ✅ Professional, trustworthy appearance
- ✅ Fintech-style subtlety maintained

**No behavioral changes:**
- ✅ Same calculations
- ✅ Same data sources
- ✅ Same time window (30 days)
- ✅ Same filtering logic

---

## 📁 Files Modified

**1. `CashflowCardView.swift`**
- Updated net values sorting logic (positives first, then by absolute value)
- Moved helper text from below chart to title area
- Adjusted Pay line opacity (90% → 85%) and dash pattern (6-3 → 5-3)

**Total changes:** ~20 lines  
**Risk level:** Very low (visual only)

**2. `CASHFLOW_UX_MICROPOLISH.md`** (NEW)
- This document

---

## 🧪 Testing Notes

**Test scenarios:**

1. **Multiple currencies (positive + negative):**
   - Create loans in EUR (+), RON (+), USD (-)
   - Verify: Positives appear first, sorted by absolute value, negatives last

2. **Line intersection:**
   - Create receive and pay loans that cross on the graph
   - Verify: Lines remain distinguishable (dash pattern + opacity help)

3. **Context text visibility:**
   - Check that "Based on scheduled payments" appears below subtitle
   - Verify: Still subtle, not headline-level

4. **Empty state:**
   - No changes to empty state
   - Verify: Still shows calendar icon + message

---

## ✅ Build Status

- ✅ No linter errors
- ✅ Compiles successfully
- ✅ No localization changes needed (no new text)
- ✅ Ready for testing

---

## 📝 Summary

Three subtle UX improvements applied:

1. **Net values ordering** — Positive first, sorted by absolute value, negative last
2. **Line distinction** — Pay line at 85% opacity + light dash (was 90% + heavier dash)
3. **Context text placement** — Moved near title for better understanding

**Result:** The Cashflow card feels calmer, more readable, and more trustworthy. Users can:
- Scan net values more easily (predictable order)
- Distinguish lines at intersections (subtle opacity + dash)
- Understand data source before interpreting graph (context near title)

**No behavioral changes.** Pure UX polish, ready for TestFlight testing.

