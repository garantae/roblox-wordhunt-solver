--// Variables
local HttpService = game:GetService("HttpService")
local WordhuntValues = game:GetService("ReplicatedStorage"):WaitForChild("WordhuntValues")
local RemoteEvents = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents")
local WordhuntSubmit = RemoteEvents:WaitForChild("WordhuntSubmit")
local WordhuntNext = RemoteEvents:WaitForChild("WordhuntNext")
local directions = {
	{-1, 0}, {1, 0}, {0, -1}, {0, 1},     -- up, down, left, right
	{-1, -1}, {-1, 1}, {1, -1}, {1, 1}    -- diagonals
}

--// Other Variables
local words = {}
local valid = {} -- available words in the English dictionary
local prefixSet = {} -- store available prefixes from valid
local currIndex = 1 -- start index for words matrix
local maxRows = 4
local budget = 1/60 -- seconds
local expireTime = 0

function init()
	local function getWords()
		local url = "https://raw.githubusercontent.com/garantae/roblox-wordhunt-solver/main/Collins%20Scrabble%20Words%20(2019).txt"
		local success, response = pcall(function()
			return HttpService:GetAsync(url)
		end)

		-- Fill valid words set
		if success then
			local words = {}
			for word in string.gmatch(response, "[^\r\n]+") do
				word = word:match("^%s*(.-)%s*$")
				table.insert(words, word)
			end
			
			return words
		else
			return nil
		end
	end
	
	local function getPrefixSet(list)
		local prefixSet = {}
		
		for _, word in ipairs(list) do
			for i = 1, #word do
				prefixSet[word:sub(1, i):upper()] = true
			end
		end
		return prefixSet
	end
	
	valid = getWords()
	prefixSet = getPrefixSet(valid)
end

function ResetTimer()
	expireTime = tick() + budget
end

--// For calling at the top of loops
function yieldIfNecessary()
	if tick() >= expireTime then
		task.wait()
		ResetTimer()
	end
end

local function isValid(char)
	return prefixSet[char:upper()] ~= nil
end

local function dfs(matrix, x, y, visited, curr_word, curr_pos, found)
	if #curr_word >= 2 and #curr_word < 8 and table.find(valid, curr_word:upper()) then
		found[curr_word] = curr_pos
	end
	
	visited[x][y] = true
	
	-- For every cell, explore ALL directions
	for _, direction in ipairs(directions) do
		yieldIfNecessary()
		local nx, ny = x + direction[1], y + direction[2]

		-- Check if the new position is within bounds and not visited
		if nx >= 1 and nx <= 4 and ny >= 1 and ny <= 4 and not visited[nx][ny] then
			local new_word = curr_word .. matrix[nx][ny]

			-- Check if the new word is a valid prefix
			if isValid(new_word) then
				local new_positions = {table.unpack(curr_pos)} -- copy current positions
				table.insert(new_positions, {nx, ny}) -- add the new position
				-- recurse into the next step of DFS
				dfs(matrix, nx, ny, visited, new_word, new_positions, found)
			end
		end
	end
	
	-- Backtrack (unmark current cell as visited)
	visited[x][y] = false
end

local function findWords(matrix)
	local found = {}

	-- Create a visited table to track visited cells
	local visited = {}
	for i = 1, 4 do
		visited[i] = {}
	end

	-- Start DFS from each cell
	for i = 1, 4 do
		for j = 1, 4 do
			yieldIfNecessary()
			dfs(matrix, i, j, visited, matrix[i][j], {{i, j}}, found)
		end
	end

	-- Convert the found words from a table to a sorted list
	local words = {}

	-- For each word in found, store the word and its positions
	for word, positions in pairs(found) do
		table.insert(words, {word:upper(), positions})
	end

	-- Sort the words by length (longest first)
	table.sort(words, function(a, b)
		return #a[1] > #b[1] -- sort by word length, longest words first
	end)

	return words
end

WordhuntSubmit.OnServerEvent:Connect(function(player, row1, row2, row3, row4)
	WordhuntValues.Row1.Value = row1
	WordhuntValues.Row2.Value = row2
	WordhuntValues.Row3.Value = row3
	WordhuntValues.Row4.Value = row4

	local matrix = {}
	for i = 1, maxRows do
		matrix[i] = {}

		local str = WordhuntValues["Row"..i].Value
		for j = 1, #str do
			local char = string.sub(str, j, j)
			matrix[i][j] = char:upper()
		end
	end
	
	-- Send the matrix to the client
	WordhuntSubmit:FireClient(player, matrix)

	words = findWords(matrix)

	-- Send the first word and its positions to the client
	if words[currIndex] then
		local word, positions = words[currIndex][1], words[currIndex][2]
		WordhuntNext:FireClient(player, word, positions)
	else
		print("No words found.")
	end
end)

WordhuntNext.OnServerEvent:Connect(function(player)
	if currIndex < #words then
		currIndex = currIndex + 1
		local word, positions = words[currIndex][1], words[currIndex][2]
		WordhuntNext:FireClient(player, word, positions)
	else
		print("No more words to display.")
	end
end)

init()
