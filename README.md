# Telecore

Aplicação [Phoenix](https://www.phoenixframework.org/) 1.8 em Elixir, servindo
como base para produtos web. Inclui login simples por email/senha (cookie
session), Postgres via Ecto, build de assets com Tailwind/esbuild e ferramental
de qualidade pré-configurado.

## Stack

- **Elixir** `~> 1.18` + **Phoenix** `~> 1.8.5`
- **Phoenix LiveView** `~> 1.1` (disponível, ainda não usado pelas páginas atuais)
- **Ecto / Postgrex** sobre **PostgreSQL**
- **Bandit** como servidor HTTP
- **Tailwind** + **esbuild** para os assets
- **bcrypt_elixir** para hash de senha
- **Swoosh** para e-mails
- **DNSCluster** para clusterização
- **Credo**, **Dialyxir**, **ExMachina** e **Mox** para qualidade e testes

## Pré-requisitos

- Elixir 1.18+ e Erlang/OTP compatível
- PostgreSQL rodando localmente (em `localhost`, usuário `postgres`/`postgres`
  por padrão — ver [config/dev.exs](config/dev.exs))

## Setup

```bash
mix setup
```

Esse alias instala dependências, cria o banco, roda migrations, executa seeds
e prepara os assets. Detalhes em [mix.exs](mix.exs#L89-L104).

O seed cria um usuário admin a partir de variáveis de ambiente, com fallback
para credenciais de dev (`admin@telecore.dev` / `changeme123`):

```bash
SEED_ADMIN_EMAIL=you@example.com SEED_ADMIN_PASSWORD=...secret... mix run priv/repo/seeds.exs
```

## Subindo o servidor

```bash
mix phx.server
# ou, com IEx anexado:
iex -S mix phx.server
```

Acesse [http://localhost:4000](http://localhost:4000) — você será redirecionado
para `/login` se não estiver autenticado.

Em ambiente de desenvolvimento, ficam disponíveis sem auth:

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

## Rotas

Definidas em [lib/telecore_web/router.ex](lib/telecore_web/router.ex).

| Método   | Rota      | Descrição                                                |
| -------- | --------- | -------------------------------------------------------- |
| `GET`    | `/login`  | Formulário de login                                      |
| `POST`   | `/login`  | Autentica email + senha; redireciona pra `/`             |
| `DELETE` | `/logout` | Encerra a sessão; redireciona pra `/login`               |
| `GET`    | `/`       | Página da aplicação (autenticada — redireciona se não)   |

Sem registro público, sem reset de senha, sem API JSON (a versão atual). Adição
de novos usuários é feita por seed ou via console (`Telecore.Accounts.create_user/1`).

## Estrutura

```
lib/
├── telecore/
│   ├── accounts.ex         # contexto: get_user_*/create_user
│   └── accounts/user.ex    # schema + changesets
└── telecore_web/
    ├── auth.ex             # plugs e helpers de sessão (cookie)
    ├── controllers/
    │   ├── session_controller.ex
    │   └── session_html/new.html.heex
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
| `DNS_CLUSTER_QUERY`      | não         | query DNS usada pelo DNSCluster                                                                               |
| `CLOAK_KEY`              | sim         | chave AES-256 em Base64 para criptografar credenciais de roteadores; gere com `:crypto.strong_rand_bytes(32) \| Base.encode64()` |
| `MIKROTIK_TLS_INSECURE`  | não         | defina como `"true"` para desabilitar verificação de certificado TLS (use apenas em dev/staging com certs autoassinados) |

Para o seed do admin em produção, defina também `SEED_ADMIN_EMAIL` e
`SEED_ADMIN_PASSWORD` antes de rodar `mix run priv/repo/seeds.exs`.

Veja também o
[guia oficial de deploy do Phoenix](https://hexdocs.pm/phoenix/deployment.html).

## Recursos do Phoenix

- Site oficial: <https://www.phoenixframework.org/>
- Guides: <https://hexdocs.pm/phoenix/overview.html>
- Docs: <https://hexdocs.pm/phoenix>
- Fórum: <https://elixirforum.com/c/phoenix-forum>
- Source: <https://github.com/phoenixframework/phoenix>
