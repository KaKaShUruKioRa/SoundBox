
local SB__pathToSound = "Interface\\AddOns\\SoundBox\\Sounds\\"
local SB__listLastPlayedByCat = {}; -- TODO
local SB__soundPlaying = false
SB__soundEnabled = 1
SB__longSoundEnabled = 1
SB__longSoundLimit = 10
local SB__version = "2.2.0"
local SB__uiMainFrameDisplayed = 0
SB__prefix = "SoundBox"

SB__uiMainFrame = nil
SB__uiCatFrame = nil
SB__uiTooltip = nil
SB__uiFavorites = nil

local SB__uiNbButtonsPerRow = 5
SB__uiButtonSoundWidth = 113;
SB__uiButtonDetailsWidth = 31;
SB__uiButtonHeight = 21;
SB__uiMarginButton = 15;
SB__uiMarginTitle = 10;
SB__uiHeaderHeight = 30;
SB__uiFavoritesHeight = 50;
SB__uiTooltipHeight = 30;
SB__uiComputedWidth = SB__uiMarginButton + SB__uiNbButtonsPerRow * (SB__uiButtonSoundWidth + SB__uiButtonDetailsWidth + SB__uiMarginButton);


local SB__waitTable = {};
local SB__waitFrame = nil;
local function SB__wait(delay, func, ...)
	if(type(delay)~="number" or type(func)~="function") then
		return false;
	end
	if(SB__waitFrame == nil) then
		SB__waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
		SB__waitFrame:SetScript("onUpdate",function (self,elapse)
			local count = #SB__waitTable;
			local i = 1;
			while(i<=count) do
				local waitRecord = tremove(SB__waitTable,i);
				local d = tremove(waitRecord,1);
				local f = tremove(waitRecord,1);
				local p = tremove(waitRecord,1);
				if(d>elapse) then
					tinsert(SB__waitTable,i,{d-elapse,f,p});
					i = i + 1;
				else
					count = count - 1;
					f(unpack(p));
				end
			end
		end);
	end
	tinsert(SB__waitTable,{delay,func,{...}});
	return true;
end

-- output on chat (only visible by the player) using a specific color and the sender
local function SB__WriteText(channel, sender, msg, options)
	local senderLink = "|Hplayer:" .. sender .. "|h" .. sender .. "|h"
	local optionText = ""
	if (options ~= nil) then	
		optionText = " - " .. options
	end
	local color = "FFFF8800"
	if channel == "WHISPER" then
		color = "FFFF80FF"
	elseif channel == "GUILD" then
		color = "FF40FF40"
	elseif channel == "PARTY" then
		color = "FFAAAAFF"
	elseif channel == "RAID" then
		color = "FFFF8800"
	elseif channel == "ADMIN" then
		color = "FFFF4444"
	end
	print("|c".. color .. "[SB] [" .. senderLink .. optionText .. "]|r " .. msg);
end

-- hides the frame displayed
local function SB__UIHide()
	if (SB__uiCatFrame ~= nil) then
		SB__uiCatFrame:Hide();
		SB__uiCatFrame = nil;
	end
	SB__uiMainFrameDisplayed = 0;
	SB__uiMainFrame:Hide();	
end


-- Sends the command either to all users or only the player
-- received by SB__OnEvent and then processed by SB__DecodeCommand
local function SB__SendCommand(command, catName, isRandom)
	local fullCommand = command .. "|" .. catName .. ";" .. isRandom
	if (SB__soundTest == 1 or not IsInGuild()) then
		C_ChatInfo.SendAddonMessage(SB__prefix, fullCommand, "WHISPER", UnitName("player"));
	else
		channel = "GUILD"
		if (IsInRaid()) then
			channel = "RAID"
		end
		C_ChatInfo.SendAddonMessage(SB__prefix, fullCommand, channel)
	end
	
end

-- getting the tooltip displayed on the bottom part of the UI from the command
local function SB__GetTooltipFromCommand(command)	
	if (command == nil) then
		return "";
	end
	local wordsArg = {}
	for w in (command .. ";"):gmatch("([^;]*);") do 
		table.insert(wordsArg, w) 
	end
	return wordsArg[3]
end

-- generic function to sort a dictionary, used on the favorites (key = sound, value = nb of time played)
function SB__GetKeysSortedByValue(tbl, sortFunction)
	local keys = {}
	for key in pairs(tbl) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		return sortFunction(tbl[a], tbl[b])
	end)

	return keys
end

-- updates the favorites displayed on the top of the UI
local function SB__UIFavoriteUpdate(name)
	
	if (name ~= nil and name ~= "") then
		if (SB__soundStats[name] == nil) then
			SB__soundStats[name] = 0;
		end
		SB__soundStats[name] = SB__soundStats[name] + 1;
	end
	
	-- sort the keys by value
	local sortedKeys = SB__GetKeysSortedByValue(SB__soundStats, function(a, b) return a > b end)

	local index = 1
	for _, key in ipairs(sortedKeys) do -- can not iterate using an index on a dictionnary, so this for loop is obligatory
		if (index <= SB__uiNbButtonsPerRow) then
			SB__uiMainFrame.favorites.buttons[index]:SetText(key:gsub("sb_", ""))
			
			SB__uiMainFrame.favorites.buttons[index]:SetScript("OnEnter", function(par, button, down)
				SB__uiMainFrame.tooltip.title.text:SetText(SB__GetTooltipFromCommand(DBSounds[key]))
			end);
			SB__uiMainFrame.favorites.buttons[index]:SetScript("OnLeave", function(par, button, down)
				SB__uiMainFrame.tooltip.title.text:SetText("")
			end);
			SB__uiMainFrame.favorites.buttons[index]:SetScript("OnClick",
			function(self, parent, down)
				if (SB__soundTest == 0) then
					SB__UIHide();
				end
				SB__UIFavoriteUpdate(key);
				SB__SendCommand(key, "Favorites", 0);
			end)
		end
		index = index + 1
	end
end


local SB_updateAntiSpamDisplay
local function SB_releaseAntiSpam()
	SB__soundPlaying = false
	SB_updateAntiSpamDisplay()
end


local function SB__isAllowedToPlay(duration, channel)
	local isAllowed = not SB__soundPlaying
	if (SB__longSoundEnabled == 0 and duration > SB__longSoundLimit) then
		isAllowed = false
	end
	
	if (channel == "GUILD" and IsInRaid()) then
		isAllowed = false
	end
	
	if (channel == "RAID" and not IsInRaid()) then
		isAllowed = false
	end	
	return isAllowed
end


-- function that will play the sound if allowed to do so
local function SB__DoPlaySound(channel, sender, sound, text, duration, categoryName, isRandom)
	--local newSec = GetTime();
	local options = nil
	if isRandom == 1 then
		options = "R"	
	end
	if not SB__isAllowedToPlay(duration, channel) then
		text = "(M) " .. text
	else
		if (SB__soundEnabled == 1 and SB__isActivated == 1) then -- mute or activation check
			PlaySoundFile(SB__pathToSound .. sound, "Dialog")
			-- adding the fact that we played this sound for this category
			--if (channel ~= "WHISPER" and categoryName ~= "") then
			if (categoryName ~= "") then
				SB__listLastPlayedByCat[categoryName] = sound
			end
		else
			text = "(M) " .. text
		end		
		--SB__timeLastPlayed = newSec
		--SB__antiSpamLength = duration - SB__antiSpamLengthAllowed
		SB__soundPlaying = true;
		SB__wait(duration, SB_releaseAntiSpam);
		SB_updateAntiSpamDisplay()
	end
	SB__WriteText(channel, sender, text, options);
end

-- called when an admin send the "enable/disable" command. Modifying this function to bypass admin command will only play sound on your part, so don't bother.
local function SB__DoSetSoundEnabled(sender, arg)
	if (arg == "1") then
		SB__soundEnabled = 1;
		SB__WriteText("ADMIN", sender, "Sound Enabled", "A");
	else
		SB__soundEnabled = 0;
		SB__WriteText("ADMIN", sender, "Sound Disabled", "A");		
	end
	if (SB_ADMIN__isAvailable ~= nil) then
		SB_ADMIN_updateFooterButtons();
	end
end

-- called when an admin send the "enable/disable Long Sound" command. Modifying this function to bypass admin command will only play sound on your part, so don't bother.
local function SB__DoSetLongSoundEnabled(sender, arg)
	if (arg == "1") then
		SB__longSoundEnabled = 1;
		SB__WriteText("ADMIN", sender, "Long Sound Enabled", "A");
	else
		SB__longSoundEnabled = 0;
		SB__WriteText("ADMIN", sender, "Long Sound Disabled", "A");		
	end
	if (SB_ADMIN__isAvailable ~= nil) then
		SB_ADMIN_updateFooterButtons();
	end
end

-- called when an admin send the "send version" command. Send the version of the addon and the plugins to the sender
local function SB__DoSendVersion(sender)
	local text = "A: " .. SB__version .. " S: " .. SB__version_DBSounds .. " C: " .. SB__version_DBCategories .. " G: " .. SB__version_DBGroups
	if (SB__soundEnabled == 0) then
		text = "(M) " .. text
	end
	if (SB_ADMIN__isAvailable ~= nil) then
		text = text.. " ADMIN";
	end
	C_ChatInfo.SendAddonMessage(SB__prefix, "admin;receiveVersion;"..text, "WHISPER", sender);
end

-- called when you, the admin, have send a "send version" command and will display the returned value of the other players
local function SB__DoReceiveVersion(sender, text)
	SB__WriteText("ADMIN", sender, text, "A");
end

-- called when the dezoom admin function was called, to allow for better dezoom
local function SB__DoDezoom(sender)
	SetCVar("cameraDistanceMax", 25)
	SetCVar("cameraDistanceMaxFactor", 2)
	SB__WriteText("ADMIN", sender, "Enabling improved zoom", "A")
end

-- main function that will decode the command receive and call the correct function to execute it (either sound or admin)
local function SB__DecodeCommand(channel, sender, command)
	local wordsArg = {}
	for w in (command .. ";"):gmatch("([^;]*);") do 
		table.insert(wordsArg, w) 
	end
	local typeOfCommand = wordsArg[1]
	if (typeOfCommand == "sound") then
		local soundToPlay = wordsArg[2]
		local textToDisplay = wordsArg[3]
		local soundDuration = tonumber(wordsArg[4])
		local categoryName = wordsArg[5]
		local isRandom = tonumber(wordsArg[6])
		if (soundToPlay ~= nil and textToDisplay ~= nil and soundDuration ~= nil) then
			SB__DoPlaySound(channel, sender, soundToPlay, textToDisplay, soundDuration, categoryName, isRandom)
		end
	elseif (typeOfCommand == "admin") then
		local order = wordsArg[2]
		if (order == "enableSound") then
			SB__DoSetSoundEnabled(sender, wordsArg[3])
		elseif (order == "enableLongSound") then
			SB__DoSetLongSoundEnabled(sender, wordsArg[3])
		elseif (order == "sendVersion") then
			SB__DoSendVersion(sender)
		elseif (order == "receiveVersion") then
			SB__DoReceiveVersion(sender, wordsArg[3])
		elseif (order == "dezoom") then
			SB__DoDezoom(sender)
		end
	end
end

-- ==================== UI ====================== --


-- backdrop used for the window, a regular dark square
SB__uiBackdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
	tile = false,
	tileSize = 0,
	edgeSize = 1
};

-- this function hide all the frames then show the main one
local function SB__UIShow()
	if (SB__uiCatFrame ~= nil) then
		SB__uiCatFrame:Hide();
		SB__uiCatFrame = nil;
	end
	SB__uiMainFrameDisplayed = 1;
	SB__uiMainFrame:Show();
end

-- activate or deactivate button was clicked, so activate all the frames, then if needed hide them. not very pretty but it's about the same thing as if else
local function SB__UIRefreshActivate()
	local activateText = "DEACTIVATE";
	SB__uiMainFrame.content:Show();
	SB__uiMainFrame.favorites:Show();
	SB__uiMainFrame.tooltip:Show();
	SB__uiMainFrame.header.btnTest:Show();
	if (SB__uiCatFrame ~= nil) then
		SB__uiCatFrame.content:Show();
		SB__uiCatFrame.header.btnTest:Show();
		SB__uiCatFrame.tooltip:Show();
	end
	if (SB__isActivated == 0) then
		activateText = "ACTIVATE"
		SB__uiMainFrame.content:Hide();
		SB__uiMainFrame.favorites:Hide();
		SB__uiMainFrame.tooltip:Hide();
		SB__uiMainFrame.header.btnTest:Hide();
		if (SB__uiCatFrame ~= nil) then
			SB__uiCatFrame.content:Hide();
			SB__uiCatFrame.header.btnTest:Hide();
			SB__uiCatFrame.tooltip:Hide();
		end
	end
	SB__uiMainFrame.header.btnActivate:SetText(activateText)
	if (SB__uiCatFrame ~= nil) then
		SB__uiCatFrame.header.btnActivate:SetText(activateText)
	end
end

-- SB__isActivated is either 1 or 0, so 1 - value toggle it
local function SB__UIToggleActivate()
	SB__isActivated = 1 - SB__isActivated;
	SB__UIRefreshActivate()
end

-- Modify the tooltip displayed with the new text
local function SB__UIUpdateTooltip(title, text)
	title.text:SetText(text)
end

-- Generic function to create a button on any UI. Adds an event for the tooltip if a frame is specified
local function SB__UICreateButton(parent, name, posX, posY, tooltipFrame, tooltip)
	local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")	
	
	button:SetPoint("TOPLEFT", parent, "TOPLEFT", posX , posY)
	button:SetWidth(SB__uiButtonSoundWidth)
	button:SetHeight(SB__uiButtonHeight)
	button:SetText(name:gsub("sb_", ""))
	
	if (tooltipFrame ~= nil) then	
		button:SetScript("OnEnter", function(par, button, down)
			SB__UIUpdateTooltip(tooltipFrame.title, tooltip);
		end);
		button:SetScript("OnLeave", function(par, button, down)
			SB__UIUpdateTooltip(tooltipFrame.title, "");	
		end);
	end
	
	return button
end


local function SB__playSpecificSound(name, catName)
	if (SB__soundTest == 0) then
		SB__UIHide();
	end
	SB__UIFavoriteUpdate(name);
	SB__SendCommand(name, catName, 0);
end


local function SB__playRandomSoundFromCat(catName)
	if (SB__soundTest == 0) then
		SB__UIHide();
	end
	local randSound;
	if ((catName == "MUSIC" and date("%A") == "Wednesday") or catName == "WEDNESDAY") then -- Easter egg, if the date is wednesday, any random "MUSIC" sound is a Wednesday sound
		randSound = DBWednesday["WED"][math.random(#DBWednesday["WED"])]
	else			
		randSound = DBCategories[catName][math.random(#DBCategories[catName])]
		-- if the categories has only one sound, add it to the stats
		if (#DBCategories[catName] == 1) then
			SB__UIFavoriteUpdate(randSound)
		elseif(#DBCategories[catName] > 1) then
			if (SB__listLastPlayedByCat[catName] ~= nil and SB__listLastPlayedByCat[catName] == (randSound .. ".ogg")) then
				SB__playRandomSoundFromCat(catName)
				return
			end
		end
	end
	SB__SendCommand(randSound, catName, 1);
end

-- Generic function to add the clicked event to display the category frame to any button
local function SB__UIAddCategoryClicked(parent, name)
	parent:SetScript("OnClick",
	function(self, parent, down)
		SB__playRandomSoundFromCat(name)
	end)	  
end


-- Generic function to add the play sound event on any button
local function SB__UIAddSoundClicked(parent, name, catName)
	parent:SetScript("OnClick",
	function(self, parent, down)
		SB__playSpecificSound(name, catName)
	end)	
end


function SB_updateAntiSpamDisplay()
	local text = ""
	local backdropColor = 0.1
	local backdropColorFavorites = 0.3
	local backdropDefault = 0.1
	local backdropDefaultFavorites = 0.3
	
	if SB__soundPlaying then
		text = "Son en cours"
		backdropColor = 0.5
		backdropColorFavorites = 0.5
		backdropDefaultFavorites = 0.1
	end
	SB__uiMainFrame.header.soundStatusLabel.text:SetText(text)
	if (SB__uiMainFrame.favorites ~= nil) then
		SB__uiMainFrame.favorites:SetBackdropColor(backdropColorFavorites, backdropDefaultFavorites, backdropDefaultFavorites, 0.8);
	end
	if (SB__uiMainFrame.content ~= nil) then
		SB__uiMainFrame.content:SetBackdropColor(backdropColor, backdropDefault, backdropDefault, 0.8)
	end
	if (SB__uiCatFrame ~= nil) then
		SB__uiCatFrame.header.soundStatusLabel.text:SetText(text)
		if (SB__uiCatFrame.content ~= nil) then
			SB__uiCatFrame.content:SetBackdropColor(backdropColor, backdropDefault, backdropDefault, 0.8)
		end
	end
end

-- creating the header of the frame
local function SB__UIAddHeader(parent)
	parent.header = CreateFrame("Frame", "header", parent, "BackdropTemplate")
	parent.header:SetPoint("TOPLEFT", 0, 0)
	parent.header:SetBackdrop(SB__uiBackdrop);
	parent.header:SetBackdropColor(0, 0, 0, 0.8);
	parent.header:SetBackdropBorderColor(0, 0, 0, 0.8);	
	parent.header:SetSize(SB__uiComputedWidth, SB__uiHeaderHeight);
	
	
	-- sound currently playing	
	parent.header.soundStatusLabel = CreateFrame("Frame", "header.soundPlayer", parent.header)
	parent.header.soundStatusLabel:SetSize(SB__uiComputedWidth,30)
	parent.header.soundStatusLabel:SetPoint("TOPLEFT", 3*SB__uiMarginTitle + SB__uiButtonSoundWidth, -7)		
	parent.header.soundStatusLabel:SetWidth(1) 
	parent.header.soundStatusLabel:SetHeight(1) 
	parent.header.soundStatusLabel:SetAlpha(.90);
	parent.header.soundStatusLabel.text = parent.header.soundStatusLabel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	parent.header.soundStatusLabel.text:SetPoint("TOPLEFT",0,0)
	SB_updateAntiSpamDisplay()
	
	
	-- back button
	parent.header.btnBack = CreateFrame("Button", nil, parent.header, "UIPanelButtonTemplate")
	parent.header.btnBack:SetPoint("BOTTOMLEFT", parent.header, "TOP", -SB__uiButtonHeight - 3,-SB__uiButtonHeight - 3)
	parent.header.btnBack:SetWidth(SB__uiButtonHeight + 20)
	parent.header.btnBack:SetHeight(SB__uiButtonHeight)

	parent.header.btnBack:SetText("Back")

	parent.header.btnBack:SetScript("OnClick",
		function(self, btnBack, down)
			if (SB__uiCatFrame ~= nil) then
				SB__uiCatFrame:Hide();
				SB__uiCatFrame = nil;
			end
			if (SB__uiMainFrameDisplayed == 1) then
			end
			SB__uiMainFrameDisplayed = 0;
			SB__uiMainFrame:Show();
		end)

	-- closing button
	parent.header.btnClose = CreateFrame("Button", nil, parent.header, "UIPanelButtonTemplate")
	parent.header.btnClose:SetPoint("BOTTOMLEFT", parent.header, "TOPRIGHT", -SB__uiButtonHeight - 3,-SB__uiButtonHeight - 3)
	parent.header.btnClose:SetWidth(SB__uiButtonHeight)
	parent.header.btnClose:SetHeight(SB__uiButtonHeight)

	parent.header.btnClose:SetText("X")

	parent.header.btnClose:SetScript("OnClick",
		function(self, btnClose, down)
		  SB__UIHide();
		end)
	  	  
	-- activate/deactivate button  
	parent.header.btnActivate = CreateFrame("Button", nil, parent.header, "UIPanelButtonTemplate")
	parent.header.btnActivate:SetPoint("TOPLEFT", parent.header, "TOPLEFT", SB__uiMarginButton, -3)
	parent.header.btnActivate:SetWidth(SB__uiButtonSoundWidth)
	parent.header.btnActivate:SetHeight(SB__uiButtonHeight)

	local activateText = "DEACTIVATE";
	if (SB__isActivated == 0) then
		activateText = "ACTIVATE"
	end
	parent.header.btnActivate:SetText(activateText)

	parent.header.btnActivate:SetScript("OnClick",
		function(self, btnActivate, down)
			SB__UIToggleActivate();			
	  end)
	  
	-- test button (only me/normal)  
	parent.header.btnTest =  CreateFrame("Button", nil, parent.header, "UIPanelButtonTemplate")
	parent.header.btnTest:SetPoint("TOPLEFT", parent.header, "TOPRIGHT", -SB__uiMarginButton - SB__uiButtonDetailsWidth - SB__uiButtonSoundWidth, -3)
	parent.header.btnTest:SetWidth(SB__uiButtonSoundWidth)
	parent.header.btnTest:SetHeight(SB__uiButtonHeight)
	
	local testText = "ONLY ME";
	if (SB__soundTest == 1) then
		testText = "NORMAL"
	end
	parent.header.btnTest:SetText(testText)

	parent.header.btnTest:SetScript("OnClick",
		function(self, buttonTest, down)
			SB__soundTest = 1 - SB__soundTest;
			local testText = "ONLY ME";
			if (SB__soundTest == 1) then
				testText = "NORMAL"
			end
			self:SetText(testText)
	  end)
	
end

-- creating the favorites buttons on top of the parent frame
local function SB__UIAddFavorites(parent)
	parent.favorites = CreateFrame("Frame", "favorites", parent, "BackdropTemplate")
	parent.favorites:SetPoint("TOPLEFT", 0, -SB__uiHeaderHeight+1)
	parent.favorites:SetBackdrop(SB__uiBackdrop);
	parent.favorites:SetBackdropColor(0.3, 0.3, 0.3, 0.8);
	parent.favorites:SetBackdropBorderColor(0, 0, 0, 0.8);	
	parent.favorites:SetSize(SB__uiComputedWidth, SB__uiFavoritesHeight);
	
	parent.favorites.content = CreateFrame("Frame", "favorites.content", parent.favorites, "BackdropTemplate")
	parent.favorites.content:SetPoint("TOPLEFT", 0, -20)
	parent.favorites.content:SetBackdrop(nil);
	parent.favorites.content:SetSize(SB__uiComputedWidth, SB__uiButtonHeight);
	
	local title = CreateFrame("Frame", "favorites.title", parent.favorites)
	title:SetSize(SB__uiComputedWidth,30)
	title:SetPoint("TOPLEFT", SB__uiMarginTitle, -5)		
	title:SetWidth(1) 
	title:SetHeight(1) 
	title:SetAlpha(.90);
	title.text = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title.text:SetPoint("TOPLEFT",0,0)
	title.text:SetText("FAVORITES")
	
	parent.favorites.buttons = {}
	-- adding the buttons, empty at first
	for index=1, SB__uiNbButtonsPerRow do
		parent.favorites.buttons[index] = SB__UICreateButton(parent.favorites.content, "(...)", SB__uiMarginButton + (index-1)*(SB__uiButtonSoundWidth + SB__uiButtonDetailsWidth + SB__uiMarginButton), 0, parent.tooltip, "")
	end	
	-- calling the function to update the content/events of the buttons
	SB__UIFavoriteUpdate("")
end

-- creating the tooltip area at the bottom of the parent frame
local function SB__UIAddTooltip(parent)
	parent.tooltip = CreateFrame("Frame", "tooltip", parent, "BackdropTemplate")
	parent.tooltip:SetPoint("BOTTOMLEFT", 0, 1)
	parent.tooltip:SetBackdrop(SB__uiBackdrop);
	parent.tooltip:SetBackdropColor(0.3, 0.3, 0.3, 0.8);
	parent.tooltip:SetBackdropBorderColor(0, 0, 0, 0.8);	
	parent.tooltip:SetSize(SB__uiComputedWidth, SB__uiTooltipHeight);
	
	parent.tooltip.title = CreateFrame("Frame", "tooltip", parent.tooltip)
	parent.tooltip.title:SetSize(SB__uiComputedWidth,SB__uiTooltipHeight)
	parent.tooltip.title:SetPoint("TOPLEFT", SB__uiMarginTitle, -10)		
	parent.tooltip.title:SetWidth(1) 
	parent.tooltip.title:SetHeight(1) 
	parent.tooltip.title:SetAlpha(.90);
	parent.tooltip.title.text = parent.tooltip.title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	parent.tooltip.title.text:SetPoint("TOPLEFT",0,0)
	parent.tooltip.title.text:SetText("")
	
end

-- if the admin plugin is available, calling the init function for the parent frame
local function SB__UIAddFooter(parent)
	if (SB_ADMIN__isAvailable ~= nil) then
		SB_ADMIN__AddFooter(parent);
	end
end

-- Creating the frame for the category display of all the sound buttons
local function SB__UIInitDisplayCategoryFrame(catName)
	table.sort(DBCategories[catName], function(a, b) return a:upper() < b:upper() end)
	local nbLines = math.ceil((#(DBCategories[catName])) / SB__uiNbButtonsPerRow);
	local SB__uiCatFrame = CreateFrame("Frame", "SB__uiCatFrame", UIParent, "BackdropTemplate")
	SB__uiCatFrame:SetPoint("CENTER")
	SB__uiCatFrame:SetFrameStrata("DIALOG");
	SB__uiCatFrame:SetBackdrop(nil);
	
	SB__UIAddHeader(SB__uiCatFrame); -- adding the header
	
	
	SB__uiCatFrame.content = CreateFrame("Frame", "content", SB__uiCatFrame, "BackdropTemplate")
	SB__uiCatFrame.content:SetPoint("TOPLEFT", 0, -SB__uiHeaderHeight+1)
	SB__uiCatFrame.content:SetBackdrop(SB__uiBackdrop);
	SB__uiCatFrame.content:SetBackdropColor(0.1, 0.1, 0.1, 0.8);
	SB__uiCatFrame.content:SetBackdropBorderColor(0, 0, 0, 0.8);	
	
	SB__UIAddTooltip(SB__uiCatFrame); -- adding the tooltip
	
	local nbButtons = 1
	local contentHeight = SB__uiMarginTitle;
	for k,v in pairs(DBCategories[catName]) do -- for each sound of the category, create the button using the generic function
		local xIndex = mod((nbButtons-1), SB__uiNbButtonsPerRow);
		local yIndex = math.ceil(nbButtons/SB__uiNbButtonsPerRow) - 1;
		local posX = SB__uiMarginButton + xIndex*(SB__uiButtonSoundWidth + SB__uiButtonDetailsWidth + SB__uiMarginButton)
		local posY = -(yIndex*SB__uiButtonHeight + contentHeight)
		local tooltip = SB__GetTooltipFromCommand(DBSounds[v]);
		local button = SB__UICreateButton(SB__uiCatFrame.content, v, posX, posY, SB__uiCatFrame.tooltip, tooltip);
		SB__UIAddSoundClicked(button, v, catName) -- adding the click event
		nbButtons = nbButtons + 1	
	end
	contentHeight = 2*SB__uiMarginTitle + nbLines * SB__uiButtonHeight; -- computing the size of the content
	SB__uiCatFrame.content:SetSize(SB__uiComputedWidth, contentHeight);	
	
	SB__UIAddFooter(SB__uiCatFrame); -- adding the footer (admin)
	
	local computedHeight = SB__uiHeaderHeight + contentHeight + SB__uiTooltipHeight;
	SB__uiCatFrame:SetSize(SB__uiComputedWidth, computedHeight);
	SB_updateAntiSpamDisplay()
end

-- Add the "..." button next to a category button from the main frame
local function SB__UIAddListButton(parent, name)
	if (DBCategories[name] ~= nil and #DBCategories[name]>1) then	-- only doing so if there is more than one sound on this category
		local buttonAll = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
		buttonAll:SetPoint("TOPLEFT", parent, "TOPLEFT", SB__uiButtonSoundWidth, 0)
		buttonAll:SetWidth(SB__uiButtonDetailsWidth)
		buttonAll:SetHeight(SB__uiButtonHeight)	
		buttonAll:SetText("...")
		buttonAll:SetScript("OnClick",
		  function(self, buttonAll, down)
			SB__UIHide();
			SB__UIInitDisplayCategoryFrame(name);
		  end)	
	end

end

-- creating the main frame of the addon
local function SB__UIInitDisplayMainFrame()
	SB__uiMainFrame = CreateFrame("Frame", "SB__uiMainFrame", UIParent, "BackdropTemplate")
	SB__uiMainFrame:SetPoint("CENTER")
	SB__uiMainFrame:SetFrameStrata("DIALOG");
	SB__uiMainFrame:SetBackdrop(nil);
	SB__uiMainFrame:Hide();
	
	SB__UIAddHeader(SB__uiMainFrame) -- adding the header
	SB__UIAddTooltip(SB__uiMainFrame) -- adding the tooltip section
	SB__UIAddFavorites(SB__uiMainFrame) -- adding the favorites buttons
	
	SB__uiMainFrame.content = CreateFrame("Frame", "content", SB__uiMainFrame, "BackdropTemplate")
	SB__uiMainFrame.content:SetPoint("TOPLEFT", 0, -SB__uiHeaderHeight - SB__uiFavoritesHeight +2)
	SB__uiMainFrame.content:SetBackdrop(SB__uiBackdrop);
	SB__uiMainFrame.content:SetBackdropColor(0.1, 0.1, 0.1, 0.8);
	SB__uiMainFrame.content:SetBackdropBorderColor(0, 0, 0, 0.8);
		
	  
	local contentHeight = 0;
	for keyG, valueG in pairs(DBGroups) do -- for each groups of categories
		local nbLines = math.ceil(#valueG/SB__uiNbButtonsPerRow);
		local title = CreateFrame("Frame", keyG, SB__uiMainFrame.content) -- display title
		title:SetSize(120,30)
		title:SetPoint("TOPLEFT", SB__uiMarginTitle, -(SB__uiMarginTitle+contentHeight))		
		title:SetWidth(1) 
		title:SetHeight(1) 
		title:SetAlpha(.90);
		title.text = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		title.text:SetPoint("TOPLEFT",0,0)
		title.text:SetText(keyG)		
		
		contentHeight = contentHeight + SB__uiMarginTitle
		local nbButtons = 1;
		for key, value in pairs(DBGroups[keyG]) do -- for each categories of this group
			local xIndex = mod((nbButtons-1), SB__uiNbButtonsPerRow);
			local yIndex = math.ceil(nbButtons/SB__uiNbButtonsPerRow) - 1;
			local posX = SB__uiMarginButton + xIndex*(SB__uiButtonSoundWidth + SB__uiButtonDetailsWidth + SB__uiMarginButton)
			local posY = -(SB__uiMarginButton + yIndex*SB__uiButtonHeight + contentHeight)
			local btn_grid = SB__UICreateButton(SB__uiMainFrame.content, value, posX, posY, SB__uiMainFrame.tooltip, "") -- create the button using the generic function
			SB__UIAddCategoryClicked(btn_grid, value); -- adding the click event
			SB__UIAddListButton(btn_grid, value); -- adding the "..." button
			nbButtons = nbButtons+1;
		end
		contentHeight = contentHeight + nbLines * SB__uiButtonHeight + 2*SB__uiMarginButton
	end		
	SB__uiMainFrame.content:SetSize(SB__uiComputedWidth, contentHeight);
	
	SB__UIAddFooter(SB__uiMainFrame)	-- adding the footer (admin)
	
	local computedHeight = SB__uiHeaderHeight + SB__uiFavoritesHeight + contentHeight + SB__uiTooltipHeight - 2;
	SB__uiMainFrame:SetSize(SB__uiComputedWidth, computedHeight)
end


-- toggle the display of the addon. SB__uiMainFrameDisplayed is either 0 or 1 so 1- value toggle the value
local function SB__UIToggle()
	SB__uiMainFrameDisplayed = 1 - SB__uiMainFrameDisplayed;
	if (SB__uiMainFrameDisplayed == 1) then
		SB__UIShow();
	else
		SB__UIHide();
	end
end


-- ==================== EVENTS ====================== --

-- on event function, called when something happened from the registered events
local function SB__OnEvent(self, event, registeredPrefix, message, channel, sender)
	if (event == "ADDON_LOADED" and registeredPrefix == SB__prefix) then -- activation of the addon
		-- initializing the saved variables
		if (SB__isActivated == nil) then
			SB__isActivated = 1;
		end
		if (SB__soundStats == nil) then
			SB__soundStats = {};
		end
		if (SB__soundTest == nil) then
			SB__soundTest = 0;
		end
		if (SB__uiMainFrame == nil) then
			SB__UIInitDisplayMainFrame() -- first time init of the main frame
		end
		SB__UIRefreshActivate() -- refresh the main frame depending on the activation of the addon
	end	
	if (event == "PLAYER_ENTERING_WORLD") then	-- player is now ingame, initializing the macro
		C_ChatInfo.RegisterAddonMessagePrefix(SB__prefix) -- registering the prefix so that chat command will be send and recognized
		local detected = GetMacroInfo(SB__prefix)
		if (detected == nil) then -- adding the macro if it is missing
			CreateMacro(SB__prefix, "inv_gizmo_goblinboombox_01", "/script SoundBox();", nil);
		end
	end
	if (event == "CHAT_MSG_ADDON") then -- event when a command was send on the addon chat system
		if (registeredPrefix == SB__prefix) then -- making sure that it is from this addon
			local wordsArg = {}
			for w in (message .. "|"):gmatch("([^|]*)|") do 
				table.insert(wordsArg, w) 
			end
			local mess = wordsArg[1]
			
			if (wordsArg[2] == nil) then
				wordsArg[2] = ""
			end
			
			local command = DBSounds[mess]; -- loading the command from the DB
			if (command ~= nil and wordsArg[2] ~= nil) then
				command = command .. ";" .. wordsArg[2]
				SB__DecodeCommand(channel, sender, command);		
			else -- command can be missing from the DB if it is directly the real command (currently used only for one admin command)
				SB__DecodeCommand(channel, sender, message);
			end
		end
	end
end

-- creating a frame (that won't be displayed) to receive the events
if not SB__receiveSoundFrame then
	SB__receiveSoundFrame = CreateFrame("Frame")
end

-- registering events
SB__receiveSoundFrame:SetScript("OnEvent", SB__OnEvent) 
SB__receiveSoundFrame:RegisterEvent("CHAT_MSG_ADDON")
SB__receiveSoundFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
SB__receiveSoundFrame:RegisterEvent("ADDON_LOADED"); -- Fired when saved variables are loaded

-- function called by the macro, will toggle the display of the main frame
function SoundBox()
	SB__UIToggle();
end

function SB_Play(soundName)
	SB__playSpecificSound("sb_" .. soundName, "")
end

function SB_PlayR(catName)
	SB__playRandomSoundFromCat(catName)
end
