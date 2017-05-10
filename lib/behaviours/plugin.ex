defmodule Plugin do

  # Each Plugin should implement an on_message function.
  @callback on_message(message :: term, channel :: term, from :: term) :: any

  # Optional callback to execute when the plugin starts.
  @callback initialize() :: any

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour Plugin
      use GenServer

      #-------------------------------------------------------------------------
      # Insert the GenServer interface methods.

      def init(args) do
        SlackManager.add_handler self()
        initialize()
        {:ok, args}
      end

      def start_link(args) do
        GenServer.start_link(__MODULE__, [args], [{:name, __MODULE__}])
      end

      def handle_info(message = %{type: "message", text: text, user: from}, state) do
        IO.inspect message
        reply = on_message(text, message.channel, from)
        case reply do
          {:ok, reply}     ->
            SlackManager.send_message("#{reply}", message.channel)
          {:error, reason} ->
            IO.puts "Error in plugin #{reason}"
          {:noreply}       ->
            :noop
        end
        {:noreply, state}
      end

      def handle_info(m,state) do
        {:noreply, state}
      end

      # End of GenServer interface methods.
      #-------------------------------------------------------------------------

      def initialize(), do: :ok
      defoverridable initialize: 0
    end
  end
end
