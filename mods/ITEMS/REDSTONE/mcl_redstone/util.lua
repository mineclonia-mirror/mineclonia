function mcl_redstone._priority_queue()
	local priority_queue = {
		heap = {},
	}

	function priority_queue:enqueue(prio, val)
		table.insert(self.heap, { val = val, prio = prio })

		local i = #self.heap
		while i ~= 1 and self.heap[math.floor(i / 2)].prio > self.heap[i].prio do
			local p = math.floor(i / 2)
			self.heap[i], self.heap[p] = self.heap[p], self.heap[i]
			i = p
		end
	end

	local function heapify(heap, i)
		local l = math.floor(2 * i)
		local r = math.floor(2 * i + 1)
		local min = i

		if l <= #heap and heap[l].prio < heap[i].prio then
			min = l
		end
		if r <= #heap and heap[r].prio < heap[min].prio then
			min = r
		end
		if min ~= i then
			heap[i], heap[min] = heap[min], heap[i]
			heapify(heap, min)
		end
	end

	function priority_queue:dequeue()
		if #self.heap == 0 then
			return nil
		end

		local root = self.heap[1]
		self.heap[1] = self.heap[#self.heap]
		self.heap[#self.heap] = nil
		heapify(self.heap, 1)

		return root.val
	end

	function priority_queue:peek()
		return #self.heap ~= 0 and self.heap[1].val or nil
	end

	function priority_queue:size()
		return #self.heap
	end

	return priority_queue
end

-- "priority queue" that preservers insertion order among entries with equal priority.
-- Implemented as an array of queues. enqueue performs linear search to find the correct queue,
-- so intended use case is when there are just a few distinct priorities.
function mcl_redstone._priority_queue_ordered()
	return {
		_queues = {},
		_size   = 0,
		_is_equal_func  = function(prio1, prio2) return prio1 == prio2 end,
		_less_than_func = function(prio1, prio2) return prio1 < prio2  end,

		_index_of = function(self, priority)
			for idx, entry in ipairs(self._queues) do
				local entry_prio = entry[1]
				if self._is_equal_func(priority, entry_prio) then
					return idx
				end
			end

			return 0
		end,

		init = function(self, is_equal, less_than)
			self._is_equal_func  = is_equal
			self._less_than_func = less_than
		end,

		enqueue = function(self, priority, value)
			local idx = self._index_of(self, priority)

			if idx == 0 then
				local queue = mcl_util.queue()
				queue:enqueue(value)
				table.insert(self._queues, { priority, queue } )

				local function compare(e1, e2)
					return self._less_than_func(e1[1], e2[1])
				end
				table.sort(self._queues, compare)
			else
				local entry = self._queues[idx]
				local queue = entry[2]
				queue:enqueue(value)
			end

			self._size = self._size + 1
		end,

		dequeue = function(self)
			if self._size == 0 then
				return nil
			end

			local entry = self._queues[1]
			local queue = entry[2]
			local value = queue:dequeue()

			if(queue:size() == 0) then
				table.remove(self._queues, 1)
			end

			self._size = self._size - 1
			return value
		end,

		peek = function(self)
			if self._size == 0 then
				return nil
			end

			local entry = self._queues[1]
			local queue = entry[2]
			return queue:peek()
		end,

		size = function(self)
			return self._size
		end,
	}
end

local function get_inventory_data(pos, lists)
	local fullness, slots = 0, 0
	local inv = core.get_inventory({type="node", pos=pos})
	if inv then
		for _, listname in pairs(lists) do
			slots = slots + inv:get_size(listname)
			if not inv:is_empty(listname) then
				for _, stack in pairs(inv:get_list(listname)) do
					if stack then
						fullness = fullness + stack:get_count() / stack:get_stack_max()
					end
				end
			end
		end
	end
	return fullness, slots
end

local function container_signal(fullness, slots)
	-- formula copied from wiki
	return fullness == 0 and 0 or  math.floor(1 + (fullness / slots) * 14)
end

function mcl_redstone.get_measure_container_function(lists)
	return function(pos)
		local fullness, slots = get_inventory_data(pos, lists)
		return container_signal(fullness, slots)
	end
end

function mcl_redstone.get_measure_double_chest_function(side)
	return function(pos, node)
		local other_pos = mcl_util.get_double_container_neighbor_pos(pos, node.param2, side)
		local fullness1, slots1 = get_inventory_data(pos, {"main"})
		local fullness2, slots2 = get_inventory_data(other_pos, {"main"})
		return container_signal(fullness1 + fullness2, slots1 + slots2)
	end
end
