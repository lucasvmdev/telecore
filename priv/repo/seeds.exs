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
