defmodule Project3 do
  #use Supervisor
  def main(args \\ []) do
    {n,_}=:string.to_integer(Enum.at(to_charlist(args),0))
    {numReq,_}=:string.to_integer(Enum.at(to_charlist(args),1))
    IO.puts "the num request #{numReq} "
    #child_list=[]
    #{:ok,pid}=Node.Supervisor.start_link(n)
    #IO.inspect(pid) #supervisor's pid
    #list=Supervisor.which_children(pid)
    #child_list=(for x <- list, into: [] do
    #  {_,cid,_,_}=x
    # cid
    #end)

    node_list=Enum.map(1..n,fn(s) -> 
        IO.puts "Node initialization and node join process "
        {_,cid}=Pastry.start_link(s) 
        state=Pastry.get_state(cid)
        node_id=Map.get(state,:nodeId)
        [node_id,cid]
        end)
   IO.puts("The child list : ")
   IO.inspect(node_list)
   sorted_list=Enum.sort(node_list)
   IO.puts("Sorted List : ")
   IO.inspect(sorted_list)
   nodeIdList=extractNodeId(sorted_list)
   IO.inspect(nodeIdList)
   Project3.leaf_setting(sorted_list,8)
   Project3.routingSetting(nodeIdList,sorted_list)
   
   #key=Enum.random(nodeIdList)
   #IO.puts("the input key is #{key}")
   nodeIdList|>Enum.each(fn(nodeId) ->
      pid=Project3.getProcessId(sorted_list,nodeId)
      Pastry.genPickNode(Enum.at(Enum.at(pid,0),0),nodeId,sorted_list,0,numReq,nodeIdList,"hello")
     
   end)



   :timer.sleep(6000)
   :ets.new(:count_registry,[:named_table])
   :ets.insert(:count_registry, {"Hop",0})
   IO.puts "THe final state of process"
   nodeIdList|>Enum.each(fn(nodeId) ->
          pid=Project3.getProcessId(sorted_list,nodeId)
          state=Pastry.get_state(Enum.at(Enum.at(pid,0),0))
          #IO.inspect(state)
          count=Map.get(state,:count)
          [{_,totalcount}]=:ets.lookup(:count_registry,"Hop")
          totalcount=totalcount+count
          IO.puts "The current count is #{totalcount}"
          :ets.insert(:count_registry, {"Hop", totalcount})  
 end)
   

 [{_,totalcount}]=:ets.lookup(:count_registry,"Hop")
 IO.puts "the final ets loopup #{totalcount}"
 reqcount=n*numReq
 average=totalcount/reqcount
 IO.puts "Average hop count is #{average}"
  end #End of main
 
  
  #Get process id
  def getProcessId(nodeIdList,node)do
    nodeList=(for x <- nodeIdList, into: [] do
      [head|tail]=x
      if(node==head)do
        tail
      end
     end)
     nodeList=Enum.reject(nodeList, &is_nil/1)
  end

  def leaf_setting(sorted_list,l)do
    sorted_list|>Enum.with_index|>Enum.each(fn({x, i})->
    lower_bound=i-(l/2)
    upper_bound=i+(l/2)
    if lower_bound< 0 do
       lower_bound=0
    end
    if upper_bound>length(sorted_list) do
      upper_bound=length(sorted_list)
    end
    #IO.puts("lower_bound:  #{lower_bound}")
    #IO.puts("the value of index: #{i}")
    #IO.puts("upper_bound:  #{upper_bound}")
    slu=i-1
    if slu<0 do
      slu=0
    end
    smaller=sorted_list|>Enum.slice(round(lower_bound)..slu)
    smaller=(for x <- smaller, into: [] do
      [head|tail]=x
      head
     end)
    #IO.puts("smaller_list: ")
    #IO.inspect(smaller)
    larger=sorted_list|>Enum.slice(i+1..round(upper_bound))
    larger=(for x <- larger, into: [] do
      [head|tail]=x
      head
     end)
   # IO.puts("larger_list: ")
    #IO.inspect(larger)
    map=%{:smaller=>smaller,:larger=>larger}
   # IO.inspect(List.last(x))

    Pastry.set_leaf(List.last(x),map)
    end)
  end
  def extractNodeId(sorted_list)do
    IO.puts("I am in extract nodes")
    nodeList=(for x <- sorted_list, into: [] do
     [head|tail]=x
      head
    end)
    nodeList   
 end

 def routingSetting(nodeIdList,sorted_list)do
  nodeIdList|>Enum.each(fn(x)-> 
  IO.puts("for process #{x}" )  
  nodeIdList=nodeIdList -- [x]  
  routing_Table=Project3.set_routingTable(x,nodeIdList,16,16)
  
  #IO.puts("Routing table")
  #IO.inspect(routing_Table)
  process_id=Project3.getProcessId(sorted_list,x)
  pid=List.first(List.flatten(process_id))
  Pastry.set_routingSet(pid,routing_Table)
  end)
end

  def set_routingTable(nodeId,list,nr,nc)do
    row=[]
    routing_table_temp=[]
    routing_table=Enum.map(nr-1..0 , fn(s) ->
    match = String.slice(nodeId,0..s-1)
    #IO.puts("old List")
   # IO.inspect((length(list)))
   # IO.puts("newList")
    row=set_routingTableROW(match,list,nc)
    #routing_table_temp=routing_table_temp ++ row
    row
    end)
  end
  
  def set_routingTableROW(match,list,nc) do
    col_list=%{0=>"0",1=>"1",2=>"2",3=>"3",4=>"4",5=>"5",6=>"6",7=>"7",8=>"8",9=>"9",10=>"A",11=>"B",12=>"C",13=>"D",14=>"E",15=>"F"}
    #row=[nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil]
   # IO.puts("Match: #{match}")
    oldmatch=match
    row=(for x <- list, into: [] do
      if String.length(match)==String.length(x)  do
     #   IO.puts "I am nil string"
        match=""
      end  
       Enum.reject(Enum.map(col_list,fn{k,v} ->
        if String.starts_with?x, match<>v do
          {k,x}
        end
       end),&is_nil/1)
     end)
    
    #IO.puts("the value of output") 
    row=List.flatten(row)
    row=Enum.reject(row, &is_nil/1)
    map=Enum.into(row,%{})
    row=Enum.map(map,fn{k,v} ->
      v
    end)
    #IO.puts ("I am printing a row")
    #IO.inspect(row)
    # IO.puts("row set_routingTableROW ")
     #IO.inspect(row)
     #IO.puts("list set_routingTableROW ")
     #IO.inspect(list)
     #row=Enum.reject(row, &is_nil/1)
     #IO.puts("newlist set_routingTableROW ")
     #newList=list--row
     #test=[]
     #row=row|>Enum.slice(0..nc)
     #IO.puts("old row: " )
     #IO.puts("old ist:  #{list}")
     #list=[list] -- [row]
     #IO.puts("row: ")
    # IO.inspect(row)
     #IO.puts("new list:  #{list}")
     row
    end
    def nodejoin(processid,sorted_list,node_listId) do
         firstnode=Enum.random(node_listId)
         state=Pastry.get_state(processid)   
         routingtable=Map.get(state,:routing_set)
         fpid=Enum.at(Enum.at(Project3.getProcessId(firstnode),0),0)
         fstate=Pastry.get_state(fpid)
         neighList=Map.get(fstate,:neigh_list)
          #updated the neighlist of the new node with the neiglist of node to which if first contacted
         state=Map.put(state,:neigh_list,neighList)
         Enum.map(1..16,fn(s) -> 
          IO.puts "Node initialization and node join process "
          state=Pastry.get_state(processid)   
          routingtable=Map.get(state,:routing_set)
          row= Project3.fetchRow(fstate,16-s)
          routingtable=routingtable++row
          state=Map.put(state,:routing_set,routingtable)
          fstate=Pastry.get_state(Enum.at(Enum.at(Project3.getProcessId(Enum.random(row)),0),0))
          end)
         Pastry.set_routingSet(processid,routingtable)      
  
      

         
    end
    def fetchRow(nodeId,index) do
      pid=Enum.at(Enum.at(Project3.getProcessId(nodeId),0),0)
      state=Pastry.get_state(pid)
      routing_table=Map.get(state,:routing_set)
      row=Enum.at(routing_table,length(routing_table)-index-1)
      row
    end
     
end







































