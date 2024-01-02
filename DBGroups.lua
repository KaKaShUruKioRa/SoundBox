SB__version_DBGroups = "2.2.1"

DBGroups = {};

DBGroups['Dialogue'] = { 'Saluer', 'Acquiescer', 'Refuser', 'Interjecter', 'Questionner', 'Demander', 'Repondre', 'Excuser', 'Insulter',
	'Silencier', 'Rire', 'Hurler', 'Se Plaindre', 'Quitter' };
DBGroups['Combat'] = { 'MANGER', 'STRAT', 'PULL', 'COUNTDOWN', 'AGGRO', 'DEATH', 'WYPE', 
'DOWN', 'Loot', 'REZ' };
DBGroups['Par Theme'] = { 'Antoine Daniel', 'Joueur du Grenier', 'Attente', 'Tristesse', 
'Degueux', 'Pere Fouras',  'Internet' };
DBGroups['Par Langue'] = { 'En Francais', 'En Anglais', 'En Allemand', 'En Russe', 
'En Japonais' }
DBGroups['Par Genre'] = { 'Homme', 'Femme', 'Autre' };
DBGroups['Par Culture'] = { 'Film', 'Serie', 'Anime', 'Jeux', 'Musique', 'Politique', 
'Meme' };
DBGroups['Par License'] = { 'Age of Mythology', 'Among Us', 'Dark Souls', 
'The Legend of Zelda', 'Nier', 'Warcraft 3', "World of Warcraft", "TES : Skyrim", "GTA",
 "Super Mario", 'Vampire Survivor', 'Kaamelott', 'Camera Cafe', 'Les Kassos', 'Dexter', 
 'Star Wars'};
DBGroups['Par Duree'] = { 'Tres Court', 'Court', 'Moyen', 'Long', 'Tres Long' };
DBGroups['Fav Membres'] = {'Amecareth', 'Balko', 'Musha', 'Corypheo', 'Hixday', 'Arzatoth', 'Chichi', 'Jaizu', 'Gramark', 'KaKaSh'}

if (date("%A") == "Monday") then
	DBGroups['OLD'] = { 'BONJOUR', 'AU REVOIR', 'LOL', 'LAVA', 'NOT LAVA', 'Modem', 'Non Trier', 'Lundi' }
elseif (date("%A") == "Wednesday") then
	DBGroups['OLD'] = { 'BONJOUR', 'AU REVOIR', 'LOL', 'LAVA', 'NOT LAVA', 'Modem', 'Non Trier', 'Mercredi' }
end
