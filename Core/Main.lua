-------------------------------------------------------------------------------
-- InterFace Frame {{{
-------------------------------------------------------------------------------

MBP = CreateFrame("Frame", "MoronBoxPostal", UIParent)

-------------------------------------------------------------------------------
-- The Stored Variables {{{
-------------------------------------------------------------------------------

MBP.DefaultOptions = {

}

-------------------------------------------------------------------------------
-- Local Variables {{{
-------------------------------------------------------------------------------

MBP.Session = {
    LoadingSpeed = 0.25,
    AfterMailTimer = nil,
    Inbox = {
        Mails = {},
        MailboxFrame = nil,
        NoMailsMessage = nil,
        TotalMails = 0,
        ItemsPerPage = 10,
        CurrentPage = 1,
        MaxPages = 5,
        MailEntries = {},
        CustomMailboxFrame = nil,
        PageIndicator = nil
    },
    OpenAll = {
        Button = nil,
        MailIndex = 1,
        NumMails = 0,
        SkipFlag = false,
        InvFull = false,
        TotalGold = 0,
        TotalMail = 0
    },
    Select = {
        Button = nil,
        SelectedMails = {},
        MailIndex = 1,
        TotalMail = 0,
        NumMails = 0,
        SkipFlag = false,
        InvFull = false,
        TotalGold = 0
    }
}

-------------------------------------------------------------------------------
-- Core Event Code {{{
-------------------------------------------------------------------------------

MBP:RegisterEvent("ADDON_LOADED")
MBP:RegisterEvent("MAIL_SHOW")
MBP:RegisterEvent("MAIL_CLOSED")

function MBP:OnEvent(event)
    if event == "ADDON_LOADED" and arg1 == self:GetName() then
        self:SetupSavedVariables()
    elseif event == "MAIL_SHOW" then
        self:CreateCustomMailboxUI()
        self:CheckMailDataLoaded()
    elseif event == "MAIL_CLOSED" then
        if self.Session.Inbox.CustomMailboxFrame then
            self.Session.Inbox.CustomMailboxFrame:Hide()
            self.Session.Inbox.CustomMailboxFrame = nil
        end
        self:ClearAllMailEntries()
        self.Session.Select.SelectedMails = {}
        self.Session.Inbox.CurrentPage = 1
    end
end

MBP:SetScript("OnEvent", MBP.OnEvent)

function MBP:SetupSavedVariables()
    if not MoronBoxPostal_Settings then
        MoronBoxPostal_Settings = {}
    end

    local function InitializeDefaults(defaults, settings)
        for k, v in pairs(defaults) do
            if type(v) == "table" then
                if settings[k] == nil then
                    settings[k] = {}
                end
                InitializeDefaults(v, settings[k])
            else
                if settings[k] == nil then
                    settings[k] = v
                end
            end
        end
    end

    InitializeDefaults(self.DefaultOptions, MoronBoxPostal_Settings)
end

function MBP:ResetToDefaults()
    MoronBoxPostal_Settings = self.DefaultOptions
    self:ResetPossibleVendorItems()
    ReloadUI()
end