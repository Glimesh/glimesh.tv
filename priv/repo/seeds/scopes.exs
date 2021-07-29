scopes = [
  %{label: "Public", name: "public", public: true},
  %{label: "Email", name: "email", public: true},
  %{label: "Chat", name: "chat", public: true},
  %{label: "Stream Key", name: "streamkey", public: true}
]

Enum.each(scopes, fn attrs ->
  Boruta.Ecto.Admin.create_scope(attrs)
end)
