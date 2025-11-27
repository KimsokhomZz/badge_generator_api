defmodule BadgeGeneratorApi.Businesses.Business do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Businesses,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication]

  postgres do
    table("businesses")
    repo(BadgeGeneratorApi.Repo)
  end

  authentication do
    strategies do
      password :password do
        identity_field(:email)
        hashed_password_field(:password_hash)
        sign_in_tokens_enabled?(false)
      end
    end

    # tokens do
    #   enabled?(true)
    #   token_resource(BadgeGeneratorApi.Businesses.Token)
    #   require_token_presence_for_authentication?(true)
    # end
  end

  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
    end

    attribute :email, :ci_string do
      allow_nil?(false)
      constraints(match: ~r/@/)
      public?(true)
    end

    attribute :password_hash, :string do
      allow_nil?(true)
      sensitive?(true)
      writable?(true)
    end

    attribute :password, :string do
      sensitive?(true)
      allow_nil?(false)
      writable?(true)
    end

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  # calculations do
  #   calculate(:password, :string, expr(nil))
  # end

  identities do
    identity(:unique_email, [:email])
  end

  relationships do
    has_many :api_keys, BadgeGeneratorApi.Businesses.BusinessAPIKey,
      destination_attribute: :business_id
  end

  actions do
    defaults([:read, :destroy])

    create :register do
      accept([:name, :email, :password])
    end

    update :update_profile do
      accept([:name])
    end
  end
end
