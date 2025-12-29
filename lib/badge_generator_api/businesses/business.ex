defmodule BadgeGeneratorApi.Businesses.Business do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Businesses,
    data_layer: AshPostgres.DataLayer

  postgres do
    table("businesses")
    repo(BadgeGeneratorApi.Repo)
  end

  # --- ATTRIBUTES ---
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

    create_timestamp(:created_at)
    update_timestamp(:updated_at)

  end


  # --- IDENTITIES ---
  identities do
    identity(:unique_email, [:email])
  end


  # --- RELATIONSHIPS ---
  relationships do
    has_many :api_keys, BadgeGeneratorApi.Businesses.BusinessAPIKey,
      destination_attribute: :business_id
  end


  # --- ACTIONS ---
  actions do
    defaults([:read, :destroy])

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
