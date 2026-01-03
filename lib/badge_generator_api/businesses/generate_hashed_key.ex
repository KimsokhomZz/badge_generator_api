# lib/badge_generator_api/businesses/changes/generate_hashed_key.ex

defmodule BadgeGeneratorApi.Businesses.GenerateHashedKey do
  use Ash.Resource.Change
  alias Ash.Changeset

  def change(changeset, _opts, _context) do
    Changeset.before_action(changeset, fn changeset ->
      secret = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

      # Ensure an ID exists before creating the raw key
      id = Changeset.get_attribute(changeset, :id) || Ecto.UUID.generate()

      full_raw_key = "bg_#{id}_#{secret}"
      last_4 = String.slice(secret, -4..-1)

      changeset
      |> Changeset.force_change_attribute(:id, id)
      |> Changeset.force_change_attribute(:hashed_key, Bcrypt.hash_pwd_salt(secret))
      |> Changeset.force_change_attribute(:last_4, last_4)
      |> Changeset.after_action(fn _changeset, record ->
        {:ok, Map.put(record, :raw_key, full_raw_key)}
      end)
    end)
  end
end
