defmodule BadgeGeneratorApi.Businesses.APIKeyService do
  # alias BadgeGeneratorApi.Businesses.{BusinessAPIKey, Business}
  alias BadgeGeneratorApi.Businesses.BusinessAPIKey
  alias Ash.Changeset
  require Logger

  @expiration_days 90

  # this function is called after a business registers
  def issue_api_key(%{id: business_id}) do
    # create raw API key (random string)
    raw_key = "bsk_" <> Base.url_encode64(:crypto.strong_rand_bytes(24), padding: false)

    # hash it for storage
    api_key_hash =
      :crypto.hash(:sha256, raw_key)
      |> Base.encode16(case: :lower)

    # calculate expiration date
    expired_at = DateTime.utc_now() |> DateTime.add(@expiration_days * 24 * 60 * 60, :second)

    # create the BusinessAPIKey record
    changeset =
      BusinessAPIKey
      |> Changeset.for_create(:issue_key, %{
        business_id: business_id,
        api_key_hash: api_key_hash,
        expired_at: expired_at
      })

    case Ash.create(changeset) do
      {:ok, _key} ->
        # return the raw API key to the client
        {:ok, raw_key}

      {:error, changeset} ->
        Logger.error("Failed to create API key: #{inspect(changeset.errors)}")
        {:error, :cannot_create_api_key}
    end
  end
end
