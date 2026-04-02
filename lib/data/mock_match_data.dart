import '../models/match_player.dart';
import '../models/match_enums.dart';
import '../models/match_state.dart';

final mockSkills = [
  const MatchSkill(id: 's1', name: 'Catch & Shoot', description: 'Improved 3PT after a pass', rarity: PlayerRarity.ssr, affectedStats: {'shooting3': 10.0}),
  const MatchSkill(id: 's2', name: 'Posterizer', description: 'Power dunk over defenders', rarity: PlayerRarity.ssr, affectedStats: {'offense': 15.0}, visualEffect: 'fire'),
  const MatchSkill(id: 's3', name: 'Rim Protector', description: 'Increase block chance', rarity: PlayerRarity.sr, affectedStats: {'defense': 12.0}),
];

final allyTeam = MatchTeam(
  id: 'ally_team',
  name: 'Lakers Elite',
  starters: [
    MatchPlayer(id: 'a1', name: 'LeBron James', position: PlayerPosition.sf, rarity: PlayerRarity.ur, overall: 98, offense: 97, defense: 92, shooting2: 95, shooting3: 88, passing: 96, dribbling: 94, rebounding: 90, speed: 85, strength: 95, iq: 99, jerseyNumber: 23, skills: [mockSkills[1], mockSkills[0]]),
    MatchPlayer(id: 'a2', name: 'Anthony Davis', position: PlayerPosition.pf, rarity: PlayerRarity.ur, overall: 96, offense: 94, defense: 98, shooting2: 92, shooting3: 75, passing: 80, dribbling: 82, rebounding: 98, speed: 78, strength: 96, iq: 92, jerseyNumber: 3, skills: [mockSkills[2]]),
    MatchPlayer(id: 'a3', name: 'Austin Reaves', position: PlayerPosition.sg, rarity: PlayerRarity.sr, overall: 84, offense: 86, defense: 78, shooting2: 85, shooting3: 88, passing: 84, dribbling: 85, rebounding: 70, speed: 82, strength: 75, iq: 88, jerseyNumber: 15, skills: []),
    MatchPlayer(id: 'a4', name: 'D\'Angelo Russell', position: PlayerPosition.pg, rarity: PlayerRarity.ssr, overall: 87, offense: 88, defense: 75, shooting2: 86, shooting3: 92, passing: 92, dribbling: 90, rebounding: 65, speed: 85, strength: 72, iq: 85, jerseyNumber: 1, skills: [mockSkills[0]]),
    MatchPlayer(id: 'a5', name: 'Rui Hachimura', position: PlayerPosition.c, rarity: PlayerRarity.sr, overall: 82, offense: 84, defense: 80, shooting2: 88, shooting3: 82, passing: 75, dribbling: 78, rebounding: 85, speed: 75, strength: 88, iq: 82, jerseyNumber: 28, skills: []),
  ],
);

final enemyTeam = MatchTeam(
  id: 'enemy_team',
  name: 'Nets Dynasty',
  starters: [
    MatchPlayer(id: 'e1', name: 'Kevin Durant', position: PlayerPosition.sf, rarity: PlayerRarity.ur, overall: 98, offense: 99, defense: 90, shooting2: 98, shooting3: 94, passing: 88, dribbling: 92, rebounding: 85, speed: 85, strength: 88, iq: 96, jerseyNumber: 7, skills: [mockSkills[0]]),
    MatchPlayer(id: 'e2', name: 'Kyrie Irving', position: PlayerPosition.pg, rarity: PlayerRarity.ur, overall: 94, offense: 98, defense: 80, shooting2: 96, shooting3: 92, passing: 95, dribbling: 99, rebounding: 60, speed: 92, strength: 72, iq: 94, jerseyNumber: 11, skills: []),
    MatchPlayer(id: 'e3', name: 'Ben Simmons', position: PlayerPosition.pf, rarity: PlayerRarity.ssr, overall: 86, offense: 75, defense: 95, shooting2: 70, shooting3: 50, passing: 90, dribbling: 88, rebounding: 90, speed: 88, strength: 92, iq: 90, jerseyNumber: 10, skills: []),
    MatchPlayer(id: 'e4', name: 'Mikal Bridges', position: PlayerPosition.sf, rarity: PlayerRarity.ssr, overall: 88, offense: 86, defense: 92, shooting2: 88, shooting3: 90, passing: 82, dribbling: 84, rebounding: 75, speed: 86, strength: 82, iq: 88, jerseyNumber: 1, skills: []),
    MatchPlayer(id: 'e5', name: 'Nic Claxton', position: PlayerPosition.c, rarity: PlayerRarity.sr, overall: 82, offense: 78, defense: 88, shooting2: 80, shooting3: 50, passing: 70, dribbling: 72, rebounding: 92, speed: 80, strength: 88, iq: 84, jerseyNumber: 33, skills: [mockSkills[2]]),
  ],
);
