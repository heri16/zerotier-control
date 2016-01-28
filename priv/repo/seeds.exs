# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Zerotier.Repo.insert!(%Zerotier.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Zerotier.Repo

alias Zerotier.Tenant
alias Zerotier.User
alias Zerotier.Company
alias Zerotier.Office
alias Zerotier.Department
alias Zerotier.Position

for tenant_name <- ~w(Default) do
  tenant = Repo.get_by(Tenant, name: tenant_name) || Repo.insert!(%Tenant{id: Ecto.UUID.generate(), name: tenant_name})
  for username <- ~w(administrator) do
    user_changeset = User.registration_changeset(%User{name: "Default-User", username: username, tenant_id: tenant.id}, %{"password" => username})
    _user = Repo.get_by(User, username: username, tenant_id: tenant.id) || Repo.insert!(user_changeset)
  end
  for company_name <- ~w(Default-Company) do
    company = Repo.get_by(Company, name: company_name, tenant_id: tenant.id) || Repo.insert!(%Company{name: company_name, tenant_id: tenant.id})
    for office_name <- ~w(Default-Office) do
      _office = Repo.get_by(Office, name: office_name) || Repo.insert(%Office{name: office_name, location: "Unknown City", type: "Branch", company_id: company.id})
    end
    for department_name <- ~w(Marketing Warehouse Transportation Purchasing Finance Accounting General-Affairs Internal-Audit Information-Technology Human-Resources) do
      _department = Repo.get_by(Department, name: department_name) || Repo.insert(%Department{name: department_name, company_id: company.id})
    end
    for position_name <- ~w(Corporate Head Manager Supervisor Admin Staff) do
      _position = Repo.get_by(Position, name: position_name) || Repo.insert(%Position{name: position_name, notes: "", company_id: company.id})
    end
  end
end