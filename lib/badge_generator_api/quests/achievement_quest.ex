defmodule BadgeGeneratorApi.Quests.AchievementQuest do
  use Ash.Resource,
    domain: BadgeGeneratorApi.Businesses,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  alias BadgeGeneratorApi.Projects.Project

  postgres do
    table("achievement_quests")
    repo(BadgeGeneratorApi.Repo)
  end

  # --- ATTRIBUTES ---
  attributes do
    uuid_primary_key(:id)
    attribute(:title, :string, allow_nil?: false)
    attribute(:description, :string)
    attribute(:badge_img_url, :string)
    attribute(:criteria_category, :atom, allow_nil?: false)
    attribute(:criteria_details, :map, allow_nil?: false)
    attribute(:start_at, :utc_datetime)
    attribute(:end_at, :utc_datetime)
    attribute(:is_active, :boolean, default: true)
    timestamps()
  end

  # --- RELATIONSHIPS ---
  relationships do
    belongs_to :project, Project, allow_nil?: false
  end

  # --- ACTIONS ---
  actions do
    defaults([:destroy])

    read :read do
      primary?(true)
      prepare(build(sort: [inserted_at: :desc]))
    end

    create :create_quest do
      accept([
        :title,
        :description,
        :badge_img_url,
        :criteria_details,
        :criteria_category,
        :start_at,
        :end_at,
        :is_active,
        :project_id
      ])

      require_attributes([:title, :criteria_category, :criteria_details, :project_id])
    end

    update :update do
      primary?(true)

      accept([
        :title,
        :description,
        :badge_img_url,
        :criteria_category,
        :criteria_details,
        :start_at,
        :end_at,
        :is_active,
        :project_id
      ])
    end
  end

  # --- POLICIES ---
  policies do
    policy action_type(:read) do
      authorize_if(expr(project.business_id == ^actor(:id)))
    end

    policy action_type(:create) do
      authorize_if(BadgeGeneratorApi.Quests.ProjectOwnerCheck)
    end

    policy action_type([:update, :destroy]) do
      authorize_if(expr(project.business_id == ^actor(:id)))
    end
  end
end
