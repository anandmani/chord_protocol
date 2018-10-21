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
		nodes = createNodes(numNodes)
		hash_map = createHashMap(nodes)
		chord_ring = createRing(nodes, hash_map)
		Enum.map(nodes, fn node -> Nodes.set_info(node, chord_ring, hash_map) end)		
		IO.inspect(nodeState.successor)
		newState = put_in state.chord_ring, chord_ring
		{:reply, :ok, newState}
  	end
  
	def createNodes(numNodes) do
		nodes = []
		nodes ++ Enum.map(1..numNodes, fn x -> Nodes.start_link(x) end)
	end

	def createHashMap(nodes) do
		for a <- nodes, id = a, data = get_hash(a), into: %{} do
            {id, data}
        end
	end

	def createRing(nodes, hash_map) do
		IO.inspect(nodes)	
		hash_list = Map.values(hash_map)

		successor_map = for a <- hash_list, id = a, data = get_successor(hash_list, a, hash_map), into: %{} do
			{id, data}
		end
		predecessor_map = for a <- hash_list, id = a, data = get_predecessor(hash_list, a, hash_map), into: %{} do
			{id, data}
		end
		
		pre_suc_map = Map.merge(predecessor_map, successor_map, 
		fn _k, v1, v2 -> List.to_tuple(Tuple.to_list(v1)++Tuple.to_list(v2)) end)
		IO.inspect(pre_suc_map)
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

defmodule Proj do
	@moduledoc """
	Documentation for Three.
	"""

	def start(numNodes) do
		{:ok, pid} = Chord.start_link([])
		Process.register(pid, :main)
		Chord.create_node(:main, numNodes)
		# Chord.join_nodes(numNodes)
	end
end


