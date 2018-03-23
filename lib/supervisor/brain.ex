defmodule Supervisor.Brain do
  use Supervisor

  def start_link(state \\ []) do
    {:ok, _pid} = Supervisor.start_link(__MODULE__, state, [{:name, __MODULE__}])
  end

  def init(_state) do
    children = [
      worker(Brain.Karma, []),
      worker(Brain.Benvolios, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
