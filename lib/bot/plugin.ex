defmodule Plugin do
  @behaviour :gen_server

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
      # Each plugin has to implement the GenServer behaviour, so we inject these
      # here.
      def init([client]) do
        SlackManager.add_handler client, self
        {:ok, client}
      end

      def start_link(client) do
        GenServer.start_link(__MODULE__, [client])
      end

      def handle_info(message = %{type: "message", text: text}, client) do
        res = on_message(text)
        case res do
          {:ok, reply}     -> SlackManager.send(client, "#{reply}", message.channel)
          {:error, reason} -> IO.puts "An error occured.."
        end
        {:noreply, client}
      end
      # End of GenServer interface methods.
    end
  end
end
