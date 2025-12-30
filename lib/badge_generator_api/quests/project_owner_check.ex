defmodule BadgeGeneratorApi.Quests.ProjectOwnerCheck do
  use Ash.Policy.SimpleCheck

  require Ecto.UUID
  alias BadgeGeneratorApi.Repo

  import Ecto.Query, only: [from: 1, limit: 2, where: 3]

  @impl true
  def describe(_opts), do: "project must belong to the current business"

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    # Get inputs from the changeset
    project_id = Ash.Changeset.get_attribute(changeset, :project_id)
    actor_id = if actor, do: actor.id, else: nil

    if project_id && actor_id do
      # Cast to correct Ecto types
      casted_project_id = Ecto.UUID.cast!(project_id)
      casted_actor_id = Ecto.UUID.cast!(actor_id)

      # 1. Build the Ecto.Query using the imported functions
      query =
        from(p in BadgeGeneratorApi.Projects.Project)
        |> where([p], p.id == ^casted_project_id and p.business_id == ^casted_actor_id)
        |> limit(1)

      # 2. Execute the query directly with the Repo
      case Repo.all(query) do
        [] ->
          IO.puts("\n!!! POLICY FAIL: Project Not Found with BOTH IDs in Repo !!!")
          false

        [_ | _] ->
          IO.puts("\n!!! POLICY PASS: Project FOUND in Repo !!!")
          true

        {:error, reason} ->
          IO.inspect(reason, label: "!!! CRITICAL DB ERROR DURING POLICY CHECK !!!")
          false
      end
    else
      false
    end
  end

  def match?(_, _, _), do: false
end
