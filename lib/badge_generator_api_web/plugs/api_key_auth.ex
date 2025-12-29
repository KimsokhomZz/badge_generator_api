defmodule BadgeGeneratorApiWeb.Plugs.ApiKeyAuth do
  import Plug.Conn
  alias BadgeGeneratorApi.Businesses.BusinessAPIKey
  require Ash.Query

  def init(opts), do: opts

  def call(conn, _opts) do
    # IO.inspect(get_req_header(conn, "authorization"), label: "Authorization header")

    case get_req_header(conn, "authorization") do
      ["Bearer " <> raw_key] ->
        case get_business_by_api_key(raw_key) do
          {:ok, business} ->
            # IO.inspect(business, label: "Authenticated business")
            assign(conn, :current_business, business)

          _ ->
            conn
            |> send_resp(401, "Unauthorized")
            |> halt()
        end

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
