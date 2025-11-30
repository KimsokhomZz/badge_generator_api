defmodule BadgeGeneratorApi.Accounts.CompanyAPIKey do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Accounts,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("company_api_keys")
    repo(BadgeGeneratorApi.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:api_key, :string, allow_nil?: false)
    attribute(:expires_at, :utc_datetime)
  end

  relationships do
    belongs_to :company, BadgeGeneratorApi.Accounts.Company
  end

  actions do
    defaults([:read])

    create :generate do
      argument(:company_id, :uuid, allow_nil?: false)

      change(set_attribute(:company_id, arg(:company_id)))
      change(set_attribute(:api_key, &__MODULE__.generate_key/2))
    end
  end

  def generate_key(_changeset, _context) do
    :crypto.strong_rand_bytes(24) |> Base.url_encode64(padding: false)
  end
end
