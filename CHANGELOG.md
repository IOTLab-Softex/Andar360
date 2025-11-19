# Histórico de Versões
1 → MAJOR
Quebra de compatibilidade. Só muda para 2.x.x quando você fizer mudanças incompatíveis com versões anteriores (APIs removidas/alteradas de forma que quem usa quebre).

0 → MINOR
Funcionalidades novas, mas compatíveis com a versão anterior. Não devem quebrar quem já usa (APIs só adicionadas, comportamentos preservados).

7 → PATCH
Correções de bugs e ajustes internos compatíveis, sem mudar comportamento público (refactors, fixes, otimizações).


## [1.0.58] pre-alpha - 2025-07-11 | 90 % Responsivo a Mobile

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
