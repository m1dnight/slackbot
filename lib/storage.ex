defmodule Storage do
  require Logger
  use GenServer

  def start_link(path \\ "/tmp/data.dat") do
    GenServer.start_link(__MODULE__, path, name: __MODULE__)
  end

  def init(path) do
    ensure_storage(path, Map.new())
    state = read_storage(path)
    {:ok, {state, path}}
  end

  ##############################################################################
  ## API

  def store(key, value) do
    GenServer.cast(__MODULE__, {:store, key, value})
  end

  def read(key) do
    GenServer.call(__MODULE__, {:read, key})
  end

  def apply(key, f) do
    GenServer.call(__MODULE__, {:apply, key, f})
  end

  ##############################################################################
  ## Callbacks

  def handle_cast({:store, key, value}, {state, path}) do
    state_ = Map.put(state, key, value)
    write_storage(state, path)
    {:noreply, {state_, path}}
  end

  def handle_call({:read, key}, _from, {state, path}) do
    if Map.has_key?(state, key) do
      {:reply, {:ok, Map.get(state, key)}, {state, path}}
    else
      {:reply, {:error, :not_found}, {state, path}}
    end
  end

  def handle_call({:apply, key, f}, _from, {state, path}) do
    if Map.has_key?(state, key) do
      state_ = Map.update(state, key, nil, f)
      {:reply, {:ok, Map.get(state_, key)}, {state_, path}}
    else
      {:reply, {:error, :not_found}, {state, path}}
    end
  end

  ##############################################################################
  ## Helpers

  defp ensure_storage(path, initial_state) do
    if read_storage(path) == nil do
      write_storage(initial_state, path)
    end
  end

  defp write_storage(storage, path) do
    bin = :erlang.term_to_binary(storage)
    File.write(path, bin)
  end

  defp read_storage(path) do
    case File.read(path) do
      {:ok, bin} ->
        :erlang.binary_to_term(bin)

      {:error, _e} ->
        nil
    end
  end
end
