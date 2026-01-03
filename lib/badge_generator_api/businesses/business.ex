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
        after_action(fn _changeset, business, _context ->
          # 1. Calculate expiration
          expires = DateTime.utc_now() |> DateTime.add(90 * 24 * 60 * 60, :second)

          # 2. Use a Changeset to be explicit
          # This ensures params and options are kept separate
          BadgeGeneratorApi.Businesses.BusinessAPIKey
          |> Ash.Changeset.for_create(:create, %{expired_at: expires}, actor: business)
          # Internal system call, bypass policies
          |> Ash.create(authorize?: false)
          |> case do
            {:ok, key} ->
              # Attach the raw key so it shows up in your controller response
              {:ok, Map.put(business, :raw_api_key, key.raw_key)}

            {:error, e} ->
              # If key creation fails, the whole registration rolls back
              {:error, e}
          end
        end)
      )
    end

    update :update_profile do
      accept([:name])
    end
  end
end
