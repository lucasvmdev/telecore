defmodule Telecore.Accounts do
  @moduledoc """
  Accounts context. Owns the `users` table and password verification.
  """
  alias Telecore.Accounts.User
  alias Telecore.Repo

  @doc """
  Fetches a user by email. Returns `nil` if no match.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: String.downcase(email))
  end

  @doc """
  Fetches a user by email/password pair. Returns `nil` on failure
  (wrong password or unknown email). Constant-time on email misses.
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    if User.valid_password?(user, password), do: user, else: nil
  end

  @doc """
  Fetches a user by id. Raises `Ecto.NoResultsError` if not found.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Creates a user. Used by seeds and (eventually) by registration.
  """
  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end
end
