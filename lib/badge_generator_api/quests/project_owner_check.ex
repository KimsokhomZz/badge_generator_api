defmodule BadgeGeneratorApi.Quests.ProjectOwnerCheck do
  use Ash.Policy.SimpleCheck
  import Ash.Query

  @impl true
  def describe(_opts), do: "project must belong to the current business"

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    project_id = Ash.Changeset.get_attribute(changeset, :project_id)

    if project_id && actor do
      query =
        BadgeGeneratorApi.Projects.Project
        |> filter(id == ^project_id)

      case Ash.read_one(query, actor: actor) do
        {:ok, %BadgeGeneratorApi.Projects.Project{}} -> true
        {:ok, nil} -> false
        {:error, _} -> false
      end
    else
      false
    end
  end

  def match?(_, _, _), do: false
end
