defmodule Slackbot.Karma do

   use Ecto.Schema

  alias Slackbot.Repo, as: Repo
  require Ecto.Query 
  alias Slackbot.Karma, as: Karma

  schema "karma" do
    field :subject, :string
    field :karma,    :integer
  end

  def changeset(karma, params \\ %{}) do
    karma
    |> Ecto.Changeset.cast(params, [:subject, :karma])
    |> Ecto.Changeset.validate_required([:subject, :karma])
    |> Ecto.Changeset.unique_constraint(:subject)
  end

  #####################
  # Internal Wrappers #
  #####################

  defp get_karma(subject) do
    rec = Karma |> Repo.get_by(subject: subject) 
    case rec do
      nil                      -> {:err, "user not found"}
      %{subject: u, karma: k} -> {:ok, u, k}
    end
  end

  defp update_karma(subject, delta \\ 1) do
    # Check if the user exists, if not, create.
    exists? = Karma 
             |> Ecto.Query.where(subject: ^subject) 
             |> Slackbot.Repo.all 
             |> Enum.count
             |> (fn(c) -> c > 0 end).()
    if exists? do
      Karma 
      |> Ecto.Query.where(subject: ^subject) 
      |> Slackbot.Repo.update_all(inc: [karma: delta])
    else
      rec = %Karma{}
      cs  = Slackbot.Karma.changeset(rec, %{subject: subject, karma: delta})
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

  def increment(subject), do: update_karma(subject, 1)

  def decrement(subject), do: update_karma(subject, -1)

  def top(n), do: tail(n, :desc)

  def bottom(n), do: tail(n, :asc)

  def get(subject), do: get_karma(subject)
end