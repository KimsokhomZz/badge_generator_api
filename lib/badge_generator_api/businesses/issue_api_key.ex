defmodule BadgeGeneratorApi.Businesses.IssueAPIKey do
  def call(business_id) do
    raw_key = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)
    hashed = Bcrypt.hash_pwd_salt(raw_key)

    {:ok, _key} =
      BadgeGeneratorApi.Businesses.BusinessAPIKey
      |> Ash.Changeset.for_create(:issue_key, %{
        business_id: business_id,
        api_key_hash: hashed
      })
      |> BadgeGeneratorApi.Repo.insert()

    {:ok, raw_key}
  end
end
