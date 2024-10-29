-------------------------------------------------------------------------------
-- InboxFrame - Open All {{{
-------------------------------------------------------------------------------

function MBP:OpenAllButton(Parent)
    if not Parent then return end

    local OpenAllButton = MBC:CreateButton(Parent, 125, MBC.Button.Middle, MBP:SL("Open All"))
    OpenAllButton:SetPoint("CENTER", Parent, "BOTTOM", 95, 59)
    OpenAllButton:SetFrameLevel(OpenAllButton:GetFrameLevel() + 1)

    OpenAllButton:SetScript("OnClick", function() 
        MBP:OpenAll()
    end)

    self.Session.OpenAll.Button = OpenAllButton
    return OpenAllButton
end

-------------------------------------------------------------------------------
-- Open All Logic Handeling {{{
-------------------------------------------------------------------------------

function MBP:OpenAll()

    -- Reset Session Storage for open all
    self.Session.OpenAll.MailIndex = GetInboxNumItems()
    self.Session.OpenAll.NumMails = 0
    self.Session.OpenAll.SkipFlag = false
    self.Session.OpenAll.InvFull = false
    self.Session.OpenAll.TotalGold = 0
    self.Session.OpenAll.TotalMail = GetInboxNumItems()

    self.Session.OpenAll.Button:Disable()
    self.Session.OpenAll.Button.Text:SetText(MBP:SL("Processing"))

    -- Define an update handler for sequential mail processing
    local function OnUpdateHandler(self, elapsed)
        self.LastUpdate = (self.LastUpdate or 0) + elapsed

        if self.LastUpdate >= MBP.Session.LoadingSpeed then
            self:EnableDots()
            MBP.Session.OpenAll.NumMails = GetInboxNumItems()

            -- End the process if no more mail is left
            if MBP.Session.OpenAll.NumMails == 0 or MBP.Session.OpenAll.MailIndex < 1 then
                if MBP.Session.OpenAll.SkipFlag then MBC:Print(MBP:SL("Some messages may have been skipped.")) end
                MBP:OpelAllMailMessage()
                MBP:ResetOpenAllButton()
                return
            end

            -- Get current mail details
            local sender, msgSubject, msgMoney, msgCOD, _, msgItem, _, _, msgText, _, isGM = select(3, GetInboxHeaderInfo(MBP.Session.OpenAll.MailIndex))

            -- Skip mail if it contains a CoD or if its from a GM
            if (msgCOD and msgCOD > 0) or isGM then
                MBP.Session.OpenAll.SkipFlag = true
                MBP.Session.OpenAll.MailIndex = MBP.Session.OpenAll.MailIndex - 1
                return
            end

            -- Process Text            
            local moneyString = (msgMoney > 0) and " ["..GetCoinTextureString(msgMoney).."]" or ""

            -- Check bag space if mail contains items
            local BagSpace = MBP:GetBagSpace()
            if msgItem and BagSpace <= 1 and not MBP.Session.OpenAll.InvFull then
                MBP.Session.OpenAll.InvFull = true
                MBC:Print(MBP:SL("No More Bagspace", BagSpace))
            end

            -- Take attachments if present
            if not MBP.Session.OpenAll.InvFull then 
                for i = 1, ATTACHMENTS_MAX_RECEIVE do
                    if GetInboxItemLink(MBP.Session.OpenAll.MailIndex, i) then
                        TakeInboxItem(MBP.Session.OpenAll.MailIndex, i)
                        
                        -- Process Text  
                        MBC:Print(MBP:SL("Processing Mail", msgSubject or "No Subject", moneyString))

                        -- Refresh mail count and update display
                        MBP.Session.OpenAll.NumMails = GetInboxNumItems()
                        MBP:UpdateMailboxDisplay()  -- Update the display here
                        self.LastUpdate = 0
                        return
                    end
                end
            end

            -- Attempt to take money if present
            if msgMoney > 0 then
                TakeInboxMoney(MBP.Session.OpenAll.MailIndex)
                MBP.Session.OpenAll.TotalGold = MBP.Session.OpenAll.TotalGold + msgMoney  -- Accumulate total gold

                -- Process Text  
                MBC:Print(MBP:SL("Processing Mail", msgSubject or "No Subject", moneyString))

                -- Refresh mail count and update display
                MBP.Session.OpenAll.NumMails = GetInboxNumItems()
                MBP:UpdateMailboxDisplay()  -- Update the display here
                self.LastUpdate = 0
                return
            end

            -- Once items and money are taken, delete the mail and move to the next
            if MBP:GetMailType(msgSubject) == "AHPending" then
                DeleteInboxItem(MBP.Session.OpenAll.MailIndex)

                -- Refresh mail count and update display
                MBP.Session.OpenAll.MailIndex = MBP.Session.OpenAll.MailIndex - 1
                MBP.Session.OpenAll.NumMails = GetInboxNumItems()
                MBP:UpdateMailboxDisplay()  -- Update the display here
                self.LastUpdate = 0
                return
            end

            -- Move to the next mail only after processing
            MBP.Session.OpenAll.MailIndex = MBP.Session.OpenAll.MailIndex - 1
            MBP.Session.OpenAll.NumMails = GetInboxNumItems()

            -- End the process if no more mail is left
            if MBP.Session.OpenAll.NumMails == 0 or MBP.Session.OpenAll.MailIndex < 1 then
                if MBP.Session.OpenAll.SkipFlag then MBC:Print(MBP:SL("Some messages may have been skipped.")) end
                MBP:OpelAllMailMessage()
                MBP:ResetOpenAllButton()
                return
            end
        end
    end

    -- Start the update loop
    self.Session.OpenAll.Button:SetScript("OnUpdate", OnUpdateHandler)
end

-------------------------------------------------------------------------------
-- Open All Helper Functions {{{
-------------------------------------------------------------------------------

function MBP:OpelAllMailMessage()

    if self.Session.OpenAll.TotalMail == 0 then
        MBC:Print(MBP:SL("There is no mail to process."))
        return
    end

    local Msg = ""
    if self.Session.OpenAll.TotalGold > 0 then
        Msg = MBP:SL("Total Money Looted")..": ["..GetCoinTextureString(self.Session.OpenAll.TotalGold).."]."
    end

    MBC:Print(MBP:SL("All Mail Processed", self.Session.OpenAll.TotalMail).." "..Msg)
end

function MBP:ResetOpenAllButton()
    self.Session.OpenAll.Button:Enable()
    self.Session.OpenAll.Button.Text:SetText(MBP:SL("Open All"))
    self.Session.OpenAll.Button:DisableDots()
    self.Session.OpenAll.Button:SetScript("OnUpdate", nil)
    MBP:TooMuchMail()
    MBP:UpdateMailboxDisplay()
end

local lastUnseen, lastTime = 0, 0
function MBP:TooMuchMail()
    local cur, tot = GetInboxNumItems()
    if tot - cur ~= lastUnseen or GetTime() - lastTime >= 60 then
        lastUnseen = tot - cur
        lastTime = GetTime()
    end

    if cur >= 50 then
        MBC:Print(MBP:SL("UnseenMail Full", lastUnseen))
    elseif lastUnseen > 0 then
        local timeRemaining = math.max(0, math.floor(lastTime + 60 - GetTime()))
        MBC:Print(MBP:SL("UnseenMail With Timer", lastUnseen, timeRemaining))
    end
end