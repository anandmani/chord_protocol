#TODO: handle predecessor, successor = nil
defmodule Participant do
    @moduledoc """
    Participant state so far = %{
      :hashcode,
      :successor => %{:pid, :hashcode},
      :predecessor => %{:pid, :hashcode}
      :num_requests,
      :pending_requests => [request_id1, request_id2],
      :completed_requests => %{
        request_id1: num_hops
      },
      :fingers
    }
    """
    use GenServer

    def start_link(opts) do
      {:ok, pid} = GenServer.start_link(__MODULE__, :ok, opts)
      hashcode = :crypto.hash(:sha, Kernel.inspect(pid)) |> Base.encode16
      set_hashcode(pid, hashcode)
      {pid, hashcode}
    end
    def inspect(server) do
      GenServer.call(server, {:inspect})
    end
    def set_info(node, hashcode, predecessor, successor, fingers) do   #Set hashcode, predecessor and successor. Used to hardcode initial chord config
      GenServer.cast(node, {:set_info, {hashcode, predecessor, successor, fingers}}) 
    end
    def set_hashcode(server, hashcode) do
      GenServer.cast(server, {:set_hashcode, {hashcode}})
    end
    def stablize do
    end
    def create(server) do
      GenServer.cast(server, {:create, {}})
    end
    def join do
    end
    def notify do
    end
    def fix_fingers do
    end
    def check_predecessor do
    end
    def find_successor(server, argument_map) do #argument_map = %{id!, request_id, successor, route_stack, num_hops}
      GenServer.cast(server, {:find_successor, {argument_map}})
    end
    def reply_find_successor(server, argument_map) do #argument_map = %{id!, request_id, successor, route_stack, num_hops}
      GenServer.cast(server, {:reply_find_successor, {argument_map}})
    end
  
    #Server callbacks
    def closest_preceding_node(id) do #Todo
      id
    end
    def handle_find_successor(argument_map, state) do #argument_map = %{id!, request_id, successor, route_stack, num_hops}
      
      isSourceNode? = Map.get(argument_map, :request_id) == nil
      {temp_argument_map, temp_state} = if isSourceNode? == true do
        request_id = System.unique_integer
          {
            %{
            :request_id => request_id,
            :successor => nil,
            :route_stack => Stack.new() |> Stack.push(self()),
            :num_hops => 0
            },
            %{
              :pending_requests => [request_id | state.pending_requests]
            }
          }
      else
        {
          %{
            :route_stack => argument_map.route_stack |> Stack.push(self()),
            :num_hops => argument_map.num_hops + 1
          },
          state
        } 
      end
      argument_map = Map.merge(argument_map, temp_argument_map)
      state = Map.merge(state, temp_state)
  
      maxHashcode = "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
      isKeyWithinSuccessor? =
        if state.hashcode < state.successor.hashcode do   #If the successor is not beyond the end of the circle
          state.hashcode < argument_map.id and argument_map.id < state.successor.hashcode
        else  #If the successor is after the end of the circle
          (state.hashcode < argument_map.id and argument_map.id < maxHashcode) or ("0" < argument_map.id and argument_map.id < state.successor.hashcode)
        end
      if isKeyWithinSuccessor? do
        argument_map = put_in argument_map.successor, state.successor
        {next_hop, updated_route_stack} = Stack.pop(argument_map.route_stack)
        argument_map = put_in argument_map.route_stack, updated_route_stack
        Participant.reply_find_successor(next_hop, argument_map)
      else
        n1 = closest_preceding_node(argument_map.id) #n1 should be pid and not {pid, hashcode}
        Participant.find_successor(n1, argument_map)
      end
      state
    end
  
    def handle_reply_find_successor(argument_map, state) do
      isRouteStackEmpty? = length(argument_map.route_stack) == 0  #The reply has come back to the source
      temp_state = if isRouteStackEmpty? == true do 
        state = update_in state.pending_requests, fn pending_requests ->
          List.delete(pending_requests, argument_map.request_id) 
        end 
        put_in state.completed_requests[argument_map.request_id], argument_map.num_hops
      else
        {next_hop, updated_route_stack} = Stack.pop(argument_map.route_stack)
        argument_map = put_in argument_map.route_stack, updated_route_stack
        Participant.reply_find_successor(next_hop, argument_map)
        state
      end
      Map.merge(state, temp_state)
    end
  
    def init(:ok) do
      {:ok, %{}}
    end
    def handle_cast({method, methodArgs}, state) do
      case method do
        :set_hashcode ->
          {hashcode} = methodArgs
          {:noreply, Map.merge(state, %{:hashcode => hashcode})}
        :set_info -> 
          {hashcode, predecessor, successor, fingers} = methodArgs
          {:noreply, Map.merge(state, %{:hashcode => hashcode, :predecessor => predecessor, :successor => successor, :fingers => fingers})}
        :create ->
          {:noreply, Map.merge(state, %{:predecessor => nil, :successor => %{:pid => self(), :hashcode => state.hashcode} })}
        :find_successor ->
          {argument_map} = methodArgs
          state = handle_find_successor(argument_map, state)
          {:noreply, state} 
        :reply_find_successor ->
          {argument_map} = methodArgs
          state = handle_reply_find_successor(argument_map, state)
          {:noreply, state} 
      end
    end
    def handle_call({:inspect}, _from, state) do
      {:reply, state, state}
    end
  
  end
  
  
# def stabilize(node, chord_ring, hash_map) do
# 	GenServer.cast(node, {:stabilize, {chord_ring, hash_map}})
# end
# # def join(node) do
# #     GenServer.cast(node, {:joinNodes})
# # end

#method == :stabilize ->
# 	IO.inspect(node)
# 	IO.inspect(state.successor)
# 	# cond do
# 	#     elem(Map.get(chord_ring, elem(state.successor, 0)), 0) != Map.get(hash_map, node) ->

# 	# end
# 	IO.inspect(elem(Map.get(chord_ring, elem(state.successor, 0)), 0))
# 	newState = state
# 	{:noreply, newState}

