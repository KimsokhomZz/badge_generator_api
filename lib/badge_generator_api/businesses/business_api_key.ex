defmodule BadgeGeneratorApi.Businesses.BusinessAPIKey do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Businesses,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("business_api_keys")
    repo(BadgeGeneratorApi.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    attribute :api_key_hash, :string do
      sensitive?(true)
      allow_nil?(false)
      constraints(min_length: 20)
    end

    attribute :is_active, :boolean do
      default(true)
    end

    attribute :expired_at, :utc_datetime do
      allow_nil?(false)
    end

    create_timestamp(:created_at)
  end

  relationships do
    belongs_to :business, BadgeGeneratorApi.Businesses.Business
  end

  actions do
    defaults([:read])

    create :issue_key do
      accept([:business_id, :api_key_hash, :expired_at])
    end

    update :revoke do
      change(set_attribute(:is_active, false))
    end
  end
end
