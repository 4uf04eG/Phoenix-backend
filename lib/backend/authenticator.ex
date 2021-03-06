defmodule Backend.Authenticator do
  # TODO: These values must be moved in a configuration file
  @seed "user token"
  @secret "Some very secret key"

  alias Backend.Logic
  alias Backend.Repo
  alias Backend.Logic.AuthToken

  def generate_token(id) do
    Phoenix.Token.sign(@secret, @seed, id, max_age: 86400)
  end

  def verify_token(token) do
    case Phoenix.Token.verify(@secret, @seed, token, max_age: 86400) do
      {:ok, _} -> {:ok, token}
      error -> error
    end
  end

  def update_token(conn) do
    case extract_token(conn) do
      {:ok, token} ->
        case Repo.get_by(AuthToken, %{token: token}) |> Repo.preload(:user) do
          nil -> {:error, :not_found}
          auth_token ->
            Logic.update_token(%{revoked: true}) do
              token = generate_token(auth_token.user)
              auth_token.user |> Ecto.build_assoc(:tokens, %{token: token}) |> Repo.insert
            end
        end
      error -> error
    end
  end


  def get_auth_token(conn) do
    case extract_token(conn) do
      {:ok, token} -> verify_token(token)
      error -> error
    end
  end

  defp extract_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      [auth_header] -> get_token_from_header(auth_header)
      _ -> {:error, :missing_auth_header}
    end
  end

  defp get_token_from_header(auth_header) do
    {:ok, reg} = Regex.compile("Bearer\:?\s+(.*)$", "i")
    case Regex.run(reg, auth_header) do
      [_, match] -> {:ok, String.trim(match)}
      _ -> {:error, "Token not found"}
    end
  end
end