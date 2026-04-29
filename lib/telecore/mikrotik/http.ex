defmodule Telecore.Mikrotik.HTTP do
  @behaviour Telecore.Mikrotik.Client

  alias Telecore.Mikrotik.{Router, Error}

  # --- PPPoE Secrets ---

  @impl true
  def list_secrets(%Router{} = router) do
    router |> base_req() |> Req.get(url: "/rest/ppp/secret") |> handle_response()
  end

  @impl true
  def get_secret(%Router{} = router, name) do
    case router
         |> base_req()
         |> Req.get(url: "/rest/ppp/secret", params: [name: name])
         |> handle_response() do
      {:ok, [secret | _]} -> {:ok, secret}
      {:ok, []} -> {:error, %Error{code: :not_found, message: "secret #{name} not found"}}
      error -> error
    end
  end

  @impl true
  def create_secret(%Router{} = router, attrs) do
    router |> base_req() |> Req.put(url: "/rest/ppp/secret", json: attrs) |> handle_response()
  end

  @impl true
  def update_secret(%Router{} = router, name, attrs) do
    with {:ok, id} <- find_id(router, "/rest/ppp/secret", name) do
      router
      |> base_req()
      |> Req.patch(url: "/rest/ppp/secret/#{id}", json: attrs)
      |> handle_response()
    end
  end

  @impl true
  def delete_secret(%Router{} = router, name) do
    with {:ok, id} <- find_id(router, "/rest/ppp/secret", name) do
      router |> base_req() |> Req.delete(url: "/rest/ppp/secret/#{id}") |> handle_response(:ok)
    end
  end

  @impl true
  def enable_secret(%Router{} = router, name) do
    with {:ok, id} <- find_id(router, "/rest/ppp/secret", name) do
      router
      |> base_req()
      |> Req.patch(url: "/rest/ppp/secret/#{id}", json: %{disabled: false})
      |> handle_response(:ok)
    end
  end

  @impl true
  def disable_secret(%Router{} = router, name) do
    with {:ok, id} <- find_id(router, "/rest/ppp/secret", name) do
      router
      |> base_req()
      |> Req.patch(url: "/rest/ppp/secret/#{id}", json: %{disabled: true})
      |> handle_response(:ok)
    end
  end

  # --- Active Sessions ---

  @impl true
  def list_sessions(%Router{} = router) do
    router |> base_req() |> Req.get(url: "/rest/ppp/active") |> handle_response()
  end

  @impl true
  def disconnect_session(%Router{} = router, session_id) do
    router
    |> base_req()
    |> Req.delete(url: "/rest/ppp/active/#{session_id}")
    |> handle_response(:ok)
  end

  # --- Simple Queues ---

  @impl true
  def list_queues(%Router{} = router) do
    router |> base_req() |> Req.get(url: "/rest/queue/simple") |> handle_response()
  end

  @impl true
  def create_queue(%Router{} = router, attrs) do
    router |> base_req() |> Req.put(url: "/rest/queue/simple", json: attrs) |> handle_response()
  end

  @impl true
  def update_queue(%Router{} = router, name, attrs) do
    with {:ok, id} <- find_id(router, "/rest/queue/simple", name) do
      router
      |> base_req()
      |> Req.patch(url: "/rest/queue/simple/#{id}", json: attrs)
      |> handle_response()
    end
  end

  @impl true
  def delete_queue(%Router{} = router, name) do
    with {:ok, id} <- find_id(router, "/rest/queue/simple", name) do
      router |> base_req() |> Req.delete(url: "/rest/queue/simple/#{id}") |> handle_response(:ok)
    end
  end

  # --- Private helpers ---

  defp base_req(%Router{url: url, username: username, password: password}) do
    tls_verify =
      if System.get_env("MIKROTIK_TLS_INSECURE") == "true", do: :verify_none, else: :verify_peer

    Req.new(
      base_url: url,
      auth: {:basic, {username, password}},
      connect_options: [verify: tls_verify]
    )
  end

  defp find_id(%Router{} = router, path, name) do
    case router |> base_req() |> Req.get(url: path, params: [name: name]) |> handle_response() do
      {:ok, [%{".id" => id} | _]} -> {:ok, id}
      {:ok, []} -> {:error, %Error{code: :not_found, message: "#{name} not found"}}
      error -> error
    end
  end

  defp handle_response(result, mode \\ :body)

  defp handle_response({:ok, %Req.Response{status: 200, body: body}}, :body), do: {:ok, body}
  defp handle_response({:ok, %Req.Response{status: 204}}, :ok), do: {:ok, :ok}
  defp handle_response({:ok, %Req.Response{status: 200}}, :ok), do: {:ok, :ok}

  defp handle_response({:ok, %Req.Response{status: 401}}, _),
    do: {:error, %Error{code: :unauthorized, message: "unauthorized"}}

  defp handle_response({:ok, %Req.Response{status: 404}}, _),
    do: {:error, %Error{code: :not_found, message: "not found"}}

  defp handle_response({:ok, %Req.Response{status: s, body: %{"detail" => msg}}}, _)
       when s in [400, 422] and is_binary(msg) do
    if msg =~ "already have" do
      {:error, %Error{code: :conflict, message: msg}}
    else
      {:error, %Error{code: :unknown, message: msg}}
    end
  end

  defp handle_response({:ok, %Req.Response{body: %{"detail" => msg}}}, _) when is_binary(msg),
    do: {:error, %Error{code: :unknown, message: msg}}

  defp handle_response({:ok, %Req.Response{status: s, body: body}}, _),
    do: {:error, %Error{code: :unknown, message: "HTTP #{s}: #{inspect(body)}"}}

  defp handle_response({:error, %{reason: :timeout}}, _),
    do: {:error, %Error{code: :timeout, message: "connection timed out"}}

  defp handle_response({:error, exception}, _),
    do: {:error, %Error{code: :unknown, message: Exception.message(exception)}}
end
