#TODO: Find fingers for last node 
#TODO: Verify if fingers are correct

defmodule Chord do
  	use GenServer

		@max_hashcode "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
		def max_hashcode, do: @max_hashcode
		def max_hashcode_integer do
			{int, _} = @max_hashcode |> Integer.parse(16)
			int
		end
	
 	 def start_link(opts) do
		GenServer.start_link(__MODULE__, :ok, opts)
	end

	def create_node(server, numNodes) do
		GenServer.call(server, {:create_node, {numNodes}})
	end

	def init(:ok) do
		{:ok,
		 	%{
				:chord_ring => nil,
				:hash_map => nil
			}}
	end

	@doc """
	hash_map = %{pid1 => hashcode1}
	chord_ring = %{pid1 => {predecessor_hashcode, predecessor_pid, successor_hashcode, successor_pid}}
	sorted_hash_list = [pidX: hashcodeX, pidY: hashcodeY]
  """
	def handle_call({:create_node, args}, _, state) do
		{numNodes} = args
		hash_map = createNodes(numNodes)
		sorted_hash_list = hash_map |> Enum.sort_by(&(elem(&1, 1)))
		chord_ring = createRing(hash_map)
		Enum.map(hash_map, fn {pid, hashcode} -> 
			neighbors = Map.get(chord_ring, Map.get(hash_map, pid))
			successor = %{:pid => elem(neighbors, 3), :hashcode => elem(neighbors, 2)}
			predecessor = %{:pid => elem(neighbors, 1), :hashcode => elem(neighbors, 0)}
			{hashcode_integer, _} = hashcode |> Integer.parse(16)
			set_fingers = fn i ->
					# new_hex = List.to_string(Integer.to_charlist(elem(Integer.parse(hashcode, 16), 0) + Kernel.trunc(:math.pow(2, i)), 16))
					two_power_i = :math.pow(2, i) |> Kernel.trunc
					sum_modulo = (hashcode_integer + two_power_i) |> rem(max_hashcode_integer)
					new_hashcode = sum_modulo |> Integer.to_string(16) |> String.pad_leading(40,"0")

					# IO.puts "new_hashcode #{new_hashcode}"; 
					node_found = Enum.find(sorted_hash_list, fn {pid,hashcode} -> hashcode > new_hashcode end) || hd(sorted_hash_list)
					# IO.puts "code #{new_hashcode}    node #{elem(node_found,1)}"
					# node_found
			end
			# IO.puts "Fingers for #{hashcode}"
			fingers = Enum.map(1..159, set_fingers)
      # IO.puts "fingers"; IO.inspect fingers          
                
			Participant.set_info(pid, hashcode, predecessor, successor, fingers) 
		end)		
		newState = put_in state.chord_ring, chord_ring

		#Testing find_successor
		# IO.puts "hash_map"; IO.inspect hash_map
		# one = hash_map |> Enum.random
		# two = hash_map |> Enum.random
		# IO.puts "Asking #1 to find #2"; IO.inspect one; IO.inspect two;
		# Participant.find_successor(elem(one,0), %{:id => elem(two,1)})

		hash_map |> Map.keys |> Enum.map(fn pid -> 
			IO.puts "Inspecting"; IO.inspect pid;
			Participant.inspect(pid) |> IO.inspect(limit: :infinity)
		end)


		{:reply, :ok, newState}
  	end

	def createNodes(numNodes) do
		1..numNodes |> Enum.map(fn index -> Participant.start_link([]) end) |> Map.new
	end


	def createRing(hash_map) do
		hash_list = Map.values(hash_map) |> Enum.sort
		IO.puts "Sorted list"; IO.inspect hash_list
		successor_map = for a <- hash_list, id = a, data = get_successor(hash_list, a, hash_map), into: %{} do
			{id, data}
		end
		predecessor_map = for a <- hash_list, id = a, data = get_predecessor(hash_list, a, hash_map), into: %{} do
			{id, data}
		end
		pre_suc_map = Map.merge(predecessor_map, successor_map,

		fn _k, v1, v2 -> List.to_tuple(Tuple.to_list(v1)++Tuple.to_list(v2)) end)
	end

	def get_successor(hash_list, node_hash, hash_map) do
		cond do
			node_hash == List.last(hash_list) -> {List.first(hash_list), get_key(hash_map, List.first(hash_list))}
			hd(hash_list) == node_hash -> {List.first(tl(hash_list)), get_key(hash_map, List.first(tl(hash_list)))}
			true -> get_successor(tl(hash_list), node_hash, hash_map)
		end
    end

    def get_predecessor(hash_list, node_hash, hash_map) do
		cond do
			node_hash == List.first(hash_list) -> {List.last(hash_list), get_key(hash_map, List.last(hash_list))}
			List.first(tl(hash_list)) == node_hash -> {hd(hash_list), get_key(hash_map, hd(hash_list))}
			true -> get_predecessor(tl(hash_list), node_hash, hash_map)
		end
	end

	def get_key(hash_map, val) do
		hash_map |> Enum.find(fn {k, v} -> v == val end) |> elem(0)
	end
end

defmodule Three do
	def start(num_nodes \\ 5, _num_requests \\ 10) do
		{:ok, pid} = Chord.start_link([])
		Process.register(pid, :main)
		Chord.create_node(:main, num_nodes)
		# Chord.join_nodes(numNodes)
	end
end


	# # Hashcode modulo
	# a = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
	# {a1, _} = a |> Integer.parse(16)
	# #a1 = 115792089237316195423570985008687907853269984665640564039457584007913129639935,
	# b = "10000000000000000000000000000000000000000000000000000000000000000"
	# {b1, _} = b |> Integer.parse(16)
	# # b1 = 115792089237316195423570985008687907853269984665640564039457584007913129639936,
	# c1 = rem(b1,a1)
	# c1 |> Integer.to_string(16) |> String.pad_leading(64,"0")