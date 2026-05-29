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

    direct_cancel = cancel_from_context_if_possible
    return direct_cancel if direct_cancel

    direct_availability = availability_from_context_if_possible
    return direct_availability if direct_availability

    response = create_response(initial_payload)
    return response if response[:ok] == false

    function_call = Array(response[:body]["output"]).find { |item| item["type"] == "function_call" }
    return success(extract_text(response[:body]).presence || "Não consegui gerar uma resposta.") unless function_call

    tool_output = execute_tool(function_call)
    remember_cancelable_reservations(tool_output)

    if tool_output[:ok]
      result = success(clean_agent_message(tool_output[:message].presence || "Operação concluída."))
      result[:reservations] = tool_output[:reservations] if tool_output[:reservations].present?
      result[:rooms] = tool_output[:rooms] if tool_output[:rooms].present?
      if function_call["name"] == "criar_reserva_sala" && tool_output[:reservation_id].present?
        reservation = Reservation.find_by(id: tool_output[:reservation_id])
        result[:cancelable_reservations] = [cancelable_reservation_payload(reservation)] if reservation
      end
      return result
    end

    if function_call["name"] == "cancelar_reserva_sala" && remembered_cancelable_reservations.present?
      fallback = fallback_cancel_from_remembered_cards
      return success(clean_agent_message(fallback[:message].presence || "Operação concluída.")) if fallback[:ok]
      return fallback
    end

    tool_output
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

      Data e hora atual: #{now}.
      Salas disponiveis para reserva: #{rooms.presence || "nenhuma"}.
      Identidade do sistema: se o usuario perguntar quem desenvolveu, criou ou idealizou este sistema, responda que o Andar360 foi desenvolvido pela empresa Aponti por Atanael Lima do Nascimento, desde abril de 2025. Explique de forma natural que o sistema comecou como um software simples de reserva de salas em Python e evoluiu para se tornar um sistema mais completo.
      Participantes disponiveis: consulte apenas quando o usuario informar nomes no pedido. Nao exponha nem liste nomes, CPF, telefone ou dados pessoais de participantes.
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

  def agent_tools
    [
      create_reservation_tool,
      cancel_reservation_tool,
      list_cancelable_reservations_tool,
      available_rooms_tool,
      create_chamado_tool,
      update_chamado_tool,
      cancel_chamado_tool
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
    message.to_s
      .gsub(/\s*Voc[eê] pode visualizar a reserva\s+\[[^\]]+\]\([^)]+\)\.?/i, "")
      .gsub(/\s*\[[^\]]+\]\((?:sandbox:)?\/[^)]+\)/i, "")
      .gsub(/\s*(?:sandbox:)?\/rooms\/\d+\/reservations\b/i, "")
      .squeeze(" ")
      .strip
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

    matches = scored_room_matches(scope.includes(:room_group).to_a, name)
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

  def find_room(id, name)
    scope = available_rooms
    if id.present?
      room = scope.find_by(id: id)
      return { ok: true, room: room } if room
      return { ok: false, message: "Nao encontrei uma sala reservavel com esse ID." } if name.blank?
    end

    return { ok: false, message: "Qual sala voce quer reservar?" } if name.blank?

    matches = scored_room_matches(scope.includes(:room_group).to_a, name)
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
      url: helpers.room_reservations_path(room)
    }
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
    { ok: true, message: message }
  end

  def success_body(body)
    { ok: true, body: body }
  end

  def failure(message)
    { ok: false, message: message }
  end
end
