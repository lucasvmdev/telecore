# Integração MikroTik

Documentação técnica da integração com a API REST do RouterOS (MikroTik), do banco de dados ao front-end.

## Visão geral

Telecore expõe uma interface web (Phoenix LiveView) para gerenciar **roteadores MikroTik**, **clientes PPPoE (secrets)** e **sessões ativas**. O acesso ao roteador é abstraído por uma *behaviour* Elixir, permitindo trocar a implementação real (HTTP) por um Fake in-memory em desenvolvimento ou um Mock em testes — sem alterar o código do contexto nem das telas.

```
                       ┌──────────────────────────────────┐
                       │   Browser (LiveView no cliente)  │
                       └────────────────┬─────────────────┘
                                        │ WebSocket / HTTP
                       ┌────────────────▼─────────────────┐
                       │   TelecoreWeb (Phoenix + Live)   │
                       │  Auth · Layouts · LiveViews      │
                       └────────────────┬─────────────────┘
                                        │ chamadas Elixir
                       ┌────────────────▼─────────────────┐
                       │   Telecore.Mikrotik (contexto)   │
                       │  CRUD de Router + delegação      │
                       └────────┬──────────────┬──────────┘
                                │              │
                  Repo (Postgres)              │ adapter (config)
                                               │
              ┌────────────────────────────────┼─────────────────────────┐
              │                                │                         │
   ┌──────────▼─────────┐   ┌──────────────────▼──────────┐   ┌──────────▼────────┐
   │ Mikrotik.HTTP      │   │ Mikrotik.Fake (dev)         │   │ Mikrotik.Mock     │
   │ (RouterOS REST)    │   │ GenServer in-memory         │   │ (Mox em test)     │
   └──────────┬─────────┘   └─────────────────────────────┘   └───────────────────┘
              │
   ┌──────────▼─────────┐
   │  Roteador físico   │
   │  ou CHR (lab)      │
   └────────────────────┘
```

---

## Camadas

### 1. Persistência — `mikrotik_routers`

Tabela Postgres com os roteadores cadastrados:

| Coluna | Tipo | Notas |
|---|---|---|
| `id` | UUID | PK |
| `label` | string | rótulo livre (ex.: `POP-SP-01`) |
| `url` | string | endpoint REST do roteador (`https://10.10.1.1`) |
| `username` | string | usuário do RouterOS |
| `password` | binary | **criptografado em repouso** via Cloak (AES-GCM) |
| `inserted_at` / `updated_at` | utc_datetime | |

A senha nunca fica em texto plano no banco. A criptografia/descriptografia é transparente para o resto da aplicação — quem lê um `%Router{}` recebe a senha em texto plano; quem grava passa em texto plano e o Cloak cifra.

**Arquivos:**
- [lib/telecore/mikrotik/router.ex](../lib/telecore/mikrotik/router.ex) — schema + changeset
- [lib/telecore/encrypted/binary.ex](../lib/telecore/encrypted/binary.ex) — tipo Cloak
- [lib/telecore/vault.ex](../lib/telecore/vault.ex) — vault do Cloak
- [priv/repo/migrations/*_create_mikrotik_routers.exs](../priv/repo/migrations/) — migração

### 2. Contrato — `Telecore.Mikrotik.Client` (behaviour)

Define a interface que toda implementação de cliente MikroTik deve respeitar. 13 callbacks cobrindo três recursos:

**PPPoE Secrets** (clientes)
- `list_secrets/1`
- `get_secret/2`
- `create_secret/2`
- `update_secret/3`
- `delete_secret/2`
- `enable_secret/2` / `disable_secret/2`

**Active Sessions** (sessões ativas)
- `list_sessions/1`
- `disconnect_session/2`

**Simple Queues** (gestão de banda)
- `list_queues/1`
- `create_queue/2`
- `update_queue/3`
- `delete_queue/2`

Todas retornam `{:ok, result} | {:error, %Telecore.Mikrotik.Error{}}`. A struct `Error` tem dois campos: `code` (`:unauthorized | :not_found | :conflict | :timeout | :unknown`) e `message`.

**Arquivos:**
- [lib/telecore/mikrotik/client.ex](../lib/telecore/mikrotik/client.ex)
- [lib/telecore/mikrotik/error.ex](../lib/telecore/mikrotik/error.ex)

### 3. Implementações da behaviour

#### `Telecore.Mikrotik.HTTP` (produção)

Fala com o RouterOS via API REST usando `Req`. Usado em produção e em dev quando o operador tem um roteador real (ou CHR) acessível.

- Autenticação Basic com `auth: {:basic, {username, password}}` (forma tupla, evita problemas com `:` na senha).
- Mapeia status HTTP para códigos da `%Error{}`:
  - `401` → `:unauthorized`
  - `404` → `:not_found`
  - `400`/`422` com body `"already have"` → `:conflict`
  - timeout → `:timeout`
  - outros → `:unknown`
- TLS verifica certificado por padrão. `MIKROTIK_TLS_INSECURE=true` desabilita (uso só em homologação com self-signed).

**Arquivo:** [lib/telecore/mikrotik/http.ex](../lib/telecore/mikrotik/http.ex)

#### `Telecore.Mikrotik.Fake` (dev)

GenServer in-memory que implementa a mesma behaviour. Mantém estado por `router.id` e gera dados realistas de seed na primeira consulta. Permite navegar todas as telas sem precisar de um RouterOS rodando.

- Cada roteador novo recebe um conjunto de secrets, sessões e queues.
- A variação entre roteadores é determinística por hash do `router.id` — alguns clientes nascem desabilitados, alguns roteadores ficam sem certas sessões.
- Operações (create/update/delete/disable) modificam o estado em memória. Reiniciar o servidor reseta tudo.

**Arquivo:** [lib/telecore/mikrotik/fake.ex](../lib/telecore/mikrotik/fake.ex)

#### `Telecore.Mikrotik.Mock` (test)

Mock gerado por [Mox](https://hexdocs.pm/mox) com `Mox.defmock(Telecore.Mikrotik.Mock, for: Telecore.Mikrotik.Client)`. Cada teste configura `expect/3` para definir o comportamento esperado, sem dependência de banco ou GenServer.

**Arquivo:** [test/support/mocks.ex](../test/support/mocks.ex)

### 4. Contexto público — `Telecore.Mikrotik`

Único módulo que o resto da aplicação usa. Centraliza:

- **CRUD do schema `Router`** (vai direto pro Repo): `list_routers/0`, `get_router!/1`, `create_router/1`, `update_router/2`, `delete_router/1`.
- **Delegação para o adapter** (vai pro HTTP/Fake/Mock conforme config): `list_secrets/1`, `disable_secret/2`, `disconnect_session/2`, etc.

A escolha do adapter é feita por configuração — o contexto não sabe (nem precisa saber) qual implementação está atrás:

```elixir
defp adapter, do: Application.fetch_env!(:telecore, :mikrotik_adapter)

def list_secrets(router), do: adapter().list_secrets(router)
```

**Arquivo:** [lib/telecore/mikrotik.ex](../lib/telecore/mikrotik.ex)

### 5. Configuração por ambiente

| Ambiente | Adapter | Onde |
|---|---|---|
| `:dev` | `Telecore.Mikrotik.Fake` | [config/dev.exs](../config/dev.exs) |
| `:test` | `Telecore.Mikrotik.Mock` | [config/test.exs](../config/test.exs) |
| `:prod` | `Telecore.Mikrotik.HTTP` | [config/runtime.exs](../config/runtime.exs) |

A chave de criptografia do Cloak também varia:
- Dev/test: chave fixa em [config/config.exs](../config/config.exs) (commitada — usada apenas para dados não sensíveis).
- Prod: lida da env `CLOAK_KEY` em runtime.

O Fake é adicionado ao supervisor da aplicação **só em dev** — em produção e teste não há GenServer in-memory rodando.

**Arquivo:** [lib/telecore/application.ex](../lib/telecore/application.ex)

---

## Front-end (Phoenix LiveView)

### Estrutura de rotas

Todas as rotas autenticadas vivem dentro de uma `live_session :authenticated` que usa o hook `TelecoreWeb.Auth.on_mount(:ensure_authenticated, ...)` para carregar o usuário da sessão e redirecionar para `/login` se não estiver logado.

```
/                                       → redireciona para /routers
/login                                  → form de login (controller, não LiveView)
/routers                                → lista de roteadores
/routers/new                            → modal "novo roteador"
/routers/:id                            → visão geral (cards de contagem)
/routers/:id/edit                       → modal "editar roteador"
/routers/:id/sessions                   → sessões PPPoE ativas (polling 5s)
/routers/:id/secrets                    → lista de clientes
/routers/:id/secrets/new                → modal "novo cliente"
/routers/:id/secrets/:name/edit         → modal "editar cliente"
```

**Arquivo:** [lib/telecore_web/router.ex](../lib/telecore_web/router.ex)

### LiveViews

#### `RouterLive.Index` — lista de roteadores

[lib/telecore_web/live/router_live/index.ex](../lib/telecore_web/live/router_live/index.ex)

Tabela com label, URL, usuário e ações (Ver, Editar, Excluir). O botão "Novo Roteador" abre um modal renderizado via `live_action: :new`. O form é um `live_component` (`RouterLive.FormComponent`) com `simple_form` + inputs do core_components.

**Funcionalidade extra: "Testar conexão"** — antes de salvar, o operador pode validar credenciais clicando em um botão que tenta `Mikrotik.list_secrets(router_provisorio)` e mostra um flash com o resultado. Funciona contra qualquer adapter — em dev usa o Fake, em prod bate no roteador real.

#### `RouterLive.Show` — visão geral

[lib/telecore_web/live/router_live/show.ex](../lib/telecore_web/live/router_live/show.ex)

Página de entrada de cada roteador. Mostra três cards clicáveis com a contagem de **sessões ativas**, **clientes** e **queues**. Cada card leva à listagem correspondente. Quando o adapter retorna erro, o card mostra `—`.

#### `SessionLive.Index` — sessões PPPoE ativas

[lib/telecore_web/live/session_live/index.ex](../lib/telecore_web/live/session_live/index.ex)

LiveView com **polling de 5 segundos** via `Process.send_after(self(), :tick, 5_000)`. A cada tick, recarrega a lista de sessões. Mostra nome do cliente, IP, serviço, uptime, caller-ID e um botão "Desconectar" que chama `Mikrotik.disconnect_session/2` com confirmação JS.

#### `SecretLive.Index` — gestão de clientes

[lib/telecore_web/live/secret_live/index.ex](../lib/telecore_web/live/secret_live/index.ex)

CRUD completo de clientes PPPoE:

- Listagem com badge de status (Habilitado/Desabilitado).
- Botão por linha: "Editar", "Habilitar/Desabilitar" (alternância imediata, sem modal), "Excluir" (com confirmação).
- Modal de criar/editar via `SecretLive.FormComponent` ([form_component.ex](../lib/telecore_web/live/secret_live/form_component.ex)).

##### `Telecore.Mikrotik.SecretForm` — schema de form

O RouterOS devolve secrets como mapas com chaves string (`%{"name" => "...", ".id" => "*1"}`), o que não casa bem com o ergonômico `<.input field={@form[:name]}>` do Phoenix. A solução é um `Ecto.Schema` virtual (`embedded_schema`) que serve de ponte:

- `changeset/2` valida campos (required, formato do `name`).
- `to_attrs/1` converte a struct validada em mapa string-keyed para o adapter.
- `from_secret/1` carrega um mapa do adapter de volta na struct (para edição).

Resultado: o form usa todas as conveniências do `core_components` e o adapter recebe o mapa que ele espera.

**Arquivo:** [lib/telecore/mikrotik/secret_form.ex](../lib/telecore/mikrotik/secret_form.ex)

### Layout e componentes

#### `Layouts.app` — layout autenticado

Top nav com:
- Logo "Telecore" (link para `/routers`)
- Link "Roteadores"
- E-mail do usuário corrente
- Botão "Sair" (`delete /logout`)
- Toggle de tema claro/escuro/sistema

**Arquivo:** [lib/telecore_web/components/layouts.ex](../lib/telecore_web/components/layouts.ex)

#### `<.router_nav>` — sub-navegação por roteador

Quando o operador está dentro de um roteador específico, aparece uma sub-nav com breadcrumb (`Roteadores › POP-SP-01`) e três abas: "Visão geral", "Sessões", "Clientes". Cada LiveView passa qual aba está ativa para o componente destacar.

**Arquivo:** [lib/telecore_web/components/core_components.ex](../lib/telecore_web/components/core_components.ex)

### Auth em LiveView

O hook `on_mount(:ensure_authenticated, _, session, socket)` em `TelecoreWeb.Auth` é chamado pela `live_session :authenticated`. Ele:

1. Lê `user_id` da sessão (`Plug.Session` cookie).
2. Busca o usuário com `Telecore.Repo.get(Telecore.Accounts.User, id)`.
3. Se existe → assign `:current_user` e continua (`{:cont, socket}`).
4. Se não → redireciona para `/login` (`{:halt, redirect}`).

Isso roda toda vez que o operador navega entre LiveViews dentro do `live_session`, sem reconectar o WebSocket.

**Arquivo:** [lib/telecore_web/auth.ex](../lib/telecore_web/auth.ex)

---

## Fluxo end-to-end (exemplo)

**Cenário:** o operador desabilita um cliente PPPoE.

1. Operador clica em "Desabilitar joao" na `SecretLive.Index`.
2. JavaScript do LiveView envia `phx-click="toggle"` com `name: "joao", disabled: "false"` via WebSocket.
3. `handle_event("toggle", ...)` no LiveView chama `Telecore.Mikrotik.disable_secret(router, "joao")`.
4. O contexto resolve o adapter via `Application.fetch_env!(:telecore, :mikrotik_adapter)`.
5. Em **dev**: o `Fake` GenServer recebe `{:set_disabled, router_id, "joao", "true"}`, marca o secret como desabilitado e remove a sessão correspondente.
6. Em **prod**: o `HTTP` faz `GET /rest/ppp/secret?name=joao` para resolver o `.id`, depois `PATCH /rest/ppp/secret/<id>` com `{disabled: true}`.
7. O LiveView recebe o resultado, chama `load_secrets/1` para recarregar a tabela e exibe um flash de sucesso ou erro.

Tudo isso é coberto por testes:
- O contexto é testado com o `Mock` (Mox).
- O `Fake` tem testes de unidade próprios.
- A `RouterLive.Index` tem smoke tests com `Phoenix.LiveViewTest`.

---

## Stack resumida

| Camada | Tech |
|---|---|
| Banco | Postgres + Ecto + Cloak (criptografia de campo) |
| HTTP outbound | Req 0.5 |
| Behaviour/Mock | Mox 1.x |
| Web | Phoenix 1.8 + Phoenix.LiveView 1.1 |
| UI | Tailwind + DaisyUI + heroicons |
| Auth | Cookie session + bcrypt |

## Configuração para apresentação

```bash
# 1. Instalar dependências e preparar o banco
mix setup

# 2. Popular roteadores de exemplo (4 POPs)
mix run priv/repo/seeds.exs

# 3. Subir o servidor
mix phx.server
```

Acessar `http://localhost:4000`, logar com `admin@telecore.dev` / `changeme123` e navegar para `/routers`.
