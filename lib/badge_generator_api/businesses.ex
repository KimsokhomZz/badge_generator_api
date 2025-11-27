defmodule BadgeGeneratorApi.Businesses do
  use Ash.Domain

  resources do
    resource(BadgeGeneratorApi.Businesses.Business)
    resource(BadgeGeneratorApi.Businesses.BusinessAPIKey)
  end
end
