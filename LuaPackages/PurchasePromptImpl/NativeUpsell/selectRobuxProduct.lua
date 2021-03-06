local XboxCatalogData = require(script.Parent.XboxCatalogData)
local NativeProducts = require(script.Parent.NativeProducts)

local Promise = require(script.Parent.Parent.Promise)

local function sortAscending(a, b)
	return a.robuxValue < b.robuxValue
end

local function selectProduct(price, availableProducts)
	table.sort(availableProducts, sortAscending)

	for _, product in ipairs(availableProducts) do
		if product.robuxValue >= price then
			return Promise.resolve(product)
		end
	end

	return Promise.reject()
end

local function selectRobuxProductPremium(platform, price, userIsSubscribed)
	local productOptions
	if platform == Enum.Platform.IOS then
		productOptions = userIsSubscribed
			and NativeProducts.IOS.PremiumSubscribed
			or NativeProducts.IOS.PremiumNotSubscribed
	else
		-- This product format is standard for other supported platforms (Android, Amazon, and UWP)
		productOptions = userIsSubscribed
			and NativeProducts.Standard.PremiumSubscribed
			or NativeProducts.Standard.PremiumNotSubscribed
	end

	return selectProduct(price, productOptions)
end

local function selectRobuxProduct(platform, price, isBuildersClubMember, premiumEnabled)
	-- Premium is not yet enabled for XBox, so we always use the existing approach
	if platform == Enum.Platform.XBoxOne then
		return XboxCatalogData.GetCatalogInfoAsync()
			:andThen(function(availableProducts)
				return selectProduct(price, availableProducts)
			end)
	end

	if premiumEnabled then
		return selectRobuxProductPremium(platform, price, isBuildersClubMember)
	end

	if platform == Enum.Platform.IOS then
		local productOptions = isBuildersClubMember and NativeProducts.IOS.BC or NativeProducts.IOS.NonBC
		return selectProduct(price, productOptions)
	else
		-- This product format is standard for other supported platforms (Android, Amazon, and UWP)
		local productOptions = isBuildersClubMember and NativeProducts.Standard.BC or NativeProducts.Standard.NonBC
		return selectProduct(price, productOptions)
	end
end

return selectRobuxProduct