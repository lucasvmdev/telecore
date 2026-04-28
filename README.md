# Telecore

Aplicação [Phoenix](https://www.phoenixframework.org/) 1.8 em Elixir, servindo
como base para produtos web e APIs JSON. Já vem com autenticação de usuários
(LiveView + API com Bearer token), Postgres via Ecto, build de assets com
Tailwind/esbuild e ferramental de qualidade pré-configurado.

## Stack

- **Elixir** `~> 1.15` + **Phoenix** `~> 1.8.5`
- **Phoenix LiveView** `~> 1.1`
- **Ecto / Postgrex** sobre **PostgreSQL**
- **Bandit** como servidor HTTP
- **Tailwind** + **esbuild** para os assets
- **bcrypt_elixir** para hash de senha
- **Swoosh** para e-mails
- **DNSCluster** para clusterização
- **Credo**, **Dialyxir**, **ExMachina** e **Mox** para qualidade e testes

## Pré-requisitos

- Elixir 1.15+ e Erlang/OTP compatível
- PostgreSQL rodando localmente (em `localhost`, usuário `postgres`/`postgres`
  por padrão — ver [config/dev.exs](config/dev.exs))

## Setup

```bash
mix setup
```

Esse alias instala dependências, cria o banco, roda migrations, executa seeds
e prepara os assets. Detalhes em [mix.exs](mix.exs#L89-L104).

## Subindo o servidor

```bash
mix phx.server
# ou, com IEx anexado:
iex -S mix phx.server
```

Acesse [http://localhost:4000](http://localhost:4000).

Em ambiente de desenvolvimento, ficam disponíveis:

- `/dev/dashboard` — [LiveDashboard](https://hexdocs.pm/phoenix_live_dashboard)
- `/dev/mailbox` — preview de e-mails enviados via Swoosh

## Testes e qualidade

```bash
mix test         # cria/migra o banco de teste e roda os testes
mix precommit    # compila com --warnings-as-errors, formata e roda testes
mix credo
mix dialyzer
```

O alias `precommit` ([mix.exs:102](mix.exs#L102)) também remove deps não
utilizadas — rode antes de abrir um PR.

## Rotas principais

Definidas em [lib/telecore_web/router.ex](lib/telecore_web/router.ex).

### Web (LiveView)

| Rota                         | Descrição                       |
| ---------------------------- | ------------------------------- |
| `GET /`                      | Página inicial                  |
| `GET /users/register`        | Cadastro                        |
| `GET /users/log-in`          | Login                           |
| `GET /users/settings`        | Configurações (autenticado)     |

### API JSON (`/api/v1`)

Pública:

| Método | Rota         | Descrição                                          |
| ------ | ------------ | -------------------------------------------------- |
| `POST` | `/sessions`  | Login → retorna `{ token, user }`                  |
| `POST` | `/users`     | Cadastro → retorna `{ token, user }`               |

Autenticada via `Authorization: Bearer <token>`:

| Método   | Rota          | Descrição                              |
| -------- | ------------- | -------------------------------------- |
| `GET`    | `/users/me`   | Usuário atual                          |
| `DELETE` | `/sessions`   | Revoga o token usado na requisição     |

A autenticação da API é feita pelo plug
[`TelecoreWeb.Plugs.ApiAuth`](lib/telecore_web/plugs/api_auth.ex), que devolve
`401 {"error":"unauthorized"}` quando o Bearer está ausente ou inválido.

Formato de erro:

- `{"error": "<código>"}` — falhas não relacionadas a campos (400/401)
- `{"errors": {"<campo>": ["<msg>"]}}` — validação de changeset (422)

## Estrutura

```
lib/
├── telecore/              # contextos de domínio (Accounts, Repo, Mailer, ...)
└── telecore_web/          # camada web
    ├── controllers/api/v1 # endpoints JSON
    ├── live/user_live     # LiveViews de auth
    ├── plugs/api_auth.ex  # autenticação Bearer
    └── router.ex
```

## Deploy

Em produção, as seguintes variáveis de ambiente são lidas em
[config/runtime.exs](config/runtime.exs):

| Variável            | Obrigatória | Descrição                                          |
| ------------------- | :---------: | -------------------------------------------------- |
| `DATABASE_URL`      | sim         | `ecto://USER:PASS@HOST/DATABASE`                   |
| `SECRET_KEY_BASE`   | sim         | gere com `mix phx.gen.secret`                      |
| `PHX_HOST`          | não         | host público (default `example.com`)               |
| `PORT`              | não         | porta HTTP (default `4000`)                        |
| `PHX_SERVER`        | não         | `true` para iniciar o endpoint a partir do release |
| `POOL_SIZE`         | não         | tamanho do pool do Ecto (default `10`)             |
| `ECTO_IPV6`         | não         | `true`/`1` para habilitar IPv6 no banco            |
| `DNS_CLUSTER_QUERY` | não         | query DNS usada pelo DNSCluster                    |

Veja também o
[guia oficial de deploy do Phoenix](https://hexdocs.pm/phoenix/deployment.html).

## Recursos do Phoenix

- Site oficial: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Fórum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>
