defmodule BadgeGeneratorApiWeb.QuestController do
  use BadgeGeneratorApiWeb, :controller

  alias Ash
  alias BadgeGeneratorApi.Quests.AchievementQuest
  import Ash.Query

  plug BadgeGeneratorApiWeb.Plugs.ApiKeyAuth

  # GET /quests
  def list(conn, _params) do
    current_business = conn.assigns.current_business

    result =
      AchievementQuest
      |> Ash.Query.for_read(:read, %{}, actor: current_business)
      |> Ash.read(actor: current_business)

    case result do
      {:ok, quests} ->
        mapped =
          Enum.map(quests, fn quest ->
            %{
              id: quest.id,
              title: quest.title,
              description: quest.description,
              badge_img_url: quest.badge_img_url,
              criteria_category: quest.criteria_category,
              criteria_details: quest.criteria_details,
              start_at: quest.start_at,
              end_at: quest.end_at,
              is_active: quest.is_active,
              inserted_at: quest.inserted_at,
              updated_at: quest.updated_at,
              project_id: quest.project_id
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

  # POST /quests
  def create(conn, params) do
    actor = conn.assigns.current_business

    case Ash.create(AchievementQuest, params, actor: actor, action: :create_quest) do
      {:ok, quest} ->
        json(conn, %{
          id: quest.id,
          title: quest.title,
          description: quest.description,
          badge_img_url: quest.badge_img_url,
          criteria_category: quest.criteria_category,
          criteria_details: quest.criteria_details,
          start_at: quest.start_at,
          end_at: quest.end_at,
          is_active: quest.is_active,
          inserted_at: quest.inserted_at,
          updated_at: quest.updated_at,
          project_id: quest.project_id
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

  # GET /quests/:id
  def show(conn, %{"id" => id}) do
    actor = conn.assigns.current_business

    if valid_uuid?(id) do
      result =
        AchievementQuest
        |> filter(id == ^id)
        |> for_read(:read)
        |> Ash.read(actor: actor)

      case result do
        {:ok, [quest | _]} ->
          json(conn, %{
            id: quest.id,
            title: quest.title,
            description: quest.description,
            badge_img_url: quest.badge_img_url,
            criteria_category: quest.criteria_category,
            criteria_details: quest.criteria_details,
            start_at: quest.start_at,
            end_at: quest.end_at,
            is_active: quest.is_active,
            inserted_at: quest.inserted_at,
            updated_at: quest.updated_at,
            project_id: quest.project_id
          })

        {:ok, []} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Quest not found"})

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
      |> json(%{error: "Invalid quest id format"})
    end
  end

  # PUT /quests/:id
  def update(conn, %{"id" => id} = params) do
    actor = conn.assigns.current_business

    if valid_uuid?(id) do
      quest =
        AchievementQuest
        |> filter(id == ^id)
        |> for_read(:read)
        |> Ash.read!(actor: actor)
        |> List.first()

      update_params =
        params
        |> Map.delete("id")
        |> Map.delete(:id)

      if quest do
        case Ash.update(quest, update_params, actor: actor) do
          {:ok, updated} ->
            json(conn, %{
              id: updated.id,
              title: updated.title,
              description: updated.description,
              badge_img_url: updated.badge_img_url,
              criteria_category: updated.criteria_category,
              criteria_details: updated.criteria_details,
              start_at: updated.start_at,
              end_at: updated.end_at,
              is_active: updated.is_active,
              inserted_at: updated.inserted_at,
              updated_at: updated.updated_at,
              project_id: updated.project_id
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
      else
        conn
        |> put_status(:not_found)
        |> json(%{error: "Quest not found"})
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid quest id format"})
    end
  end

  # DELETE /quests/:id
  def delete(conn, %{"id" => id}) do
    actor = conn.assigns.current_business

    if valid_uuid?(id) do
      quest =
        AchievementQuest
        |> filter(id == ^id)
        |> for_read(:read)
        |> Ash.read!(actor: actor)
        |> List.first()

      if quest do
        case Ash.destroy(quest, actor: actor) do
          {:ok, _} ->
            json(conn, %{message: "Quest deleted successfully"})

          :ok ->
            json(conn, %{message: "Quest deleted successfully"})

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
        |> json(%{error: "Quest not found"})
      end
    else
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Invalid quest id format"})
    end
  end

  # private helper for uuid validation
  defp valid_uuid?(id) do
    Regex.match?(~r/^[0-9a-fA-F\-]{36}$/, id)
  end
end
