defmodule Telecore.AccountsTest do
  use Telecore.DataCase, async: true

  import Telecore.Factory

  alias Telecore.Accounts
  alias Telecore.Accounts.User

  describe "get_user_by_email/1" do
    test "returns the user when the email matches (case-insensitive)" do
      user = insert(:user, email: "alice@telecore.test")
      assert %User{id: id} = Accounts.get_user_by_email("ALICE@telecore.test")
      assert id == user.id
    end

    test "returns nil when no user matches" do
      refute Accounts.get_user_by_email("nobody@telecore.test")
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "returns the user with valid credentials" do
      user = insert(:user)
      assert %User{id: id} = Accounts.get_user_by_email_and_password(user.email, valid_password())
      assert id == user.id
    end

    test "returns nil with wrong password" do
      user = insert(:user)
      refute Accounts.get_user_by_email_and_password(user.email, "wrong-password")
    end

    test "returns nil for unknown email" do
      refute Accounts.get_user_by_email_and_password("nope@telecore.test", valid_password())
    end
  end

  describe "create_user/1" do
    test "persists a valid user with hashed password" do
      attrs = %{email: "Bob@telecore.test", password: "supersecret1"}
      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.email == "bob@telecore.test"
      assert user.hashed_password != nil
      assert User.valid_password?(user, "supersecret1")
    end

    test "rejects duplicate email" do
      insert(:user, email: "dup@telecore.test")

      assert {:error, changeset} =
               Accounts.create_user(%{email: "dup@telecore.test", password: "anything12"})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "rejects short password" do
      assert {:error, changeset} =
               Accounts.create_user(%{email: "x@telecore.test", password: "short"})

      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "rejects bad email format" do
      assert {:error, changeset} =
               Accounts.create_user(%{email: "no-at-sign", password: "longenough1"})

      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end
  end
end
