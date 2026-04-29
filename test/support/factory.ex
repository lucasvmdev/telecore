defmodule Telecore.Factory do
  @moduledoc """
  ExMachina factories. Use `insert/1`, `build/1`, `params_for/1` etc.
  """
  use ExMachina.Ecto, repo: Telecore.Repo

  alias Telecore.Accounts.User

  @valid_password "passw0rd-test"

  def user_factory do
    %User{
      email: sequence(:email, &"user-#{&1}@telecore.test"),
      hashed_password: Bcrypt.hash_pwd_salt(@valid_password)
    }
  end

  @doc """
  Returns the plaintext password matching `user_factory`'s hashed_password.
  Use this to authenticate factory-built users in controller tests.
  """
  def valid_password, do: @valid_password
end
