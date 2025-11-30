defmodule BadgeGeneratorApi.Accounts do
  use Ash.Domain

  resources do
    resource(BadgeGeneratorApi.Accounts.Company)
    resource(BadgeGeneratorApi.Accounts.CompanyAPIKey)
  end
end
