defmodule Telecore.MikrotikTest do
  use ExUnit.Case, async: true
  import Mox

  alias Telecore.Mikrotik
  alias Telecore.Mikrotik.{Error, Router}

  setup :verify_on_exit!

  @router %Router{
    id: "00000000-0000-0000-0000-000000000001",
    label: "POP-TEST",
    url: "https://10.0.0.1",
    username: "admin",
    password: "secret"
  }

  # --- PPPoE Secrets ---

  describe "list_secrets/1" do
    test "delegates to adapter and returns ok" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :list_secrets, fn ^router ->
        {:ok, [%{"name" => "joao", "profile" => "10mbps"}]}
      end)

      assert {:ok, [%{"name" => "joao"}]} = Mikrotik.list_secrets(@router)
    end

    test "propagates error from adapter" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :list_secrets, fn ^router ->
        {:error, %Error{code: :unauthorized, message: "login failure"}}
      end)

      assert {:error, %Error{code: :unauthorized}} = Mikrotik.list_secrets(@router)
    end
  end

  describe "get_secret/2" do
    test "delegates to adapter" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :get_secret, fn ^router, "joao" ->
        {:ok, %{"name" => "joao"}}
      end)

      assert {:ok, %{"name" => "joao"}} = Mikrotik.get_secret(@router, "joao")
    end
  end

  describe "create_secret/2" do
    test "delegates to adapter" do
      router = @router
      attrs = %{"name" => "maria", "password" => "pw", "profile" => "10mbps"}

      expect(Telecore.Mikrotik.Mock, :create_secret, fn ^router, ^attrs ->
        {:ok, Map.put(attrs, ".id", "*1")}
      end)

      assert {:ok, %{".id" => "*1"}} = Mikrotik.create_secret(@router, attrs)
    end
  end

  describe "update_secret/3" do
    test "delegates to adapter" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :update_secret, fn ^router, "joao", %{"profile" => "50mbps"} ->
        {:ok, %{"name" => "joao", "profile" => "50mbps"}}
      end)

      assert {:ok, %{"profile" => "50mbps"}} =
               Mikrotik.update_secret(@router, "joao", %{"profile" => "50mbps"})
    end
  end

  describe "delete_secret/2" do
    test "delegates to adapter" do
      router = @router
      expect(Telecore.Mikrotik.Mock, :delete_secret, fn ^router, "joao" -> {:ok, :ok} end)
      assert {:ok, :ok} = Mikrotik.delete_secret(@router, "joao")
    end
  end

  describe "enable_secret/2" do
    test "delegates to adapter" do
      router = @router
      expect(Telecore.Mikrotik.Mock, :enable_secret, fn ^router, "joao" -> {:ok, :ok} end)
      assert {:ok, :ok} = Mikrotik.enable_secret(@router, "joao")
    end
  end

  describe "disable_secret/2" do
    test "delegates to adapter" do
      router = @router
      expect(Telecore.Mikrotik.Mock, :disable_secret, fn ^router, "joao" -> {:ok, :ok} end)
      assert {:ok, :ok} = Mikrotik.disable_secret(@router, "joao")
    end
  end

  # --- Active Sessions ---

  describe "list_sessions/1" do
    test "delegates to adapter" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :list_sessions, fn ^router ->
        {:ok, [%{"name" => "joao", "uptime" => "1h"}]}
      end)

      assert {:ok, [%{"name" => "joao"}]} = Mikrotik.list_sessions(@router)
    end
  end

  describe "disconnect_session/2" do
    test "delegates to adapter" do
      router = @router
      expect(Telecore.Mikrotik.Mock, :disconnect_session, fn ^router, "*A1" -> {:ok, :ok} end)
      assert {:ok, :ok} = Mikrotik.disconnect_session(@router, "*A1")
    end

    test "propagates not_found error" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :disconnect_session, fn ^router, "bad" ->
        {:error, %Error{code: :not_found, message: "no such item"}}
      end)

      assert {:error, %Error{code: :not_found}} = Mikrotik.disconnect_session(@router, "bad")
    end
  end

  # --- Simple Queues ---

  describe "list_queues/1" do
    test "delegates to adapter" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :list_queues, fn ^router ->
        {:ok, [%{"name" => "joao", "max-limit" => "10M/10M"}]}
      end)

      assert {:ok, [%{"name" => "joao"}]} = Mikrotik.list_queues(@router)
    end
  end

  describe "create_queue/2" do
    test "delegates to adapter" do
      router = @router
      attrs = %{"name" => "maria", "target" => "10.0.0.5/32", "max-limit" => "20M/20M"}

      expect(Telecore.Mikrotik.Mock, :create_queue, fn ^router, ^attrs ->
        {:ok, Map.put(attrs, ".id", "*2")}
      end)

      assert {:ok, %{".id" => "*2"}} = Mikrotik.create_queue(@router, attrs)
    end
  end

  describe "update_queue/3" do
    test "delegates to adapter" do
      router = @router

      expect(Telecore.Mikrotik.Mock, :update_queue, fn ^router, "joao", %{"max-limit" => "50M/50M"} ->
        {:ok, %{"name" => "joao", "max-limit" => "50M/50M"}}
      end)

      assert {:ok, %{"max-limit" => "50M/50M"}} =
               Mikrotik.update_queue(@router, "joao", %{"max-limit" => "50M/50M"})
    end
  end

  describe "delete_queue/2" do
    test "delegates to adapter" do
      router = @router
      expect(Telecore.Mikrotik.Mock, :delete_queue, fn ^router, "joao" -> {:ok, :ok} end)
      assert {:ok, :ok} = Mikrotik.delete_queue(@router, "joao")
    end
  end
end
