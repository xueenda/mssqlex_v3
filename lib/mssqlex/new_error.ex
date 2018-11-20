defmodule Mssqlex.NewError do
  @moduledoc """
  Defines an error returned from the ODBC adapter.
  * `message` is the full message returned by ODBC
  * `odbc_code` is an atom representing the returned
    [SQLSTATE](https://docs.microsoft.com/en-us/sql/odbc/reference/appendixes/appendix-a-odbc-error-codes)
    or the string representation of the code if it cannot be translated.
  """

  # defexception [:mssql, :message, :odbc_code, constraint_violations: []]

  defexception [:message, :mssql, :connection_id, :query]

  @type t :: %Mssqlex.NewError{}
  # @type t :: %__MODULE__{
          # mssql: map(),
          # message: binary(),
          # odbc_code: atom() | binary(),
          # constraint_violations: Keyword.t()
        # }

  # @not_allowed_in_transaction_messages [226, 574]

  # @doc false
  # @spec exception({binary()) :: t()
  # def exception({odbc_code, native_code, reason} = message) do
    # %__MODULE__{
      # message:
        # to_string(reason) <>
          # " | ODBC_CODE " <>
          # to_string(odbc_code) <>
          # " | SQL_SERVER_CODE " <> to_string(native_code),
      # odbc_code: get_code(message),
      # constraint_violations: get_constraint_violations(to_string(reason))
    # }
  # end

  @doc false
  @spec exception({list(), integer(), list()}) :: t()
  def exception(opts) do
    mssql =
      if fields = Keyword.get(opts, :mssql) do
        code = fields.code
        message = fields.message
        driver = build_driver(fields.driver)

        fields
        |> Map.put(:mssql_code, to_string(code))
        |> Map.put(:driver, driver)
        |> Map.put(:code, Mssqlex.ErrorCode.code_to_name(code))
        |> Map.put(:message, build_message(message, driver))
      end

    message = Keyword.get(opts, :message)
    connection_id = Keyword.get(opts, :connection_id)
    %Mssqlex.NewError{mssql: mssql, message: message, connection_id: connection_id}
  end

  def message(e) do
    if map = e.mssql do
      IO.iodata_to_binary([
        # map.severity,
        # ?\s,
        map.mssql_code,
        ?\s,
        [?(, Atom.to_string(map.code), ?)],
        ?\s,
        map.message,
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

# defmodule Mssqlex.QueryError do
  # defexception [:message]
# end
