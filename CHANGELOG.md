# Histórico de Versões

## [1.1.9] release - 2026-06-03

### Adicionado

* Agente IA com suporte a manutenção programada: criar, cancelar, listar e consultar status.
* Agente IA com consulta de encomendas na portaria.
* Agente IA com consulta de cadastros aguardando aprovação sem expor dados sensíveis.
* Agente IA com controle de objetos por perfil: admin gerencia retirada/devolução/histórico, operador depende da permissão do subgrupo, cliente consulta apenas objetos em seu nome.
* Verificação de dispositivo online antes de enviar comando de abertura de porta.

### Melhorado

* Dashboard com cards mais estáveis ao expandir, contadores fixos e ocultos no modo personalizar.
* `feedback-fab`, `monitoring-fab` e `ai-agent-fab` reorganizados com espaçamento mais consistente.
* Cards do dashboard alinhados com a cor de fundo dos KPIs.
* Campo do agente no desktop envia com Enter e quebra linha com Shift+Enter.
* Voz do agente com ajustes de microfone, interrupção e acentuação nas respostas faladas.
* Tela de release redesenhada para a versão 1.1.9.

### Corrigido

* Evita anúncios na tela `/users/edit`.
* Evita duplicidade na seleção de salas ao abrir porta pelo agente.
* Corrige consulta de objeto devolvido para o cliente saber se a chave/projetor foi devolvido.
* Cliente que tentar retirar objeto pelo agente agora é orientado a procurar a portaria ou o responsável.

---

Primeiro digito → MAJOR
Quebra de compatibilidade. Só muda para 2.x.x quando você fizer mudanças incompatíveis com versões anteriores (APIs removidas/alteradas de forma que quem usa quebre).

Segundo digito → MINOR
Funcionalidades novas, mas compatíveis com a versão anterior. Não devem quebrar quem já usa (APIs só adicionadas, comportamentos preservados).

Terceiro digito → PATCH
Correções de bugs e ajustes internos compatíveis, sem mudar comportamento público (refactors, fixes, otimizações).

## [1.0.20] pre-alpha - 2025-12-16 | 90 % Responsivo a Mobile
* **Bugs**
    * [/formulario_cadastros/new]-[Status:]
      *Formulário não esta reposivo, e precisa ser separado por função no setor para notificar responsável de cadastramento por email*
      
    * [/dashboard]-[Status:]
      *O orverley do modal de perfil precisa sobrepor o togle de opção sidebar*
      
    * [/settings/1/edit]-[Status:]
      *Verificar o sistema de importação dos arquivos do incontrol*
      
    * [/dashboard]-[Status:]
      *Tabela esta mostrando o Head quando não tem conteúdo e esta mostrando quebrado a versão mobile*
      
    * [/prestador_servicos/new]-[Status:Corrigido]
      *A ferramenta de feedback não esta conseguindo upar imagem Apresenta esse erro ERR_UPLOAD_FILE_CHANGED*
      
    * [/prestador_servicos/new]-[Status:]
      *Ao criar a encomenda esta apresentando erro 500*
    
    * [/feedbacks]-[Status:]
      *sistema não esta conseguindo excluir os feedback*
* **Melhoria**
    * [/reservations/new]-[Status:]
      *No solicitante seria interessante deixa o usuário logado pre selecionado com opções de desmarcar-lo*
      
    * [/solicitacao_compras/new]-[Status:]
      *A barra de salvar e cancelar esta sobrepondo os campos na versão mobile*
      
    * [/prestador_servicos/new]-[Status:]
      *Prestador de serviço esta sem validação de dados*
      
    * [/participants]-[Status:Resolvido]
      *Usuário na tabela de excluido ou aguardando aprovação de exclusão tem que perder o acesso ao sistema a nao ser que ele estaja na tebela usuário*
         
    * [/feedbacks]-[Status:]
      *Colocar opção para gerar CHANGELOG com feedback resolvidos e ja imcluir na versão do path*

    * [/dashboard]-[Status:]
      *colocar atualização no monitoramento para os kpi*

## [1.0.7] pre-alpha - 2025-07-11 | 90 % Responsivo a Mobile

*Ciclo de desenvolvimento: ~3 meses*

### Adicionado

* **Inicia importação manual**
* **Solicitação de compra**

  * **Função do usuario por cargo** Selecionar no cargo qual funcionario tem permissão para Solicitar comprar, autorizar comprar e quem compra.
  * **adcionar checkbox com as permiçoes** Na seleção de cargo vai ser permitido conceder a função a o funcionario pelo seu cargo.

* **Ler regra da sala antes de reservar**

  * **Configuração** opção de habilitar/desabilitar a leitura de regra da sala.
  * **Confirmação de leitura** adcionar o modal com a exebição da regra e confimação da leitura.

* **Chamados de manutenção**

  * Abertura de chamados de manutenção pelos usuários.
  * **Ações rápidas** no *index* para mudar o status do chamado.
* **Manutenção programada**

  * Cadastro e gestão de manutenções programadas.
* **Formulário de cadastro para acesso por reconhecimento facial**
  *(substitui o formulário do Google, com mais controle e automação)*

  * Captura de foto integrada.
  * Notificação por e-mail.
  * Acompanhamento do status do cadastro.
  * Permissão para que empresas cadastrem seus funcionários.

### Corrigido

* **Chamados**

  * Ao editar e anexar novo arquivo, o sistema **não substitui mais** o anexo anterior; agora **acrescenta** ao histórico de ocorrências.
* **Manutenção programada**

  * Anexos não são mais duplicados entre “manutenção programada” e “novo anexo”.
  * *Backdrop* do modal agora cobre a tela inteira.
  * Título com suporte adequado ao modo claro.

### Próximas atualizações (Roadmap)

* **Comunicação**

  * Mural de aviso — emitir avisos em massa para grupos.
  * Comunicados individuais — enviar aviso individual.
* **Portaria**

  * Usuário “portaria”.
  * Achados e perdidos.
* **Condomínio (em desenvolvimento)**

  * **Área comum** (salas compartilhadas, **não reserváveis**).
  * **Mapa de manutenção** (visualizar áreas em manutenção e abrir solicitações).

### Problemas conhecidos

* **Participantes**

  * Clientes ainda conseguem visualizar dados completos de usuários. *(Restringir permissões — pendente.)*

### Checagem de funcionalidades

* **Reservas de Salas**
  * Criar reservas - OK
---

## [1.0.6] beta - 2025-06-05

### Corrigido

* Validação de data e hora: impedir salvar reservas com término menor que o início.
* Exigir preenchimento obrigatório nos campos de reserva.
* Ajustes de layout em dispositivos móveis nas telas:

  * `index#participantes`
  * `new#reservation`

### Adicionado

* Integração facial automática.
* Validação de agendamento por subgrupo.

---

## [1.0.5] beta - 2025-05-30

### Corrigido

* Erro no modal de participantes.
