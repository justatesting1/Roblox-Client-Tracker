local PatchInfo = require(script.Parent.PatchInfo)
local PageDownloader = require(script.Parent.PageDownloader)

local AddWebEntriesToRbxEntries = require(script.Parent.AddWebEntriesToRbxEntries)
local Urls = require(script.Parent.Parent.Urls)
local Promise = require(script.Parent.Parent.Promise)

local HttpService = game:GetService("HttpService")
local BaseUrl = game:GetService("ContentProvider").BaseUrl:lower()

local GameInternationalizationUrl = Urls.GetGameInternationalizationUrlFromBaseUrl(BaseUrl)
local TranslationRolesUrl = Urls.GetTranslationRolesUrlFromBaseUrl(BaseUrl)
local ApiUrl = Urls.GetApiUrlFromBaseUrl(BaseUrl)

local BAD_REQUEST = 400
local CODE_INVALID_GAME_ID = 14
local CODE_PERMISSIONS = 28

local TranslationRolesApi2 = settings():GetFFlag("TranslationRolesApi2")

local LocalizationTableUploadRowMax =
	tonumber(settings():GetFVariable("LocalizationTableUploadRowMax")) or 50
local LocalizationTableUploadTranslationMax =
	tonumber(settings():GetFVariable("LocalizationTableUploadTranslationMax")) or 250

return function(studioUserId)
--[[When a tableid is obtained, remember the gameId associated with it, then check
that gameId matches next time we attempt to access the table, hit the get/create web endpoint
again if we have a new gameID]]
local currentTableId
local currentGameId

local function urlEncode(datum)
	return HttpService:UrlEncode(tostring(datum))
end

--[[
	Appeals to the Roblox API to decode a json string, returns nil on any error.
]]
local function decodeJSON(json)
	if json == nil or #json == 0 then
		return nil
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(json)
	end)

	if not success then
		return nil
	end

	return result
end

--[[
	Appeals to the Roblox API to encode a json string.
]]
local function encodeJSON(obj)
	return HttpService:JSONEncode(obj)
end

--[[
	Appeals to the internet using placeId as an asset-id to determine if the user
	has permission to edit the current place.

	Clean up along with TranslationRolesApi2
]]
local function UserCanManagePlace(userId, placeId)
	return Promise.new(function(resolve, reject)
		local Url = ApiUrl
			.."users/"
			.. urlEncode(tostring(userId))
			.. "/canmanage/"
			.. urlEncode(tostring(placeId))

		HttpService:RequestInternal({
			Url = Url,
			Method = "GET",
			CachePolicy = Enum.HttpCachePolicy.None,
			RequestType = Enum.HttpRequestType.Localization,
		}):Start(function(success, response)
			spawn(function()
				if success then
					local decodedResponseBody = decodeJSON(response.Body)
					if response.StatusCode >= BAD_REQUEST then
						warn(string.format("Status code: %s", tostring(response.StatusCode)))

						if decodedResponseBody ~= nil and decodedResponseBody.message then
							warn(decodedResponseBody.message)
						end

						reject("Place-management status download failed (See Output)")
					else
						if decodedResponseBody.Success then
							resolve(decodedResponseBody.CanManage)
						end
					end
				else
					reject("Place-management status download failed")
				end
			end)
		end)
	end)
end

--[[
	Appeals to the get/create web endpoint to create the lcoalization table for the current game.
	Upon success, calls resolve passing the object that the get/create endpoint returns as
	its response:

	Upon any error, calls reject() passing it an error message string.
]]
local function GetOrCreateGameTable(gameId)
	return Promise.new(function(resolve, reject)
		local Url = GameInternationalizationUrl
			.. "v1/autolocalization/games/"
			.. urlEncode(tostring(gameId))
			.. "/autolocalizationtable"

		local bodyObject = {
			name = "MyLocalizationTable",
			ownerType = "User",
			ownerId = studioUserId,
		}

		HttpService:RequestInternal({
			Url = Url,
			Method = "POST",
			Body = encodeJSON(bodyObject),
			CachePolicy = Enum.HttpCachePolicy.None,
			RequestType = Enum.HttpRequestType.Localization,
			Headers = {
				["Content-Type"] = "application/json"
			},
		}):Start(function(success, response)
			spawn(function()
				if success then
					if response.StatusCode >= BAD_REQUEST then
						if TranslationRolesApi2 then
							local decodedResponseBody = decodeJSON(response.Body)
							if decodedResponseBody ~= nil
								and decodedResponseBody.errors ~= nil
								and next(decodedResponseBody.errors)~=nil
							then
								for _, err in ipairs(decodedResponseBody.errors) do
									if err.code == CODE_INVALID_GAME_ID or err.code == CODE_PERMISSIONS then
										--[[Don't warn about these errors, because that could simply mean the
											That shouldn't present as an error to the user.]]
										reject("User cannot access game")
										return
									else
										warn(err.message)
									end
								end
								reject("Game table download failed (See Output)")
								return
							else
								warn(string.format("Get/Create Table status code: %s", tostring(response.StatusCode)))
							end

							reject("Game table download failed")
							return
						else
							warn(string.format("Get/Create Table status code: %s", tostring(response.StatusCode)))

							local decodedResponseBody = decodeJSON(response.Body)
							if decodedResponseBody ~= nil and decodedResponseBody.message then
								warn(decodedResponseBody.message)
								reject("Game table download failed (See Output)")
								return
							end

							reject("Game table download failed")
							return
						end
					end

					local decodedResponseBody = decodeJSON(response.Body)
					if decodedResponseBody == nil then
						reject("Create request returned invalid JSON")
						return
					end

					if decodedResponseBody.autoLocalizationTableId == nil then
						reject("Create request returned no tableId")
						return
					end

					resolve(decodedResponseBody)
				else
					warn(string.format("Creating game table HTTP error: %s", tostring(response.HttpError)))
					reject("Failed to create game table")
					return
				end
			end)
		end)
	end)
end

--[[
	Determine using the internet whether the current studio user is allowed to
	access the placefile, and if so, get the tableId for the current
	web-based localization table and store it.

	Returns a promise that resolves with the following arguments on success:
		available = whether the current Studio user has permission to edit the place.
		autoscraping = whether server-side auto scraping is enabled for the place,
			this is mostly so that the receiving UI can decide whether to turn on the
			checkbox.

	Clean up along with TranslationRolesApi2
]]
local function UpdateGameTableInfo()
	return Promise.new(function(resolve, reject)
		if game.PlaceId == 0 then
			resolve(false)
			return
		end

		UserCanManagePlace(studioUserId, game.PlaceId)
			:andThen(
				function(canManage)
					if canManage then
						GetOrCreateGameTable(game.GameId)
							:andThen(
								function(tableInfo)
									currentTableId = tableInfo.autoLocalizationTableId
									currentGameId = game.GameId
									resolve(true, tableInfo.isAutolocalizationEnabled)
								end,
								reject
							)
					else
						resolve(false)
					end
				end,
				reject
			)
	end)
end

--[[
	Sends an HTTP request to download the localization table with the given tableId.
	Returns a promise that resolves with a Roblox LocalizationTable object upon success.
]]
local function DownloadGameTableWithId(gameId, tableId)
	return Promise.new(function(resolve, reject)
		local function MakeDownloadRequest(cursor)
			local Url = GameInternationalizationUrl
				.. "v1/localizationtable/tables/"
				.. urlEncode(tableId)
				.. "/entries?cursor="
				.. urlEncode(cursor)
				.. "&gameId="
				.. urlEncode(gameId)

			return HttpService:RequestInternal({
				Url = Url,
				Method = "GET",
				CachePolicy = Enum.HttpCachePolicy.None,
				RequestType = Enum.HttpRequestType.Localization,
			})
		end

		local pageDownloader = PageDownloader(
			MakeDownloadRequest,
			function(body)
				return decodeJSON(body)
			end,
			function(responseObject, rbxEntries)
				if responseObject.data == nil then
					return {errorMessage = "Table download format error"}
				end

				local info = AddWebEntriesToRbxEntries(responseObject.data, rbxEntries)

				if info.errorMessage then
					return {errorMessage = info.errorMessage}
				end

				return {success = true}
			end,
			function(message)
				warn(message)
			end)

		pageDownloader:download():andThen(
			function(receivedEntries)
				local localizationTable = Instance.new("LocalizationTable")
				localizationTable:SetEntries(receivedEntries)
				resolve(localizationTable)
			end,
			function(errorMessage)
				reject(errorMessage)
			end
		)
	end)
end

--[[
	Uploads a single patch to the endpoint for the given table id.
	Returns a promise that resolves with no arguments upon success.
]]
local function UploadPatchToTableId(gameId, patch, tableId)
	return Promise.new(function(resolve, reject)
		local Url = GameInternationalizationUrl
			.."v1/localizationtable/tables/"
			..tableId
			.."?gameId="
			..urlEncode(gameId)

		HttpService:RequestInternal({
			Url = Url,
			Method = "PATCH",
			Body = encodeJSON(patch),
			CachePolicy = Enum.HttpCachePolicy.None,
			RequestType = Enum.HttpRequestType.Localization,
			Headers = {
				["Content-Type"] = "application/json"
			},
		}):Start(function(success, response)
			spawn(function()
				if success then
					if response.StatusCode >= BAD_REQUEST then
						warn(string.format("Uploading table failed with status code: %s", tostring(response.StatusCode)))

						local decodedResponseBody = decodeJSON(response.Body)
						if decodedResponseBody == nil and decodedResponseBody.message then
							warn(decodedResponseBody.message)
							reject("Upload failed (See Output)")
							return
						end

						reject("Upload failed")
						return
					end

					resolve()
				else
					warn(string.format("Uploading table failed with HTTP error: %s", tostring(response.HttpError)))
					reject("Upload failed (See Output)")
				end
			end)
		end)
	end)
end

--[[Takes a list of role-names as returned by the translationroles endpoint,
	and returns true if one of them grants the current user permission to edit
	the cloud table.  At the moment this is if any of them are "owner" or "translator" ]]
local function rolesGivePermission(roles)
	for _,role in ipairs(roles) do
		if role == "owner" or role == "translator" then
			return true
		end
	end
	return false
end

--[[
	Uses the translation-roles endpoint to determine if the current user has permission
	to edit/view the cloud table for the given gameId.

	Returns a promise that resolves if the user has permssions, and rejects in any other case,
	error or successfully determined no permission.
]]
local function GetTranslationRolesPermission(gameId)
	-- Opening a placefile from disk gives you gameId=0, we should not ask the server
	-- in that case whether we have permission to edit, but otherwise, we have to.
	-- Also the server automatically rejects negative numbers, so let's leave the server
	-- alone if the developer types game:SetUniverseId(-1)
	if gameId <= 0 then
		return Promise.reject("GameId non-positive")
	else
		return Promise.new(function(resolve, reject)
			local Url = TranslationRolesUrl
				.."v1/game-localization-roles/games/"
				..urlEncode(gameId)
				.."/current-user/roles"

			HttpService:RequestInternal({
				Url = Url,
				Method = "GET",
				CachePolicy = Enum.HttpCachePolicy.None,
				RequestType = Enum.HttpRequestType.Localization,
			}):Start(function(success, response)
				spawn(function()
					if success then
						if response.StatusCode >= BAD_REQUEST then
							reject("Permissions request for cloud table failed")
							return
						end

						local decodedResponseBody = decodeJSON(response.Body)

						if decodedResponseBody and
							decodedResponseBody.data and
							rolesGivePermission(decodedResponseBody.data)
						then
							resolve()
						else
							reject("Current user does not have permission to edit cloud table")
						end
					else
						reject("Permissions request for cloud table failed")
					end
				end)
			end)
		end)
	end
end

--[[
	Uses the translation-roles endpoint to determine if the table is available.

	Returns a promise that resolves with a boolean argument (which is true if the request
	successfully gave back a tableid)
]]
local function CheckTableAvailability(gameId)
	if currentTableId ~= nil and currentGameId == gameId then
		return Promise.resolve(true)
	else
		return GetTranslationRolesPermission(gameId):andThen(
			function()
				return Promise.resolve(true)
			end
		)
	end
end

--[[
	Downloads the web-based table for this game, creates it if it doesn't exist.
	Upon success, calls resolve(localizationTable) passing it a
	LocalizationTable object.

	Upon any error, calls reject() passing it an error message string.
]]
local function DownloadGameTable(gameId)
	if currentTableId ~= nil and currentGameId == gameId then
		return DownloadGameTableWithId(gameId, currentTableId)
	else
		return Promise.new(
			function(resolve, reject)
				GetOrCreateGameTable(gameId)
					:andThen(
						function(tableInfo)
							currentTableId = tableInfo.autoLocalizationTableId
							currentGameId = gameId
							DownloadGameTableWithId(gameId, tableInfo.autoLocalizationTableId)
								:andThen(
									function(table)
										resolve(table)
									end,
									reject
								)
						end,
						reject
					)
			end
		)
	end
end

--[[
	Takes a list of patches, spawns an upload for each patch.
	Return the promsie that all the uplaods succeed.
]]
local function UploadPatchesToTableId(gameId, patches, tableId)
	local uploadPromiseList = {}

	for _, patch in pairs(patches) do
		table.insert(uploadPromiseList, UploadPatchToTableId(gameId, patch, tableId))
	end

	return Promise.all(uploadPromiseList)
end

--[[
	UploadPatch() takes a patchInfo object, which is expected object to contain
	a function patchInfo.makePatch()

	UploadPatch() returns a promise that resolves with no arguments upon success.
]]
local function UploadPatch(gameId, patchInfo)
	local patches = PatchInfo.SplitByLimits(
		patchInfo.makePatch(),
		LocalizationTableUploadRowMax,
		LocalizationTableUploadTranslationMax)

	if currentTableId ~= nil and currentGameId == gameId then
		return UploadPatchesToTableId(gameId, patches, currentTableId)
	else
		return Promise.new(function(resolve, reject)
			GetOrCreateGameTable(gameId):andThen(
				function(tableInfo)
					currentTableId = tableInfo.autoLocalizationTableId
					currentGameId = gameId
					UploadPatchesToTableId(gameId, patches, currentTableId)
						:andThen(resolve, reject)
				end
			)
		end)
	end
end

return {
	UploadPatch = UploadPatch,
	DownloadGameTable = DownloadGameTable,
	UpdateGameTableInfo = UpdateGameTableInfo,
	CheckTableAvailability = CheckTableAvailability,
}

end
