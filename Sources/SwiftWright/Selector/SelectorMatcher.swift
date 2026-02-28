import Foundation

/// Matches ``ParsedSelector`` against an ``AXElementProtocol`` tree.
public enum SelectorMatcher {

    // MARK: - Role aliases

    /// Maps user-facing role names (lowercase) to canonical AX role strings.
    public static let roleAliases: [String: String] = [
        "application":   "AXApplication",
        "button":        "AXButton",
        "cell":          "AXCell",
        "checkbox":      "AXCheckBox",
        "colorwell":     "AXColorWell",
        "combobox":      "AXComboBox",
        "dialog":        "AXSheet",
        "disclosure":    "AXDisclosureTriangle",
        "drawer":        "AXDrawer",
        "group":         "AXGroup",
        "growarea":      "AXGrowArea",
        "handle":        "AXHandle",
        "image":         "AXImage",
        "incrementor":   "AXIncrementor",
        "input":         "AXTextField",
        "layoutarea":    "AXLayoutArea",
        "layoutitem":    "AXLayoutItem",
        "levelindicator":"AXLevelIndicator",
        "link":          "AXLink",
        "list":          "AXList",
        "menu":          "AXMenu",
        "menubar":       "AXMenuBar",
        "menubaritem":   "AXMenuBarItem",
        "menuitem":      "AXMenuItem",
        "outline":       "AXOutline",
        "popupbutton":   "AXPopUpButton",
        "progressindicator": "AXProgressIndicator",
        "radiobutton":   "AXRadioButton",
        "radiogroup":    "AXRadioGroup",
        "relevanceindicator": "AXRelevanceIndicator",
        "row":           "AXRow",
        "ruler":         "AXRuler",
        "rulermarker":   "AXRulerMarker",
        "scrollarea":    "AXScrollArea",
        "scrollbar":     "AXScrollBar",
        "sheet":         "AXSheet",
        "slider":        "AXSlider",
        "splitgroup":    "AXSplitGroup",
        "splitter":      "AXSplitter",
        "statictext":    "AXStaticText",
        "systemwide":    "AXSystemWide",
        "tabgroup":      "AXTabGroup",
        "table":         "AXTable",
        "text":          "AXStaticText",
        "textarea":      "AXTextArea",
        "textfield":     "AXTextField",
        "toolbar":       "AXToolbar",
        "unknown":       "AXUnknown",
        "valueindicator":"AXValueIndicator",
        "window":        "AXWindow",
    ]

    /// Resolves a user role name to its canonical AX role string.
    public static func resolveRole(_ name: String) -> String {
        roleAliases[name.lowercased()] ?? name
    }

    // MARK: - Tree search

    /// Finds all elements in `root`'s subtree (including `root`) that satisfy `selector`.
    ///
    /// Descendant semantics: each step must be satisfied by a descendant of the
    /// element that satisfied the previous step.
    public static func find<E: AXElementProtocol>(selector: ParsedSelector, in root: E) -> [E] {
        var parents: [E] = [root]

        for step in selector.steps {
            var nextMatches: [E] = []
            for parent in parents {
                let candidates = parent.descendants()
                nextMatches.append(contentsOf: candidates.filter { matches(step: step, element: $0) })
            }
            parents = nextMatches
            if parents.isEmpty { break }
        }

        return parents
    }

    /// Returns the first element matching `selector` in `root`'s subtree.
    public static func findFirst<E: AXElementProtocol>(selector: ParsedSelector, in root: E) -> E? {
        find(selector: selector, in: root).first
    }

    // MARK: - Element matching

    /// Returns `true` if `element` satisfies all constraints in `step`.
    public static func matches<E: AXElementProtocol>(step: SelectorStep, element: E) -> Bool {
        // Role check
        if let roleAlias = step.role {
            let expected = resolveRole(roleAlias)
            guard element.role == expected else { return false }
        }

        // Identifier check
        if let id = step.identifier {
            guard element.identifier == id else { return false }
        }

        // Attribute filters
        for filter in step.attributes {
            let actual = attributeValue(key: filter.key, element: element)
            switch filter.op {
            case .equals:
                guard actual == filter.value else { return false }
            case .contains:
                guard let a = actual, a.localizedCaseInsensitiveContains(filter.value) else { return false }
            }
        }

        return true
    }

    // MARK: - Attribute key resolution

    /// Maps a user-facing attribute key to the element property value.
    private static func attributeValue<E: AXElementProtocol>(key: String, element: E) -> String? {
        switch key.lowercased() {
        case "title":       return element.title
        case "label", "description": return element.label
        case "identifier":  return element.identifier
        case "value":       return element.stringValue
        case "role":        return element.role
        default:            return nil
        }
    }
}
