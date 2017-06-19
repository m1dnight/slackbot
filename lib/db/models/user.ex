defmodule Slackbot.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Slackbot.Repo
  alias Slackbot.User

  schema "users" do
    field :name, :string
  end

  def changeset(model, params \\ %{}) do
      model 
      |> cast(params, [:name])
      |> validate_required([:name])
      |> unique_constraint(:name)
  end


  def create(username) do
      changeset = User.changeset(%User{}, %{name: username})
      Repo.insert(changeset)
    end
end