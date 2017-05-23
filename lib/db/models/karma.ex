defmodule Slackbot.Karma do

   use Ecto.Schema

  alias Slackbot.Repo, as: Repo
  require Ecto.Query 
  alias Slackbot.Karma, as: Karma

  schema "karma" do
    field :username, :string
    field :karma,    :integer
  end

  def changeset(karma, params \\ %{}) do
    karma
    |> Ecto.Changeset.cast(params, [:username, :karma])
    |> Ecto.Changeset.validate_required([:username, :karma])
    |> Ecto.Changeset.unique_constraint(:username)
  end

  #####################
  # Internal Wrappers #
  #####################

  defp get_karma(username) do
    rec = Karma |> Repo.get_by(username: username) 
    case rec do
      nil                      -> {:err, "user not found"}
      %{username: u, karma: k} -> {:ok, u, k}
    end
  end

  defp update_karma(username, delta \\ 1) do
    # Check if the user exists, if not, create.
    exists? = Karma 
             |> Ecto.Query.where(username: ^username) 
             |> Slackbot.Repo.all 
             |> Enum.count
             |> (fn(c) -> c > 0 end).()
    if exists? do
      Karma 
      |> Ecto.Query.where(username: ^username) 
      |> Slackbot.Repo.update_all(inc: [karma: delta])
    else
      rec = %Karma{}
      cs  = Slackbot.Karma.changeset(rec, %{username: username, karma: delta})
      Slackbot.Repo.insert(cs)      
    end
  end

  defp tail(n, order) do
    Karma 
    |> Ecto.Query.order_by([{^order, :karma}]) 
    |> Ecto.Query.limit(^n) 
    |> Slackbot.Repo.all    
  end

  #############
  # Interface #
  #############

  def increment(username), do: update_karma(username, 1)

  def decrement(username), do: update_karma(username, -1)

  def top(n), do: tail(n, :desc)

  def bottom(n), do: tail(n, :asc)

  def get(username), do: get_karma(username)
end