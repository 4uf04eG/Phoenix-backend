defmodule Backend.Logic.AuthToken do
  use Ecto.Schema
  import Ecto.Changeset
  alias Backend.Logic.User

  @derive {Jason.Encoder, only: [:token]}
  schema "auth_tokens" do
    field :revoked, :boolean, default: false
    field :revoked_at, :utc_datetime
    field :token, :string
    belongs_to :user, User, references: :login, foreign_key: :user_login,  type: :string

    timestamps()
  end

  @doc false
  def changeset(auth_token, attrs) do
    auth_token
    |> cast(attrs, [:token, :revoked, :revoked_at])
    |> validate_required([:token, :revoked, :revoked_at])
    |> unique_constraint(:token, name: :token)
  end
end
