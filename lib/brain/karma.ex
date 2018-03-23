defmodule Brain.Karma do
  require Logger
  use GenServer

  def start_link(initial_state \\ []) do
    GenServer.start_link(__MODULE__, [initial_state], name: __MODULE__)
  end

  def init([[]]) do
    Logger.debug("No initial karma state provided, attempting to read from disk")

    case :file.consult(data_backup_file()) do
      {:ok, state} ->
        {:ok, state}

      _ ->
        Logger.warn("No initial karma and can't read backup, starting with empty Karma Brain")
        {:ok, []}
    end
  end

  def init([state]) do
    {:ok, state}
  end

  #############
  # Interface #
  #############

  def increment(subject, amount \\ 1) do
    GenServer.call(__MODULE__, {:change, subject, amount})
  end

  def decrement(subject, amount \\ -1) do
    GenServer.call(__MODULE__, {:change, subject, amount})
  end

  def get(subject) do
    GenServer.call(__MODULE__, {:get, subject})
  end

  #########
  # Calls #
  #########

  def handle_call({:get, subject}, _from, state) do
    {^subject, current_karma} = List.keyfind(state, subject, 0, {subject, 0})
    {:reply, current_karma, state}
  end

  def handle_call({:change, subject, amount}, _from, state) do
    IO.puts("Changing karma")
    {^subject, current_karma} = List.keyfind(state, subject, 0, {subject, 0})
    new_karma = current_karma + amount
    new_state = List.keystore(state, subject, 0, {subject, new_karma})

    content =
      new_state
      |> Enum.map(&[:io_lib.print(&1) | ".\n"])
      |> IO.iodata_to_binary()

    File.write(data_backup_file(), content)
    {:reply, new_karma, new_state}
  end

  ###########
  # Private #
  ###########

  defp data_backup_file do
    "data/karma/backup.dat"
  end
end
