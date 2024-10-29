-------------------------------------------------------------------------------
-- Localization English {{{
-------------------------------------------------------------------------------

function MBP:Localization_enUS()

    self.L = {}

    self.L["Moron Box Postal"] = ""

    self.L["Intro"] = 
        MBC:ApplyTextColor("MoronBoxRepair", MBC.Colors.Highlight)..
        MBC:ApplyTextColor(" is a lightweight mailing addon.", MBC.Colors.Text)

    self.L["Open All"] = ""
    self.L["Processing"] = ""
    self.L["Processing Mail"] = "Processing Mail: %s%s."
    self.L["All mail has been processed."] = ""
    self.L["Total Money Looted"] = "Total money looted"
    self.L["No More Bagspace"] = "Cannot take more items because there are only %s regular bag slots available."
    self.L["Some messages may have been skipped."] = ""
    self.L["There is no mail to process."] = ""
    self.L["All Mail Processed"] = "Totally %d mail(s) have been processed."
    self.L["UnseenMail Full"] = "There are %s more messages not currently shown."
    self.L["UnseenMail With Timer"] = "There are %s more messages not currently shown. More should become available in %s seconds."
end