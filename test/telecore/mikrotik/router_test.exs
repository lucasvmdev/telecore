defmodule Telecore.Mikrotik.RouterTest do
  use Telecore.DataCase, async: true

  alias Telecore.Mikrotik.Router

  @valid_attrs %{
    label: "POP-SP-01",
    url: "https://192.168.1.1",
    username: "admin",
    password: "supersecret"
  }

  describe "changeset/2" do
    test "valid attrs" do
      assert %{valid?: true} = Router.changeset(%Router{}, @valid_attrs)
    end

    test "requires all fields" do
      changeset = Router.changeset(%Router{}, %{})
      assert %{label: [_ | _], url: [_ | _], username: [_ | _], password: [_ | _]} = errors_on(changeset)
    end

    test "validates url format" do
      changeset = Router.changeset(%Router{}, %{@valid_attrs | url: "not-a-url"})
      assert %{url: [_ | _]} = errors_on(changeset)
    end
  end
end
