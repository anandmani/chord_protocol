defmodule Chord do
  	use GenServer

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

	def handle_call({:create_node, args}, _, state) do
		{numNodes} = args
		hash_map = createNodes(numNodes)
		sorted_hash_list = hash_map |> Enum.sort_by(&(elem(&1, 1))) 
		IO.puts "hash_map"; IO.inspect hash_map
		chord_ring = createRing(hash_map)
		Enum.map(hash_map, fn {pid, hashcode} -> 
			neighbors = Map.get(chord_ring, Map.get(hash_map, pid))
			successor = %{:pid => elem(neighbors, 3), :hashcode => elem(neighbors, 2)}
			predecessor = %{:pid => elem(neighbors, 1), :hashcode => elem(neighbors, 0)}
      
			set_fingers = fn i ->
					new_hex = List.to_string(Integer.to_charlist(elem(Integer.parse(hashcode, 16), 0) +
					Kernel.trunc(:math.pow(2, i)), 16))
					Enum.find(sorted_hash_list, fn {pid,hashcode} -> hashcode > new_hex end)
			end
			fingers = Enum.map(1..10, set_fingers)
      # IO.puts "fingers"; IO.inspect fingers          
                
			Participant.set_info(pid, hashcode, predecessor, successor, fingers) 
		end)		
		newState = put_in state.chord_ring, chord_ring
		# Enum.map(nodes, fn node -> Nodes.stabilize(node, hash_map, chord_ring) end)
		{:reply, :ok, newState}
  	end

	def createNodes(numNodes) do
		a = 1..numNodes |> Enum.map(fn index -> Participant.start_link([]) end) |> Map.new
		IO.puts "Map.new"; IO.inspect a
		a
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

	def get_hash(node) do
		node_bin = node |> :erlang.pid_to_list |> :erlang.list_to_binary
		:crypto.hash(:sha, node_bin) |> Base.encode16
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
	def start(num_nodes \\ 10, _num_requests \\ 10) do
		{:ok, pid} = Chord.start_link([])
		Process.register(pid, :main)
		Chord.create_node(:main, num_nodes)
		# Chord.join_nodes(numNodes)
	end
end

# {a1, _}= Integer.parse(a, 16)
# 15 |> Integer.to_string(16)