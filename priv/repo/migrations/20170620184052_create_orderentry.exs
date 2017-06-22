defmodule Slackbot.Repo.Migrations.CreateOrderentry do
  use Ecto.Migration

  def change do
    create table(:order_entries) do
      add :value, :string
      add :user, :string
      timestamps
    end
  end
end
