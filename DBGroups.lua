SB__version_DBGroups = "2.2.0"
DBGroups = {};

DBGroups['COMBAT'] = {'MANGER', 'STRAT', 'PULL', 'COUNTDOWN', 'AGGRO', 'DEATH', 'WYPE', 'DOWN', 'LOOT', 'REZ'}
DBGroups['GAMES'] = {'LAVA', 'NOT LAVA'}
DBGroups['SOCIAL'] = {'NON', 'SAD', 'SILENCE', 'ATTENTE', 'BONJOUR', 'BONJOUR AD', 'AU REVOIR', 'DECO'}
DBGroups['MISC.'] = {'MUSIC', 'LOL', 'NEW'}

if (date("%A") == "Wednesday") then
	DBGroups['MISC.'] = {'MUSIC', 'LOL', 'NEW', 'WEDNESDAY'}
end