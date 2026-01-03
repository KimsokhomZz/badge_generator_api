defmodule BadgeGeneratorApiWeb.ApiKeyController do
  use BadgeGeneratorApiWeb, :controller

  alias BadgeGeneratorApi.Businesses.BusinessAPIKey
  import Ash.Query

  plug BadgeGeneratorApiWeb.Plugs.ApiKeyAuth

  # GET /api/apikey/list
  def list(conn, _params) do
    actor = conn.assigns.current_business

    keys =
      BusinessAPIKey
      |> for_read(:read, %{}, actor: actor)
      |> Ash.read!(actor: actor)

    json(conn, %{
      status: "success",
      data:
        Enum.map(keys, fn key ->
          %{
            id: key.id,
            last_4: key.last_4,
            is_active: key.is_active,
            expired_at: key.expired_at,
            created_at: key.created_at
          }
        end)
    })
  end

  # POST /api/apikey/create
  def create(conn, params) do
    actor = conn.assigns.current_business

    expires =
      params["expired_at"] ||
        DateTime.utc_now() |> DateTime.add(90 * 24 * 60 * 60, :second)

    case Ash.create(BusinessAPIKey, %{expired_at: expires}, actor: actor) do
      {:ok, key} ->
        json(conn, %{
          status: "success",
          message: "Key created. Copy it now; you will never see it again!",
          data: %{
            id: key.id,
            apiKey: key.raw_key,
            expiredDate: key.expired_at
          }
        })

      {:error, _err} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: "Creation failed"})
    end
  end

  # POST /api/apikey/:id/rotate
  def rotate(conn, %{"id" => id} = params) do
    actor = conn.assigns.current_business

    update_params = Map.delete(params, "id")

    with {:ok, key_record} <- fetch_key(id, actor),
         {:ok, updated} <- Ash.update(key_record, update_params, actor: actor, action: :rotate) do
      json(conn, %{
        status: "success",
        message: "Key rotated. The old key is now invalid.",
        data: %{
          id: updated.id,
          apiKey: updated.raw_key,
          expiredDate: updated.expired_at
        }
      })
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "API key not found"})

      {:error, %Ash.Error.Forbidden{}} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You do not have permission to rotate this API key"})

      {:error, err} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Rotation failed", details: Exception.message(err)})

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Rotation failed"})
    end
  end

  # PATCH /api/apikey/:id/disable
  def revoke(conn, %{"id" => id}) do
    actor = conn.assigns.current_business

    with {:ok, key_record} <- fetch_key(id, actor),
         {:ok, _} <- Ash.update(key_record, %{}, actor: actor, action: :revoke) do
      json(conn, %{status: "success", message: "API Key revoked successfully"})
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "API key not found"})

      {:error, %Ash.Error.Forbidden{}} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "You do not have permission to revoke this API key"})

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Revocation failed"})
    end
  end

  # Private helper to find a key while checking ownership
  defp fetch_key(id, actor) do
    BusinessAPIKey
    |> filter(id == ^id)
    |> Ash.read_one(actor: actor)
    |> case do
      {:ok, nil} -> {:error, :not_found}
      {:ok, record} -> {:ok, record}
      error -> error
    end
  end
end
