defmodule Mssqlex.Error do
  @moduledoc """
  Defines an error returned from the ODBC adapter.
  * `message` is the full message returned by ODBC
  * `odbc_code` is an atom representing the returned
    [SQLSTATE](https://docs.microsoft.com/en-us/sql/odbc/reference/appendixes/appendix-a-odbc-error-codes)
    or the string representation of the code if it cannot be translated.
  """

  defexception [:message, :mssql, :connection_id, :query]

  @type t :: %Mssqlex.Error{}

  @doc false
  @spec exception({list(), integer(), list()}) :: t()
  def exception({_odbc_code, 574, reason}) do
    exception([mssql: %{code: :not_allowed_in_transaction, message: reason}])
  end

  def exception({_odbc_code, 226, reason}) do
    exception([mssql: %{code: :not_allowed_in_transaction, message: reason}])
  end

  def exception({odbc_code, native_code, reason}) do
    exception([mssql: %{code: odbc_code, message: reason}])
  end

  def exception(code) when is_atom(code) do
    exception([mssql: %{code: code, message: code}])
  end

  def exception(opts) do
    mssql =
      if fields = Keyword.get(opts, :mssql) do
        code = Map.get(fields, :code, :feature_not_supported)
        message = Map.get(fields, :message, "No message provided!")
        driver = fields |> Map.get(:driver) |> build_driver()

        fields
        |> Map.put(:mssql_code, to_string(code))
        |> Map.put(:driver, driver)
        |> Map.put(:code, Mssqlex.ErrorCode.code_to_name(code))
        |> Map.put(:message, build_message(message, driver))
      end

    message = Keyword.get(opts, :message)
    connection_id = Keyword.get(opts, :connection_id)
    %Mssqlex.Error{mssql: mssql, message: message, connection_id: connection_id}
  end

  def message(e) do
    if map = e.mssql do
      IO.iodata_to_binary([
        # map.severity,
        # ?\s,
        Map.get(map, :mssql_code, "feature_not_supported"),
        ?\s,
        [?(, Atom.to_string(map.code), ?)],
        ?\s,
        Map.get(map, :message, "No message provided!"),
        # build_query(e.query),
        # build_metadata(map),
        # build_detail(map)
      ])
    else
      e.message
    end
  end

  defp build_driver(nil), do: nil
  defp build_driver(driver) do
    String.replace(driver, ~r/\{|\}/, "")
  end

  defp build_message(msg, driver) do
    msg
    |> to_string()
    |> String.replace("[Microsoft]", "")
    |> String.replace("[SQL Server]", "")
    |> String.replace("[ODBC Driver 17 for SQL Server]", "")
    |> String.replace("[#{driver}]", "")
    |> String.replace(~r/(\.\s+|\.)/, ". ")
    |> String.trim()
  end

  # defp get_constraint_violations(reason) do
    # constraint_checks = [
      # unique: ~r/Violation of UNIQUE KEY constraint '(\S+?)'./,
      # unique: ~r/Cannot insert duplicate key row .* with unique index '(\S+?)'/,
      # foreign_key:
        # ~r/conflicted with the (?:FOREIGN KEY|REFERENCE) constraint "(\S+?)"./,
      # check: ~r/conflicted with the CHECK constraint "(\S+?)"./
    # ]

    # extract = fn {key, test}, acc ->
      # concatenate_match = fn [match], acc -> [{key, match} | acc] end

      # case Regex.scan(test, reason, capture: :all_but_first) do
        # [] -> acc
        # matches -> Enum.reduce(matches, acc, concatenate_match)
      # end
    # end

    # Enum.reduce(constraint_checks, [], extract)
  # end
end

defmodule Mssqlex.QueryError do
  defexception [:message]
end
