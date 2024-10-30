-------------------------------------------------------------------------------
-- Helper Functions {{{
-------------------------------------------------------------------------------

function MBP:GetBagSpace()
    self.BagSlots = 0
    for i = 0, NUM_BAG_SLOTS do
        local n, BagType = GetContainerNumFreeSlots(i)
        if BagType == 0 then 
            self.BagSlots = self.BagSlots + n
        end
    end
    return self.BagSlots
end

local SubjectPatterns = {
	AHCancelled = gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*"),
	AHExpired = gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*"),
	AHOutbid = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*"),
	AHSuccess = gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*"),
	AHWon = gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*"),
	AHPending = gsub("Sale Pending: %s", "%%s", ".*")
}

function MBP:GetMailType(msgSubject)
	if msgSubject then
		for k, v in pairs(SubjectPatterns) do
			if msgSubject:find(v) then return k end
		end
	end
	return "NonAHMail"
end

local lastUnseen, lastTime = 0, 0
function MBP:TooMuchMail()
    local cur, tot = GetInboxNumItems()
    if tot - cur ~= lastUnseen or GetTime() - lastTime >= 60 then
        lastUnseen = tot - cur
        lastTime = GetTime()
    end

    if cur >= 50 then
        MBC:Print(self:SL("UnseenMail Full", lastUnseen))
    elseif lastUnseen > 0 then
        local timeRemaining = math.max(0, math.floor(lastTime + 60 - GetTime()))
        MBC:Print(self:SL("UnseenMail With Timer", lastUnseen, timeRemaining))
    end
end

function MBP:DisableButtons(Button)
    self.Session.Select.Button:Disable()
    self.Session.OpenAll.Button:Disable()

    if Value == 1 then
        self.Session.Select.Button.Text:SetText(self:SL("Processing"))
    elseif Value == 2 then
        self.Session.OpenAll.Button.Text:SetText(self:SL("Processing"))
    end
end

function MBP:ResetButtons()
    self.Session.Select.Button:Enable()
    self.Session.OpenAll.Button:Enable()

    self.Session.Select.Button:DisableDots()
    self.Session.OpenAll.Button:DisableDots()

    self:UpdateMailboxDisplay()

    self.Session.Select.Button.Text:SetText(self:SL("Open"))
    self.Session.OpenAll.Button.Text:SetText(self:SL("Open All"))

    self.Session.Select.Button:SetScript("OnUpdate", nil)
    self.Session.OpenAll.Button:SetScript("OnUpdate", nil)

    self:TooMuchMail()
end

function MBP:MailProcessingMessage(session)
    if session.TotalMail == 0 then
        MBC:Print(self:SL("There is no mail to process."))
        return
    end

    local Msg = ""
    if session.TotalGold > 0 then
        Msg = self:SL("Total Money Looted")..": ["..GetCoinTextureString(session.TotalGold).."]."
    end

    MBC:Print(self:SL("All Mail Processed", session.TotalMail).." "..Msg)
end