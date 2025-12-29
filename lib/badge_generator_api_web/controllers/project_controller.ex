defmodule BadgeGeneratorApiWeb.ProjectController do
  use BadgeGeneratorApiWeb, :controller

  alias Ash
  alias BadgeGeneratorApi.Projects.Project
  import Ash.Query

  plug BadgeGeneratorApiWeb.Plugs.ApiKeyAuth

  # GET /projects
  def list(conn, _params) do
    current_business = conn.assigns.current_business

    result =
      Project
      |> Ash.Query.for_read(:list, %{}, actor: current_business)
      |> Ash.read(actor: current_business)

    case result do
      {:ok, projects} ->
        mapped =
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

        json(conn, mapped)

      {:error, err} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: err.class |> to_string(),
          message: Exception.message(err),
          details: Enum.map(err.errors, &Exception.message/1)
        })
    end
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
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: err.class |> to_string(),
          message: Exception.message(err),
          details: Enum.map(err.errors, &Exception.message/1)
        })
    end
  end

  # GET /projects/:id
  def show(conn, %{"id" => id}) do
    actor = conn.assigns.current_business

    if valid_uuid?(id) do
      result =
        Project
        |> filter(id == ^id)
        |> for_read(:get)
        |> Ash.read(actor: actor)

      case result do
        {:ok, [project | _]} ->
          json(conn, %{
            id: project.id,
            name: project.name,
            description: project.description,
            created_at: project.created_at,
            updated_at: project.updated_at,
            business_id: project.business_id
          })

        {:ok, []} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Project not found"})

        {:error, err} ->
          conn
          |> put_status(:bad_request)
          |> json(%{
            error: err.class |> to_string(),
            message: Exception.message(err),
            details: Enum.map(err.errors, &Exception.message/1)
          })
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid project id format"})
    end
  end

  # PUT /projects/:id
  def update(conn, %{"id" => id} = params) do
    actor = conn.assigns.current_business

    if valid_uuid?(id) do
      project =
        Project
        |> filter(id == ^id)
        |> for_read(:get)
        |> Ash.read!(actor: actor)
        |> List.first()

      update_params =
        params
        |> Map.delete("id")
        |> Map.delete(:id)

      if project do
        case Ash.update(project, update_params, actor: actor) do
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
            conn
            |> put_status(:bad_request)
            |> json(%{
              error: err.class |> to_string(),
              message: Exception.message(err),
              details: Enum.map(err.errors, &Exception.message/1)
            })
        end
      else
        conn
        |> put_status(:not_found)
        |> json(%{error: "Project not found"})
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid project id format"})
    end
  end

  # DELETE /projects/:id
  def delete(conn, %{"id" => id}) do
    actor = conn.assigns.current_business

    if valid_uuid?(id) do
      project =
        Project
        |> filter(id == ^id)
        |> for_read(:get)
        |> Ash.read!(actor: actor)
        |> List.first()

      if project do
        case Ash.destroy(project, actor: actor) do
          {:ok, _} ->
            json(conn, %{message: "Project deleted successfully"})

          :ok ->
            json(conn, %{message: "Project deleted successfully"})

          {:error, err} ->
            conn
            |> put_status(:bad_request)
            |> json(%{
              error: err.class |> to_string(),
              message: Exception.message(err),
              details: Enum.map(err.errors, &Exception.message/1)
            })
        end
      else
        conn
        |> put_status(:not_found)
        |> json(%{error: "Project not found"})
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid project id format"})
    end
  end

  # private helper for uuid validation
  defp valid_uuid?(id) do
    Regex.match?(~r/^[0-9a-fA-F\-]{36}$/, id)
  end
end
