defmodule BadgeGeneratorApiWeb.Plugs.ApiKeyAuth do
  import Plug.Conn
  alias BadgeGeneratorApi.Businesses.BusinessAPIKey
  require Ash.Query

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> full_key] ->
        case verify_api_key(full_key) do
          {:ok, business} ->
            assign(conn, :current_business, business)

          _ ->
            unauthorized(conn)
        end

      _ ->
        unauthorized(conn)
    end
  end

  defp verify_api_key("bg_" <> rest) do
    # Split the key into ID and Secret
    with [id, secret] <- String.split(rest, "_", parts: 2),
         {:ok, key_record} <- fetch_active_key(id),
         true <- key_record != nil do
      if Bcrypt.verify_pass(secret, key_record.hashed_key) do
        {:ok, key_record.business}
      else
        {:error, :unauthorized}
      end
    else
      _ ->
        {:error, :unauthorized}
    end
  end

  defp verify_api_key(_), do: {:error, :unauthorized}

  defp fetch_active_key(id) do
    now = DateTime.utc_now()

    BusinessAPIKey
    |> Ash.Query.filter(
      id == ^id and
        is_active == true and
        expired_at > ^now
    )
    |> Ash.Query.load(:business)
    |> Ash.read_one(authorize?: false)
  end

  defp unauthorized(conn) do
    conn |> send_resp(401, "Unauthorized") |> halt()
  end
end
