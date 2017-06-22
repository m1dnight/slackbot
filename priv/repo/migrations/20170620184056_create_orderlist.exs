defmodule Slackbot.Repo.Migrations.CreateOrderlist do
  use Ecto.Migration

  def change do
    create table(:order_lists) do
      add :open, :boolean
      timestamps
    end
  end
end
