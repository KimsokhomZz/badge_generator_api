defmodule BadgeGeneratorApi.Repo.Migrations.AddHashedKeyAndLast4ToBusinessApiKeys do
  use Ecto.Migration

  def change do
    alter table(:business_api_keys) do
      add :hashed_key, :text
      add :last_4, :text
    end

    # If you want to remove the old column
    alter table(:business_api_keys) do
      remove :api_key_hash
    end
  end
end
