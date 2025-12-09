defmodule BadgeGeneratorApiWeb.ProjectController do
  use BadgeGeneratorApiWeb, :controller

  alias Ash
  alias BadgeGeneratorApi.Projects.Project
  import Ash.Query

  plug BadgeGeneratorApiWeb.Plugs.ApiKeyAuth

  # GET /projects
  def list(conn, _params) do
    current_business = conn.assigns.current_business

    projects =
      Project
      |> Ash.Query.for_read(:list, %{}, actor: current_business)
      |> Ash.read!()

    # Convert each project struct to a map
    result =
      Enum.map(projects, fn project ->
        %{
          id: project.id,
          name: project.name,
          description: project.description,
          created_at: project.created_at,
          updated_at: project.updated_at,
          business_id: project.business_id
        }
      end)

    json(conn, result)
  end

  # POST /projects
  def create(conn, params) do
    actor = conn.assigns.current_business

    # Ensure business_id is set
    params = Map.put(params, "business_id", actor.id)

    case Ash.create(Project, params, actor: actor) do
      {:ok, project} ->
        json(conn, %{
          id: project.id,
          name: project.name,
          description: project.description,
          created_at: project.created_at,
          updated_at: project.updated_at,
          business_id: project.business_id
        })

      {:error, err} ->
        json(conn, %{
          error: err.class |> to_string(),
          message: Exception.message(err),
          details: Enum.map(err.errors, &Exception.message/1)
        })
    end
  end

  # GET /projects/:id
  def show(conn, %{"id" => id}) do
    actor = conn.assigns.current_business

    project =
      Project
      |> filter(id == ^id)
      |> for_read(:get)
      |> Ash.read!(actor: actor)

    # Convert struct to map
    result = %{
      id: project.id,
      name: project.name,
      description: project.description,
      created_at: project.created_at,
      updated_at: project.updated_at,
      business_id: project.business_id
    }

    json(conn, result)
  end

  # PUT /projects/:id
  def update(conn, %{"id" => id} = params) do
    actor = conn.assigns.current_business

    project =
      Project
      |> filter(id == ^id)
      |> for_read(:get)
      |> Ash.read!(actor: actor)
      |> List.first()

    case Ash.update(project, params, actor: actor) do
      {:ok, updated} ->
        result = %{
          id: updated.id,
          name: updated.name,
          description: updated.description,
          created_at: updated.created_at,
          updated_at: updated.updated_at,
          business_id: updated.business_id
        }

        json(conn, result)

      {:error, err} ->
        json(conn, %{
          error: err.class |> to_string(),
          message: Exception.message(err),
          details: Enum.map(err.errors, &Exception.message/1)
        })
    end
  end

  # DELETE /projects/:id
  def delete(conn, %{"id" => id}) do
    actor = conn.assigns.current_business

    project =
      Project
      |> filter(id == ^id)
      |> for_read(:get)
      |> Ash.read!(actor: actor)

    {:ok, _} = Ash.destroy(project, actor: actor)

    json(conn, %{success: true})
  end
end
