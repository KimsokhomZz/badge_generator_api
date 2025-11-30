defmodule BadgeGeneratorApi.Businesses.Business do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Businesses,
    data_layer: AshPostgres.DataLayer

  # extensions: [AshAuthentication]

  postgres do
    table("businesses")
    repo(BadgeGeneratorApi.Repo)
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

    # attribute :password_hash, :string do
    #   allow_nil?(true)
    #   sensitive?(true)
    #   writable?(true)
    # end

    # attribute :password, :string do
    #   sensitive?(true)
    #   allow_nil?(false)
    #   writable?(true)
    # end

    create_timestamp(:created_at)
    update_timestamp(:updated_at)

    # Virtual field to return raw API key after creation
    # attribute :raw_api_key, :string do
    #   allow_nil?(true)
    #   writable?(false)
    #   public?(true)
    # end
    # attribute(:raw_api_key, :string,
    #   persistent?: false,
    #   allow_nil?: true,
    #   writable?: false,
    #   public?: true
    # )
  end

  identities do
    identity(:unique_email, [:email])
  end

  relationships do
    has_many :api_keys, BadgeGeneratorApi.Businesses.BusinessAPIKey,
      destination_attribute: :business_id
  end

  actions do
    defaults([:read, :destroy])

    # create :register do
    #   accept([:name, :email])

    #   change(
    #     after_action(fn changeset, business ->
    #       # business is the created Business struct
    #       case BadgeGeneratorApi.Businesses.APIKeyService.issue_api_key(business) do
    #         {:ok, raw_key} ->
    #           # attach raw key temporarily to return in JSON
    #           {:ok, Map.put(business, :raw_api_key, raw_key)}

    #         {:error, reason} ->
    #           {:error, "Failed to issue API key: #{inspect(reason)}"}
    #       end
    #     end)
    #   )
    # end
    create :register do
      accept([:name, :email])

      change(
        after_action(fn changeset, business, _context ->
          # business is the created Business struct
          case BadgeGeneratorApi.Businesses.APIKeyService.issue_api_key(business) do
            {:ok, raw_key} ->
              # attach raw key temporarily to return in JSON
              {:ok, Map.put(business, :raw_api_key, raw_key)}

            {:error, reason} ->
              {:error, "Failed to issue API key: #{inspect(reason)}"}
          end
        end)
      )
    end

    update :update_profile do
      accept([:name])
    end
  end
end
