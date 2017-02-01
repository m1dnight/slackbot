defmodule Plugin do


  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)

      # Insert the functions for the GenServer.
      def start_link(client) do
        GenServer.start_link(__MODULE__, [client])
      end
      def init([client]) do
        SlackManager.add_handler client, self
        {:ok, client}
      end
    end
  end

  defmacro on_message(pattern, do: body) do
    quote do
      def handle_info(message = %{type: "message", text: <<unquote(pattern)::utf8, _::bitstring>>}, client) do
        var!(c) = client
        var!(m) = message
        unquote(body)
        {:noreply, client}
      end
    end
  end

  defmacro reply(text) do
    quote do
      SlackManager.send(var!(c), unquote(text), var!(m).channel)
    end
  end

end
