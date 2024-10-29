-------------------------------------------------------------------------------
-- InboxFrame - Open All {{{
-------------------------------------------------------------------------------

function MBP:SelectButton(Parent)
    if not Parent then return end

    local SelectButton = MBC:CreateButton(Parent, 125, MBC.Button.Middle, MBP:SL("Open"))
    SelectButton:SetPoint("CENTER", Parent, "BOTTOM", -95, 59)
    SelectButton:SetFrameLevel(SelectButton:GetFrameLevel() + 1)

    SelectButton:SetScript("OnClick", function()
        MBP:OpenSelected()
    end)

    self.Session.Select.Button = SelectButton
    return SelectButton
end

-------------------------------------------------------------------------------
-- Open All Logic Handeling {{{
-------------------------------------------------------------------------------

function MBP:OpenSelected()

    -- Reset Session Storage for selected mails
    self.Session.Select.MailIndex = 1
    self.Session.OpenAll.StoredNumMails = #self.Session.Select.SelectedMails
    self.Session.OpenAll.NumMails = #self.Session.Select.SelectedMails -- Get total number of mails
    self.Session.Select.SkipFlag = false
    self.Session.Select.InvFull = false
    self.Session.Select.TotalGold = 0
    table.sort(self.Session.Select.SelectedMails, function(a, b) return a > b end)

    self.Session.Select.Button:Disable()
    self.Session.Select.Button.Text:SetText(MBP:SL("Processing"))

    -- Define an update handler for sequential mail processing
    local function OnUpdateHandler(self, elapsed)
        self.LastUpdate = (self.LastUpdate or 0) + elapsed

        if self.LastUpdate >= MBP.Session.LoadingSpeed then
            self:EnableDots()

            -- Check for no mails or index out of range
            if MBP.Session.OpenAll.NumMails == 0 or MBP.Session.Select.MailIndex > MBP.Session.OpenAll.NumMails then
                if MBP.Session.Select.SkipFlag then MBC:Print(MBP:SL("Some messages may have been skipped.")) end
                MBP:SelectedMailMessages()
                MBP:ResetSelectButton()
                return
            end

            -- Get current mail details
            local Index = MBP.Session.Select.SelectedMails[MBP.Session.Select.MailIndex]
            MBP.Session.OpenAll.NumMails = #MBP.Session.Select.SelectedMails - 1

            -- Get mail details from SelectedMails list
            local sender, msgSubject, msgMoney, msgCOD, _, msgItem, _, _, msgText, _, isGM = select(3, GetInboxHeaderInfo(Index))

            -- Skip mail if it contains a CoD or if it's from a GM
            if (msgCOD and msgCOD > 0) or isGM then
                MBP.Session.Select.SkipFlag = true
                MBP.Session.OpenAll.NumMails = #MBP.Session.Select.SelectedMails - 1
                MBP.Session.Select.MailIndex = MBP.Session.Select.MailIndex + 1
                return
            end

            -- Process Text
            local moneyString = (msgMoney > 0) and " ["..GetCoinTextureString(msgMoney).."]" or ""

            -- Check bag space if mail contains items
            local BagSpace = MBP:GetBagSpace()
            if msgItem and BagSpace <= 1 and not MBP.Session.Select.InvFull then
                MBP.Session.Select.InvFull = true
                MBC:Print(MBP:SL("No More Bagspace", BagSpace))
            end

            -- Take attachments if present
            if not MBP.Session.Select.InvFull then 
                for i = 1, ATTACHMENTS_MAX_RECEIVE do
                    if GetInboxItemLink(Index, i) then
                        TakeInboxItem(Index, i)

                        -- Process Text
                        MBC:Print(MBP:SL("Processing Mail", msgSubject or "No Subject", moneyString))

                        -- Refresh mail count and update display
                        table.remove(MBP.Session.Select.SelectedMails, MBP.Session.Select.MailIndex)
                        MBP.Session.OpenAll.NumMails = #MBP.Session.Select.SelectedMails

                        -- Refresh mail count and update display
                        MBP:UpdateMailboxDisplay()
                        self.LastUpdate = 0
                        return
                    end
                end
            end

            -- Attempt to take money if present
            if msgMoney > 0 then
                TakeInboxMoney(Index)
                MBP.Session.Select.TotalGold = MBP.Session.Select.TotalGold + msgMoney

                -- Process Text
                MBC:Print(MBP:SL("Processing Mail", msgSubject or "No Subject", moneyString))

                -- Refresh mail count and update display
                table.remove(MBP.Session.Select.SelectedMails, MBP.Session.Select.MailIndex)
                MBP.Session.OpenAll.NumMails = #MBP.Session.Select.SelectedMails

                -- Refresh mail count and update display
                MBP:UpdateMailboxDisplay()
                self.LastUpdate = 0
                return
            end

            -- Once items and money are taken, delete the mail if needed
            if MBP:GetMailType(msgSubject) == "AHPending" then
                DeleteInboxItem(Index)

                -- Refresh mail count and update display
                MBP.Session.OpenAll.NumMails = #MBP.Session.Select.SelectedMails
                MBP:UpdateMailboxDisplay()
                self.LastUpdate = 0
                return
            end

            MBP.Session.Select.MailIndex = MBP.Session.Select.MailIndex + 1
            MBP.Session.OpenAll.NumMails = #MBP.Session.Select.SelectedMails

            -- Check for no mails or index out of range
            if MBP.Session.OpenAll.NumMails == 0 or MBP.Session.Select.MailIndex > MBP.Session.OpenAll.NumMails then
                if MBP.Session.Select.SkipFlag then MBC:Print(MBP:SL("Some messages may have been skipped.")) end
                MBP:SelectedMailMessages()
                MBP:ResetSelectButton()
                return
            end
        end
    end

    -- Start the update loop
    self.Session.Select.Button:SetScript("OnUpdate", OnUpdateHandler)
end

function MBP:SelectedMailMessages()

    if self.Session.OpenAll.StoredNumMails == 0 then
        MBC:Print(MBP:SL("There is no mail to process."))
        return
    end

    local Msg = ""
    if self.Session.Select.TotalGold > 0 then
        Msg = MBP:SL("Total Money Looted")..": ["..GetCoinTextureString(self.Session.Select.TotalGold).."]."
    end

    MBC:Print(MBP:SL("All Mail Processed", self.Session.OpenAll.StoredNumMails).." "..Msg)
end

function MBP:ResetSelectButton()
    self.Session.Select.Button:Enable()
    self.Session.Select.Button.Text:SetText(MBP:SL("Open"))
    self.Session.Select.Button:DisableDots()
    self.Session.Select.Button:SetScript("OnUpdate", nil)
    MBP:UpdateMailboxDisplay()
    self.Session.Select.SelectedMails = {}
    self.Session.OpenAll.StoredNumMails = 0
end