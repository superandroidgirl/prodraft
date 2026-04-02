import 'package:flutter/material.dart';

/// Represents the team side a 3D player model belongs to.
enum TeamSide { ally, enemy }

/// Grade of a player used for triggering special skills.
enum PlayerGrade { sClass, aClass, bClass }

/// Defines a single GLB model to be loaded in the battle scene.
class GlbModel {
  /// A unique identifier for this player/model slot.
  final String id;

  /// Human-readable name (e.g., "LeBron James").
  final String name;

  /// Remote or local asset URL for the .glb model file.
  /// TODO: Replace with real low-poly basketball player model URLs.
  /// Example: 'assets/models/lakers_player.glb' or
  ///          'https://your-cdn.com/models/nets_player.glb'
  final String srcUrl;

  /// Which team this model belongs to.
  final TeamSide team;

  /// The player's grade — used for skill-trigger logic.
  final PlayerGrade grade;

  /// Power rating fed into the battle simulation.
  final int power;

  /// Player's jersey number (e.g., "23").
  final String jerseyNumber;

  const GlbModel({
    required this.id,
    required this.name,
    required this.srcUrl,
    required this.team,
    required this.grade,
    required this.power,
    required this.jerseyNumber,
  });
}

/// ─── GlbModelLoader ───────────────────────────────────────────────────────────
/// Manages up to 11 concurrent GLB asset references:
///   • 5 ally players
///   • 5 enemy players
///   • 1 basketball
///
/// Usage:
///   final loader = GlbModelLoader(allyModels: [...], enemyModels: [...]);
///   loader.onModelReady = (model) { /* update UI */ };
///   loader.load();
/// ─────────────────────────────────────────────────────────────────────────────
class GlbModelLoader {
  /// The 5 ally player model definitions.
  final List<GlbModel> allyModels;

  /// The 5 enemy player model definitions.
  final List<GlbModel> enemyModels;

  /// The basketball model definition.
  /// TODO: Load 'assets/models/basketball.glb'
  final GlbModel? basketballModel;

  /// Called once for each model as soon as its URL is resolved / ready.
  void Function(GlbModel model)? onModelReady;

  /// Called when ALL models are confirmed ready to render.
  void Function()? onAllModelsReady;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  GlbModelLoader({
    required this.allyModels,
    required this.enemyModels,
    this.basketballModel,
    this.onModelReady,
    this.onAllModelsReady,
  }) : assert(allyModels.length == 5, 'Exactly 5 ally models required'),
       assert(enemyModels.length == 5, 'Exactly 5 enemy models required');

  /// Begins the (simulated) load sequence for all 11 models.
  /// Replace the Future.delayed bodies with real asset/network loading.
  Future<void> load() async {
    final all = [...allyModels, ...enemyModels, if (basketballModel != null) basketballModel!];
    final futures = all.map((model) async {
      // TODO: Replace with actual GLB pre-fetching / caching if needed.
      await Future.delayed(const Duration(milliseconds: 100));
      onModelReady?.call(model);
    });
    await Future.wait(futures);
    _loaded = true;
    onAllModelsReady?.call();
  }

  /// Neon green for ally ring; lava red for enemy ring.
  static Color ringColor(TeamSide side) =>
      side == TeamSide.ally ? const Color(0xFF00FF88) : const Color(0xFFFF3B30);
}

// ─── Preset model lists (placeholders — swap URLs for real assets) ────────────

/// TODO: Replace srcUrl with real low-poly Laker / ally player .glb paths.
final defaultAllyModels = [
  const GlbModel(id: 'ally_1', name: 'LeBron James',  srcUrl: 'TODO: lakers_player_01.glb', team: TeamSide.ally, grade: PlayerGrade.sClass, power: 98, jerseyNumber: '23'),
  const GlbModel(id: 'ally_2', name: 'Anthony Davis', srcUrl: 'TODO: lakers_player_02.glb', team: TeamSide.ally, grade: PlayerGrade.sClass, power: 96, jerseyNumber: '3'),
  const GlbModel(id: 'ally_3', name: 'D\'Angelo Russell', srcUrl: 'TODO: lakers_player_03.glb', team: TeamSide.ally, grade: PlayerGrade.aClass, power: 85, jerseyNumber: '0'),
  const GlbModel(id: 'ally_4', name: 'Austin Reaves', srcUrl: 'TODO: lakers_player_04.glb', team: TeamSide.ally, grade: PlayerGrade.aClass, power: 80, jerseyNumber: '15'),
  const GlbModel(id: 'ally_5', name: 'Rui Hachimura', srcUrl: 'TODO: lakers_player_05.glb', team: TeamSide.ally, grade: PlayerGrade.aClass, power: 78, jerseyNumber: '28'),
];

/// TODO: Replace srcUrl with real low-poly Nets / enemy player .glb paths.
final defaultEnemyModels = [
  const GlbModel(id: 'enemy_1', name: 'Kevin Durant',  srcUrl: 'TODO: nets_player_01.glb', team: TeamSide.enemy, grade: PlayerGrade.sClass, power: 97, jerseyNumber: '7'),
  const GlbModel(id: 'enemy_2', name: 'Kyrie Irving',  srcUrl: 'TODO: nets_player_02.glb', team: TeamSide.enemy, grade: PlayerGrade.sClass, power: 94, jerseyNumber: '11'),
  const GlbModel(id: 'enemy_3', name: 'Ben Simmons',   srcUrl: 'TODO: nets_player_03.glb', team: TeamSide.enemy, grade: PlayerGrade.aClass, power: 86, jerseyNumber: '10'),
  const GlbModel(id: 'enemy_4', name: 'Joe Harris',    srcUrl: 'TODO: nets_player_04.glb', team: TeamSide.enemy, grade: PlayerGrade.aClass, power: 79, jerseyNumber: '12'),
  const GlbModel(id: 'enemy_5', name: 'Nic Claxton',   srcUrl: 'TODO: nets_player_05.glb', team: TeamSide.enemy, grade: PlayerGrade.aClass, power: 76, jerseyNumber: '33'),
];
