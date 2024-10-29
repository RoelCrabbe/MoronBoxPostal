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
