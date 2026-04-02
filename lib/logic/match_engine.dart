import 'dart:math';
import '../models/match_player.dart';
import '../models/match_state.dart';
import '../models/match_enums.dart';

class MatchEngine {
  static final _rng = Random();

  static PossessionResult simulatePossession(
    MatchTeam offense,
    MatchTeam defense,
    OffensiveTactic oTactic,
    DefensiveTactic dTactic,
    MatchState state,
  ) {
    // 1. Pick a main offensive player (weighted by position and tactic)
    // For ISO, pick the SF/SG. For P&R, pick PG.
    MatchPlayer primary = _pickPrimaryOffense(offense, oTactic);
    MatchPlayer defender = _pickDefender(defense, primary.position);

    // 2. Calculate Base Chance
    double offPower = primary.getEffectiveStat('offense');
    double defPower = defender.getEffectiveStat('defense');
    
    // Tactic Modifiers
    double tacticMod = _getTacticModifier(oTactic, dTactic);
    
    // Skill Modifiers
    double skillMod = _getSkillBonus(primary);
    
    // Stamina Decay (Already in getEffectiveStat, but can add extra impact)
    
    // 3. Final Success Rate
    // Result = Offense + TacticMod + SkillMod - Defense - DefenseTacticMod
    double scoreChance = (offPower * 0.5 + 40 + tacticMod + skillMod) - (defPower * 0.4);
    scoreChance = scoreChance.clamp(15, 85); // Reasonable limits

    // 4. Decide outcome
    double roll = _rng.nextDouble() * 100;
    bool isMade = roll < scoreChance;
    
    MatchOutcome outcome;
    int points = 0;
    String commentary = "";
    AnimationType anim = AnimationType.idle;

    if (isMade) {
      bool is3 = _rng.nextDouble() < (primary.shooting3 / 200.0 + 0.1);
      outcome = is3 ? MatchOutcome.made3 : MatchOutcome.made2;
      points = is3 ? 3 : 2;
      commentary = "${primary.name} ${is3 ? '遠投三分命中！' : '精彩上籃得分！'}";
      anim = is3 ? AnimationType.catchShoot3 : AnimationType.isoDrive;
    } else {
      // Check for block or steal
      double dRoll = _rng.nextDouble() * 100;
      if (dRoll < 10) {
        outcome = MatchOutcome.block;
        commentary = "${defender.name} 賞了一個火鍋！";
        anim = AnimationType.chasedownBlock;
      } else if (dRoll < 20) {
        outcome = MatchOutcome.steal;
        commentary = "${defender.name} 抄截成功！";
        anim = AnimationType.stealAndRun;
      } else {
        outcome = MatchOutcome.defRebound; // Simplified: mostly defensive rebounds
        commentary = "${primary.name} 投籃不中。";
        anim = AnimationType.contestMidrange;
      }
    }

    // 5. Stamina Decay
    primary.stamina -= 1.5;
    defender.stamina -= 1.2;

    return PossessionResult(
      outcome: outcome,
      points: points,
      player: primary,
      commentary: commentary,
      animType: anim,
    );
  }

  static MatchPlayer _pickPrimaryOffense(MatchTeam team, OffensiveTactic tactic) {
    // Logic to select player based on tactic
    if (tactic == OffensiveTactic.iso) return team.starters[1]; // SG usually
    if (tactic == OffensiveTactic.postUp) return team.starters[4]; // C
    return team.starters[_rng.nextInt(5)];
  }

  static MatchPlayer _pickDefender(MatchTeam team, PlayerPosition pos) {
    // Matchup logic (PG vs PG, etc.)
    return team.starters[pos.index];
  }

  static double _getTacticModifier(OffensiveTactic o, DefensiveTactic d) {
    // Simplified logic: Zone beats PostUp, TightPerimeter beats CatchAndShoot
    if (o == OffensiveTactic.catchAndShoot && d == DefensiveTactic.tightPerimeter) return -10.0;
    if (o == OffensiveTactic.postUp && d == DefensiveTactic.protectPaint) return -8.0;
    return 0.0;
  }

  static double _getSkillBonus(MatchPlayer p) {
    return p.skills.length * 2.5; // Dummy logic
  }
}
