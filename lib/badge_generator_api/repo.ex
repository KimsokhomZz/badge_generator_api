defmodule BadgeGeneratorApi.Repo do
  use AshPostgres.Repo,
    otp_app: :badge_generator_api,
    adapter: Ecto.Adapters.Postgres

  def installed_extensions do
    ["citext"]
  end

  def min_pg_version do
    %Version{major: 16, minor: 0, patch: 0}
  end
end
