defmodule Telecore.Mikrotik.SecretFormTest do
  use ExUnit.Case, async: true

  alias Telecore.Mikrotik.SecretForm

  describe "changeset/2" do
    test "valid attrs" do
      attrs = %{"name" => "joao", "password" => "pw", "profile" => "10mbps"}
      assert %{valid?: true} = SecretForm.changeset(%SecretForm{}, attrs)
    end

    test "requires name, password, profile" do
      changeset = SecretForm.changeset(%SecretForm{}, %{})
      errors = errors_on(changeset)
      assert errors[:name]
      assert errors[:password]
      assert errors[:profile]
    end

    test "rejects invalid name format" do
      attrs = %{"name" => "with space", "password" => "pw", "profile" => "10mbps"}
      changeset = SecretForm.changeset(%SecretForm{}, attrs)
      assert errors_on(changeset)[:name]
    end
  end

  describe "to_attrs/1" do
    test "produces string-keyed map" do
      form = %SecretForm{name: "joao", password: "pw", profile: "10mbps", service: "pppoe", comment: nil}
      assert SecretForm.to_attrs(form) == %{
               "name" => "joao",
               "password" => "pw",
               "profile" => "10mbps",
               "service" => "pppoe",
               "comment" => ""
             }
    end
  end

  describe "from_secret/1" do
    test "loads a secret map into struct" do
      secret = %{"name" => "joao", "password" => "pw", "profile" => "10mbps", "service" => "pppoe", "comment" => "x"}
      assert %SecretForm{name: "joao", profile: "10mbps", comment: "x"} = SecretForm.from_secret(secret)
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key -> opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string() end)
    end)
  end
end
