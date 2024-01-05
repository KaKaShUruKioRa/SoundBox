SB__version_DBGroups = "2.2.2"

DBGroups = {};

DBGroups['Dialogue'] = {
	'Saluer', 'Acquiescer', 'Refuser', 'Interjecter', 'Questionner', 'Demander', 'Repondre', 'S\'excuser', 'Feliciter',
	'S\'exclafer', 'Rire', 'Se Moquer', 'Se Plaindre', 'Hurler', 'Silencier', 'Insulter', 'Quitter'
	};
DBGroups['Combat'] = { 'Manger', 'Strat', 'Pull', 'Aggro', 'Mort', 'Down', 'Wype', 'Loot', 'Rez' };
DBGroups['Par Theme'] = { 
	'Attente', 'Degueux',  'Tristesse', 
	'Internet', 'Bruitages', 'Jingles',
	'Antoine Daniel', 'Joueur du Grenier', 'Pere Fouras', 
};
DBGroups['Par Langue'] = { 'En Francais', 'En Anglais', 'En Allemand', 'En Russe', 
'En Japonais' }
DBGroups['Par Genre'] = { 'Homme', 'Femme', 'Autres' };
DBGroups['Par Culture'] = {'Films', 'Series', 'TVs', 'Comedies', 'Dessins Animees', 'Animes', 'Jeux', 'Musiques', 'Politique', 'Meme' };
DBGroups['Par License'] = {
	'Age of Mythology', 'Among Us', 'Counter Strike', 'Dark Souls', 'Diablo', 'Final Fantasy', 'The Legend of Zelda', --[['Nier',]] 'TES : Skyrim', 'GTA', "Super Mario", 'Vampire Survivor', 'Warcraft 3', 'World of Warcraft', 
	'Ken', 'Jojo\'s', 
	'Kaamelott', 'Les Kassos','Palmashow', 
	'Dexter', 
	'Star Wars'};
DBGroups['Par Duree'] = {'Tres Court', 'Court', 'Moyen', 'Long', 'Tres Long' };
DBGroups['Fav Membres'] = {
	'Amecareth', 'Balko', 'Musha', 'Corypheo', 'Hixday', 'Arzatoth', 'Chichi', 'Jaizu', 'Gramark', 'KaKaShUruKioRa'
};

if (date("%A") == "Monday") then
	DBGroups['OLD'] = { 'BONJOUR', 'AU REVOIR', 'LOL', 'LAVA', 'NOT LAVA', 'Modem', 'Non Trier', 'Lundi' }
elseif (date("%A") == "Wednesday") then
	DBGroups['OLD'] = { 'BONJOUR', 'AU REVOIR', 'LOL', 'LAVA', 'NOT LAVA', 'Modem', 'Non Trier', 'Mercredi' }
end
