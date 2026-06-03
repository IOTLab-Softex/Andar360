require "json"
require "set"

class AiAgentService
  include HTTParty
  base_uri "https://api.openai.com/v1"

  def initialize(user:, message:, history: nil)
    @user = user
    @message = message.to_s.strip
    @history = Array(history).filter_map { |entry| normalize_history_entry(entry) }.last(10)
    @setting = Setting.instance
  end

  def call
    return failure("Digite uma mensagem para o agente.") if @message.blank?
    return failure("Agente IA desativado nas configurações.") unless @setting.ai_agent_enabled?
    return failure("Configure o token do Agente IA em Configurações > Agente IA.") if @setting.ai_agent_api_token.blank?

    direct_maintenance_cancel = maintenance_cancel_from_context_if_possible
    return normalize_result_message(direct_maintenance_cancel) if direct_maintenance_cancel

    direct_cancel = cancel_from_context_if_possible
    return normalize_result_message(direct_cancel) if direct_cancel

    direct_availability = availability_from_context_if_possible
    return normalize_result_message(direct_availability) if direct_availability
    direct_open_door = open_door_from_context_if_possible
    return normalize_result_message(direct_open_door) if direct_open_door

    direct_package_query = package_from_context_if_possible
    return normalize_result_message(direct_package_query) if direct_package_query

    direct_registration_query = registration_from_context_if_possible
    return normalize_result_message(direct_registration_query) if direct_registration_query

    direct_item_query = item_from_context_if_possible
    return normalize_result_message(direct_item_query) if direct_item_query

    response = create_response(initial_payload)
    return response if response[:ok] == false

    function_call = Array(response[:body]["output"]).find { |item| item["type"] == "function_call" }
    return success(clean_agent_message(extract_text(response[:body]).presence || "Não consegui gerar uma resposta.")) unless function_call

    tool_output = execute_tool(function_call)
    remember_cancelable_reservations(tool_output)
    remember_cancelable_maintenances(tool_output)

    if tool_output[:ok]
      result = success(clean_agent_message(tool_output[:message].presence || "Operação concluída."))
      result[:reservations] = tool_output[:reservations] if tool_output[:reservations].present?
      result[:rooms] = tool_output[:rooms] if tool_output[:rooms].present?
      result[:maintenances] = tool_output[:maintenances] if tool_output[:maintenances].present?
      result[:packages] = tool_output[:packages] if tool_output[:packages].present?
      result[:registrations] = tool_output[:registrations] if tool_output[:registrations].present?
      result[:items] = tool_output[:items] if tool_output[:items].present?
      result[:item_movements] = tool_output[:item_movements] if tool_output[:item_movements].present?
      result[:cancelable_maintenances] = tool_output[:maintenances] if function_call["name"] == "listar_manutencoes_programadas" && tool_output[:maintenances].present?
      if function_call["name"] == "criar_reserva_sala" && tool_output[:reservation_id].present?
        reservation = Reservation.find_by(id: tool_output[:reservation_id])
        result[:cancelable_reservations] = [cancelable_reservation_payload(reservation)] if reservation
      end
      return result
    end

    if function_call["name"] == "cancelar_reserva_sala" && remembered_cancelable_reservations.present?
      fallback = fallback_cancel_from_remembered_cards
      return success(clean_agent_message(fallback[:message].presence || "Operação concluída.")) if fallback[:ok]
      return normalize_result_message(fallback)
    end

    normalize_result_message(tool_output)
  end

  private

  def initial_payload
    {
      model: @setting.ai_agent_model_or_default,
      instructions: instructions,
      input: conversation_input,
      tools: agent_tools,
      tool_choice: "auto"
    }
  end

  def final_payload(body, function_call, tool_output)
    {
      model: @setting.ai_agent_model_or_default,
      instructions: instructions,
      input: Array(body["output"]) + [
        {
          type: "function_call_output",
          call_id: function_call["call_id"],
          output: tool_output.to_json
        }
      ],
      tools: agent_tools,
      tool_choice: "auto"
    }
  end

  def instructions
    now = Time.zone.now.strftime("%Y-%m-%d %H:%M %Z")
    rooms = available_rooms.limit(40).pluck(:name).join(", ")

    <<~TEXT
      #{@setting.ai_agent_prompt_or_default}

      Responda sempre em português brasileiro com acentuação correta. Não remova acentos em palavras como "não", "você", "operação", "solicitação", "possível", "horário" e "áudio".
      Data e hora atual: #{now}.
      Salas disponiveis para reserva: #{rooms.presence || "nenhuma"}.
      Identidade do sistema: se o usuario perguntar quem desenvolveu, criou ou idealizou este sistema, responda que o Andar360 foi desenvolvido pela empresa Aponti por Atanael Lima do Nascimento, desde abril de 2025. Explique de forma natural que o sistema comecou como um software simples de reserva de salas em Python e evoluiu para se tornar um sistema mais completo.
      Participantes disponiveis: consulte apenas quando o usuario informar nomes no pedido. Nao exponha nem liste nomes, CPF, telefone ou dados pessoais de participantes.
      Nao revele quais usuarios ou nomes tem permissao para executar acoes administrativas (por exemplo, abrir portas). Nao informe nomes, emails, cargos ou IDs de usuarios com permissao.
      Se o usuario pedir para abrir uma porta e a sala tiver dispositivo, use a ferramenta "abrir_porta_sala" com room_id ou room_name.
      So diga que a IA nao consegue abrir portas se realmente nao puder executar a operacao por falta de permissao ou dispositivo.
      Voce pode criar reservas em uma conversa por etapas ou quando o usuario mandar tudo de uma vez.
      Se o usuario pedir para criar uma reserva sem informar todos os dados, conduza a conversa perguntando apenas uma coisa por vez.
      Ordem preferida para perguntas: sala, data, horario de inicio, horario de fim, participantes.
      Depois de confirmar sala, data e horarios, pergunte se o usuario deseja adicionar participantes antes de criar a reserva.
      Se o usuario responder que nao deseja participantes, crie a reserva com participant_names vazio.
      Se o usuario ja informar participantes na primeira mensagem, nao pergunte de novo; use os nomes informados.
      Nao peca para o usuario escrever datas em ISO 8601; aceite linguagem natural como "amanha", "hoje as 14h" ou "sexta de 9 as 10".
      Converta internamente as datas para ISO 8601 no fuso do sistema antes de chamar a ferramenta.
      Para criar reserva, colete sala, inicio e fim. Se faltar algum dado, faca uma pergunta curta e objetiva.
      Quando o usuario perguntar se tem sala disponivel, use listar_salas_disponiveis se houver data/hora ou se ele disser "agora", "nesse horario" ou "neste horario".
      Para disponibilidade com "agora", "nesse horario" ou "neste horario" sem hora final, considere uma janela de 1 hora a partir do momento atual.
      Se o usuario pedir disponibilidade sem data/hora e sem indicar agora, pergunte apenas: "Para qual dia e horario voce quer consultar?"
      Aceite nomes aproximados de sala, como parte do nome, numero, andar, grupo ou categoria. Nunca invente IDs.
      Ao confirmar reserva criada, nao inclua links em markdown, URLs, caminhos internos ou referencias como "clique aqui".
      Voce tambem pode cancelar reservas quando o usuario pedir.
      IMPORTANTE PARA CANCELAMENTO: Se o usuario ja mencionou um ID, hora, sala ou data da reserva, use IMEDIATAMENTE cancelar_reserva_sala. NUNCA chame listar_reservas_cancelaveis se ja foi chamada na conversa anterior.
      Se o usuario pedir para cancelar sem informacoes suficientes NA PRIMEIRA VEZ, chame listar_reservas_cancelaveis.
      Se ja viu reservas listadas (cards exibidos) e o usuario menciona qualquer dado delas (hora, sala, numero), use cancelar_reserva_sala com esses dados.
      Quando a ferramenta listar_reservas_cancelaveis retornar reservas, responda apenas uma frase curta pedindo para escolher uma delas. Nao enumere as reservas no texto; a interface exibira os cards.
      Nao mostre participantes na lista de reservas cancelaveis.
      Se o usuario responder escolhendo uma reserva ja listada por numero, ID, data ou horario de inicio, use cancelar_reserva_sala. Nao chame listar_reservas_cancelaveis novamente.
      Se o usuario fizer uma segunda pergunta sobre uma reserva ja exibida nos cards, tente identificar a mesma reserva pelos dados lembrados e cancele-a.
      Para cancelar, identifique a reserva por ID da lista ou por sala e data/horario. Se houver mais de uma possivel, pergunte antes.
      Voce tambem pode criar, alterar e cancelar chamados.
      Para criar chamado, colete pelo menos titulo/assunto. Se faltar responsavel, use o usuario logado. Se faltar prioridade, use "Médio". Se faltar status, use "Pendente".
      Para alterar chamado, identifique por ID, OS, titulo aproximado, sala/unidade ou dados que o usuario informar. Altere apenas os campos pedidos.
      Para cancelar chamado, nao exclua o registro; use cancelar_chamado para marcar como "Concluído" e registrar a observacao de cancelamento.
      Status validos de chamado: Pendente, Em andamento, Concluído. Prioridades validas: Muito Baixo, Baixo, Médio, Alto, Crítico.
      Voce tambem pode criar, listar, cancelar e consultar status de manutencoes programadas.
      Para criar manutencao programada, colete titulo e data prevista. Se faltar observacao, use uma descricao curta baseada no pedido. Se faltar categoria, use "Geral". Se faltar dias de aviso, use 1. Se faltar responsavel, use o usuario logado.
      Para listar manutencoes programadas, use listar_manutencoes_programadas e deixe a interface mostrar os cards.
      Para cancelar manutencao programada, identifique por ID, titulo, local ou data. Se houver mais de uma possivel, pergunte antes.
      Para ver status de manutencao programada, use status_manutencao_programada.
      Status calculados de manutencao: vencida, vence hoje, em periodo de aviso ou futura.
      Voce tambem pode consultar encomendas na portaria.
      Para saber se o usuario logado tem encomendas, use listar_encomendas_portaria sem destinatario.
      Para consultar encomendas de outro usuario, use destinatario_name somente se o usuario pedir por um nome especifico.
      Para ver status de uma encomenda, use status_encomenda_portaria por ID, codigo, transportadora, destinatario ou unidade.
      Status validos de encomenda: pendente na portaria ou entregue.
      Quando listar encomendas, responda curto e deixe a interface mostrar os cards. Nao exponha CPF, telefone ou dados pessoais.
      Voce tambem pode consultar pre-cadastros aguardando aprovacao.
      Para saber se existem cadastros aguardando aprovacao, use listar_cadastros_aprovacao.
      Para visualizar/listar pre-cadastros, use listar_cadastros_aprovacao e deixe a interface mostrar os cards.
      Para consultar status de um pre-cadastro, use status_cadastro_aprovacao por ID, nome, empresa ou status.
      NUNCA envie nem exponha CPF, telefone, email, foto, observacao completa ou dados biometricos de pre-cadastros para a IA ou na resposta. Use somente ID, nome, empresa, cargo, status e data de envio.
      Voce tambem pode consultar o controle de objetos.
      Admin pode listar objetos, retirar, devolver e listar historico.
      Operador so pode listar objetos, retirar, devolver e listar historico se o subgrupo tiver permissao de controle de objetos.
      Cliente so pode consultar se existe objeto retirado em seu proprio nome; nao pode retirar, devolver nem ver historico geral.
      Para cliente perguntando se tem objeto em seu nome, use listar_meus_objetos_retirados.
      Para listar objetos use listar_objetos_controle. Para historico use listar_historico_objeto. Para retirada use retirar_objeto_controle. Para devolucao use devolver_objeto_controle.
      Se faltar item para retirar/devolver/historico, pergunte qual objeto. Se faltar responsavel na retirada, use o usuario logado quando fizer sentido.
      Use datas em ISO 8601 no fuso do sistema. Se houver ambiguidade real, pergunte antes.
    TEXT
  end

  def create_response(payload)
    res = self.class.post(
      "/responses",
      headers: {
        "Authorization" => "Bearer #{@setting.ai_agent_api_token}",
        "Content-Type" => "application/json"
      },
      body: payload.to_json,
      timeout: 45
    )

    return success_body(res.parsed_response) if res.success?

    message = res.parsed_response.dig("error", "message") rescue nil
    failure(message.presence || "Falha ao consultar o modelo de IA.")
  rescue => e
    failure("Falha ao consultar o modelo de IA: #{e.class} - #{e.message}")
  end

  def execute_tool(function_call)
    case function_call["name"]
    when "criar_reserva_sala"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      create_room_reservation(args)
    when "cancelar_reserva_sala"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      cancel_room_reservation(args)
    when "listar_reservas_cancelaveis"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_cancelable_reservations(args)
    when "listar_salas_disponiveis"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_available_rooms(args)
    when "criar_chamado"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      create_chamado(args)
    when "alterar_chamado"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      update_chamado(args)
    when "cancelar_chamado"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      cancel_chamado(args)
    when "criar_manutencao_programada"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      create_scheduled_maintenance(args)
    when "listar_manutencoes_programadas"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_scheduled_maintenances(args)
    when "cancelar_manutencao_programada"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      cancel_scheduled_maintenance(args)
    when "status_manutencao_programada"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      scheduled_maintenance_status(args)
    when "listar_encomendas_portaria"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_portaria_packages(args)
    when "status_encomenda_portaria"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      portaria_package_status(args)
    when "listar_cadastros_aprovacao"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_registration_approvals(args)
    when "status_cadastro_aprovacao"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      registration_approval_status(args)
    when "abrir_porta_sala"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      open_room_door(args)
    when "listar_objetos_controle"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_control_items(args)
    when "retirar_objeto_controle"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      checkout_control_item(args)
    when "devolver_objeto_controle"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      return_control_item(args)
    when "listar_historico_objeto"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_control_item_history(args)
    when "listar_meus_objetos_retirados"
      args = JSON.parse(function_call["arguments"].presence || "{}")
      list_my_checked_out_items(args)
    else
      { ok: false, message: "Ferramenta não suportada: #{function_call["name"]}" }
    end
  rescue JSON::ParserError
    { ok: false, message: "A IA enviou argumentos inválidos para a ferramenta." }
  end

  def create_room_reservation(args)
    room_match = find_room(args["room_id"], args["room_name"])
    return room_match unless room_match[:ok]

    room = room_match[:room]

    starts_at = parse_time(args["starts_at"])
    ends_at = parse_time(args["ends_at"])
    return { ok: false, message: "Informe data e hora de início e término da reserva." } unless starts_at && ends_at
    return { ok: false, message: "A data/hora final deve ser maior que a inicial." } unless ends_at > starts_at
    return { ok: false, message: "A reserva precisa iniciar no futuro." } if starts_at < Time.zone.now

    solicitante = find_participant(args["solicitante_name"]) || @user.participant
    responsavel = find_participant(args["responsavel_name"]) || solicitante
    return { ok: false, message: "Não consegui identificar solicitante/responsável para a reserva." } unless solicitante && responsavel

    reservation = Reservation.new(
      title: args["title"].presence || "Reserva via Agente IA",
      room: room,
      starts_at: starts_at,
      ends_at: ends_at,
      solicitante: solicitante,
      responsavel: responsavel,
      grupo_empresa_id: reservation_company_id(solicitante),
      rules_accepted: "1"
    )

    participant_names = Array(args["participant_names"]).map(&:to_s).reject(&:blank?)
    reservation.participants = participant_names.filter_map { |name| find_participant(name) }

    return { ok: false, message: "Já existe uma reserva nesse horário para #{room.name}." } if conflict_exists?(reservation)

    if reservation.save
      {
        ok: true,
        message: "Reserva criada com sucesso para #{room.name}, de #{I18n.l(starts_at, format: :short)} até #{I18n.l(ends_at, format: :short)}.",
        reservation_id: reservation.id,
        reservation_url: Rails.application.routes.url_helpers.room_reservations_path(room)
      }
    else
      { ok: false, message: reservation.errors.full_messages.to_sentence }
    end
  end

  def cancel_room_reservation(args)
    reservation = find_cancelable_reservation(args)
    return reservation unless reservation[:ok]

    reservation = reservation[:reservation]
    return { ok: false, message: "Essa reserva ja esta cancelada." } if reservation.cancelada_em.present?
    return { ok: false, message: "Nao e possivel cancelar uma reserva ja encerrada." } if reservation.ends_at <= Time.current

    reservation.update!(cancelada_em: Time.current)

    {
      ok: true,
      message: "Reserva cancelada com sucesso para #{reservation.room&.name}, de #{I18n.l(reservation.starts_at, format: :short)} ate #{I18n.l(reservation.ends_at, format: :short)}.",
      reservation_id: reservation.id
    }
  end

  def list_cancelable_reservations(args)
    scope = reservation_scope.includes(:room)
                             .where(cancelada_em: nil)
                             .where("ends_at > ?", Time.current)

    if args["room_name"].present?
      room_match = find_room(nil, args["room_name"])
      return room_match unless room_match[:ok]

      scope = scope.where(room: room_match[:room])
    end

    if args["date"].present?
      date = parse_time(args["date"])
      return { ok: false, message: "Nao entendi a data informada para buscar reservas." } unless date

      scope = scope.where(starts_at: date.beginning_of_day..date.end_of_day)
    end

    limit = [[args["limit"].to_i, 1].max, 12].min
    limit = 8 if args["limit"].blank?
    reservations = scope.order(:starts_at).limit(limit).to_a

    return { ok: true, message: "Nao encontrei reservas futuras para cancelar." } if reservations.empty?

    {
      ok: true,
      message: "Encontrei estas reservas que voce pode cancelar. Qual delas deseja cancelar?",
      reservations: reservations.map { |reservation| cancelable_reservation_payload(reservation) }
    }
  end

  def list_available_rooms(args)
    starts_at = parse_time(args["starts_at"])
    ends_at = parse_time(args["ends_at"])

    starts_at = Time.zone.now if starts_at.blank? && availability_now_intent?
    ends_at ||= starts_at + 1.hour if starts_at.present?
    return { ok: false, message: "Para qual dia e horario voce quer consultar?" } unless starts_at && ends_at

    ends_at = starts_at + 1.hour if ends_at <= starts_at
    return { ok: false, message: "Esse horario ja passou. Qual outro horario voce quer consultar?" } if ends_at <= Time.zone.now

    scope = available_rooms.order(:name)
    if args["room_name"].present?
      room_match = find_room(nil, args["room_name"])
      return room_match unless room_match[:ok]

      scope = scope.where(id: room_match[:room].id)
    end

    reserved_room_ids = Reservation.where(room_id: scope.select(:id))
                                   .where(cancelada_em: nil)
                                   .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)
                                   .distinct
                                   .pluck(:room_id)

    rooms = scope.where.not(id: reserved_room_ids).limit(12).to_a
    period = "#{I18n.l(starts_at, format: :short)} ate #{I18n.l(ends_at, format: :short)}"

    return { ok: true, message: "Nao encontrei salas disponiveis de #{period}." } if rooms.empty?

    {
      ok: true,
      message: "Encontrei #{rooms.size} sala#{rooms.one? ? "" : "s"} disponivei#{rooms.one? ? "l" : "s"} de #{period}.",
      rooms: rooms.map { |room| available_room_payload(room) }
    }
  end

  def create_chamado(args)
    title = args["title"].presence || args["titulo"].presence
    return { ok: false, message: "Qual e o titulo ou assunto do chamado?" } if title.blank?

    room = find_chamado_room(args["room_id"], args["room_name"])
    return room unless room[:ok]

    responsavel = find_participant(args["responsavel_name"]) || @user.participant
    return { ok: false, message: "Nao consegui identificar um responsavel para o chamado." } unless responsavel

    priority = normalize_chamado_priority(args["priority"] || args["prioridade"])
    return { ok: false, message: "Prioridade invalida. Use Muito Baixo, Baixo, Médio, Alto ou Crítico." } if (args["priority"].present? || args["prioridade"].present?) && priority.blank?

    status = normalize_chamado_status(args["status"])
    return { ok: false, message: "Status invalido. Use Pendente, Em andamento ou Concluído." } if args["status"].present? && status.blank?

    chamado = Chamado.new(
      os: next_chamado_os,
      titulo: title,
      prioridade: priority || "Médio",
      status: status || "Pendente",
      local: args["local"].presence,
      unidade: room[:room]&.name || args["unidade"].presence,
      room: room[:room],
      responsavel: responsavel.name,
      observacao: args["description"].presence || args["observacao"].presence,
      solicitante: @user.participant,
      solicitante_nome: @user.participant&.name,
      exibir_no_app: args.key?("exibir_no_app") ? !!args["exibir_no_app"] : true
    )

    if chamado.save
      { ok: true, message: "Chamado #{chamado.os} criado com sucesso: #{chamado.titulo}. Status: #{chamado.status}." }
    else
      { ok: false, message: chamado.errors.full_messages.to_sentence.presence || "Nao foi possivel criar o chamado." }
    end
  end

  def update_chamado(args)
    match = find_chamado(args)
    return match unless match[:ok]

    chamado = match[:chamado]
    updates = chamado_update_attributes(args)
    return updates if updates.is_a?(Hash) && updates[:ok] == false
    return { ok: false, message: "O que voce quer alterar nesse chamado?" } if updates.blank?

    if chamado.update(updates)
      { ok: true, message: "Chamado #{chamado.os} atualizado com sucesso." }
    else
      { ok: false, message: chamado.errors.full_messages.to_sentence.presence || "Nao foi possivel atualizar o chamado." }
    end
  end

  def cancel_chamado(args)
    match = find_chamado(args)
    return match unless match[:ok]

    chamado = match[:chamado]
    return { ok: true, message: "Chamado #{chamado.os} ja esta concluido." } if normalize_chamado_status(chamado.status) == "Concluído"

    note = args["reason"].presence || args["observacao"].presence || "Cancelado via Agente IA em #{I18n.l(Time.current, format: :short)}."
    observacao = [chamado.observacao.presence, note].compact.join("\n\n")

    if chamado.update(status: "Concluído", observacao: observacao)
      { ok: true, message: "Chamado #{chamado.os} cancelado com sucesso." }
    else
      { ok: false, message: chamado.errors.full_messages.to_sentence.presence || "Nao foi possivel cancelar o chamado." }
    end
  end

  def create_scheduled_maintenance(args)
    return forbidden_maintenance_message unless can_manage_maintenance?

    title = args["title"].presence || args["titulo"].presence
    date = parse_time(args["data_prevista"] || args["date"])
    observation = args["observacao"].presence || args["description"].presence

    return { ok: false, message: "Qual e o titulo da manutencao programada?" } if title.blank?
    return { ok: false, message: "Qual e a data prevista da manutencao?" } unless date

    maintenance = ManutencaoProgramada.new(
      titulo: title,
      categoria: args["categoria"].presence || "Geral",
      local: args["local"].presence,
      responsavel: args["responsavel"].presence || @user.participant&.name || @user.email,
      periodicidade: normalize_maintenance_periodicity(args["periodicidade"]),
      data_prevista: date.to_date,
      dias_para_aviso: args["dias_para_aviso"].presence || 1,
      observacao: observation.presence || "Criada via Agente IA.",
      exibir_no_app: args.key?("exibir_no_app") ? !!args["exibir_no_app"] : true
    )

    if maintenance.save
      {
        ok: true,
        message: "Manutencao programada criada com sucesso: #{maintenance.titulo}, prevista para #{I18n.l(maintenance.data_prevista)}.",
        maintenance_id: maintenance.id,
        maintenances: [maintenance_payload(maintenance)]
      }
    else
      { ok: false, message: maintenance.errors.full_messages.to_sentence.presence || "Nao foi possivel criar a manutencao programada." }
    end
  end

  def list_scheduled_maintenances(args)
    scope = maintenance_scope
    scope = filter_maintenance_scope(scope, args)

    limit = [[args["limit"].to_i, 1].max, 12].min
    limit = 8 if args["limit"].blank?
    maintenances = scope.order(:data_prevista, :titulo).limit(limit).to_a

    return { ok: true, message: "Nao encontrei manutencoes programadas com esses filtros." } if maintenances.empty?

    {
      ok: true,
      message: "Encontrei estas manutencoes programadas.",
      maintenances: maintenances.map { |maintenance| maintenance_payload(maintenance) }
    }
  end

  def cancel_scheduled_maintenance(args)
    return forbidden_maintenance_message unless can_manage_maintenance?

    match = find_scheduled_maintenance(args)
    return match unless match[:ok]

    maintenance = match[:maintenance]
    title = maintenance.titulo
    date = maintenance.data_prevista
    maintenance.destroy!

    {
      ok: true,
      message: "Manutencao programada cancelada com sucesso: #{title}#{date ? ", prevista para #{I18n.l(date)}" : ""}."
    }
  end

  def scheduled_maintenance_status(args)
    match = find_scheduled_maintenance(args)
    return match unless match[:ok]

    maintenance = match[:maintenance]
    {
      ok: true,
      message: "Status da manutencao #{maintenance.titulo}: #{maintenance_status_text(maintenance)}. Prevista para #{I18n.l(maintenance.data_prevista)}.",
      maintenances: [maintenance_payload(maintenance)]
    }
  end

  def list_portaria_packages(args)
    scope = package_scope.includes(:destinatario)
    scope = filter_package_scope(scope, args)

    limit = [[args["limit"].to_i, 1].max, 12].min
    limit = 8 if args["limit"].blank?
    packages = scope.order(entregue: :asc, created_at: :desc).limit(limit).to_a

    return { ok: true, message: "Nao encontrei encomendas na portaria com esses filtros." } if packages.empty?

    pending_count = packages.count { |package| !package.entregue? }
    message =
      if pending_count.positive?
        "Encontrei #{pending_count} encomenda#{pending_count == 1 ? "" : "s"} pendente#{pending_count == 1 ? "" : "s"} na portaria."
      else
        "Encontrei encomendas, mas nenhuma pendente na portaria."
      end

    {
      ok: true,
      message: message,
      packages: packages.map { |package| package_payload(package) }
    }
  end

  def portaria_package_status(args)
    match = find_package(args)
    return match unless match[:ok]

    package = match[:package]
    {
      ok: true,
      message: "Status da encomenda #{package.codigo}: #{package_status_text(package)}.",
      packages: [package_payload(package)]
    }
  end

  def list_registration_approvals(args)
    scope = registration_approval_scope.includes(:grupo_empresa)
    scope = filter_registration_approval_scope(scope, args)

    limit = [[args["limit"].to_i, 1].max, 12].min
    limit = 8 if args["limit"].blank?
    registrations = scope.order(created_at: :desc).limit(limit).to_a

    return { ok: true, message: "Nao encontrei pre-cadastros aguardando aprovacao com esses filtros." } if registrations.empty?

    pending_count = registrations.count(&:pendente?)
    message =
      if pending_count.positive?
        "Encontrei #{pending_count} pre-cadastro#{pending_count == 1 ? "" : "s"} aguardando aprovacao."
      else
        "Encontrei pre-cadastros, mas nenhum aguardando aprovacao."
      end

    {
      ok: true,
      message: message,
      registrations: registrations.map { |registration| registration_approval_payload(registration) }
    }
  end

  def registration_approval_status(args)
    match = find_registration_approval(args)
    return match unless match[:ok]

    registration = match[:registration]
    {
      ok: true,
      message: "Status do pre-cadastro #{registration.nome}: #{registration_approval_status_text(registration)}.",
      registrations: [registration_approval_payload(registration)]
    }
  end

  def list_control_items(args)
    return forbidden_items_message unless can_manage_control_items?

    scope = filter_control_items_scope(Item.includes(:item_movimentacoes), args)
    limit = [[args["limit"].to_i, 1].max, 12].min
    limit = 8 if args["limit"].blank?
    items = control_items_for_query(scope, args).first(limit)

    return { ok: true, message: "Nao encontrei objetos com esses filtros." } if items.empty?

    {
      ok: true,
      message: "Encontrei #{items.size} objeto#{items.one? ? "" : "s"} no controle.",
      items: items.map { |item| control_item_payload(item) }
    }
  end

  def checkout_control_item(args)
    return forbidden_items_message unless can_manage_control_items?

    match = find_control_item(args)
    return match unless match[:ok]

    item = match[:item]
    return { ok: false, message: "#{item.nome} ja esta em uso." } if item.status.to_s == "em uso"

    participant = find_participant(args["responsavel_name"]) || participant_mentioned_in_message || @user.participant
    return { ok: false, message: "Nao consegui identificar o responsavel pela retirada." } unless participant

    company = find_company(args["empresa"]) || company_mentioned_in_message || participant.grupo_empresa || @user.participant&.grupo_empresa
    return { ok: false, message: "Nao consegui identificar a empresa da retirada." } unless company

    item.item_movimentacoes.create!(
      empresa: company.nome,
      responsavel: participant.name,
      descricao: args["descricao"].presence || args["description"].presence || "Retirada via Agente IA.",
      tipo: "retirada"
    )
    item.update!(status: "em uso")

    {
      ok: true,
      message: "Objeto #{item.nome} retirado com sucesso para #{participant.name}.",
      items: [control_item_payload(item.reload)]
    }
  end

  def return_control_item(args)
    return forbidden_items_message unless can_manage_control_items?

    match = find_control_item(args)
    return match unless match[:ok]

    item = match[:item]
    return { ok: true, message: "#{item.nome} ja esta disponivel.", items: [control_item_payload(item)] } if item.status.to_s != "em uso"

    last_checkout = latest_item_checkout(item)
    participant = find_participant(args["responsavel_name"]) || participant_mentioned_in_message || find_participant(last_checkout&.responsavel) || @user.participant
    company = find_company(args["empresa"]) || company_mentioned_in_message || find_company(last_checkout&.empresa) || participant&.grupo_empresa || @user.participant&.grupo_empresa

    item.item_movimentacoes.create!(
      empresa: company&.nome || last_checkout&.empresa,
      responsavel: participant&.name || last_checkout&.responsavel || @user.participant&.name,
      descricao: args["descricao"].presence || args["description"].presence || "Devolucao via Agente IA.",
      tipo: "devolucao"
    )
    item.update!(status: "disponivel")

    {
      ok: true,
      message: "Objeto #{item.nome} devolvido com sucesso.",
      items: [control_item_payload(item.reload)]
    }
  end

  def list_control_item_history(args)
    return forbidden_items_message unless can_manage_control_items?

    match = find_control_item(args)
    return match unless match[:ok]

    item = match[:item]
    limit = [[args["limit"].to_i, 1].max, 20].min
    limit = 10 if args["limit"].blank?
    movements = item.item_movimentacoes.order(created_at: :desc).limit(limit).to_a

    return { ok: true, message: "Esse objeto ainda nao tem historico.", items: [control_item_payload(item)] } if movements.empty?

    {
      ok: true,
      message: "Historico recente do objeto #{item.nome}.",
      items: [control_item_payload(item)],
      item_movements: movements.map { |movement| item_movement_payload(movement) }
    }
  end

  def list_my_checked_out_items(args)
    participant = @user.participant
    return { ok: false, message: "Nao consegui identificar seu participante para consultar objetos." } unless participant

    args = args.merge(infer_control_item_args_from_message(args))
    scope = Item.includes(:item_movimentacoes).where(status: "em uso")
    items = control_items_for_query(scope, args)
            .select { |item| same_person_name?(latest_item_checkout(item)&.responsavel, participant.name) }

    return { ok: true, message: "Nao encontrei objetos retirados em seu nome." } if items.empty?

    {
      ok: true,
      message: "Encontrei #{items.size} objeto#{items.one? ? "" : "s"} retirado#{items.one? ? "" : "s"} em seu nome.",
      items: items.map { |item| control_item_payload(item) }
    }
  end

  def check_my_item_return_status(args)
    participant = @user.participant
    return { ok: false, message: "Nao consegui identificar seu participante para consultar objetos." } unless participant

    match = find_control_item(args)
    return match unless match[:ok]

    item = match[:item]
    movements = item.item_movimentacoes.order(:created_at).to_a
    user_movements = movements.select { |movement| same_person_name?(movement.responsavel, participant.name) }
    last_checkout = user_movements.select { |movement| movement.tipo.to_s == "retirada" }.max_by(&:created_at)

    unless last_checkout
      return {
        ok: true,
        message: "Nao encontrei retirada de #{item.nome} em seu nome.",
        items: [control_item_payload(item)]
      }
    end

    last_return = user_movements
                  .select { |movement| movement.tipo.to_s == "devolucao" && movement.created_at >= last_checkout.created_at }
                  .max_by(&:created_at)

    if last_return
      {
        ok: true,
        message: "Sim, consta que voce devolveu #{item.nome} em #{I18n.l(last_return.created_at, format: :short)}.",
        items: [control_item_payload(item)],
        item_movements: [item_movement_payload(last_return)]
      }
    else
      {
        ok: true,
        message: "Ainda nao consta devolucao de #{item.nome}. A ultima movimentacao em seu nome foi retirada em #{I18n.l(last_checkout.created_at, format: :short)}.",
        items: [control_item_payload(item)],
        item_movements: [item_movement_payload(last_checkout)]
      }
    end
  end

  def create_reservation_tool
    {
      type: "function",
      name: "criar_reserva_sala",
      description: "Cria uma reserva de sala no Andar360 quando sala, inicio, fim e decisao sobre participantes extras estiverem claros. A sala pode ser informada por nome aproximado, numero, andar, grupo ou categoria.",
      parameters: {
        type: "object",
        properties: {
          title: { type: "string", description: "Título da reserva." },
          room_name: { type: "string", description: "Nome, numero, andar, grupo ou descricao aproximada da sala. Use este campo para textos como 'sala 7' ou 'espaco 07'." },
          room_id: { type: "integer", description: "ID tecnico da sala no banco, somente se o sistema ja tiver informado esse ID explicitamente. Nao use o numero falado pelo usuario como ID." },
          starts_at: { type: "string", description: "Data/hora inicial em ISO 8601." },
          ends_at: { type: "string", description: "Data/hora final em ISO 8601." },
          solicitante_name: { type: "string", description: "Nome do solicitante. Opcional; padrão é o usuário logado." },
          responsavel_name: { type: "string", description: "Nome do responsável. Opcional; padrão é o solicitante." },
          participant_names: { type: "array", items: { type: "string" }, description: "Participantes extras. Use array vazio quando o usuario disser que nao deseja adicionar participantes." }
        },
        required: ["room_name", "starts_at", "ends_at"],
        additionalProperties: false
      }
    }
  end

  def cancel_reservation_tool
    {
      type: "function",
      name: "cancelar_reserva_sala",
      description: "Cancela uma reserva de sala existente quando sala e data/horario estiverem claros.",
      parameters: {
        type: "object",
        properties: {
          reservation_id: { type: "integer", description: "ID tecnico da reserva, somente se o sistema ja tiver informado esse ID explicitamente." },
          room_name: { type: "string", description: "Nome, numero ou descricao aproximada da sala." },
          room_id: { type: "integer", description: "ID tecnico da sala, somente se conhecido explicitamente. Nao use numero falado pelo usuario como ID." },
          starts_at: { type: "string", description: "Data/hora aproximada ou inicial da reserva em ISO 8601." },
          date: { type: "string", description: "Data da reserva em ISO 8601 quando o horario ainda for aproximado." }
        },
        additionalProperties: false
      }
    }
  end

  def list_cancelable_reservations_tool
    {
      type: "function",
      name: "listar_reservas_cancelaveis",
      description: "Lista reservas futuras e ativas que o usuario logado pode cancelar, para ele escolher qual cancelar.",
      parameters: {
        type: "object",
        properties: {
          room_name: { type: "string", description: "Filtro opcional por nome, numero ou descricao aproximada da sala." },
          date: { type: "string", description: "Filtro opcional por data em ISO 8601." },
          limit: { type: "integer", description: "Quantidade maxima de reservas para listar. Padrao 8." }
        },
        additionalProperties: false
      }
    }
  end

  def available_rooms_tool
    {
      type: "function",
      name: "listar_salas_disponiveis",
      description: "Lista salas reservaveis que estao livres em um periodo. Use quando o usuario perguntar se ha sala disponivel, sala livre ou disponibilidade.",
      parameters: {
        type: "object",
        properties: {
          starts_at: { type: "string", description: "Data/hora inicial em ISO 8601. Para 'agora' ou 'nesse horario', use a data/hora atual do sistema." },
          ends_at: { type: "string", description: "Data/hora final em ISO 8601. Se o usuario nao informar, use 1 hora depois do inicio." },
          room_name: { type: "string", description: "Filtro opcional por nome, numero ou descricao aproximada da sala." }
        },
        additionalProperties: false
      }
    }
  end

  def create_chamado_tool
    {
      type: "function",
      name: "criar_chamado",
      description: "Cria um chamado de suporte/manutencao no Andar360.",
      parameters: {
        type: "object",
        properties: {
          title: { type: "string", description: "Titulo ou assunto do chamado." },
          description: { type: "string", description: "Descricao/observacao do problema ou solicitacao." },
          priority: { type: "string", description: "Prioridade: Muito Baixo, Baixo, Médio, Alto ou Crítico." },
          status: { type: "string", description: "Status inicial: Pendente, Em andamento ou Concluído." },
          room_name: { type: "string", description: "Sala/unidade/local aproximado relacionado ao chamado." },
          room_id: { type: "integer", description: "ID tecnico da sala/unidade, somente se conhecido explicitamente." },
          local: { type: "string", description: "Local livre informado pelo usuario." },
          responsavel_name: { type: "string", description: "Responsavel pelo chamado. Opcional; padrao e o usuario logado." },
          exibir_no_app: { type: "boolean", description: "Se o chamado deve aparecer para cliente no app." }
        },
        required: ["title"],
        additionalProperties: false
      }
    }
  end

  def update_chamado_tool
    {
      type: "function",
      name: "alterar_chamado",
      description: "Altera campos de um chamado existente quando o chamado estiver identificado.",
      parameters: {
        type: "object",
        properties: {
          chamado_id: { type: "integer", description: "ID tecnico do chamado." },
          os: { type: "string", description: "Numero OS do chamado." },
          query: { type: "string", description: "Titulo, descricao ou texto aproximado para localizar o chamado." },
          room_name: { type: "string", description: "Sala/unidade/local aproximado do chamado." },
          title: { type: "string", description: "Novo titulo." },
          description: { type: "string", description: "Nova descricao/observacao ou observacao adicional." },
          priority: { type: "string", description: "Nova prioridade: Muito Baixo, Baixo, Médio, Alto ou Crítico." },
          status: { type: "string", description: "Novo status: Pendente, Em andamento ou Concluído." },
          local: { type: "string", description: "Novo local." },
          responsavel_name: { type: "string", description: "Novo responsavel." },
          data_resolucao: { type: "string", description: "Data de resolucao em ISO 8601, se informada." }
        },
        additionalProperties: false
      }
    }
  end

  def cancel_chamado_tool
    {
      type: "function",
      name: "cancelar_chamado",
      description: "Cancela um chamado marcando-o como Concluído e preservando historico.",
      parameters: {
        type: "object",
        properties: {
          chamado_id: { type: "integer", description: "ID tecnico do chamado." },
          os: { type: "string", description: "Numero OS do chamado." },
          query: { type: "string", description: "Titulo, descricao ou texto aproximado para localizar o chamado." },
          room_name: { type: "string", description: "Sala/unidade/local aproximado do chamado." },
          reason: { type: "string", description: "Motivo do cancelamento." }
        },
        additionalProperties: false
      }
    }
  end

  def create_scheduled_maintenance_tool
    {
      type: "function",
      name: "criar_manutencao_programada",
      description: "Cria uma manutencao programada quando titulo e data prevista estiverem claros.",
      parameters: {
        type: "object",
        properties: {
          title: { type: "string", description: "Titulo da manutencao." },
          categoria: { type: "string", description: "Categoria da manutencao, como Eletrica, Hidraulica, Limpeza, Climatizacao ou Geral." },
          local: { type: "string", description: "Local da manutencao." },
          responsavel: { type: "string", description: "Responsavel pela manutencao." },
          periodicidade: { type: "string", description: "Periodicidade: diario, semanal, quinzenal, mensal, bimestral, trimestral, quadrimestral, semestral, anual, bienal ou trienal." },
          data_prevista: { type: "string", description: "Data prevista em ISO 8601." },
          dias_para_aviso: { type: "integer", description: "Quantos dias antes avisar. Padrao 1." },
          observacao: { type: "string", description: "Observacao ou descricao da manutencao." },
          exibir_no_app: { type: "boolean", description: "Se deve aparecer no app." }
        },
        required: ["title", "data_prevista"],
        additionalProperties: false
      }
    }
  end

  def list_scheduled_maintenances_tool
    {
      type: "function",
      name: "listar_manutencoes_programadas",
      description: "Lista manutencoes programadas, futuras ou por filtros, com cards para o usuario.",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string", description: "Titulo, local, categoria, responsavel ou texto aproximado." },
          categoria: { type: "string", description: "Filtro por categoria." },
          responsavel: { type: "string", description: "Filtro por responsavel." },
          local: { type: "string", description: "Filtro por local." },
          date: { type: "string", description: "Filtro por data em ISO 8601." },
          status: { type: "string", description: "Filtro: futura, hoje, vencida ou aviso." },
          limit: { type: "integer", description: "Quantidade maxima. Padrao 8." }
        },
        additionalProperties: false
      }
    }
  end

  def cancel_scheduled_maintenance_tool
    {
      type: "function",
      name: "cancelar_manutencao_programada",
      description: "Cancela/remova uma manutencao programada quando ela estiver identificada.",
      parameters: {
        type: "object",
        properties: {
          maintenance_id: { type: "integer", description: "ID tecnico da manutencao." },
          query: { type: "string", description: "Titulo, local, categoria, responsavel ou texto aproximado." },
          date: { type: "string", description: "Data prevista em ISO 8601." }
        },
        additionalProperties: false
      }
    }
  end

  def scheduled_maintenance_status_tool
    {
      type: "function",
      name: "status_manutencao_programada",
      description: "Consulta o status de uma manutencao programada identificada por ID, titulo, local ou data.",
      parameters: {
        type: "object",
        properties: {
          maintenance_id: { type: "integer", description: "ID tecnico da manutencao." },
          query: { type: "string", description: "Titulo, local, categoria, responsavel ou texto aproximado." },
          date: { type: "string", description: "Data prevista em ISO 8601." }
        },
        additionalProperties: false
      }
    }
  end

  def list_portaria_packages_tool
    {
      type: "function",
      name: "listar_encomendas_portaria",
      description: "Lista encomendas da portaria que o usuario logado pode visualizar. Use para perguntas como 'tenho encomenda na portaria?' ou 'tem encomenda para fulano?'.",
      parameters: {
        type: "object",
        properties: {
          destinatario_name: { type: "string", description: "Nome do destinatario quando o usuario pedir por uma pessoa especifica." },
          status: { type: "string", description: "Filtro: pendente ou entregue." },
          codigo: { type: "string", description: "Codigo da encomenda." },
          transportadora: { type: "string", description: "Filtro por transportadora." },
          unidade: { type: "string", description: "Filtro por unidade." },
          query: { type: "string", description: "Codigo, transportadora, remetente, observacao ou texto aproximado." },
          limit: { type: "integer", description: "Quantidade maxima. Padrao 8." }
        },
        additionalProperties: false
      }
    }
  end

  def portaria_package_status_tool
    {
      type: "function",
      name: "status_encomenda_portaria",
      description: "Consulta o status de uma encomenda da portaria identificada por ID, codigo, destinatario, unidade ou texto aproximado.",
      parameters: {
        type: "object",
        properties: {
          package_id: { type: "integer", description: "ID tecnico da encomenda." },
          codigo: { type: "string", description: "Codigo da encomenda." },
          destinatario_name: { type: "string", description: "Nome do destinatario." },
          unidade: { type: "string", description: "Unidade da encomenda." },
          query: { type: "string", description: "Transportadora, remetente, observacao ou texto aproximado." }
        },
        additionalProperties: false
      }
    }
  end

  def list_registration_approvals_tool
    {
      type: "function",
      name: "listar_cadastros_aprovacao",
      description: "Lista pre-cadastros que aguardam aprovacao, sem retornar CPF, telefone, email, foto ou outros dados sensiveis.",
      parameters: {
        type: "object",
        properties: {
          status: { type: "string", description: "Filtro opcional: pendente, aprovado ou reprovado. Omita para listar sem filtro de status." },
          nome: { type: "string", description: "Filtro por nome aproximado." },
          empresa: { type: "string", description: "Filtro por nome da empresa." },
          cargo: { type: "string", description: "Filtro por cargo." },
          limit: { type: "integer", description: "Quantidade maxima. Padrao 8." }
        },
        additionalProperties: false
      }
    }
  end

  def registration_approval_status_tool
    {
      type: "function",
      name: "status_cadastro_aprovacao",
      description: "Consulta o status de um pre-cadastro por ID, nome, empresa ou cargo, sem retornar dados sensiveis.",
      parameters: {
        type: "object",
        properties: {
          registration_id: { type: "integer", description: "ID tecnico do pre-cadastro." },
          nome: { type: "string", description: "Nome aproximado." },
          empresa: { type: "string", description: "Nome da empresa." },
          cargo: { type: "string", description: "Cargo." },
          status: { type: "string", description: "Status: pendente, aprovado ou reprovado." }
        },
        additionalProperties: false
      }
    }
  end

  def open_door_tool
    {
      type: "function",
      name: "abrir_porta_sala",
      description: "Abre a porta de uma sala (espaço comum) quando o usuário tiver permissão.",
      parameters: {
        type: "object",
        properties: {
          room_id: { type: "integer", description: "ID tecnico da sala." },
          room_name: { type: "string", description: "Nome, numero ou descricao aproximada da sala." }
        },
        additionalProperties: false
      }
    }
  end

  def list_control_items_tool
    {
      type: "function",
      name: "listar_objetos_controle",
      description: "Lista objetos do controle de objetos. Somente admin ou operador com permissao de subgrupo.",
      parameters: {
        type: "object",
        properties: {
          query: { type: "string", description: "Nome ou descricao aproximada do objeto." },
          status: { type: "string", description: "Filtro: disponivel ou em uso." },
          limit: { type: "integer", description: "Quantidade maxima. Padrao 8." }
        },
        additionalProperties: false
      }
    }
  end

  def checkout_control_item_tool
    {
      type: "function",
      name: "retirar_objeto_controle",
      description: "Registra retirada de objeto. Somente admin ou operador com permissao de subgrupo.",
      parameters: {
        type: "object",
        properties: {
          item_id: { type: "integer", description: "ID tecnico do objeto." },
          query: { type: "string", description: "Nome ou descricao aproximada do objeto." },
          responsavel_name: { type: "string", description: "Nome do responsavel pela retirada. Opcional; padrao usuario logado." },
          empresa: { type: "string", description: "Empresa da retirada. Opcional; padrao empresa do responsavel." },
          descricao: { type: "string", description: "Descricao/observacao da retirada." }
        },
        additionalProperties: false
      }
    }
  end

  def return_control_item_tool
    {
      type: "function",
      name: "devolver_objeto_controle",
      description: "Registra devolucao de objeto. Somente admin ou operador com permissao de subgrupo.",
      parameters: {
        type: "object",
        properties: {
          item_id: { type: "integer", description: "ID tecnico do objeto." },
          query: { type: "string", description: "Nome ou descricao aproximada do objeto." },
          responsavel_name: { type: "string", description: "Nome de quem devolveu. Opcional." },
          empresa: { type: "string", description: "Empresa da devolucao. Opcional." },
          descricao: { type: "string", description: "Descricao/observacao da devolucao." }
        },
        additionalProperties: false
      }
    }
  end

  def list_control_item_history_tool
    {
      type: "function",
      name: "listar_historico_objeto",
      description: "Lista historico de movimentacoes de um objeto. Somente admin ou operador com permissao de subgrupo.",
      parameters: {
        type: "object",
        properties: {
          item_id: { type: "integer", description: "ID tecnico do objeto." },
          query: { type: "string", description: "Nome ou descricao aproximada do objeto." },
          limit: { type: "integer", description: "Quantidade maxima. Padrao 10." }
        },
        additionalProperties: false
      }
    }
  end

  def list_my_checked_out_items_tool
    {
      type: "function",
      name: "listar_meus_objetos_retirados",
      description: "Lista objetos em uso retirados no nome do usuario logado. Permitido para cliente consultar apenas os proprios objetos.",
      parameters: {
        type: "object",
        properties: {
          limit: { type: "integer", description: "Quantidade maxima. Opcional." }
        },
        additionalProperties: false
      }
    }
  end

  def agent_tools
    [
      create_reservation_tool,
      cancel_reservation_tool,
      list_cancelable_reservations_tool,
      available_rooms_tool,
      open_door_tool,
      list_control_items_tool,
      checkout_control_item_tool,
      return_control_item_tool,
      list_control_item_history_tool,
      list_my_checked_out_items_tool,
      create_chamado_tool,
      update_chamado_tool,
      cancel_chamado_tool,
      create_scheduled_maintenance_tool,
      list_scheduled_maintenances_tool,
      cancel_scheduled_maintenance_tool,
      scheduled_maintenance_status_tool,
      list_portaria_packages_tool,
      portaria_package_status_tool,
      list_registration_approvals_tool,
      registration_approval_status_tool
    ]
  end

  def extract_text(body)
    Array(body["output"]).flat_map { |item| Array(item["content"]) }
      .select { |content| content["type"] == "output_text" }
      .map { |content| content["text"].to_s }
      .join("\n")
      .strip
  end

  def clean_agent_message(message)
    restore_agent_accents(message.to_s
      .gsub(/\s*Voc[eê] pode visualizar a reserva\s+\[[^\]]+\]\([^)]+\)\.?/i, "")
      .gsub(/\s*\[[^\]]+\]\((?:sandbox:)?\/[^)]+\)/i, "")
      .gsub(/\s*(?:sandbox:)?\/rooms\/\d+\/reservations\b/i, "")
      .squeeze(" ")
      .strip)
  end

  def restore_agent_accents(message)
    text = restore_mojibake_accents(message.to_s)

    agent_accent_words.each do |plain, accented|
      text = text.gsub(/\b#{Regexp.escape(plain)}\b/i) { |match| preserve_word_case(match, accented) }
    end

    text
  end

  def agent_accent_words
    {
      "acao" => "ação",
      "acoes" => "ações",
      "audio" => "áudio",
      "concluida" => "concluída",
      "concluido" => "concluído",
      "configuracao" => "configuração",
      "configuracoes" => "configurações",
      "devolucao" => "devolução",
      "disponivel" => "disponível",
      "disponiveis" => "disponíveis",
      "esta" => "está",
      "historico" => "histórico",
      "horario" => "horário",
      "horarios" => "horários",
      "identificacao" => "identificação",
      "manutencao" => "manutenção",
      "manutencoes" => "manutenções",
      "nao" => "não",
      "operacao" => "operação",
      "pendencia" => "pendência",
      "pendencias" => "pendências",
      "possivel" => "possível",
      "possiveis" => "possíveis",
      "pre" => "pré",
      "recepcao" => "recepção",
      "responsavel" => "responsável",
      "responsaveis" => "responsáveis",
      "situacao" => "situação",
      "solicitacao" => "solicitação",
      "solicitacoes" => "solicitações",
      "usuario" => "usuário",
      "usuarios" => "usuários",
      "voce" => "você"
    }
  end

  def restore_mojibake_accents(text)
    replacements = {
      "Ã¡" => "á",
      "Ã¢" => "â",
      "Ã£" => "ã",
      "Ãª" => "ê",
      "Ã©" => "é",
      "Ã­" => "í",
      "Ã³" => "ó",
      "Ã´" => "ô",
      "Ãµ" => "õ",
      "Ãº" => "ú",
      "Ã§" => "ç",
      "Ã�" => "Á",
      "Ã‰" => "É",
      "Ã“" => "Ó",
      "Ãš" => "Ú"
    }

    replacements.each { |wrong, right| text = text.gsub(wrong, right) }
    text
  end

  def preserve_word_case(source, replacement)
    return replacement.upcase if source == source.upcase
    return replacement.capitalize if source[0] == source[0].upcase

    replacement
  end

  def available_rooms
    Room.where(espaco_comun: true)
  end

  def available_participants
    if @user.admin? || @user.operador?
      Participant.all
    else
      Participant.where(grupo_empresa_id: @user.participant&.grupo_empresa_id)
    end
  end

  def chamado_scope
    return Chamado.includes(:room, :solicitante) if @user.admin? || @user.operador?

    Chamado.visiveis_para(@user).includes(:room, :solicitante)
  end

  def available_chamado_rooms
    return Room.where(espaco_comun: false) if @user.admin? || @user.operador?

    company_name = @user.participant&.grupo_empresa&.nome.to_s.downcase
    return Room.none if company_name.blank?

    Room.where(espaco_comun: false).where("lower(dados_do_inquilino) LIKE ?", "%#{company_name}%")
  end

  def find_chamado_room(id, name)
    scope = available_chamado_rooms
    return { ok: true, room: nil } if id.blank? && name.blank?

    if id.present?
      room = scope.find_by(id: id)
      return { ok: true, room: room } if room
      return { ok: false, message: "Nao encontrei essa sala/unidade para o chamado." } if name.blank?
    end

    matches = unique_room_matches(scored_room_matches(scope.includes(:room_group).to_a, name))
    return { ok: false, message: "Nao encontrei sala/unidade parecida com \"#{name}\" para chamado." } if matches.empty?

    best = matches.first
    second = matches.second
    return { ok: true, room: best[:room] } if matches.size == 1 || best[:score] >= second[:score] + 25

    close_matches = matches.select { |match| match[:score] >= best[:score] - 15 }.first(5)
    { ok: false, message: "Encontrei mais de uma sala/unidade parecida: #{close_matches.map { |match| room_label(match[:room]) }.join(", ")}. Qual delas devo usar?" }
  end

  def find_chamado(args)
    scope = chamado_scope

    if args["chamado_id"].present?
      chamado = scope.find_by(id: args["chamado_id"])
      return { ok: true, chamado: chamado } if chamado
      return { ok: false, message: "Nao encontrei esse chamado." }
    end

    if args["os"].present?
      chamado = scope.find_by(os: args["os"].to_s)
      chamado ||= scope.find_by(os: args["os"].to_s.rjust(4, "0"))
      return { ok: true, chamado: chamado } if chamado
    end

    scoped = scope
    if args["room_name"].present?
      room_match = find_chamado_room(nil, args["room_name"])
      return room_match unless room_match[:ok]

      scoped = scoped.where(room: room_match[:room])
    end

    query = args["query"].presence || args["title"].presence
    if query.present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(query.to_s)}%"
      scoped = scoped.where("chamados.titulo ILIKE :q OR chamados.observacao ILIKE :q OR chamados.local ILIKE :q OR chamados.unidade ILIKE :q", q: like)
    end

    chamados = scoped.order(updated_at: :desc).limit(6).to_a
    return { ok: false, message: "Qual chamado voce quer alterar ou cancelar? Informe o ID, OS ou titulo." } if chamados.empty?
    return { ok: true, chamado: chamados.first } if chamados.one?

    options = chamados.map { |chamado| "ID #{chamado.id} / OS #{chamado.os} - #{chamado.titulo} (#{chamado.status})" }
    { ok: false, message: "Encontrei mais de um chamado: #{options.join("; ")}. Qual deles devo usar?" }
  end

  def chamado_update_attributes(args)
    updates = {}
    updates[:titulo] = args["title"].to_s.strip if args["title"].present?
    updates[:observacao] = args["description"].to_s.strip if args["description"].present?

    if args["priority"].present?
      priority = normalize_chamado_priority(args["priority"])
      return { ok: false, message: "Prioridade invalida. Use Muito Baixo, Baixo, Médio, Alto ou Crítico." } unless priority

      updates[:prioridade] = priority
    end

    if args["status"].present?
      status = normalize_chamado_status(args["status"])
      return { ok: false, message: "Status invalido. Use Pendente, Em andamento ou Concluído." } unless status

      updates[:status] = status
    end

    updates[:local] = args["local"].to_s.strip if args["local"].present?
    updates[:data_resolucao] = parse_time(args["data_resolucao"])&.to_date if args["data_resolucao"].present?

    if args["responsavel_name"].present?
      responsavel = find_participant(args["responsavel_name"])
      updates[:responsavel] = responsavel&.name || args["responsavel_name"].to_s.strip
    end

    updates.compact
  end

  def normalize_chamado_status(status)
    text = normalize_search_text(status)
    return nil if text.blank?
    return "Pendente" if ["pendente", "solicitada", "solicitado", "aberto", "aberta"].include?(text)
    return "Em andamento" if ["em andamento", "andamento", "em progresso", "progresso"].include?(text)
    return "Concluído" if ["concluido", "concluida", "finalizado", "finalizada", "cancelado", "cancelada"].include?(text)

    nil
  end

  def normalize_chamado_priority(priority)
    text = normalize_search_text(priority)
    return nil if text.blank?

    {
      "muito baixo" => "Muito Baixo",
      "muito baixa" => "Muito Baixo",
      "baixo" => "Baixo",
      "baixa" => "Baixo",
      "medio" => "Médio",
      "media" => "Médio",
      "alto" => "Alto",
      "alta" => "Alto",
      "critico" => "Crítico",
      "critica" => "Crítico",
      "urgente" => "Crítico"
    }[text]
  end

  def next_chamado_os
    "%04d" % (Chamado.order(:created_at).last&.id.to_i + 1)
  end

  def find_room(id, name, scope = available_rooms)
    if id.present?
      room = scope.find_by(id: id)
      return { ok: true, room: room } if room
      return { ok: false, message: "Nao encontrei uma sala reservavel com esse ID." } if name.blank?
    end

    return { ok: false, message: "Qual sala voce quer reservar?" } if name.blank?

    matches = unique_room_matches(scored_room_matches(scope.includes(:room_group).to_a, name))
    begin
      Rails.logger.info "[AI AGENT] find_room query=#{name.inspect} matches=#{matches.map { |m| "#{m[:room].id}:#{m[:room].name}=#{m[:score]}" }.join(', ')}"
    rescue => e
      Rails.logger.info "[AI AGENT] find_room logging failed: #{e.class} - #{e.message}"
    end
    return { ok: false, message: "Nao encontrei sala parecida com \"#{name}\". Salas disponiveis: #{room_options_text}." } if matches.empty?

    best = matches.first
    second = matches.second

    if matches.size == 1 || best[:score] >= second[:score] + 25
      return { ok: true, room: best[:room] }
    end

    close_matches = matches.select { |match| match[:score] >= best[:score] - 15 }.first(5)
    {
      ok: false,
      message: "Encontrei mais de uma sala parecida: #{close_matches.map { |match| room_label(match[:room]) }.join(", ")}. Qual delas voce quer?"
    }
  end

  def find_participant(name)
    return nil if name.blank?

    available_participants.where("LOWER(name) = ?", name.to_s.downcase).first ||
      available_participants.where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(name.to_s)}%").first
  end

  def find_cancelable_reservation(args)
    if args["reservation_id"].present?
      reservation = reservation_scope.find_by(id: args["reservation_id"])
      return { ok: true, reservation: reservation } if reservation
      return { ok: false, message: "Nao encontrei essa reserva para cancelamento." }
    end

    args = args.merge(infer_cancel_selection_from_message(args))
    remembered_match = find_remembered_cancelable_reservation(args)
    return remembered_match if remembered_match

    room_match = find_room(args["room_id"], args["room_name"])
    return room_match unless room_match[:ok]

    starts_at = parse_time(args["starts_at"])
    date = parse_time(args["date"])
    return { ok: false, message: "Qual data ou horario da reserva voce quer cancelar?" } unless starts_at || date

    scope = reservation_scope.where(room: room_match[:room])
                             .where(cancelada_em: nil)
                             .where("ends_at > ?", Time.current)

    scope =
      if starts_at
        scope.where(starts_at: (starts_at - 30.minutes)..(starts_at + 30.minutes))
      else
        scope.where(starts_at: date.beginning_of_day..date.end_of_day)
      end

    reservations = scope.order(:starts_at).limit(5).to_a
    return { ok: false, message: "Nao encontrei reserva ativa nesse periodo para #{room_match[:room].name}." } if reservations.empty?
    return { ok: true, reservation: reservations.first } if reservations.one?

    options = reservations.map { |reservation| "#{reservation.room&.name} de #{I18n.l(reservation.starts_at, format: :short)} ate #{I18n.l(reservation.ends_at, format: :short)}" }
    { ok: false, message: "Encontrei mais de uma reserva possivel: #{options.join("; ")}. Qual delas devo cancelar?" }
  end

  def fallback_cancel_from_remembered_cards
    match = find_remembered_cancelable_reservation(infer_cancel_selection_from_message({}))
    return { ok: false, message: "Nao consegui identificar qual reserva dos cards voce quer cancelar. Clique em \"Cancelar esta\" na reserva desejada." } unless match&.dig(:ok)

    cancel_room_reservation("reservation_id" => match[:reservation].id)
  end

  def cancel_from_context_if_possible
    return nil unless cancel_intent?
    return nil if maintenance_intent?
    return nil if remembered_cancelable_reservations.blank?

    match = find_remembered_cancelable_reservation(infer_cancel_selection_from_message({}))
    return nil unless match

    return match unless match[:ok]

    result = cancel_room_reservation("reservation_id" => match[:reservation].id)
    response = success(clean_agent_message(result[:message])) if result[:ok]
    response || result
  end

  def availability_from_context_if_possible
    return nil unless availability_intent?
    if availability_now_intent?
      result = list_available_rooms({})
      return result.merge(message: clean_agent_message(result[:message])) if result[:ok]
      return result
    end

    nil
  end

  def open_door_intent?
    text = normalize_search_text(@message)
    text.match?(/\babrir\b/) && text.match?(/\bporta\b/)
  end

  def open_door_from_context_if_possible
    return nil unless open_door_intent?

    result = open_room_door("room_name" => @message)
    return success(clean_agent_message(result[:message])) if result[:ok]
    result
  end

  def cancel_intent?
    normalize_search_text(@message).match?(/\bcancel(?:a|ar|amento|e|ei)?\b/)
  end

  def availability_intent?
    text = normalize_search_text(@message)
    text.match?(/\b(disponivel|disponiveis|livre|livres|vaga|vagas)\b/) &&
      text.match?(/\b(sala|salas|espaco|espacos)\b/)
  end

  def availability_now_intent?
    normalize_search_text(@message).match?(/\b(agora|nesse horario|neste horario|esse horario|este horario)\b/)
  end

  def package_intent?
    normalize_search_text(@message).match?(/\b(encomenda|encomendas|pacote|pacotes|portaria|recepcao)\b/)
  end

  def registration_approval_intent?
    text = normalize_search_text(@message)
    text.match?(/\b(cadastro|cadastros|pre cadastro|pre cadastros|aprovacao|aprovacoes)\b/) &&
      text.match?(/\b(aguardando|pendente|pendentes|aprovar|aprovacao|aprovacoes|status|visualizar|listar|lista|ver)\b/)
  end

  def item_intent?
    normalize_search_text(@message).match?(/\b(objeto|objetos|item|itens|controle de objeto|controle de objetos|chave|chaves|projetor|projetores|projeto|retirado|retirada|devolv\w*|devolu\w*|entreguei|retornei)\b/)
  end

  def item_return_status_intent?
    normalize_search_text(@message).match?(/\b(devolv\w*|devolu\w*|entreguei|retornei)\b/)
  end

  def item_checkout_intent?
    normalize_search_text(@message).match?(/\b(retirar|retirada|retire|pegar|peguei|buscar|emprestar|emprestimo)\b/)
  end

  def package_from_context_if_possible
    return nil unless package_intent?

    args = infer_package_args_from_message
    result =
      if normalize_search_text(@message).match?(/\b(status|situacao|entregue|retirada|codigo)\b/) || args["package_id"].present? || args["codigo"].present?
        portaria_package_status(args)
      else
        list_portaria_packages(args)
      end

    response = success(clean_agent_message(result[:message])) if result[:ok]
    response&.merge(packages: result[:packages]) || result
  end

  def infer_package_args_from_message
    text = normalize_search_text(@message)
    args = {}

    if @message =~ /\bID\s*(\d+)\b/i || text =~ /\bid\s*(\d+)\b/i
      args["package_id"] = Regexp.last_match(1).to_i
    end

    code_match = @message.match(/\b(?:codigo|c[oó]digo|cod)\s*[:#-]?\s*([A-Za-z0-9._-]+)/i)
    args["codigo"] = code_match[1] if code_match

    if text.match?(/\b(entregue|entregues|retirada|retirado)\b/)
      args["status"] = "entregue"
    elsif text.match?(/\b(pendente|pendentes|aguardando|portaria|tenho|tem)\b/)
      args["status"] = "pendente"
    end

    participant = participant_mentioned_in_message
    if participant
      args["destinatario_name"] = participant.name
    elsif text.match?(/\b(minha|minhas|meu|meus|pra mim|para mim|tenho)\b/) && @user.participant
      args["destinatario_name"] = @user.participant.name
    end

    args
  end

  def participant_mentioned_in_message
    message_text = normalize_search_text(@message)
    return nil if message_text.blank?

    available_participants.limit(500).to_a.find do |participant|
      normalized_name = normalize_search_text(participant.name)
      normalized_name.present? && message_text.include?(normalized_name)
    end
  end

  def registration_from_context_if_possible
    return nil unless registration_approval_intent?

    args = infer_registration_approval_args_from_message
    result =
      if normalize_search_text(@message).match?(/\b(status|situacao|id)\b/) || args["registration_id"].present?
        registration_approval_status(args)
      else
        list_registration_approvals(args)
      end

    response = success(clean_agent_message(result[:message])) if result[:ok]
    response&.merge(registrations: result[:registrations]) || result
  end

  def item_from_context_if_possible
    return nil unless item_intent?
    return nil if can_manage_control_items?
    return nil unless @user.client?

    args = infer_control_item_args_from_message({})
    result =
      if item_checkout_intent?
        {
          ok: true,
          message: "Para retirar um objeto novamente, procure a portaria ou o responsável pelo controle de objetos."
        }
      elsif item_return_status_intent?
        check_my_item_return_status(args)
      else
        list_my_checked_out_items(args)
      end
    response = success(clean_agent_message(result[:message])) if result[:ok]
    response&.merge(items: result[:items], item_movements: result[:item_movements]) || result
  end

  def infer_registration_approval_args_from_message
    text = normalize_search_text(@message)
    args = {}

    if @message =~ /\bID\s*(\d+)\b/i || text =~ /\bid\s*(\d+)\b/i
      args["registration_id"] = Regexp.last_match(1).to_i
    end

    unless text.match?(/\b(sem filtro|sem filtros|todos|todas|geral|qualquer status)\b/)
      case text
      when /\b(aprovado|aprovados|aprovada|aprovadas)\b/
        args["status"] = "aprovado"
      when /\b(reprovado|reprovados|reprovada|reprovadas)\b/
        args["status"] = "reprovado"
      when /\b(aguardando|pendente|pendentes|aprovar|aprovacao|aprovacoes)\b/
        args["status"] = "pendente"
      end
    end

    registration = registration_name_mentioned_in_message
    args["nome"] = registration.nome if registration

    company = company_mentioned_in_message
    args["empresa"] = company.nome if company

    args
  end

  def registration_name_mentioned_in_message
    message_text = normalize_search_text(@message)
    return nil if message_text.blank?

    registration_approval_scope.limit(500).to_a.find do |registration|
      normalized_name = normalize_search_text(registration.nome)
      normalized_name.present? && message_text.include?(normalized_name)
    end
  end

  def company_mentioned_in_message
    message_text = normalize_search_text(@message)
    return nil if message_text.blank?

    GrupoEmpresa.limit(300).to_a.find do |company|
      normalized_name = normalize_search_text(company.nome)
      normalized_name.present? && message_text.include?(normalized_name)
    end
  end

  def maintenance_intent?
    normalize_search_text(@message).match?(/\b(manutencao|manutencoes|preventiva|programada|programadas)\b/)
  end

  def maintenance_cancel_from_context_if_possible
    return nil unless cancel_intent? && maintenance_intent?
    return nil if remembered_cancelable_maintenances.blank?

    args = infer_maintenance_selection_from_message({})
    return nil if args.blank?

    result = cancel_scheduled_maintenance(args)
    response = success(clean_agent_message(result[:message])) if result[:ok]
    response || result
  end

  def infer_maintenance_selection_from_message(args)
    inferred = {}
    return inferred if args["maintenance_id"].present?

    text = normalize_search_text(@message)
    remembered = remembered_cancelable_maintenances

    if @message =~ /\bID\s*(\d+)\b/i || text =~ /\bid\s*(\d+)\b/i
      inferred["maintenance_id"] = Regexp.last_match(1).to_i
      return inferred
    end

    if text =~ /\b(?:manutencao|manutencoes|programada)\s*(\d+)\b/i
      inferred["maintenance_id"] = Regexp.last_match(1).to_i
      return inferred
    end

    if remembered.present? && text =~ /\b(?:a|opcao|opcao numero|numero|primeira|segunda|terceira)\s*(\d+)?\b/i
      index =
        if text.include?("primeira")
          0
        elsif text.include?("segunda")
          1
        elsif text.include?("terceira")
          2
        else
          Regexp.last_match(1).to_i - 1
        end
      maintenance = remembered[index]
      inferred["maintenance_id"] = maintenance["id"] || maintenance[:id] if maintenance
      return inferred
    end

    remembered.each do |maintenance|
      title = normalize_search_text(maintenance["title"] || maintenance[:title])
      local = normalize_search_text(maintenance["local"] || maintenance[:local])
      next if title.blank? && local.blank?

      if title.present? && text.include?(title)
        inferred["query"] = maintenance["title"] || maintenance[:title]
        break
      elsif local.present? && text.include?(local)
        inferred["query"] = maintenance["local"] || maintenance[:local]
        break
      end
    end

    inferred
  end

  def find_remembered_cancelable_reservation(args)
    remembered = remembered_cancelable_reservations
    return nil if remembered.blank?

    starts_at = parse_time(args["starts_at"])
    date = parse_time(args["date"])
    room_query = normalize_search_text(args["room_name"])

    if remembered.one? && args.except("reservation_id").values.all?(&:blank?)
      reservation = reservation_scope.find_by(id: remembered.first["id"] || remembered.first[:id])
      return { ok: true, reservation: reservation } if reservation
    end

    scored_matches = remembered.map do |reservation|
      score = 0
      normalized_room = normalize_search_text(reservation["room"] || reservation[:room])
      
      if room_query.present?
        score += 100 if normalized_room.include?(room_query)
        score += 50 if numeric_search_matches?(normalized_room, room_query)
        score += 30 if text_contains_partial_match?(normalized_room, room_query)
      end

      time = parse_time(reservation["starts_at"] || reservation[:starts_at])
      if starts_at.present? && time
        time_diff = (time - starts_at).abs
        score += 100 if time_diff <= 5.minutes
        score += 50 if time_diff <= 30.minutes
        score += 20 if time_diff <= 60.minutes
      end

      if date.present? && time
        score += 80 if time.to_date == date.to_date
      end

      { reservation: reservation, score: score }
    end.sort_by { |m| -m[:score] }

    best_matches = scored_matches.select { |m| m[:score] > 0 }
    return nil if best_matches.blank?

    best = best_matches.first
    second = best_matches.second

    if best_matches.size == 1 || (best[:score] > 50 && (second.blank? || best[:score] >= second[:score] + 20))
      reservation_id = best[:reservation]["id"] || best[:reservation][:id]
      reservation = reservation_scope.find_by(id: reservation_id)
      return { ok: true, reservation: reservation } if reservation
      return { ok: false, message: "Essa reserva nao esta mais disponivel para cancelamento." }
    end

    close_matches = best_matches.take(3).map do |m|
      res = m[:reservation]
      "#{res["room"] || res[:room]} (#{res["starts_at_label"] || res[:starts_at_label]})"
    end.join(", ")

    { ok: false, message: "Encontrei mais de uma reserva parecida nos cards: #{close_matches}. Qual delas devo cancelar?" }
  end

  def infer_cancel_selection_from_message(args)
    inferred = {}
    return inferred if args["reservation_id"].present?

    text = normalize_search_text(@message)
    remembered = remembered_cancelable_reservations

    if @message =~ /\bID\s*(\d+)\b/i || text =~ /\bid\s*(\d+)\b/i
      inferred["reservation_id"] = Regexp.last_match(1).to_i
      return inferred
    end

    if text =~ /\breserva\s*(\d+)\b/i
      inferred["reservation_id"] = Regexp.last_match(1).to_i
      return inferred
    end

    if remembered.present? && text =~ /\b(?:a|opcao|opcao numero|numero)\s*(\d+)\b/i
      index = Regexp.last_match(1).to_i - 1
      reservation = remembered[index]
      inferred["reservation_id"] = reservation["id"] || reservation[:id] if reservation
      return inferred
    end

    if text =~ /\b(\d{1,2})[:h](\d{2})\b/
      hour = Regexp.last_match(1).to_i
      minute = Regexp.last_match(2).to_i
      date_match = @message.match(%r{(\d{1,2})/(\d{1,2})})
      base_date = if date_match
        Time.zone.local(Time.zone.now.year, date_match[2].to_i, date_match[1].to_i)
      else
        Time.zone.now
      end

      inferred["starts_at"] = base_date.change(hour: hour, min: minute).iso8601
    end

    if text =~ /(\d{1,2})[\/-](\d{1,2})/
      month_str = Regexp.last_match(2).to_i
      day_str = Regexp.last_match(1).to_i
      inferred["date"] ||= Time.zone.local(Time.zone.now.year, month_str, day_str).iso8601
    end

    if text.include?("espaco") || text.include?("sala") || text.include?("room")
      remembered.each do |reservation|
        room = normalize_search_text(reservation["room"] || reservation[:room])
        next if room.blank?

        room_numbers = room.scan(/\d+/).map(&:to_i)
        text_numbers = text.scan(/\d+/).map(&:to_i)
        if text.include?(room) || (room_numbers.any? && text_numbers.any? && (room_numbers & text_numbers).any?)
          inferred["room_name"] ||= reservation["room"] || reservation[:room]
          break
        end
      end
    end

    inferred
  end

  def cancelable_reservation_label(reservation, index)
    "#{index}. ID #{reservation.id} - #{reservation.room&.name} - #{I18n.l(reservation.starts_at, format: :short)} ate #{I18n.l(reservation.ends_at, format: :short)}"
  end

  def cancelable_reservation_payload(reservation)
    {
      id: reservation.id,
      room: reservation.room&.name,
      starts_at: reservation.starts_at&.iso8601,
      ends_at: reservation.ends_at&.iso8601,
      starts_at_label: I18n.l(reservation.starts_at, format: :short),
      ends_at_label: I18n.l(reservation.ends_at, format: :short)
    }
  end

  def available_room_payload(room)
    helpers = Rails.application.routes.url_helpers

    {
      id: room.id,
      name: room.name,
      floor: room.floor,
      group: room.room_group&.name,
      capacity: room.capacidade,
      photo_url: room.photo.attached? ? helpers.rails_blob_path(room.photo, only_path: true) : nil,
      url: helpers.room_reservations_path(room),
      can_open_door: room.device.present? && (
        @user.admin? || @user.operador? || @user.participant&.sub_grupo_empresa&.can_open_doors?
      ),
      open_door_path: (helpers.open_door_room_path(room) if room.device.present?)
    }
  end

  def open_room_door(args)
    # Debug logging to help diagnose permission issues (temporary)
    begin
      Rails.logger.info "[AI AGENT] open_room_door called by user_id=#{@user&.id} role=#{@user&.role} admin=#{@user&.admin?} operador=#{@user&.operador?} participant_id=#{@user&.participant&.id} sub_grupo_id=#{@user&.participant&.sub_grupo_empresa&.id} sub_can_open=#{@user&.participant&.sub_grupo_empresa&.can_open_doors? rescue 'unknown'}"
    rescue => e
      Rails.logger.info "[AI AGENT] open_room_door logging failed: #{e.class} - #{e.message}"
    end

    return { ok: false, message: "Desculpe, não consigo abrir portas." } unless (
      @user.admin? || @user.operador? || @user.participant&.sub_grupo_empresa&.can_open_doors?
    )

    room_match = find_room(args["room_id"], args["room_name"], Room.where.not(device_id: nil))
    return room_match unless room_match[:ok]

    room = room_match[:room]
    device = room.device
    return { ok: false, message: "Dispositivo nao encontrado para essa sala." } unless device.present?
    return { ok: false, message: "A sala #{room.name} esta offline. Nao enviei o comando para abrir a porta." } unless device_online_for_door?(device)

    OpenDoorJob.perform_later(device.ip, device.user, device.password)

    { ok: true, message: "Comando para abrir a porta enviado para #{room.name}." }
  end

  def device_online_for_door?(device)
    device.status.to_s.downcase == "online"
  end

  def can_manage_control_items?
    @user.admin? || (@user.operador? && @user.participant&.sub_grupo_empresa&.can_manage_items?)
  end

  def forbidden_items_message
    { ok: false, message: "Voce nao tem permissao para gerenciar o controle de objetos." }
  end

  def filter_control_items_scope(scope, args)
    scoped = scope

    case normalize_search_text(args["status"])
    when "disponivel", "disponiveis", "livre", "livres"
      scoped = scoped.where(status: "disponivel")
    when "em uso", "uso", "retirado", "retirada", "retirados"
      scoped = scoped.where(status: "em uso")
    end

    scoped
  end

  def control_items_for_query(scope, args)
    query = control_item_query(args)
    items = scope.to_a
    return items.sort_by { |item| [item.status.to_s == "em uso" ? 0 : 1, item.nome.to_s] } if query.blank?

    matches = scored_control_item_matches(items, query)
    matches.map { |match| match[:item] }
  end

  def control_item_query(args)
    [
      args["query"],
      args["item_name"],
      args["nome"]
    ].find(&:present?).to_s
  end

  def scored_control_item_matches(items, query)
    query_text = normalize_control_item_query(query)
    query_tokens = search_tokens(query_text)
    return [] if query_text.blank?

    items.filter_map do |item|
      fields = [item.nome, item.descricao, item.status]
      normalized_fields = fields.map { |field| normalize_search_text(field) }.reject(&:blank?)
      joined = normalized_fields.join(" ")
      score = control_item_match_score(query_text, query_tokens, normalized_fields, joined)
      score.positive? ? { item: item, score: score } : nil
    end.sort_by { |match| -match[:score] }
  end

  def control_item_match_score(query_text, query_tokens, normalized_fields, joined)
    score = 0
    score += 140 if normalized_fields.include?(query_text)
    score += 100 if normalized_fields.any? { |field| field.start_with?(query_text) }
    score += 80 if normalized_fields.any? { |field| field.include?(query_text) }

    matched_tokens = query_tokens.count { |token| joined.include?(token) }
    score += matched_tokens * 25
    score += 35 if query_tokens.any? && matched_tokens == query_tokens.size

    query_numbers = query_text.scan(/\d+/)
    field_numbers = joined.scan(/\d+/).to_set
    score += (query_numbers & field_numbers.to_a).size * 40

    score
  end

  def normalize_control_item_query(value)
    text = normalize_search_text(value)
    ignored = %w[
      objeto objetos item itens controle retirar retirada retire devolvendo devolver devolucao devolva
      devolvi devolvir devolveu devolvido devolvida devolvidos devolvidas entregue entreguei retornei
      listar lista historico historial status ver veja verificar consultar consulta saber consta perguntar pergunte
      para pra de da do das dos a o as os ao aos e ou se ja nao ainda
      com em eu voce vc meu minha meus minhas nome responsavel empresa
    ].to_set

    text.split.reject { |token| ignored.include?(token) }.join(" ")
  end

  def infer_control_item_args_from_message(args)
    inferred = {}
    return inferred if args["item_id"].present?

    text = normalize_search_text(@message)
    if @message =~ /\bID\s*(\d+)\b/i || text =~ /\bid\s*(\d+)\b/i
      inferred["item_id"] = Regexp.last_match(1).to_i
      return inferred
    end

    return inferred if control_item_query(args).present?

    query = normalize_control_item_query(@message)
    inferred["query"] = query if query.present?
    inferred
  end

  def find_control_item(args)
    args = args.merge(infer_control_item_args_from_message(args))
    scope = Item.includes(:item_movimentacoes)

    if args["item_id"].present?
      item = scope.find_by(id: args["item_id"])
      return { ok: true, item: item } if item
      return { ok: false, message: "Nao encontrei esse objeto." }
    end

    scoped = filter_control_items_scope(scope, args)
    items = control_items_for_query(scoped, args).first(6)
    return { ok: false, message: "Qual objeto voce quer usar? Informe ID ou nome." } if items.empty?
    return { ok: true, item: items.first } if items.one?

    options = items.map { |item| "ID #{item.id} - #{item.nome} (#{item.status.presence || "sem status"})" }
    { ok: false, message: "Encontrei mais de um objeto: #{options.join("; ")}. Qual deles devo usar?" }
  end

  def latest_item_checkout(item)
    item.item_movimentacoes
        .select { |movement| movement.tipo.to_s == "retirada" }
        .max_by(&:created_at)
  end

  def latest_item_movement(item)
    item.item_movimentacoes.max_by(&:created_at)
  end

  def same_person_name?(left, right)
    left_name = normalize_search_text(left)
    right_name = normalize_search_text(right)
    left_name.present? && right_name.present? && left_name == right_name
  end

  def control_item_payload(item)
    last_checkout = latest_item_checkout(item)
    last_movement = latest_item_movement(item)

    {
      id: item.id,
      nome: item.nome,
      descricao: item.descricao,
      status: item.status.presence || "sem status",
      em_uso: item.status.to_s == "em uso",
      responsavel_atual: (last_checkout&.responsavel if item.status.to_s == "em uso"),
      empresa_atual: (last_checkout&.empresa if item.status.to_s == "em uso"),
      ultima_movimentacao: last_movement&.tipo,
      ultima_movimentacao_em: last_movement&.created_at&.iso8601,
      ultima_movimentacao_em_label: (I18n.l(last_movement.created_at, format: :short) if last_movement)
    }
  end

  def item_movement_payload(movement)
    {
      id: movement.id,
      item_id: movement.item_id,
      item_nome: movement.item&.nome,
      tipo: movement.tipo,
      empresa: movement.empresa,
      responsavel: movement.responsavel,
      descricao: movement.descricao,
      criado_em: movement.created_at&.iso8601,
      criado_em_label: I18n.l(movement.created_at, format: :short)
    }
  end

  def find_company(name)
    return nil if name.blank?

    GrupoEmpresa.where("LOWER(nome) = ?", name.to_s.downcase).first ||
      GrupoEmpresa.where("nome ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(name.to_s)}%").first
  end

  def reservation_people_names(reservation)
    [
      reservation.solicitante&.name,
      reservation.responsavel&.name,
      *reservation.participants.map(&:name)
    ].compact.map(&:to_s).reject(&:blank?).uniq
  end

  def reservation_scope
    scope = Reservation.includes(:room)
    return scope if @user.admin? || @user.operador?

    scope.where(grupo_empresa_id: @user.participant&.grupo_empresa_id)
  end

  def can_manage_packages?
    @user.admin? || @user.operador? || !!@user.participant&.sub_grupo_empresa&.can_manage_encomendas
  end

  def package_scope
    scope = Encomenda.all
    return scope if can_manage_packages?

    if @user.participant_id.present?
      scope.where(destinatario_id: @user.participant_id)
    else
      Encomenda.none
    end
  end

  def filter_package_scope(scope, args)
    scoped = scope

    if args["destinatario_name"].present?
      participant = find_participant(args["destinatario_name"])
      return Encomenda.none unless participant

      scoped = scoped.where(destinatario_id: participant.id)
    end

    if args["codigo"].present?
      scoped = scoped.where("codigo ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(args["codigo"].to_s)}%")
    end

    %w[transportadora unidade].each do |field|
      next if args[field].blank?

      scoped = scoped.where("#{field} ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(args[field].to_s)}%")
    end

    if args["query"].present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(args["query"].to_s)}%"
      scoped = scoped.left_outer_joins(:destinatario)
                     .where("encomendas.codigo ILIKE :q OR encomendas.transportadora ILIKE :q OR encomendas.remetente ILIKE :q OR encomendas.observacao ILIKE :q OR encomendas.unidade ILIKE :q OR participants.name ILIKE :q", q: like)
    end

    case normalize_search_text(args["status"])
    when "pendente", "pendentes", "na portaria", "aguardando", "nao entregue", "nao entregues"
      scoped = scoped.where(entregue: [false, nil])
    when "entregue", "entregues", "retirada", "retirado"
      scoped = scoped.where(entregue: true)
    end

    scoped
  end

  def find_package(args)
    scope = package_scope.includes(:destinatario)

    if args["package_id"].present?
      package = scope.find_by(id: args["package_id"])
      return { ok: true, package: package } if package
      return { ok: false, message: "Nao encontrei essa encomenda." }
    end

    scoped = filter_package_scope(scope, args)
    packages = scoped.order(entregue: :asc, created_at: :desc).limit(6).to_a
    return { ok: false, message: "Qual encomenda voce quer consultar? Informe ID, codigo, destinatario ou unidade." } if packages.empty?
    return { ok: true, package: packages.first } if packages.one?

    options = packages.map do |package|
      "ID #{package.id} - #{package.codigo} - #{package.destinatario&.name || "sem destinatario"} (#{package_status_text(package)})"
    end
    { ok: false, message: "Encontrei mais de uma encomenda: #{options.join("; ")}. Qual delas devo consultar?" }
  end

  def package_status_text(package)
    package.entregue? ? "entregue" : "pendente na portaria"
  end

  def package_payload(package)
    {
      id: package.id,
      codigo: package.codigo,
      transportadora: package.transportadora,
      tipo: package.tipo,
      tamanho: package.tamanho,
      remetente: package.remetente,
      unidade: package.unidade,
      destinatario: package.destinatario&.name,
      status: package_status_text(package),
      entregue: package.entregue?,
      entregue_em: package.entregue_em&.iso8601,
      entregue_em_label: (I18n.l(package.entregue_em, format: :short) if package.entregue_em),
      recebido_em_label: I18n.l(package.created_at, format: :short)
    }
  end

  def registration_approval_scope
    scope = FormularioCadastro.all
    return scope if @user.admin? || @user.operador?

    grupo_empresa_id = @user.participant&.grupo_empresa_id
    return FormularioCadastro.none if grupo_empresa_id.blank?

    scope.where(grupo_empresa_id: grupo_empresa_id)
  end

  def filter_registration_approval_scope(scope, args)
    scoped = scope

    status = normalize_search_text(args["status"])
    case status
    when "aprovado", "aprovados", "aprovada", "aprovadas"
      scoped = scoped.where(status: "aprovado")
    when "reprovado", "reprovados", "reprovada", "reprovadas"
      scoped = scoped.where(status: "reprovado")
    when "pendente", "pendentes", "aguardando", "aguardando aprovacao"
      scoped = scoped.where(status: "pendente")
    end

    if args["nome"].present?
      scoped = scoped.where("nome ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(args["nome"].to_s)}%")
    end

    if args["cargo"].present?
      scoped = scoped.where("cargo ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(args["cargo"].to_s)}%")
    end

    if args["empresa"].present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(args["empresa"].to_s)}%"
      scoped = scoped.left_outer_joins(:grupo_empresa).where("grupo_empresas.nome ILIKE ?", like)
    end

    scoped
  end

  def find_registration_approval(args)
    scope = registration_approval_scope.includes(:grupo_empresa)

    if args["registration_id"].present?
      registration = scope.find_by(id: args["registration_id"])
      return { ok: true, registration: registration } if registration
      return { ok: false, message: "Nao encontrei esse pre-cadastro." }
    end

    scoped = filter_registration_approval_scope(scope, args)
    registrations = scoped.order(created_at: :desc).limit(6).to_a
    return { ok: false, message: "Qual pre-cadastro voce quer consultar? Informe ID, nome ou empresa." } if registrations.empty?
    return { ok: true, registration: registrations.first } if registrations.one?

    options = registrations.map do |registration|
      "ID #{registration.id} - #{registration.nome} - #{registration.grupo_empresa&.nome || "sem empresa"} (#{registration_approval_status_text(registration)})"
    end
    { ok: false, message: "Encontrei mais de um pre-cadastro: #{options.join("; ")}. Qual deles devo consultar?" }
  end

  def registration_approval_status_text(registration)
    {
      "pendente" => "aguardando aprovacao",
      "aprovado" => "aprovado",
      "reprovado" => "reprovado"
    }[registration.status.to_s] || registration.status.to_s
  end

  def registration_approval_payload(registration)
    {
      id: registration.id,
      nome: registration.nome,
      empresa: registration.grupo_empresa&.nome,
      cargo: registration.cargo,
      status: registration_approval_status_text(registration),
      status_key: registration.status,
      enviado_em: registration.created_at&.iso8601,
      enviado_em_label: I18n.l(registration.created_at, format: :short),
      url: Rails.application.routes.url_helpers.participants_path(tab: "aprovacoes")
    }
  end

  def can_manage_maintenance?
    @user.admin? || @user.operador?
  end

  def forbidden_maintenance_message
    { ok: false, message: "Voce nao tem permissao para criar ou cancelar manutencoes programadas." }
  end

  def maintenance_scope
    scope = ManutencaoProgramada.all
    return scope if can_manage_maintenance?

    scope.where(exibir_no_app: true)
  end

  def filter_maintenance_scope(scope, args)
    scoped = scope

    if args["query"].present?
      like = "%#{ActiveRecord::Base.sanitize_sql_like(args["query"].to_s)}%"
      scoped = scoped.where("titulo ILIKE :q OR categoria ILIKE :q OR local ILIKE :q OR responsavel ILIKE :q OR observacao ILIKE :q", q: like)
    end

    %w[categoria responsavel local].each do |field|
      next if args[field].blank?

      like = "%#{ActiveRecord::Base.sanitize_sql_like(args[field].to_s)}%"
      scoped = scoped.where("#{field} ILIKE ?", like)
    end

    if args["date"].present?
      date = parse_time(args["date"])
      scoped = scoped.where(data_prevista: date.to_date) if date
    end

    case normalize_search_text(args["status"])
    when "vencida", "vencido", "atrasada", "atrasado"
      scoped = scoped.where("data_prevista < ?", Date.current)
    when "hoje", "vence hoje"
      scoped = scoped.where(data_prevista: Date.current)
    when "aviso", "periodo de aviso", "em aviso"
      scoped = scoped.em_periodo_de_aviso
    when "futura", "futuro", "proxima", "proximas"
      scoped = scoped.where("data_prevista >= ?", Date.current)
    end

    scoped
  end

  def find_scheduled_maintenance(args)
    args = args.merge(infer_maintenance_selection_from_message(args))
    scope = maintenance_scope

    if args["maintenance_id"].present?
      maintenance = scope.find_by(id: args["maintenance_id"])
      return { ok: true, maintenance: maintenance } if maintenance
      return { ok: false, message: "Nao encontrei essa manutencao programada." }
    end

    scoped = filter_maintenance_scope(scope, args)
    maintenances = scoped.order(:data_prevista, :titulo).limit(6).to_a
    return { ok: false, message: "Qual manutencao programada voce quer usar? Informe ID, titulo, local ou data." } if maintenances.empty?
    return { ok: true, maintenance: maintenances.first } if maintenances.one?

    options = maintenances.map do |maintenance|
      "ID #{maintenance.id} - #{maintenance.titulo} (#{maintenance.data_prevista ? I18n.l(maintenance.data_prevista) : "sem data"})"
    end
    { ok: false, message: "Encontrei mais de uma manutencao programada: #{options.join("; ")}. Qual delas devo usar?" }
  end

  def maintenance_status_text(maintenance)
    date = maintenance.data_prevista
    return "sem data prevista" unless date
    return "vencida" if date < Date.current
    return "vence hoje" if date == Date.current
    return "em periodo de aviso" if maintenance_notice_period?(maintenance)

    "futura"
  end

  def maintenance_notice_period?(maintenance)
    date = maintenance.data_prevista
    return false unless date

    if maintenance.data_de_aviso.present?
      return Date.current.between?(maintenance.data_de_aviso.to_date, date.to_date)
    end

    days = maintenance.dias_para_aviso.to_i
    days.positive? && Date.current.between?(date.to_date - days, date.to_date)
  end

  def maintenance_payload(maintenance)
    {
      id: maintenance.id,
      title: maintenance.titulo,
      categoria: maintenance.categoria,
      local: maintenance.local,
      responsavel: maintenance.responsavel,
      periodicidade: maintenance.periodicidade,
      data_prevista: maintenance.data_prevista&.iso8601,
      data_prevista_label: (I18n.l(maintenance.data_prevista) if maintenance.data_prevista),
      status: maintenance_status_text(maintenance),
      observacao: maintenance.observacao,
      can_cancel: can_manage_maintenance?
    }
  end

  def normalize_maintenance_periodicity(value)
    text = normalize_search_text(value)
    return nil if text.blank?

    {
      "diaria" => "diario",
      "diario" => "diario",
      "semanal" => "semanal",
      "quinzenal" => "quinzenal",
      "mensal" => "mensal",
      "bimestral" => "bimestral",
      "trimestral" => "trimestral",
      "quadrimestral" => "quadrimestral",
      "semestral" => "semestral",
      "anual" => "anual",
      "bienal" => "bienal",
      "trienal" => "trienal"
    }[text] || value.to_s.strip
  end

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def conversation_input
    @history.map { |entry| entry.slice(:role, :content).merge(content: sanitize_ai_input(entry[:content])) } +
      [{ role: "user", content: sanitize_ai_input(@message) }]
  end

  def sanitize_ai_input(text)
    sanitized = text.to_s
      .gsub(/\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b/, "[cpf oculto]")
      .gsub(/\b\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}\b/, "[cnpj oculto]")

    known_participant_names.each do |name|
      next if name.blank?

      sanitized.gsub!(/#{Regexp.escape(name)}/i, "[participante]")
    end

    sanitized
  end

  def known_participant_names
    @known_participant_names ||= available_participants.limit(500).pluck(:name).compact
  end

  def normalize_history_entry(entry)
    return nil unless entry.respond_to?(:key?)

    role = entry["role"].presence || entry[:role].presence
    content = entry["content"].presence || entry[:content].presence
    return nil unless %w[user assistant].include?(role.to_s)
    return nil if content.blank?

    normalized = { role: role.to_s, content: content.to_s.first(2000) }
    cancelable_reservations = entry["cancelable_reservations"].presence || entry[:cancelable_reservations].presence
    normalized[:cancelable_reservations] = cancelable_reservations if cancelable_reservations.present?
    cancelable_maintenances = entry["cancelable_maintenances"].presence || entry[:cancelable_maintenances].presence
    normalized[:cancelable_maintenances] = cancelable_maintenances if cancelable_maintenances.present?
    normalized
  end

  def remembered_cancelable_reservations
    @history.reverse.find { |entry| entry[:role] == "assistant" && entry[:cancelable_reservations].present? }
      &.dig(:cancelable_reservations) || []
  end

  def remember_cancelable_reservations(tool_output)
    return unless tool_output[:reservations].present?

    @history << { role: "assistant", content: tool_output[:message].to_s, cancelable_reservations: tool_output[:reservations] }
  end

  def remembered_cancelable_maintenances
    @history.reverse.find { |entry| entry[:role] == "assistant" && entry[:cancelable_maintenances].present? }
      &.dig(:cancelable_maintenances) || []
  end

  def remember_cancelable_maintenances(tool_output)
    return unless tool_output[:maintenances].present?

    @history << { role: "assistant", content: tool_output[:message].to_s, cancelable_maintenances: tool_output[:maintenances] }
  end

  def scored_room_matches(rooms, query)
    query_text = normalize_search_text(query)
    query_tokens = search_tokens(query_text)
    return [] if query_text.blank?

    rooms.filter_map do |room|
      fields = room_search_fields(room)
      normalized_fields = fields.map { |field| normalize_search_text(field) }.reject(&:blank?)
      joined = normalized_fields.join(" ")
      score = room_match_score(query_text, query_tokens, normalized_fields, joined)
      score.positive? ? { room: room, score: score } : nil
    end.sort_by { |match| -match[:score] }
  end

  def unique_room_matches(matches)
    matches
      .group_by { |match| normalize_search_text(match[:room].name) }
      .map do |_name, grouped_matches|
        grouped_matches.max_by do |match|
          [
            match[:score],
            match[:room].device_id.present? ? 1 : 0,
            match[:room].espaco_comun? ? 1 : 0,
            -match[:room].id.to_i
          ]
        end
      end
      .sort_by { |match| -match[:score] }
  end

  def room_match_score(query_text, query_tokens, normalized_fields, joined)
    score = 0
    score += 120 if normalized_fields.include?(query_text)
    score += 90 if normalized_fields.any? { |field| field.start_with?(query_text) }
    score += 70 if normalized_fields.any? { |field| field.include?(query_text) }

    matched_tokens = query_tokens.count { |token| joined.include?(token) }
    score += matched_tokens * 18
    score += 30 if query_tokens.any? && matched_tokens == query_tokens.size

    query_numbers = query_text.scan(/\d+/)
    field_numbers = joined.scan(/\d+/).to_set
    score += (query_numbers & field_numbers.to_a).size * 35

    score
  end

  def room_search_fields(room)
    [
      room.name,
      room.floor,
      room.grupo,
      room.categoria,
      room.capacidade,
      room.interfone,
      room.empresa_proprietaria,
      room.dados_do_inquilino,
      room.room_group&.name
    ]
  end

  def normalize_search_text(value)
    I18n.transliterate(value.to_s)
      .downcase
      .gsub(/[^a-z0-9]+/, " ")
      .squeeze(" ")
      .strip
  end

  def numeric_search_matches?(text, query)
    text_numbers = text.scan(/\d+/).map(&:to_i)
    query_numbers = query.scan(/\d+/).map(&:to_i)
    text_numbers.any? && query_numbers.any? && (text_numbers & query_numbers).any?
  end

  def text_contains_partial_match?(text, query)
    words_text = text.split
    words_query = query.split
    words_query.any? { |q_word| words_text.any? { |t_word| t_word.start_with?(q_word) || q_word.start_with?(t_word) } }
  end

  def search_tokens(text)
    text.split.reject { |token| token.length <= 2 && token !~ /\d/ }
  end

  def room_options_text
    available_rooms.order(:name).limit(8).map { |room| room_label(room) }.join(", ")
  end

  def room_label(room)
    [room.name, room.floor.presence && "andar #{room.floor}", room.room_group&.name].compact.join(" - ")
  end

  def reservation_company_id(solicitante)
    return solicitante.grupo_empresa_id unless @user.admin? || @user.operador?

    solicitante.grupo_empresa_id || @user.participant&.grupo_empresa_id
  end

  def conflict_exists?(reservation)
    Reservation.where(room_id: reservation.room_id)
      .where("starts_at < ? AND ends_at > ?", reservation.ends_at, reservation.starts_at)
      .where(cancelada_em: nil)
      .where("ends_at > ?", Time.current)
      .exists?
  end

  def success(message)
    { ok: true, message: restore_agent_accents(message) }
  end

  def success_body(body)
    { ok: true, body: body }
  end

  def failure(message)
    { ok: false, message: restore_agent_accents(message) }
  end

  def normalize_result_message(result)
    return result unless result.is_a?(Hash) && result.key?(:message)

    result.merge(message: restore_agent_accents(result[:message]))
  end
end
