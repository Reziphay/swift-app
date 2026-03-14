import Foundation

// AuthFlowState is intentionally minimal.
// Each auth screen manages its own @State locally to keep things simple and decoupled.
// This file exists as the designated location for any future shared auth flow state.
//
// If you need to share state across multiple auth screens (e.g., a multi-step registration
// wizard), add an @Observable class here and inject it via .environment().
