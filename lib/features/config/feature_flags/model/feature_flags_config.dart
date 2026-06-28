/// Mirrors config/featureFlags in Firestore.
class FeatureFlagsConfig {
  /// flagKey → bool
  final Map<String, bool> flags;

  const FeatureFlagsConfig({required this.flags});

  /// Known flags with friendly metadata. Other keys in Firestore will
  /// still appear in the editor with their raw key as the label.
  static const knownFlags = <FlagDef>[
    FlagDef(
      key: 'aiAssistantEnabled',
      label: 'AI Assistant',
      description: 'Cursor-style command bar in editor (Ctrl/Cmd + J).',
    ),
    FlagDef(
      key: 'aiComposeEnabled',
      label: 'AI Compose',
      description: 'Per-section AI generation from Career Profile.',
    ),
    FlagDef(
      key: 'aiRefineEnabled',
      label: 'AI Refine',
      description: 'Rewrite-section presets and custom instructions.',
    ),
    FlagDef(
      key: 'aiProofreadEnabled',
      label: 'AI Proofread',
      description: 'Spellcheck via Haiku (free for all users).',
    ),
    FlagDef(
      key: 'linkedinGeneratorEnabled',
      label: 'LinkedIn Generator',
      description: 'The /linkedin page for generating profile content.',
    ),
    FlagDef(
      key: 'trialEnabled',
      label: 'Trial Activation',
      description: 'Allow new users to start the 7-day free trial.',
    ),
    FlagDef(
      key: 'signupEnabled',
      label: 'New Signups',
      description: 'Allow new account creation. Disable for emergencies.',
    ),
  ];

  factory FeatureFlagsConfig.fromMap(Map<String, dynamic> map) {
    final flags = <String, bool>{};
    for (final entry in map.entries) {
      if (entry.key == 'updatedAt' || entry.key == 'updatedBy') continue;
      if (entry.value is bool) flags[entry.key] = entry.value as bool;
    }
    // Ensure every known flag exists with a default of true
    for (final f in knownFlags) {
      flags.putIfAbsent(f.key, () => true);
    }
    return FeatureFlagsConfig(flags: flags);
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(flags);

  FeatureFlagsConfig copyWith({Map<String, bool>? flags}) {
    return FeatureFlagsConfig(
      flags: flags ?? Map<String, bool>.from(this.flags),
    );
  }

  int diffCountTo(FeatureFlagsConfig other) {
    final keys = {...flags.keys, ...other.flags.keys};
    var n = 0;
    for (final k in keys) {
      if (flags[k] != other.flags[k]) n++;
    }
    return n;
  }
}

class FlagDef {
  final String key;
  final String label;
  final String description;
  const FlagDef({
    required this.key,
    required this.label,
    required this.description,
  });
}