defmodule BadgeGeneratorApi.Repo do
  use Ecto.Repo,
    otp_app: :badge_generator_api,
    adapter: Ecto.Adapters.Postgres
end
