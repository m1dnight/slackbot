defmodule Brain.Benvolios do
  require Logger

  def save_order(orderer, order) do
    order = Slackbot.OrderEntry.new_order(order)
    Slackbot.OrderList.store_order(order)
  end

  def forget_order(orderer) do
    GenServer.call __MODULE__, {:forget_order, orderer}
  end

  def get_order(orderer) do
    GenServer.call __MODULE__, {:get_order, orderer}
  end

  def list() do
    GenServer.call __MODULE__, :list
  end

  def clear() do
    GenServer.call __MODULE__, :clear
  end

  #########
  # Calls #
  #########

  def handle_call(:list, _from, state) do
    orders = state
    {:reply, {:ok, orders}, state}
  end

  def handle_call({:get_order, orderer}, _from, state) do
    order = Map.get(state, orderer)
    {:reply, {:ok, order}, state}
  end

  def handle_call({:forget_order, orderer}, _from, state) do
    Logger.debug "Forgetting order for #{orderer}"
    new_state = Map.delete(state, orderer)
    save_orders(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call({:order, orderer, order}, _from, state) do
    Logger.debug "Remembering order #{orderer} - #{order}"
    new_state = Map.put(state, orderer, order)
    save_orders(new_state)
    {:reply, :ok, new_state}
  end

  def handle_call(:clear, _from, _state) do
    Logger.debug "Clearing orders"
    new_state = %{}
    save_orders(new_state)
    {:reply, :ok, new_state}
  end

  ###########
  # Private #
  ###########

  defp save_orders(orders) do
    content = :io_lib.format("~tp.~n", [orders])
    :ok     = :file.write_file(data_backup_file(), content)
  end

  defp read_orders() do
    res = :file.consult(data_backup_file())
    case res do
      {:ok, [orders]} -> {:ok, orders}
      _               -> {:error}
    end
  end

  defp data_backup_file do
    "data/benvolios/benvolios.dat"
  end
end
