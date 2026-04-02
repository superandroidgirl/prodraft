// Enums for the new strategic match engine.

/// PG / SG / SF / PF / C
enum PlayerPosition { pg, sg, sf, pf, c }

/// R / SR / SSR / UR
enum PlayerRarity { r, sr, ssr, ur }

/// Offensive Tactics
enum OffensiveTactic {
  iso,            // Isolation
  pickAndRoll,    // P&R
  catchAndShoot,  // C&S
  postUp,         // Low post
  fastBreak,      // Fast break
  balanced,       // Normal
}

/// Defensive Strategies
enum DefensiveTactic {
  manToMan,       // 1-on-1
  zone,           // 2-3 Zone
  switchDef,      // Switching
  doubleTeam,     // Trap
  protectPaint,   // Shrink
  tightPerimeter, // Press
}

/// Possession Outcomes
enum MatchOutcome {
  made2,
  made3,
  missed2,
  missed3,
  andOne,
  block,
  steal,
  turnover,
  offRebound,
  defRebound,
  foulDrawn,
}

/// Player Match Status
enum PlayerStatus {
  normal,
  hot,
  cold,
  clutch,
}

/// Animation Types for Match Engine
enum AnimationType {
  isoDrive,
  crossoverPullup,
  catchShoot3,
  postSpinFinish,
  pickRollLob,
  chasedownBlock,
  stealAndRun,
  putbackScore,
  contestMidrange,
  idle,
}
