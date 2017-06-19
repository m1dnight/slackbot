defmodule Slackbot.Repo.Migrations.CreateKarma do
  use Ecto.Migration

  def change do
    create table(:karma) do
      add :subject, :string
      add :karma,    :integer
    end
    create unique_index(:karma, [:subject])
  end
end
