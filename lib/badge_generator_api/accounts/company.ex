defmodule BadgeGeneratorApi.Accounts.Company do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("companies")
    repo(BadgeGeneratorApi.Repo)
  end

  attributes do
    uuid_primary_key(:id)
    attribute(:name, :string, allow_nil?: false)
    attribute(:email, :string, allow_nil?: false)
  end

  relationships do
    has_many :api_keys, BadgeGeneratorApi.Accounts.CompanyAPIKey
  end

  actions do
    create(:create,
      primary?: true,
      # <-- THIS IS REQUIRED
      accept: [:name, :email]
    )
  end
end
