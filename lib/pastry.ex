defmodule Pastry do
  use GenServer
 
  #Initiate GenServer
  def start_link(s) do
    test=GenServer.start_link(__MODULE__,s)
    IO.inspect(test)
  end
 
  #Set the initial state for each of the actors
  def init(s) do
    IO.puts "Inside Pastry init #{s}"
    hashed_id=:crypto.hash(:md5, "#{s}}") |> Base.encode16
    #IO.puts(hashed_id)
    state= %{:pid=>self(),:nodeId=>hashed_id,:leaf_set=>%{:smaller=>[],:larger=>[]},:routing_set=>[],:neigh_list=>[],:t_neigh=>[],:count=>0}
    #IO.inspect(state)
    {:ok,state}
  end

  def setcount(pid, count) do
    GenServer.call(pid, {:count, count})
  end

  def handle_call({:count, count},_from,state) do
    IO.puts "setting the count"
    state = Map.put(state, :count, count)
    IO.inspect(state)
    {:reply, state,state}
  end

  def get_state(pid) do
    GenServer.call(pid, {:state})
  end
  
  def handle_call({:state},_from,state) do
    my_neighbour = Map.get(state,:neigh_list)
    {:reply, state, state}
  end
  #setting leaf set

  #Set the state of leaf_list for an actor
  def set_leaf(pid, leafMap) do
    GenServer.call(pid, {:leafSet, leafMap})
  end
  
  def handle_call({:leafSet,leafMap},_from,state) do
    IO.puts "Leaf Set"
    state = Map.put(state, :leaf_set, leafMap)
    IO.inspect(state)
    {:reply, state,state}
  end

 
  #Set the state of routing_set for an actor
  def set_routingSet(pid, routing_set) do
    GenServer.call(pid, {:routing_set, routing_set})
  end
  
  def handle_call({:routing_set,routing_set},_from,state) do
    IO.puts "I am setting routing_set"
    state = Map.put(state, :routing_set, routing_set)
 
    {:reply, state,state}
  end 

  def pickNode(key, pid,nodeList,hop,state) do
     #state=Pastry.get_state(pid)
     #count=Map.get(state,:count)
     #count=count+1
     #Pastry.setcount(pid,count)
     leaf=Map.get(state,:leaf_set)
     routing_table=Map.get(state,:routing_set)
     IO.inspect(routing_table)
     leaf_small=Map.get(leaf,:smaller)
     leaf_large=Map.get(leaf,:larger)
     leaf_list=leaf_small ++ leaf_large
     smallest=List.first(leaf_small)
     largest=Enum.take(leaf_large,-1)
  
     #IO.inspect(smallest <= key)
     #IO.inspect(key <= List.first(largest))
      if smallest <= key && key <= List.first(largest) do
        IO.puts("leaf comparsion")
        for x <- leaf_list do
           #IO.inspect(x)
             if(x==key) do
                process_id=Project3.getProcessId(nodeList,x)
                IO.puts("Finally in leaf set of #{x} ... Message hello has reached ")
                IO.inspect(process_id)
                hop=hop+1
                #state=Pastry.get_state(Enum.at(Enum.at(process_id,0),0))
                pid=Enum.at(Enum.at(process_id,0),0)
                state=Pastry.get_state(pid)
                 count=Map.get(state,:count)
                 count=count+hop
                 Pastry.setcount(pid,count)
                IO.puts("the value of hop is #{hop}")
             end
          end
         
        else 
            routing_table|>Enum.with_index|>Enum.find(fn({s,i}) ->
             match = String.slice(key,0..length(routing_table)-i-1)
             row=Enum.at(routing_table,i)
             IO.inspect(row)
             x=""
             if(length(row)>0) do
                row |> Enum.find(fn(t) ->
                #row_key=String.slice(t,0..length(routing_table)-i-1)   
                if String.starts_with?t, match do
                  IO.puts "I will call pic node here with #{t}"
                  if(key==t) do
                     #IO.puts("reached")
                     hop=hop+1
                     process_id=Project3.getProcessId(nodeList,t)
                     IO.puts("Message hello has reached .... #{t} .... , #{hop} ")
                     IO.inspect(process_id)
                      pid=Enum.at(Enum.at(process_id,0),0)
                      state=Pastry.get_state(pid)
                      count=Map.get(state,:count)
                      count=count+hop
                      Pastry.setcount(pid,count)
                     true
                  else
                  pick_id=Project3.getProcessId(nodeList,t)
                  if(pid==t) do
                    IO.puts "prcoess id picked given are same"
                  end
                  state=Pastry.get_state(Enum.at(Enum.at(pick_id,0),0))
                  Pastry.pickNode(key,Enum.at(Enum.at(pick_id,0),0),nodeList,hop+1,state)
                  true
                  end
                end
              end)
  
             end
         
            end)
        end
       
        
  end
  #numrequest method
  def forward(pid,message,key,numReq)do
    state=Pastry.get_state(pid)
    count=Map.get(state,:reqCount)
    if(count < numReq) do
      IO.inspect(pid)
      GenServer.cast(pid,{:deliver,key})
      #:timer.sleep(100)
      IO.puts "calling myself"
      :timer.sleep(120000)
    end
  end
  #casting picknode
  def genPickNode(pid,nodeId,nodeList,hop,numReq,list,message) do
    :timer.sleep(200)   
    Enum.map(1..numReq, fn(t) ->
      key=Enum.random(list--[nodeId])
      IO.puts("this pid is picked as current node with #{key} key")
      #IO.inspect(pid)
      GenServer.cast(pid,{:pickNextNode,key,nodeList,hop})
      end)
   
  end

  def handle_cast({:pickNextNode,key,nodeList,hop},state) do
    pid=Map.get(state,:pid)
    nodeID=Map.get(state,:nodeId)
    #state=Map.get(state,:neigh_list)
    IO.puts("I am going inside cast process")
    #IO.inspect(pid)
    Pastry.pickNode(key, pid,nodeList,hop,state) 
    {:noreply, state}
  end
  


end

