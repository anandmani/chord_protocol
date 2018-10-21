defmodule Nodes do
    use GenServer

    def start_link(x) do
        {:ok, pid} = GenServer.start_link(__MODULE__,x , [])
        pid
    end

    def set_info(node, chord_ring, hash_map) do
        GenServer.cast(node, {:setInfo, {node, chord_ring, hash_map}})
    end

    def fix_fingers(node, chord_ring, hash_map) do
        GenServer.cast(node, {:fixFingers, {node, chord_ring, hash_map}})
    end
    # def join(node) do
    #     GenServer.cast(node, {:joinNodes})
    # end

    def init(x) do
        {:ok,
            %{
                :index => x,
                :successor => nil, 
                :predecessor => nil,
                :fingers =>
            }
        }
    end

    def handle_cast({method, args}, state) do
        node = elem(args, 0)
        chord_ring = elem(args, 1)
        hash_map = elem(args, 2)
        cond do
            method == :setInfo ->
                neighbors = Map.get(chord_ring, Map.get(hash_map, node))
                successor = %{node => {elem(neighbors, 0), elem(neighbors, 1)}}
                predecessor = %{node => {elem(neighbors, 2), elem(neighbors, 3)}}
                newState = state
                newState = put_in newState.successor, successor
                newState = put_in newState.predecessor, predecessor
                {:noreply, newState}
                set_fingers = fn i ->
                    Map.get(hash_map, node) + 
                Enum.map(1..256, set_fingers)
            method == :fixFinger ->

        end       
    end

    
end