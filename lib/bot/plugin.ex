defmodule Plugin do

  # Each Plugin should implement an on_message function.
  @callback on_message(message :: term) :: {:ok, response :: term} | {:error, reason :: term}

  def start_link(client) do
    GenServer.start_link(__MODULE__, [client])
  end

  defmacro __using__(_) do
    quote do
      @behaviour Plugin
      use GenServer

      # Insert the GenServer interface methods.
      def init([client]) do
        SlackManager.add_handler client, self()
        {:ok, client}
      end

      def start_link(client) do
        GenServer.start_link(__MODULE__, [client])
      end

      def handle_info(message = %{type: "message", text: text}, client) do
        res = on_message(text)
        case res do
          {:ok, reply}     -> SlackManager.send(client, "#{reply}", message.channel)
          {:error, reason} -> IO.puts "Error in plugin #{reason}"
          {:noreply}       -> :noop
        end
        {:noreply, client}
      end

      def handle_info(_,client) do
        {:noreply, client}
      end

      def handle_cast(msg, state) do
        # We do this to trick dialyzer to not complain about non-local returns.
        reason = {:bad_cast, msg}
        case :erlang.phash2(1, 1) do
          0 -> exit(reason)
          1 -> {:stop, reason, state}
        end
      end
      # End of GenServer interface methods.
    end
  end
end
