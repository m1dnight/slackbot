defmodule Supervisor.Scheduler do
  @moduledoc false

  use Supervisor

  def start_link(state \\ []) do
    {:ok, _pid} = Supervisor.start_link(__MODULE__, state, [{:name, __MODULE__}])
  end

  def init(_state) do
    children = [
      worker(Scheduler.DishwasherScheduler, [])
    ]
    supervise children, strategy: :one_for_one
  end

end
