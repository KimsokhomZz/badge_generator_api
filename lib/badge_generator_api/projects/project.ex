defmodule BadgeGeneratorApi.Projects.Project do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Businesses,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table("projects")
    repo(BadgeGeneratorApi.Repo)
  end

  # --- ATTRIBUTES ---
  attributes do
    uuid_primary_key(:id)

    attribute :name, :string do
      allow_nil?(false)
    end

    attribute :description, :string do
      allow_nil?(true)
    end

    create_timestamp(:created_at)
    update_timestamp(:updated_at)
  end

  # --- RELATIONSHIPS ---
  relationships do
    belongs_to :business, BadgeGeneratorApi.Businesses.Business do
      allow_nil?(false)
    end
  end

  # --- POLICIES ---
  policies do
    # Business API key can ONLY access its own projects
    policy action_type(:read) do
      authorize_if(expr(business_id == ^actor(:id)))
    end

    policy action_type(:create) do
      authorize_if(actor_present())
      authorize_if(changing_attributes(business_id: [to: expr(^actor(:id))]))
    end

    policy action_type([:update, :destroy]) do
      authorize_if(expr(business_id == ^actor(:id)))
    end
  end

  # --- ACTIONS ---
  actions do
    default_accept([:name, :description])

    # GET /projects
    read :list do
      filter(expr(business_id == ^actor(:id)))

      prepare(fn query, _ctx ->
        Ash.Query.sort(query, [{:created_at, :desc}])
      end)
    end

    # GET /projects/:id
    read :get do
      primary?(true)
      get?(true)
    end

    # POST /projects
    create :create do
      primary?(true)
      require_attributes([:name])
      accept([:name, :description, :business_id])
    end

    # PUT /projects/:id
    update :update do
      primary?(true)
      accept([:name, :description])
    end

    # DELETE /projects/:id
    destroy :delete do
      primary?(true)
    end
  end
end
