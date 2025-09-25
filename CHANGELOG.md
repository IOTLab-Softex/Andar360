# Histórico de Versões

## \[1.0.7] - 2025-07-11 duração da incrementação 3 meses

### Adicionado


-- Criação de funcionalidades de codomio
* Area comun ( sala onde são alocadas para empresas, que não pode ser reservadas): ADCIONANDO
* Mapa de manutenção (onde é possível visualizar as áreas que estão em manutenção, onde pode ser criada uma solicitação de manutenção ou chamado): ADCIONANDO
* Chamado de manutenção (onde é possível criar uma solicitação de manutenção): ADICIONADO
* Manutenção programada (onde é possível criar uma manutenção programada): ADICIONADO

-- Criação de Formulario de cadastro para acesso ao reconhecimento facial
Observação: esta função foi criar para substituir o form do google, e ter mais controle e automatizar o processo.

* formulario com suporte a captura de foto: ADICIONADO
* notificação por email: ADICIONADO
* acompanhamento do cadastro: ADICIONADO
* permisão para as empresas poder cadastar seus funcionanrios: ADICIONADO


### Correção de bugs
-- Chamado
- Esta substituindo ao inves de acresentar o arquivo quando anexar outro ao editar, o historico de ocorrencias: RESOLVIDO
- Adicionar buttos de ação para mudar status do chamado direto do index

-- Manutenção programada
- Esta anexando o arquvo tanto para manutenção programanda quanto para novo anexo: RESOLVIDO
- notificação do modal de manutenção programada backdrop não cobre a tela inteira, titulo sem suporte ao modo branco
-- Participantes
- client esta tendo acesso ao usuario total
### Corrigido

-- Chamado 
- Esta substituindo ao inves de acresentar o arquivo quando anexar outro ao editar, o historico de ocorrencias
-- Manutenção programada
- Esta anexando o arquvo tanto para manutenção programanda quanto para novo anexo



---

## \[1.0.6] - 2025-06-05

### Corrigido

* Validação de data e hora: impedido salvar reservas com data/hora final menor que a inicial
* Exigência de preenchimento obrigatório nos campos de reserva
* Ajustes de layout para dispositivos móveis nas telas:

  * `index#participantes`
  * `new#reservation`

### Adicionado

* Integração facial automática
* Validação de agendamento com subgrupo

---

## \[1.0.5] - 2025-05-30

### Corrigido

* Erro no modal de participantes
