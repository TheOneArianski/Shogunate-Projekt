-- Erstellt alle RemoteEvents, bevor andere Skripte sie brauchen.
local RS = game:GetService("ReplicatedStorage")
local folder = Instance.new("Folder")
folder.Name = "Remotes"
for _, name in ipairs({ "ChooseClan", "M1", "Block", "Dash", "M1Anim", "DashStart", "StateUpdate", "RequestReroll", "RerollResult" }) do
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = folder
end
folder.Parent = RS
