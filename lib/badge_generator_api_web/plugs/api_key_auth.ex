defmodule BadgeGeneratorApiWeb.Plugs.ApiKeyAuth do
  import Plug.Conn
  alias BadgeGeneratorApi.Businesses.BusinessAPIKey
  require Ash.Query

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> raw_key] <- get_req_header(conn, "authorization"),
         {:ok, business} <- get_business_by_api_key(raw_key) do
      assign(conn, :current_business, business)
    else
      _ ->
        conn
        |> send_resp(401, "Unauthorized")
        |> halt()
    end
  end

  defp get_business_by_api_key(raw_key) do
    hash =
      :crypto.hash(:sha256, raw_key)
      |> Base.encode16(case: :lower)

    now = DateTime.utc_now()

    query =
      Ash.Query.for_read(BusinessAPIKey, :read)
      |> Ash.Query.filter(
        api_key_hash == ^hash and
          is_active == true and
          (is_nil(expired_at) or expired_at >= ^now)
      )
      |> Ash.Query.load(:business)

    case Ash.read(query) do
      {:ok, [key]} -> {:ok, key.business}
      _ -> {:error, :unauthorized}
    end
  end
end
