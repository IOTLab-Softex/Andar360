# Histórico de Versões

## [1.0.7] - 2025-07-11 | 5% Responsivo a Mobile

*Ciclo de desenvolvimento: ~3 meses*

### Adicionado

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

---

## [1.0.6] - 2025-06-05

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

## [1.0.5] - 2025-05-30

### Corrigido

* Erro no modal de participantes.
