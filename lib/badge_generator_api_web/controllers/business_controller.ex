defmodule BadgeGeneratorApiWeb.BusinessController do
  use BadgeGeneratorApiWeb, :controller
  alias BadgeGeneratorApi.Businesses.Business

  def register(conn, params) do
    case Ash.create(Business, params, action: :register) do
      {:ok, business} ->
        json(conn, %{
          status: "success",
          data: %{
            id: business.id,
            name: business.name,
            email: business.email,
            api_key: business.raw_api_key,
            created_at: business.created_at,
            updated_at: business.updated_at
          }
        })

      {:error, ash_error} ->
        json(conn, %{
          status: "error",
          errors: serialize_ash_error(ash_error)
        })
    end
  end

  # helper function : serialize Ash errors into readable messages (invalid errors)
  defp serialize_ash_error(%Ash.Error.Invalid{errors: errors}) do
    Enum.map(errors, fn
      %Ash.Error.Changes.InvalidAttribute{field: field, message: message} ->
        %{field: field, message: message}

      other ->
        %{message: inspect(other)}
    end)
  end

  # helper function : serialize Ash errors into readable messages (unknown errors)
  defp serialize_ash_error(%Ash.Error.Unknown{errors: errors}) do
    Enum.map(errors, fn
      %Ash.Error.Unknown.UnknownError{field: field, error: msg} ->
        %{field: field, message: msg}

      other ->
        %{message: inspect(other)}
    end)
  end

  # fallback for other Ash errors
  defp serialize_ash_error(other) do
    %{message: inspect(other)}
  end

  # error message when unauthorized get /me request

  def me(conn, _params) do
    case conn.assigns[:current_business] do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})

      business ->
        conn
        |> json(%{
          data: %{
            id: business.id,
            name: business.name,
            email: business.email
          }
        })
    end
  end
end
