defmodule BadgeGeneratorApi.Businesses.BusinessAPIKey do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Businesses,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("business_api_keys")
    repo(BadgeGeneratorApi.Repo)
  end

  attributes do
    uuid_primary_key(:id)

    # This stores the Bcrypt hash
    attribute :hashed_key, :string do
      sensitive?(true)
      allow_nil?(false)
    end

    # For identification in the UI (display like "Key ending in ...8a2b")
    attribute :last_4, :string do
      allow_nil?(false)
    end

    attribute :is_active, :boolean do
      default(true)
      allow_nil?(false)
    end

    attribute :expired_at, :utc_datetime do
      allow_nil?(false)
    end

    create_timestamp(:created_at)
  end

  # We use this virtual attribute to pass the raw key to the controller ONLY ONCE
  calculations do
    calculate(:raw_key, :string, expr(nil))
  end

  relationships do
    belongs_to :business, BadgeGeneratorApi.Businesses.Business, allow_nil?: false
  end

  actions do
    defaults([:read])

    # POST /apikey/create
    create :create do
      primary?(true)
      accept([:expired_at])
      change(set_attribute(:business_id, actor(:id)))
      change(BadgeGeneratorApi.Businesses.GenerateHashedKey)
    end

    # POST /apikey/:id/rotate
    update :rotate do
      require_atomic?(false)
      accept([:expired_at])
      change(BadgeGeneratorApi.Businesses.GenerateHashedKey)
    end

    # PATCH /apikey/:id/disable
    update :revoke do
      accept([])
      change(set_attribute(:is_active, false))
    end
  end

  policies do
    policy action_type(:create) do
      authorize_if(actor_present())
    end

    policy action_type([:read, :update]) do
      authorize_if(expr(business_id == ^actor(:id)))
    end
  end
end
