defmodule Plugin do

  # Each Plugin should implement an on_message function.
  @callback on_message(message :: term) :: {:ok, response :: term} | {:error, reason :: term}

  @callback startup(opts :: term) :: {:ok} | {:error, reason :: term}
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
        startup([client])
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

      def handle_info(m,client) do
        {:noreply, client}
      end
      defoverridable handle_info: 2
      # End of GenServer interface methods.

      # Standard behavior of plugins.
      def startup(opts) do
        IO.puts "Default startup behaviour"
        {:noreply}
      end
      defoverridable startup: 1

    end
  end
end
