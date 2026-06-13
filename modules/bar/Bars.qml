pragma ComponentBehavior: Bound

import Quickshell
import "../../services"

// Instantiate one Bar per screen
Scope {
    Variants {
        model: Screens.screens

        Bar {
            required property ShellScreen modelData
            screen: modelData
        }
    }
}
