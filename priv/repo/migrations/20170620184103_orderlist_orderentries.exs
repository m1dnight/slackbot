defmodule Slackbot.Repo.Migrations.OrderlistOrderentries do
  use Ecto.Migration

  def change do
    create table(:order_entries_order_lists) do
      add :order_entry_id, references(:order_entries)
      add :order_list_id, references(:order_lists)
    end

    create unique_index(:order_entries_order_lists, [:order_entry_id, :order_list_id])
  end
end
