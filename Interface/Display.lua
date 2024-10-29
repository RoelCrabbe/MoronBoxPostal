-------------------------------------------------------------------------------
-- General Setting Window {{{
-------------------------------------------------------------------------------

function MBP:GeneralSettingWindow()

    local SettingsFrame = MBC:CreateGeneralWindow(UIParent, MBP:SL("Moron Box Postal"), 500, 450)
    local FrameHeight = SettingsFrame:GetHeight()
    local LineWidth = SettingsFrame:GetWidth() - 60

    local Description = SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    Description:SetPoint("TOPLEFT", SettingsFrame, "TOPLEFT", 20, -60)
    Description:SetWidth(SettingsFrame:GetWidth() - 40)
    Description:SetJustifyH("LEFT")
    Description:SetHeight(0)
    Description:SetWordWrap(true)
    Description:SetText(MBP:SL("Intro"))

    local OffsetY = FrameHeight * 0.5 - 105
    MBC:CreateLine(SettingsFrame, LineWidth, 1, 0, OffsetY, MBC.Colors.LineColor)

    SettingsFrame.ReturnButton:SetScript("OnClick", function()

    end)

    SettingsFrame.CloseButton:SetScript("OnClick", function()
        MBC:HideFrameIfShown(SettingsFrame)
    end)

    SettingsFrame.Description = Description
    SettingsFrame.AutoOpenInteractionCheckbox = AutoOpenVendorCheckbox
    SettingsFrame.AutoRepairCheckbox = AutoRepairCheckbox
    SettingsFrame.AutoSellGreyCheckbox = AutoSellGreyCheckbox

    return SettingsFrame
end

-------------------------------------------------------------------------------
-- Mail UI {{{
-------------------------------------------------------------------------------

function MBP:GetMailItemsForPage()

    self.Session.Inbox.Mails = {}
    self.Session.Inbox.TotalMails = GetInboxNumItems()
    self.Session.Inbox.MaxPages = math.ceil(self.Session.Inbox.TotalMails / self.Session.Inbox.ItemsPerPage)

    local StartIndex = (self.Session.Inbox.CurrentPage - 1) * self.Session.Inbox.ItemsPerPage + 1
    local EndIndex = math.min(StartIndex + self.Session.Inbox.ItemsPerPage - 1, self.Session.Inbox.TotalMails)

    for i = StartIndex, EndIndex do
        local sender, msgSubject, msgMoney, _, _, msgItem, _, _, _, _, _ = select(3, GetInboxHeaderInfo(i))

        if msgSubject or msgItem then
            local itemLink = GetInboxItemLink(i)
            local itemIcon

            if msgMoney > 0 then
                itemIcon = "Interface\\Icons\\Inv_Scroll_03"
            elseif itemLink then
                itemIcon = GetItemIcon(itemLink)
            else
                itemIcon = "Interface\\Icons\\INV_Misc_Note_01"
            end

            local MailInformation = {
                Icon = itemIcon,
                Link = itemLink or "",
                Title = msgSubject or "No Subject",
                Sender = sender,
                Money = msgMoney > 0 and msgMoney or nil
            }

            table.insert(self.Session.Inbox.Mails, MailInformation)
        end
    end
end

function MBP:UpdateMailboxDisplay()

    if not self.Session.Inbox.MailboxFrame then return end
    
    -- Clear previous mail entries
    for _, MailItem in ipairs(self.Session.Inbox.MailEntries) do
        MailItem:Hide()
    end

    -- Create new mail entries
    self.Session.Inbox.MailEntries = self.Session.Inbox.MailEntries or {}
    self:GetMailItemsForPage()

    -- Update page indicator
    self.Session.Inbox.PageIndicator:Update(self.Session.Inbox.CurrentPage, self.Session.Inbox.MaxPages)

    -- Show or hide the no mails message based on the inbox content
    if #self.Session.Inbox.Mails == 0 then
        self.Session.Inbox.NoMailsMessage:Show()
    else
        self.Session.Inbox.NoMailsMessage:Hide()

        -- Store new entries
        for k, v in ipairs(self.Session.Inbox.Mails) do
            local Index = ((self.Session.Inbox.CurrentPage - 1) * self.Session.Inbox.ItemsPerPage) + k
            local MailEntry = MBC:CreateMailEntry(self.Session.Inbox.MailboxFrame, k, 45, v.Icon, v.Link, v.Title, v.Sender, v.Money)
            MailEntry.CheckBox:SetScript("OnClick", function(self)
                MBP:ManageSelectedMails(Index, (self:GetChecked() == 1))
            end)            
            table.insert(self.Session.Inbox.MailEntries, MailEntry)
        end
    end
end

function MBP:ManageSelectedMails(MailId, IsChecked)
    if IsChecked then
        if not MBC:Contains(self.Session.Select.SelectedMails, MailId) then
            table.insert(self.Session.Select.SelectedMails, MailId)
        end
    else
        for i, id in ipairs(self.Session.Select.SelectedMails) do
            if id == MailId then
                table.remove(self.Session.Select.SelectedMails, i)
                break
            end
        end
    end
end

function MBP:CreateCustomMailboxUI()

    if self.Session.Inbox.CustomMailboxFrame then return self.Session.Inbox.CustomMailboxFrame:Show() end
    
    -- Create Custom Mailbox Frame
    local CustomMailboxFrame = MBC:CreateGeneralWindow(UIParent, self:SL("Moron Box Postal"), 500, 630)
    CustomMailboxFrame.ReturnButton:Hide()
    CustomMailboxFrame.CloseButton:SetScript("OnClick", function()
        MBC:HideFrameIfShown(CustomMailboxFrame)
    end)

    local SelectButton = self:SelectButton(CustomMailboxFrame)
    local OpenAllButton = self:OpenAllButton(CustomMailboxFrame)

    -- Page Indicator
    self.Session.Inbox.PageIndicator = MBC:PageIndicator(CustomMailboxFrame, self.Session.Inbox.CurrentPage, self.Session.Inbox.MaxPages)
    self.Session.Inbox.PageIndicator:SetPoint("LEFT", SelectButton, "RIGHT", 15, 0)

    -- Pagination Controls
    local LeftArrow = MBC:PaginationButton(CustomMailboxFrame, 1, 40, MBC.Button.Middle)
    LeftArrow:SetPoint("RIGHT", SelectButton, "LEFT", -27.5, 0)
    LeftArrow:SetScript("OnClick", function()
        if self.Session.Inbox.CurrentPage > 1 then
            self.Session.Inbox.CurrentPage = self.Session.Inbox.CurrentPage - 1
            self:UpdateMailboxDisplay()
            self.Session.Inbox.PageIndicator:Update(self.Session.Inbox.CurrentPage, self.Session.Inbox.MaxPages)
        end
    end)

    local RightArrow = MBC:PaginationButton(CustomMailboxFrame, 2, 40, MBC.Button.Middle)
    RightArrow:SetPoint("LEFT", OpenAllButton, "RIGHT", 27.5, 0)
    RightArrow:SetScript("OnClick", function()
        if self.Session.Inbox.CurrentPage < self.Session.Inbox.MaxPages then
            self.Session.Inbox.CurrentPage = self.Session.Inbox.CurrentPage + 1
            self:UpdateMailboxDisplay()
            self.Session.Inbox.PageIndicator:Update(self.Session.Inbox.CurrentPage, self.Session.Inbox.MaxPages)
        end
    end)

    -- Mailbox Frame
    self.Session.Inbox.MailboxFrame = MBC:CreateFrame(CustomMailboxFrame, MBC.BackDrops.Basic, CustomMailboxFrame:GetWidth() * 0.9, CustomMailboxFrame:GetHeight() * 0.8)
    self.Session.Inbox.MailboxFrame:SetBackdropColor(0, 0, 0, 0)
    self.Session.Inbox.MailboxFrame:SetPoint("TOP", 0, -45)

    -- Create a FontString for the "No Mails" message
    self.Session.Inbox.NoMailsMessage = self.Session.Inbox.MailboxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.Session.Inbox.NoMailsMessage:SetPoint("CENTER", self.Session.Inbox.MailboxFrame, "CENTER")
    self.Session.Inbox.NoMailsMessage:SetText(MBC:ApplyTextColor("No more mails", MBC.Colors.Title))
    MBC:ApplyCustomFont(self.Session.Inbox.NoMailsMessage, MBC.Font.BigTitle)
    self.Session.Inbox.NoMailsMessage:Hide()

    -- Initial load of mails
    self:UpdateMailboxDisplay()
    self.Session.Inbox.CustomMailboxFrame = CustomMailboxFrame
end

function MBP:CheckMailDataLoaded()
    C_Timer.After(self.Session.LoadingSpeed, function()
        if GetInboxNumItems() > 0 then
            self:UpdateMailboxDisplay()
        else
            self:CheckMailDataLoaded()
        end
    end)
end