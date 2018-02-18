defmodule Manager do
  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(s,w) do
    GenServer.start_link(Manager,{s,w})
  end
  
  ## Server Callbacks

  def init(s,w) do
      {:ok,pid}=spawn(Actor, :actor, [1])
  end
end  