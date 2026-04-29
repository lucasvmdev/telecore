defmodule Telecore.Mikrotik.FakeTest do
  use ExUnit.Case, async: false

  alias Telecore.Mikrotik.{Fake, Router, Error}

  setup do
    start_supervised!(Fake)
    :ok
  end

  @router %Router{
    id: "00000000-0000-0000-0000-000000000099",
    label: "POP-FAKE",
    url: "https://10.0.0.1",
    username: "admin",
    password: "secret"
  }

  describe "seed" do
    test "first call seeds 3 secrets and 3 queues; sessions vary by router id" do
      assert {:ok, secrets} = Fake.list_secrets(@router)
      assert length(secrets) == 3
      assert Enum.all?(secrets, &(&1["disabled"] in ["true", "false"]))

      assert {:ok, sessions} = Fake.list_sessions(@router)
      # Sessions are derived from secrets that aren't disabled; varies 1..3 across routers.
      assert length(sessions) in 1..3

      assert {:ok, queues} = Fake.list_queues(@router)
      assert length(queues) == 3
    end

    test "seed is deterministic for the same router id" do
      {:ok, sessions_a} = Fake.list_sessions(@router)
      {:ok, sessions_b} = Fake.list_sessions(@router)
      assert sessions_a == sessions_b
    end
  end

  describe "create_secret/2" do
    test "adds to state and returns map with .id" do
      attrs = %{"name" => "novo", "password" => "pw", "profile" => "10mbps", "service" => "pppoe"}
      assert {:ok, secret} = Fake.create_secret(@router, attrs)
      assert secret["name"] == "novo"
      assert is_binary(secret[".id"])

      {:ok, all} = Fake.list_secrets(@router)
      assert Enum.any?(all, &(&1["name"] == "novo"))
    end
  end

  describe "delete_secret/2" do
    test "removes from state" do
      {:ok, [%{"name" => name} | _]} = Fake.list_secrets(@router)
      assert {:ok, :ok} = Fake.delete_secret(@router, name)
      {:ok, secrets} = Fake.list_secrets(@router)
      refute Enum.any?(secrets, &(&1["name"] == name))
    end

    test "returns not_found for unknown name" do
      assert {:error, %Error{code: :not_found}} = Fake.delete_secret(@router, "ghost-name-xyz")
    end
  end

  describe "disable_secret/2" do
    test "sets disabled and removes session" do
      {:ok, [%{"name" => name} | _]} = Fake.list_secrets(@router)
      assert {:ok, :ok} = Fake.disable_secret(@router, name)

      {:ok, secrets} = Fake.list_secrets(@router)
      target = Enum.find(secrets, &(&1["name"] == name))
      assert target["disabled"] == "true"

      {:ok, sessions} = Fake.list_sessions(@router)
      refute Enum.any?(sessions, &(&1["name"] == name))
    end
  end

  describe "enable_secret/2" do
    test "clears disabled flag" do
      {:ok, [%{"name" => name} | _]} = Fake.list_secrets(@router)
      Fake.disable_secret(@router, name)
      assert {:ok, :ok} = Fake.enable_secret(@router, name)

      {:ok, secrets} = Fake.list_secrets(@router)
      target = Enum.find(secrets, &(&1["name"] == name))
      assert target["disabled"] == "false"
    end
  end

  describe "disconnect_session/2" do
    test "removes the session" do
      {:ok, [first | _]} = Fake.list_sessions(@router)
      assert {:ok, :ok} = Fake.disconnect_session(@router, first[".id"])
      {:ok, sessions} = Fake.list_sessions(@router)
      refute Enum.any?(sessions, &(&1[".id"] == first[".id"]))
    end
  end

  describe "create_queue/2 + delete_queue/2" do
    test "round trip" do
      attrs = %{"name" => "qx", "target" => "10.0.0.99/32", "max-limit" => "5M/5M"}
      assert {:ok, %{".id" => _}} = Fake.create_queue(@router, attrs)
      assert {:ok, :ok} = Fake.delete_queue(@router, "qx")
    end
  end
end
