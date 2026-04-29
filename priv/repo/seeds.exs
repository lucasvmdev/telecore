# Run with: mix run priv/repo/seeds.exs
# Idempotent — safe to re-run. Reads SEED_ADMIN_EMAIL / SEED_ADMIN_PASSWORD,
# falling back to a dev-only default.

email = System.get_env("SEED_ADMIN_EMAIL") || "admin@telecore.dev"
password = System.get_env("SEED_ADMIN_PASSWORD") || "changeme123"

case Telecore.Accounts.get_user_by_email(email) do
  nil ->
    {:ok, _user} = Telecore.Accounts.create_user(%{email: email, password: password})
    IO.puts("Seeded admin user: #{email}")

  _user ->
    IO.puts("Admin user already exists: #{email}")
end

# --- Mikrotik routers (dev-only fixtures) ---
#
# Per-router state variation (which clients are enabled/disabled, which
# sessions are active) is generated deterministically by Telecore.Mikrotik.Fake
# based on the router's id. So just creating the routers is enough — the Fake
# does the rest when the LiveView first queries each router.

routers = [
  %{label: "POP-SP-01", url: "https://10.10.1.1", username: "admin", password: "router-sp-01"},
  %{label: "POP-RJ-01", url: "https://10.10.2.1", username: "admin", password: "router-rj-01"},
  %{label: "POP-SC-01", url: "https://10.10.3.1", username: "admin", password: "router-sc-01"},
  %{label: "POP-MG-01", url: "https://10.10.4.1", username: "admin", password: "router-mg-01"}
]

for %{label: label} = attrs <- routers do
  case Telecore.Repo.get_by(Telecore.Mikrotik.Router, label: label) do
    nil ->
      {:ok, _} = Telecore.Mikrotik.create_router(attrs)
      IO.puts("Seeded router: #{label}")

    _existing ->
      IO.puts("Router already exists: #{label}")
  end
end
