defmodule Telecore.Mikrotik.RouterTest do
  use Telecore.DataCase, async: true

  import Ecto.Query

  alias Telecore.Mikrotik
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

      assert %{label: [_ | _], url: [_ | _], username: [_ | _], password: [_ | _]} =
               errors_on(changeset)
    end

    test "validates url format" do
      changeset = Router.changeset(%Router{}, %{@valid_attrs | url: "not-a-url"})
      assert %{url: [_ | _]} = errors_on(changeset)
    end
  end

  describe "list_routers/0" do
    test "returns all routers" do
      router = insert(:mikrotik_router)
      assert [%Router{id: id}] = Mikrotik.list_routers()
      assert id == router.id
    end
  end

  describe "get_router!/1" do
    test "returns the router" do
      %{id: id} = insert(:mikrotik_router)
      assert %Router{id: ^id} = Mikrotik.get_router!(id)
    end

    test "raises when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Mikrotik.get_router!(Ecto.UUID.generate())
      end
    end
  end

  describe "create_router/1" do
    test "creates with valid attrs" do
      assert {:ok, %Router{label: "POP-RJ-01"}} =
               Mikrotik.create_router(%{@valid_attrs | label: "POP-RJ-01"})
    end

    test "encrypts password at rest" do
      {:ok, router} = Mikrotik.create_router(@valid_attrs)
      raw_id = Ecto.UUID.dump!(router.id)

      raw =
        Telecore.Repo.one(
          from r in "mikrotik_routers", where: r.id == ^raw_id, select: r.password
        )

      assert raw != "supersecret"
      assert Mikrotik.get_router!(router.id).password == "supersecret"
    end

    test "returns error with invalid attrs" do
      assert {:error, changeset} = Mikrotik.create_router(%{})
      assert %{label: [_ | _]} = errors_on(changeset)
    end
  end

  describe "update_router/2" do
    test "updates the router" do
      router = insert(:mikrotik_router)

      assert {:ok, %Router{label: "UPDATED"}} =
               Mikrotik.update_router(router, %{label: "UPDATED"})
    end
  end

  describe "delete_router/1" do
    test "deletes the router" do
      router = insert(:mikrotik_router)
      assert {:ok, %Router{}} = Mikrotik.delete_router(router)
      assert_raise Ecto.NoResultsError, fn -> Mikrotik.get_router!(router.id) end
    end
  end
end
