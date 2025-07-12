--// Variables
local RemoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents")
local WordhuntSubmit = RemoteEvents:WaitForChild("WordhuntSubmit")
local WordhuntNext = RemoteEvents:WaitForChild("WordhuntNext")

--// UI Variables
local Main = script.Parent:WaitForChild("Main")
local Main_Wordhunt = script.Parent:WaitForChild("Main_Wordhunt")
local Init_Wordhunt = script.Parent:WaitForChild("Init_Wordhunt")
local WordhuntButton = Main:WaitForChild("Wordhunt")
local NextWordButton = Main_Wordhunt:WaitForChild("NextWord")
local SubmitWordButton = Init_Wordhunt:WaitForChild("Submit")

--// Other Variables
local NextWordDebounce = false

function init()
    if Main.Visible == false then
		Main.Visible = true
	end
end

init()

WordhuntButton.MouseButton1Click:Connect(function()
	if Init_Wordhunt.Visible == false then
		Init_Wordhunt.Visible = true
		Main.Visible = false
	end
end)

SubmitWordButton.MouseButton1Click:Connect(function()
	if string.len(Init_Wordhunt.Row1.Text) == 4
		and string.len(Init_Wordhunt.Row2.Text) == 4 
		and string.len(Init_Wordhunt.Row3.Text) == 4
		and string.len(Init_Wordhunt.Row4.Text) == 4 then
		
		if Main_Wordhunt.Visible == false then
			Main_Wordhunt.Visible = true
			Init_Wordhunt.Visible = false
			WordhuntSubmit:FireServer(Init_Wordhunt.Row1.Text, Init_Wordhunt.Row2.Text, Init_Wordhunt.Row3.Text, Init_Wordhunt.Row4.Text)
		end
	end
end)

NextWordButton.MouseButton1Click:Connect(function()
	if NextWordDebounce == false then
		NextWordDebounce = true
		
		--// Hide order of previous word (if visible)
		for _, txt in ipairs(Main_Wordhunt:GetChildren()) do
			if txt:IsA("TextLabel") and txt:FindFirstChild("order") and txt.order.Visible == true then
				txt.order.Visible = false
			end
		end
		
		WordhuntNext:FireServer()
		
		task.wait(0.1)
		NextWordDebounce = false
	end
end)

WordhuntNext.OnClientEvent:Connect(function(word, positions)
	Main_Wordhunt.CurrentWord.Text = word
	
	--// Get the order of the word
	local count = 1
	for _, pos in ipairs(positions) do
		local x, y = pos[1], pos[2]
		local cell = Main_Wordhunt[""..x..y]
		cell.order.Text = count
		cell.order.Visible = true
		
		count += 1
	end
end)

WordhuntSubmit.OnClientEvent:Connect(function(matrix)
	for i = 1, #matrix do
		for j = 1, #matrix[i] do
			Main_Wordhunt[""..i..j].Text = matrix[i][j]
		end
	end
end)
