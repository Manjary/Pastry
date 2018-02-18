defmodule Talker do
    def loop(count) do
        receive do
            {:next, sender, ref} ->
            send(sender, {:ok, ref, count})
            loop(count + 1)
        end
    end 
end 
defmodule Counter do
    def loop(count) do
        receive do
            {:next} ->
                IO.puts("current count : #{count}")
                loop(count + 1)
        end
    end
end 

defmodule Caller do
    def start(count) do
        spawn(Counter, :loop, [count])
    end
    def next(counter) do
        send(counter, {:next})
    end
end

