defmodule Nodes do
    use GenServer

    def start_link(x) do
        {:ok, pid} = GenServer.start_link(__MODULE__,x , [])
        pid
    end

    def set_info(node, chord_ring, hash_map) do
        GenServer.cast(node, {:setInfo, {chord_ring, hash_map}})
    end

    def stabilize(node, chord_ring, hash_map) do
        GenServer.cast(node, {:stabilize, {chord_ring, hash_map}})
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
                :fingers => nil
            }
        }
    end

    def handle_cast({method, args}, state) do

        node = self()
        chord_ring = elem(args, 0)
        hash_map = elem(args, 1)
        cond do
            method == :setInfo ->
                neighbors = Map.get(chord_ring, Map.get(hash_map, node))
                successor = {elem(neighbors, 2), elem(neighbors, 3)}
                predecessor = {elem(neighbors, 2), elem(neighbors, 3)}
                newState = state
                newState = put_in newState.successor, successor
                newState = put_in newState.predecessor, predecessor
                hash_list = Enum.sort(Map.values(hash_map))
                set_fingers = fn i ->
                    new_hex = List.to_string(Integer.to_charlist(elem(Integer.parse(Map.get(hash_map, node), 16), 0) +
                    Kernel.trunc(:math.pow(2, i)), 16))
                    Enum.find(hash_list, fn x -> x > new_hex end)
                end
                fingers = Enum.map(1..10, set_fingers)
                # IO.inspect(fingers)
                newState = put_in newState.fingers, fingers
                {:noreply, newState}
            method == :stabilize ->
                IO.inspect(node)
                IO.inspect(state.successor)
                # cond do
                #     elem(Map.get(chord_ring, elem(state.successor, 0)), 0) != Map.get(hash_map, node) ->

                # end
                IO.inspect(elem(Map.get(chord_ring, elem(state.successor, 0)), 0))
                newState = state
                {:noreply, newState}
        end
    end


end
