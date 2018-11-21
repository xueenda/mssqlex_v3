# Mssqlex.Types.define(Mssqlex.DefaultTypes, [])

defmodule Mssqlex.Utils do

  @doc """
  Fills in the given `opts` with default options.
  """
  @spec default_opts(Keyword.t) :: Keyword.t
  def default_opts(opts) do
    opts
    |> Keyword.put_new(:username, System.get_env("MSSQL_UID"))
    |> Keyword.put_new(:password, System.get_env("MSSQL_PWD"))
    |> Keyword.put_new(:database, System.get_env("MSSQL_DB"))
    |> Keyword.put_new(:hostname, System.get_env("MSSQL_HST") || "localhost")
    |> Keyword.update(:port, normalize_port(System.get_env("MSSQL_PRT")), &normalize_port/1)
    # |> Keyword.put_new(:types, Mssqlex.DefaultTypes)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
  end

  defp normalize_port(port) when is_binary(port), do: String.to_integer(port)
  defp normalize_port(port), do: port
end
