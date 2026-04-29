defmodule Telecore.Mikrotik.Client do
  alias Telecore.Mikrotik.{Router, Error}

  @type result(t) :: {:ok, t} | {:error, Error.t()}

  # PPPoE Secrets
  @callback list_secrets(Router.t()) :: result([map()])
  @callback get_secret(Router.t(), name :: String.t()) :: result(map())
  @callback create_secret(Router.t(), attrs :: map()) :: result(map())
  @callback update_secret(Router.t(), name :: String.t(), attrs :: map()) :: result(map())
  @callback delete_secret(Router.t(), name :: String.t()) :: result(:ok)
  @callback enable_secret(Router.t(), name :: String.t()) :: result(:ok)
  @callback disable_secret(Router.t(), name :: String.t()) :: result(:ok)

  # Active Sessions
  @callback list_sessions(Router.t()) :: result([map()])
  @callback disconnect_session(Router.t(), session_id :: String.t()) :: result(:ok)

  # Simple Queues
  @callback list_queues(Router.t()) :: result([map()])
  @callback create_queue(Router.t(), attrs :: map()) :: result(map())
  @callback update_queue(Router.t(), name :: String.t(), attrs :: map()) :: result(map())
  @callback delete_queue(Router.t(), name :: String.t()) :: result(:ok)
end
