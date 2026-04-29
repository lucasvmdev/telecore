defmodule Telecore.Mikrotik.Error do
  @enforce_keys [:code, :message]
  defstruct [:code, :message]

  @type t :: %__MODULE__{
          code: :unauthorized | :not_found | :conflict | :timeout | :unknown,
          message: binary()
        }
end
