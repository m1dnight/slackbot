defmodule Slackbot.Repo.Migrations.CreateOrderlist do
  use Ecto.Migration

  def change do
    create table(:order_lists) do
      add :week, :integer
      add :open, :boolean
      timestamps
    end
    create unique_index(:order_lists, [:week])
  end
end
