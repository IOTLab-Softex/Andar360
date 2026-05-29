# Changelog — Anúncios, Notificações e Melhorias Gerais

> Documento gerado em 13/05/2026  
> Cobre as alterações desde o commit `46ad7425` (04/05/2026) até as mudanças atuais (não commitadas)  
> Branch: `master`

---

## Sumário

1. [v1 — Feature: Sistema de Anúncios (04/05/2026)](#v1--feature-sistema-de-anúncios)
2. [v1.1 — Melhorias no Modal de Anúncios (05–11/05/2026)](#v11--melhorias-no-modal-de-anúncios)
3. [v1.2 — Painel de Anúncios na Tela de Login (11/05/2026)](#v12--painel-de-anúncios-na-tela-de-login)
4. [v1.0.9 — Permissões Portaria, Hard-Delete de Participantes e Correções (11/05/2026)](#v109--permissões-portaria-hard-delete-e-correções)
5. [v1.1.0-dev — Melhorias de UI e Comportamento (sessão atual)](#v110-dev--melhorias-de-ui-e-comportamento-sessão-atual)
   - [5.1 Suporte a vídeo nos anúncios](#51-suporte-a-vídeo-nos-anúncios)
   - [5.2 Sino de notificação redesenhado](#52-sino-de-notificação-redesenhado)
   - [5.3 Exclusão inteligente de participantes](#53-exclusão-inteligente-de-participantes)
   - [5.4 Formulário de anúncios redesenhado](#54-formulário-de-anúncios-redesenhado)
   - [5.5 Indicador de tipo de mídia no índice de anúncios](#55-indicador-de-tipo-de-mídia-no-índice-de-anúncios)
   - [5.6 Carrossel de espaços comuns — fix mobile](#56-carrossel-de-espaços-comuns--fix-mobile)
   - [5.7 Correção de cor no SweetAlert2 (tema escuro)](#57-correção-de-cor-no-sweetalert2-tema-escuro)
6. [v1.1.1-dev — Período, Segmentação por Empresa e Expiração Automática](#v111-dev--período-segmentação-por-empresa-e-expiração-automática)

---

## v1 — Feature: Sistema de Anúncios

**Commit:** `46ad7425` · 04/05/2026

### O que foi adicionado

O sistema de anúncios permite que administradores e operadores criem comunicados que aparecem automaticamente como modal para usuários que ainda não viram.

#### Banco de dados (migrações)

| Tabela | Colunas |
|---|---|
| `announcements` | `id`, `title` (string), `body` (text), `active` (boolean, default `true`), `created_by_id` (FK → users) |
| `announcement_views` | `id`, `user_id` (FK), `announcement_id` (FK), índice único `[user_id, announcement_id]` |

#### Model `Announcement`

```ruby
belongs_to :created_by, class_name: "User", optional: true
has_many   :announcement_views, dependent: :destroy
has_one_attached :image

scope :active, -> { where(active: true).order(created_at: :desc) }

def viewed_by?(user)
  announcement_views.exists?(user: user)
end
```

#### Model `User`

```ruby
has_many :announcement_views, dependent: :destroy
has_many :viewed_announcements, through: :announcement_views, source: :announcement
```

#### Controller `AnnouncementsController`

Ações: `index`, `new`, `create`, `edit`, `update`, `destroy`, `mark_viewed`

- Acesso restrito a `admin` ou `operador` para criar/editar/excluir
- `mark_viewed` — endpoint POST que registra o `AnnouncementView` via `find_or_create_by`

#### Views

- `announcements/index` — tabela com título, imagem, status, visualizações, criador e data
- `announcements/_form` — formulário com campos de título, corpo, imagem e toggle de status
- `shared/_announcement_modal` — modal sobreposto que exibe todos os anúncios ativos não vistos pelo usuário, com navegação entre múltiplos, marcação automática de visto e dots de progresso

#### Rotas adicionadas

```ruby
resources :announcements do
  member { post :mark_viewed }
end
```

---

## v1.1 — Melhorias no Modal de Anúncios

**Commits:** `c9cb16ea`, `07e823a9` · 05–11/05/2026

### Melhorias visuais do modal

- Imagem exibida em tamanho grande (`max-height: 420px`, `object-fit: contain`)
- Badge "Anúncio" com ícone de megafone no cabeçalho
- Contador de progresso "1 / 3" quando há múltiplos
- Dots (bolinhas) de progresso na rodapé
- Botão "Próximo" para avançar e "Entendido" no último
- Suporte a tema escuro e claro via variáveis CSS (`--color-card`, `--color-text`, `--color-accent`)
- Ícone de estrela no título do anúncio
- Borda roxa sutil (`rgba(112, 20, 241, 0.25)`) no card

### Correção

- `AnnouncementView` não estava declarado na `User` model — corrigido com `has_many :announcement_views, dependent: :destroy`

---

## v1.2 — Painel de Anúncios na Tela de Login

**Commit:** `61ef0596` · 11/05/2026

### Card público na tela de login

- Novo partial `shared/_login_announcement` exibido no rodapé da tela de login
- Visível para **qualquer pessoa** (não requer login)
- Campo `show_on_login` (boolean) adicionado à tabela `announcements`
- Apenas o anúncio mais recente com `show_on_login: true` é exibido como card fixo
- Ao clicar no card, abre modal com imagem grande e corpo completo
- Card oculto automaticamente quando há flash de alerta (ex.: erro de login)

### Card de clima na tela de login

- Integração com Open-Meteo API (sem chave de API)
- Exibe temperatura atual, condição e ícone do tempo
- Configurável via `Setting` (`login_weather_card_enabled`)
- Atualização automática a cada 10 minutos via JS

---

## v1.0.9 — Permissões Portaria, Hard-Delete e Correções

**Commit:** `7e0e11df` · 11/05/2026

### Permissões granulares para portaria (SubGrupoEmpresa)

Nova migração adiciona flags booleanas à tabela `sub_grupo_empresas`:

| Campo | Função |
|---|---|
| `can_manage_items` | Acesso ao módulo de itens |
| `can_manage_encomendas` | Acesso ao módulo de encomendas |

Controllers `EncomendasController` e `ItemsController` passam a verificar essas flags antes de liberar acesso.

### Hard-delete de participantes

- Participantes com `excluido: true` (soft-deleted) agora podem ser **excluídos definitivamente** pelo admin
- Cascata segura: limpa `access_logs`, nulifica FK em chamados, encomendas e reservas antes de destruir
- Participantes ativos só podem ser soft-deleted (via fluxo de exclusão existente)
- Restrição: somente admins podem excluir participantes

### Correções

- Calendário de reservas em mobile: layout responsivo corrigido com CSS
- Painel de anúncio de login oculto quando há flash alert presente
- Melhorias gerais de controle de acesso em controllers

---

## v1.1.0-dev — Melhorias de UI e Comportamento (sessão atual)

> Alterações não commitadas. Arquivos modificados: 18 arquivos, +1.446 linhas / -550 linhas.

---

### 5.1 Suporte a vídeo nos anúncios

**Arquivos:** `_announcement_modal.html.erb`, `_login_announcement.html.erb`, `announcements/_form.html.erb`

#### O que mudou

- Campo único de upload (`f.file_field :image`) aceita `image/*,video/*`
- Detecção de tipo via `content_type.start_with?("video/")` em tempo de renderização
- **Modal de anúncios** (`_announcement_modal`):
  - Elemento `<video autoplay muted loop playsinline>` renderizado quando o anexo é vídeo
  - Botão de som flutuante no canto inferior direito do vídeo
  - Ícone muda entre `fa-volume-xmark` (mudo) e `fa-volume-high` (com som)
  - JSON enviado ao JS inclui campos separados `image:` e `video:`
- **Card de login** (`_login_announcement`):
  - Thumbnail do card usa `<video>` para vídeos
  - Modal de detalhe usa `<video>` com botão de som idêntico
  - `closeModal()` pausa o vídeo e reseta para mudo

#### Comportamento

| Tipo de mídia | Thumbnail | Modal |
|---|---|---|
| Imagem | `<img>` | `<img>` |
| Vídeo | `<video autoplay muted loop>` | `<video autoplay muted loop>` + botão de som |
| Sem mídia | — | Apenas título e corpo |

---

### 5.2 Sino de notificação redesenhado

**Arquivo:** `layouts/application.html.erb`

#### Visual

- Sino agora tem **fundo circular cinza** igual ao `.user-avatar` (usando `var(--foto-user-avatar)`)
- Dimensões: `50×50 px`, `border-radius: 50%`
- **Nome do usuário movido para depois do sino** (antes ficava antes)

#### Comportamento do efeito de pulso e balão

**Antes:** o efeito (pulso + balão amarelo) reaparecia a cada reload de página.

**Depois:** persistência via `localStorage`

```
key: notif_dismissed_at_count
valor: número de não lidas no momento em que o usuário abriu o sino
```

Regra: o efeito só aparece se `notificações_não_lidas_agora > notif_dismissed_at_count`.  
Ao abrir o painel, salva o valor atual — efeito some e não volta até chegarem notificações novas.

#### Fix: pulso interceptando cliques

`::before` pseudo-elemento do `.notification-btn.attention` recebia `inset: -6px` expandindo a área além do botão.  
**Correção:** `pointer-events: none` no pseudo-elemento.

---

### 5.3 Exclusão inteligente de participantes (Smart Delete)

**Arquivos:** `participants_controller.rb`, `participants/index.html.erb`, `config/routes.rb`

#### Antes

Ao tentar excluir um participante com reservas vinculadas, exibia alert de bloqueio e não permitia a exclusão.

#### Depois

1. Frontend faz `GET /participants/:id/check_dependencies` antes do submit
2. Controller retorna JSON com contagens:

```json
{
  "chamados_solicitante": 2,
  "reservas_solicitante": 1,
  "reservas_responsavel": 0,
  "reservas_participante": 3,
  "has_dependencies": true
}
```

3. Se `has_dependencies: true`, exibe SweetAlert2 detalhando o impacto:

```
⚠️ Este participante possui vínculos:
• 2 chamado(s) como solicitante → serão excluídos
• 1 reserva(s) como solicitante → serão excluídas
• 3 reserva(s) como participante → serão desvinculadas
```

4. Se o admin confirmar, a exclusão executa em transação:

```ruby
Participant.transaction do
  Chamado.where(solicitante_id: id).destroy_all
  Reservation.where(solicitante_id: id).destroy_all
  Reservation.where(responsavel_id: id).update_all(responsavel_id: nil)
  participant.reservations.clear
  participant.destroy!
end
```

#### Rota adicionada

```ruby
resources :participants do
  member { get :check_dependencies }
end
```

---

### 5.4 Formulário de anúncios redesenhado

**Arquivo:** `announcements/_form.html.erb`

#### Layout

- Botões "Cancelar" e "Salvar/Criar" movidos para `<div class="form-group-fixed">` (barra fixa no topo)
- Seções com `chamado-section section-box` + `chamado-grid` (mesmo padrão dos chamados)
- Três seções: **Conteúdo**, **Configurações de exibição**, **Período**, **Segmentação por empresa**

#### Toggle switches

Substituição de checkboxes simples por toggles animados (`.ann-toggle`) compatíveis com tema escuro:
- Track cinza → verde quando ativo
- Labels dinâmicos `data-on` / `data-off`
- **Status**: Ativo / Inativo
- **Tela de login**: Sim / Não

#### Confirmação SweetAlert2 para "Exibir na tela de login"

Ao ativar o toggle "Tela de login", exibe alerta:

> *"Ao ativar esta opção, o card ficará visível para qualquer pessoa que acessar a tela de login — incluindo usuários não autenticados. Deseja continuar?"*

Se cancelar, o toggle volta para Não.

#### Visualizador de imagem (modal)

- Thumbnail clicável com ícone de olho ao hover
- Abre modal de tela cheia com zoom via scroll do mouse
- Fechar com clique fora ou tecla `Escape`

#### Correção: bug `layout_helper.rb`

`@announcements.id` (plural → nil) causava `NoMethodError` na página de edição.  
**Correção:** `@announcement&.id` (singular + operador safe navigation).

---

### 5.5 Indicador de tipo de mídia no índice de anúncios

**Arquivo:** `announcements/index.html.erb`

- Coluna renomeada de "Imagem" para **"Mídia"**
- Vídeos exibem `<video preload="metadata">` como thumbnail (mostra o primeiro frame)
- Badge indicador abaixo do thumbnail:
  - `fa-film` + "Vídeo" (roxo/índigo) para vídeos
  - `fa-image` + "Imagem" (cinza) para imagens

---

### 5.6 Carrossel de Espaços Comuns — fix mobile

**Arquivo:** `dashboard/_espacos_comuns.html.erb`

Botões de ação dos cards (`.room-actions`) em telas móveis recebiam `transform` herdado do posicionamento do carrossel, deslocando os botões visualmente.

**Correção:** `transform: none !important` adicionado nos breakpoints `768px` e `480px`.

---

### 5.7 Correção de cor no SweetAlert2 (tema escuro)

**Arquivo:** `assets/stylesheets/dashboard.css`

Popups do SweetAlert2 herdavam `color: #fff` do tema escuro, tornando título, texto e inputs invisíveis (texto branco sobre fundo branco).

**Correção global:**

```css
.swal2-popup {
  color: #1f2937 !important;
  background: #ffffff !important;
}
.swal2-popup .swal2-title,
.swal2-popup .swal2-html-container,
.swal2-popup input { color: #1f2937 !important; }
```

---

## v1.1.1-dev — Período, Segmentação por Empresa e Expiração Automática

> Alterações atuais desta sessão.

### Migração

**Arquivo:** `db/migrate/20260513100000_add_period_and_companies_to_announcements.rb`

```ruby
add_column :announcements, :starts_at, :datetime   # início do período de exibição
add_column :announcements, :ends_at,   :datetime   # fim do período de exibição

create_table :announcement_grupo_empresas, id: false do |t|
  t.bigint :announcement_id, null: false
  t.bigint :grupo_empresa_id, null: false
end
```

---

### Modelo `Announcement` — novos scopes e associações

```ruby
has_and_belongs_to_many :grupo_empresas,
                        join_table: :announcement_grupo_empresas

# Filtra pelo período de exibição (nil = sem restrição)
scope :in_period, -> {
  now = Time.current
  where("(starts_at IS NULL OR starts_at <= ?) AND (ends_at IS NULL OR ends_at >= ?)", now, now)
}

# Filtra por empresa do usuário (sem empresas = visível para todos)
scope :visible_to, ->(user) {
  gid = user.participant&.grupo_empresa_id&.to_i || 0
  where(
    "announcements.id NOT IN (SELECT announcement_id FROM announcement_grupo_empresas)
     OR announcements.id IN (SELECT announcement_id FROM announcement_grupo_empresas WHERE grupo_empresa_id = ?)",
    gid
  )
}

# Expiração lazy: muda active → false em registros vencidos
def self.expire_passed!
  where(active: true).where.not(ends_at: nil)
    .where("ends_at < ?", Time.current)
    .update_all(active: false)
end
```

---

### Formulário — novas seções

#### Período de exibição

- Campo **"Exibir a partir de"** (`starts_at`) — datetime-local, opcional
- Campo **"Exibir até"** (`ends_at`) — datetime-local, opcional
- Deixar em branco = sem restrição de período

#### Segmentação por empresa

- Checkboxes estilizados em grade responsiva para cada `GrupoEmpresa`
- **Sem seleção** = anúncio visível para **todos os usuários**
- **Com seleção** = visível apenas para usuários cujo participante pertence a uma das empresas marcadas
- **Barra de pesquisa** em tempo real filtra os cards pelo nome da empresa
  - Ícone de lupa, botão `✕` para limpar, mensagem "Nenhuma empresa encontrada"
- **Auto-seleção** na criação: se o usuário logado pertence a uma empresa, ela é pré-marcada automaticamente
- **Contador dinâmico** no cabeçalho: "Todos os usuários" / "X empresa(s) selecionada(s)"

#### Visual dos cards de empresa

| Estado | Aparência |
|---|---|
| Nenhum selecionado | Cards normais, borda sutil |
| Selecionado | Fundo `rgb(54 7 120)`, borda + glow `#7014f1`, texto branco bold |
| Não selecionado (quando há seleção) | `opacity: 0.35`, `saturate(0.3)` — acinzentado |
| Hover no acinzentado | `opacity: 0.7`, `saturate(0.7)` |

#### Bloqueio automático de "Tela de login" com empresa selecionada

Regra de negócio: anúncio segmentado por empresa não pode aparecer na tela de login pública (que é acessada por qualquer pessoa, sem contexto de empresa).

- Ao selecionar qualquer empresa: toggle "Tela de login" é **desmarcado e desabilitado**
- Mensagem exibida: *"Indisponível — este anúncio está segmentado por empresa. Remova todas as empresas selecionadas para liberar esta opção."*
- Ao remover todas as seleções: toggle volta a ser **habilitado**

---

### Índice de anúncios — novas colunas

| Coluna | Conteúdo |
|---|---|
| **Período** | Datas de início e fim com ícones; badge "Aguardando" (amarelo) se ainda não iniciou; badge "Expirado" (cinza) se passou |
| **Visualizações** | Contador numérico + rótulo "usuário(s)" |
| **Empresas** | Badge roxo "Todos" se nenhuma empresa; lista de badges com nome de cada empresa selecionada |

O índice agora lista **todos os anúncios** (ativos e inativos), não apenas os ativos.

---

### Expiração automática de anúncios

`Announcement.expire_passed!` é chamado em três pontos:

| Ponto de chamada | Quando ocorre |
|---|---|
| `AnnouncementsController#index` | Admin acessa a listagem |
| `shared/_announcement_modal` | Qualquer página carregada por usuário logado |
| `shared/_login_announcement` | Tela de login |

**Comportamento:**
- Anúncio com `ends_at < agora` e `active: true` → `active` muda para `false` automaticamente
- **Re-ativação:** admin edita o anúncio, define nova data futura (ou remove a data) e marca como Ativo → volta a aparecer normalmente

---

## Resumo de arquivos modificados nesta sessão

| Arquivo | Tipo de alteração |
|---|---|
| `db/migrate/20260513100000_add_period_and_companies_to_announcements.rb` | **Novo** — migração |
| `app/models/announcement.rb` | Novos scopes `in_period`, `visible_to`, `expire_passed!`; HABTM com `grupo_empresas` |
| `app/models/grupo_empresa.rb` | HABTM com `announcements` |
| `app/controllers/announcements_controller.rb` | `expire_passed!` no index; `@grupo_empresas` em `new`/`edit`; auto-select empresa; params com `starts_at`, `ends_at`, `grupo_empresa_ids` |
| `app/views/announcements/_form.html.erb` | Seções Período e Segmentação; barra de pesquisa; visual dos cards; bloqueio do toggle login |
| `app/views/announcements/index.html.erb` | Colunas Período, Visualizações, Empresas; badge de mídia; thumbnail de vídeo |
| `app/views/shared/_announcement_modal.html.erb` | Filtros `in_period`, `visible_to`, `expire_passed!` |
| `app/views/shared/_login_announcement.html.erb` | Filtro `in_period`, `expire_passed!` |
| `app/assets/stylesheets/dashboard.css` | Fix SweetAlert2 tema escuro |
| `app/views/layouts/application.html.erb` | Sino circular; nome após sino; localStorage para efeito; `pointer-events: none` no pulso |
| `app/views/participants/index.html.erb` | Smart delete com SweetAlert2 e check de dependências |
| `app/controllers/participants_controller.rb` | `check_dependencies`; `destroy` com transação em cascata |
| `config/routes.rb` | Rota `check_dependencies` em participants |
| `app/views/dashboard/_espacos_comuns.html.erb` | `transform: none` em `.room-actions` mobile |
| `app/helpers/layout_helper.rb` | Fix `@announcements` → `@announcement&.id` |
