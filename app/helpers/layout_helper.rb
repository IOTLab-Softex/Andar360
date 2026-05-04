module LayoutHelper
  def operador_ou_admin?
    return false unless current_user

    current_user.admin? || current_user.role.to_s == "operador"
  end

  def page_title
    case "#{controller_name}##{action_name}"
    when "dashboard#index"
      "INÍCIO"
    when "users#new"
      "RESERVAS DE SALAS"
    when "reservations#new"
      "Nova Reserva"
    when "reservations#edit"
      "Editar Reserva"
    when "reservations#by_room"
      if params[:room_id].present? && defined?(@room)
        "Reservas da Sala #{@room.name}"
      else
        "Reservas por Sala"
      end
    when "reservations#index"
      "Todas as Reservas"
    when "reservations#show"
      "Reserva: #{@reservation.title}"
    when "participants#new"
      "Novo Participante"
    when "participants#edit"
      "Editar Participante"
    when "rooms#index"
      "Salas"
    when "rooms#new", "rooms#create"
      "Adicionar Sala"
    when "rooms#show"
      "DETALHES DA SALA"
    when "rooms#edit", "rooms#update"
      "Editar Sala"
    when "devices#edit", "devices#update"
      "EDITAR DISPOSITIVO" 
    when "devices#index"
      "Dispositivos"
    when "devices#new", "devices#create"
      "Adicionar Dispositivos"
    when "participants#index"
      "USUÁRIOS"
    when "import_logs#index"
      "Logs de Importação"
    when "grupo_empresas#index"
      "EMPRESAS CADASTRADAS"
    when "grupo_empresas#new"
      "CADASTRAR EMPRESAS"
    when "settings#edit"
      "CONFIGURAÇÕES"
    when "grupo_empresas#edit"
      "EDITAR EMPRESA"
    when "room_groups#index"
      "GRUPOS DE SALAS"
    when "chamados#index"
      "CHAMADOS"
    when "chamados#new", "chamados#create"
      "ABRIR CHAMADO"
    when "chamados#edit", "chamados#update"
      "EDITAR CHAMADO"
    when "chamados#show"
      "CHAMADO: #{@chamado.titulo}"
    when "manutencao_programadas#edit", "manutencao_programadas#update"
      "EDITAR MANUTENÇÃO"
    when "manutencao_programadas#index"
      "MANUTENÇÕES PROGRAMADAS"
    when "manutencao_programadas#new", "manutencao_programadas#create"
      "ADICIONAR MANUTENÇÕES PROGRAMADAS"
    when "manutencao_programadas#show"
      "MANUTENÇÕES PROGRAMADAS: #{@manutencao_programada.titulo}"
    when "items#index"
      "CONTROLE DE OBJETOS"
    when "items#edit"
      "EDITAR OBJETO"
    when "items#new"
      "ADCIONAR OBJETO"
    when "prestador_servicos#index"
      "PRESTADORES DE SERVIÇOS"
    when "prestador_servicos#edit"
      "EDITAR PRESTADOR DE SERVIÇO: #{@prestador_servico.nome}"
    when "prestador_servicos#new"
      "ADCIONAR PRESTADOR DE SERVIÇO"
          when "prestador_servicos#show"
      "PRESTADOR: #{@prestador_servico.nome}"
    when "encomendas#show"
      "ENCOMENDA: #{@encomenda.id}"
    when "encomendas#index"
      "ENCOMENDAS"
      when "encomendas#new"
      "ADICIONAR ENCOMENDA"
    when "encomendas#edit"
      "EDITAR ENCOMENDA: #{@encomenda.codigo}"
    when "formulario_cadastros#new"
      "CADASTRO PARA CONTROLE DE ACESSO FACIAL"
        when "formulario_cadastros#edit"
      "EDITAR FORMULARIO DE CADASTRO"
       when "feedbacks#index"
      "FEEDBACK"
       when "feedbacks#show"
      "FEEDBACK: #{@feedback.id}"
      when "room_items#index"
      "ITEMS DE SALAS"
       when "solicitacao_compras#index"
      "SOLICITAÇÃO DE COMPRAS"
      when "solicitacao_compras#show"
      "SOLICITAÇÃO DE COMPRA: #{@solicitacao_compra.id}"
      when "solicitacao_compras#new"
      "SOLICITAÇÃO DE COMPRA"
      when "solicitacao_compras#edit"
      "EDITAR SOLICITAÇÃO DE COMPRA: #{@solicitacao_compra.id}"
    else
      content_for?(:title) ? content_for(:title) : "Sistema"
    end
    
  end

  def dashboard_button
    link_to(dashboard_path, class: "menu-btn-home") do
      content_tag(:i, "", class: "fa-solid fa-house") + " VOLTAR AO INÍCIO"
    end
  end

  def page_menu
    case "#{controller_name}##{action_name}"
    when "dashboard#index"
      safe_join([

        operador_ou_admin? ?
          link_to(new_room_path, class: "hide-on-mobile menu-btn") do
          content_tag(:span, "", class: "icon-rectangle-plus") + " ADICIONAR SALA / ESPAÇO"
        end : nil,

        link_to(participants_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-user") + " USUÁRIOS"
        end,
        link_to(new_reservation_path, class: "menu-btn-destaque") do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " ADICIONAR RESERVA"
        end,
        current_user&.admin? ?
          link_to(devices_path, class: "hide-on-mobile menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-mobile-screen") + " DISPOSITIVOS"
        end : nil,
        current_user&.admin? ?
          link_to(settings_path, class: "hide-on-mobile menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-gear") + " CONFIGURAÇÃO"
        end : nil,
        
      ])
    when "reservations#index"
      safe_join([
        dashboard_button,
        link_to(new_reservation_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " NOVA RESERVA"
        end,
      ])
    when "reservations#new"
      safe_join([
        dashboard_button,
        link_to(reservations_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " RESERVAS"
        end,
      ])
    when "reservations#show"
      safe_join([
        dashboard_button,
        link_to(edit_reservation_path(@reservation), class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-pen") + " EDITAR"
        end,
        link_to("VOLTAR À SALA", room_reservations_path(@reservation.room), class: "menu-btn"),
      ])
    when "reservations#edit"
      safe_join([
        dashboard_button,
        link_to(reservations_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " RESERVAS"
        end,
      ])
    when "reservations#by_room"
      if params[:room_id].present? && defined?(@room)
        safe_join([
          dashboard_button,
          link_to(new_reservation_path(room_id: @room.id), class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-plus") + " NOVA RESERVA"
          end,
          link_to(reservations_path, class: "menu-btn hide-sm") do
            content_tag(:i, "", class: "fa-solid fa-calendar-days") + " TODAS RESERVAS"
          end
        ])
      else
        dashboard_button
      end
    when "participants#new"
      safe_join([dashboard_button,
                 link_to(participants_path, class: "menu-btn") do
        content_tag(:i, "", class: "fa-solid fa-user") + " USUÁRIOS"
      end])
    when "rooms#index"
      safe_join([
        dashboard_button,
        link_to(new_room_path(), class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " NOVA SALA"
        end,
      ])
    
    when "rooms#edit", "rooms#update"
      if @room
        safe_join([
          dashboard_button,

          # Só admins podem criar nova sala (opcional)
          link_to(new_room_path, class: "menu-btn") do
            safe_join([content_tag(:i, "", class: "fa-solid fa-plus"), " NOVA SALA"])
          end,

          link_to(rooms_path, class: "menu-btn") do
            safe_join([content_tag(:i, "", class: "fa-solid fa-list"), " VER TODAS"])
          end,
        ].compact)
      else
        dashboard_button
      end
    when "rooms#show"
      if @room
        safe_join([
          dashboard_button,

          link_to(new_room_path, class: "menu-btn") do
            safe_join([content_tag(:i, "", class: "fa-solid fa-plus"), " NOVA SALA"])
          end,

          link_to(edit_room_path(@room), class: "menu-btn") do
            safe_join([content_tag(:i, "", class: "fa-solid fa-pen-to-square"), " EDITAR"])
          end,

          link_to(rooms_path, class: "menu-btn") do
            safe_join([content_tag(:i, "", class: "fa-solid fa-list"), " VER TODAS"])
          end,
        ])
      else
        dashboard_button
      end
    when "devices#edit", "devices#update"

      if params[:id].present? && @device.present?
        safe_join([
          dashboard_button,
          link_to(devices_path, class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-mobile-screen-button") + " VER DISPOSITIVOS"
          end,
        ])
      else
        safe_join([dashboard_button])
      end
    when "devices#new", "devices#create"
      safe_join([
        dashboard_button,
        link_to(devices_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-mobile-screen-button") + " VER DISPOSITIVOS"
        end,
      ])
    when "devices#index"
      safe_join([
        dashboard_button,
        link_to(new_device_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADICIONAR DISPOSITIVO"
        end
      ])
    when "participants#index"
      safe_join([
        dashboard_button,
        if current_user&.admin? || current_user&.operador?
          link_to(new_participant_path, class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-user") + " ADICIONAR USUÁRIOS"
          end
        end,
      ])
    when "participants#edit"
      safe_join([dashboard_button,
                 link_to(participants_path, class: "menu-btn") do
        content_tag(:i, "", class: "fa-solid fa-user") + " USUÁRIOS"
      end])
    when "rooms#new", "rooms#create"
      if @room
        safe_join([
          dashboard_button,

          link_to(rooms_path, class: "menu-btn") do
            safe_join([content_tag(:i, "", class: "fa-solid fa-list"), " VER TODAS"])
          end,
        ].compact)
      else
        dashboard_button
      end
    when "import_logs#index"
      dashboard_button
    when "grupo_empresas#index"
      safe_join([
        dashboard_button,
        if operador_ou_admin?
          link_to(new_grupo_empresa_path, class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-plus") + " CADASTRAR EMPRESA"
          end
        end,
      ])
    when "grupo_empresas#new"
      safe_join([
        dashboard_button,

        link_to(grupo_empresas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-building") + " EMPRESAS CADASTRADAS"
        end,
      ])
    when "grupo_empresas#edit"
      safe_join([
        dashboard_button,

        link_to(grupo_empresas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-building") + " EMPRESAS CADASTRADAS"
        end,
      ])
    when "settings#edit"
      safe_join([
        dashboard_button,
      ])
    when "room_groups#index"
      safe_join([
        dashboard_button,
      ])
    when "chamados#index"
      safe_join([
        dashboard_button,
        link_to(new_chamado_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADCIONAR CHAMADOS"
        end,
      ])
    when "chamados#new", "chamados#create"
      safe_join([
        dashboard_button,
        link_to(chamados_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-table-list") + " VER TODOS"
        end,
      ])
    when "chamados#edit", "chamados#update"
      safe_join([
        dashboard_button,
        link_to(new_chamado_path, class: "menu-btn hide-sm") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADCIONAR CHAMADOS"
        end,
        link_to(chamados_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-table-list") + " VER TODOS"
        end,
      ])
    when "chamados#show"
      safe_join([
        link_to(chamados_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-arrow-left") + " VOLTAR"
        end,
        dashboard_button,
        link_to(edit_chamado_path(@chamado), class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-file-pen") + " EDITAR"
        end,
        link_to(chamados_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-table-list") + " VER TODOS"
        end,
      ])
    when "manutencao_programadas#edit", "manutencao_programadas#update"
      safe_join([
        link_to(manutencao_programadas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-arrow-left") + " VOLTAR"
        end,
        dashboard_button,
        link_to(new_manutencao_programada_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADICIONAR"
        end,
        link_to(manutencao_programadas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-list-ul") + " VER TODOS"
        end,
      ])
    when "manutencao_programadas#index"
      safe_join([
        dashboard_button,
        link_to(new_manutencao_programada_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADICIONAR"
        end,
      ])
    when "manutencao_programadas#new", "manutencao_programadas#create"
      safe_join([
        dashboard_button,
        link_to(manutencao_programadas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-list-ul") + " VER TODOS"
        end,
      ])
    when "manutencao_programadas#show"
      safe_join([
        link_to(manutencao_programadas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-arrow-left") + " VOLTAR"
        end,
        dashboard_button,
        link_to(manutencao_programadas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-list-ul") + " VER TODOS"
        end,
        link_to(edit_manutencao_programada_path(@manutencao_programada), class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-file-pen") + " EDITAR"
        end,
      ])
    when "items#index"
      safe_join([
        dashboard_button,
        link_to(new_item_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-file-pen") + " ADCIONAR OBJETOS"
        end,
      ])
    when "items#edit"
      safe_join([
        dashboard_button,
        link_to(new_item_path, class: "menu-btn hide-sm") do
          content_tag(:i, "", class: "fa-solid fa-file-pen") + " ADCIONAR OBJETOS"
        end,
        link_to(items_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-file-pen") + " TODOS OBJETOS"
        end,
      ])
    when "items#new"
      safe_join([
        dashboard_button,
        link_to(items_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-file-pen") + " TODOS OBJETOS"
        end,
      ])
    when "prestador_servicos#index"
      safe_join([
        dashboard_button,
        link_to(new_prestador_servico_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADCIONAR"
        end,
      ])
    when "prestador_servicos#edit"
      safe_join([
        dashboard_button,
        link_to(prestador_servicos_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-toolbox") + " VER TODOS"
        end,
        link_to(new_prestador_servico_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADCIONAR"
        end,

      ])
    when "prestador_servicos#new"
      safe_join([
        dashboard_button,
        link_to(prestador_servicos_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-toolbox") + " VER TODOS"
        end,
      ])
      when "prestador_servicos#show"
      safe_join([
        dashboard_button,
        link_to(prestador_servicos_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-toolbox") + " VER TODOS"
        end,
      ])
    when "encomendas#show"
      safe_join([
        dashboard_button,
        link_to(encomendas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-box") + " VER TODOS"
        end,
        link_to(new_encomenda_path, class: "menu-btn hide-sm") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADCIONAR"
        end,

      ])
    when "encomendas#index"
      safe_join([
        dashboard_button,
        link_to(new_encomenda_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADCIONAR"
        end,

      ])
    when "encomendas#edit"
      safe_join([
        dashboard_button,
        link_to(new_encomenda_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " ADCIONAR"
        end,
        link_to(encomendas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-box") + " VER TODOS"
        end,
      ])
      when "encomendas#new"
      safe_join([
        dashboard_button,
        link_to(encomendas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-box") + " VER TODOS"
        end,
      ])

    when "formulario_cadastros#new"
      safe_join([
        dashboard_button,
        link_to(grupo_empresas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-left-long") + " VOLTAR"
        end,
      ])
       when "formulario_cadastros#edit"
      safe_join([
        dashboard_button,
        link_to(grupo_empresas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-left-long") + " VOLTAR"
        end,
      ])
       when "feedbacks#index"
      safe_join([
        dashboard_button
        
      ])
       when "feedbacks#show"
      safe_join([
        dashboard_button
        
      ])
       when "room_items#index"
      safe_join([
        dashboard_button
        
      ])
      when "solicitacao_compras#index"
      safe_join([
        dashboard_button,
        link_to(new_solicitacao_compra_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-file-circle-plus") + " SOLICITAR COMPRA"
        end
        
      ])
    when "solicitacao_compras#show"
  safe_join([
    link_to(solicitacao_compras_path, class: "menu-btn") do
      content_tag(:i, "", class: "fa-solid fa-left-long") + " Voltar"
    end,
    dashboard_button,   

    link_to("#", class: "menu-btn-destaque", onclick: "window.print(); return false;") do
      content_tag(:i, "", class: "fa-solid fa-print") + " IMPRIMIR"
    end,

    link_to(new_solicitacao_compra_path, class: "menu-btn") do
      content_tag(:i, "", class: "fa-solid fa-file-circle-plus") + " SOLICITAR COMPRA"
    end
  ])
  when "solicitacao_compras#new"
  safe_join([
    link_to(solicitacao_compras_path, class: "menu-btn hide-sm") do
      content_tag(:i, "", class: "fa-solid fa-left-long") + " Voltar"
    end,
    dashboard_button,   

    link_to(solicitacao_compras_path, class: "menu-btn") do
      content_tag(:i, "", class: "fa-solid fa-file-circle-plus") + " SOLICITAÇÕES COMPRA"
    end
  ])

  when "solicitacao_compras#edit"
  safe_join([
    link_to(solicitacao_compras_path, class: "menu-btn hide-sm") do
      content_tag(:i, "", class: "fa-solid fa-left-long") + " Voltar"
    end,
    dashboard_button,   

    link_to(solicitacao_compras_path, class: "menu-btn") do
      content_tag(:i, "", class: "fa-solid fa-file-circle-plus") + " SOLICITAÇÕES COMPRA"
    end
  ])
    end
  end
end

def sidebar_menu
  items = []

  items << content_tag(:li) do
    button_tag id: "toggle-theme", title: "Alternar tema", class: "btn-exit menu-btn", type: "button", style: "color: #ecf0f1;" do
      content_tag(:i, "", class: "fa-solid fa-circle-half-stroke me-2") +
      content_tag(:span, "", id: "theme-label")
    end
  end

  items << content_tag(:li) do
    if controller_name == "dashboard" && action_name == "index"
      # Botão desabilitado, só visual
      content_tag(:span, class: "btn-exit menu-btn disabled", style: "cursor: not-allowed; opacity: 0.6;") do
        content_tag(:i, "", class: "fa-solid fa-house") + " Início"
      end
    else
      # Link ativo
      link_to(root_path, class: "btn-exit menu-btn") do
        content_tag(:i, "", class: "fa-solid fa-house") + " Início"
      end
    end
  end

  if current_user&.admin? || current_user&.operador?
    submenu = content_tag(:ul, class: "submenu", id: "submenu-salas", style: "display: none;") do
      safe_join([
        content_tag(:li) do
          link_to(rooms_path) do
            safe_join([
              content_tag(:span, "", class: "icon-rectangle"),
              "Salas / Espaços",
            ])
          end
        end,
        content_tag(:li) do
          link_to(new_room_path) do
            safe_join([
              content_tag(:span, "", class: "icon-rectangle-plus"),
              " Adicionar Sala / Espaços",
            ])
          end
        end,
        content_tag(:li) do
          link_to(room_items_path) do
            safe_join([
              content_tag(:span, "", class: "fa-solid fa-cube"),
              " Items de Sala / Espaços ",
            ])
          end
        end,
        content_tag(:li) do
          link_to(room_groups_path) do
            safe_join([
              content_tag(:span, "", class: "fa-solid fa-layer-group"),
              " Grupos de Salas",
            ])
          end
        end,

      ])
    end

    items << content_tag(:li) do
      safe_join([
        content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-salas" }) do
          safe_join([
            content_tag(:span, "", class: "icon-rectangle"), "Sala / Espaço",
            content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
          ])
        end,
        submenu,
      ])
    end
  end

  submenu_chamados = content_tag(:ul, class: "submenu", id: "submenu_chamados", style: "display: none;") do
    safe_join([
      content_tag(:li) do
        link_to(new_chamado_path) do
          safe_join([
            content_tag(:span, "", class: "fa-solid fa-plus"),
            " Adicionar",
          ])
        end
      end,
      content_tag(:li) do
        link_to(chamados_path) do
          safe_join([
            content_tag(:span, "", class: "fa-solid fa-calendar-days"),
            " Todas",
          ])
        end
      end,
    ])
  end

  item_chamados = content_tag(:li) do
    safe_join([
      content_tag(:span, class: "submenu-toggle", data: { target: "#submenu_chamados" }) do
        safe_join([
          content_tag(:span, "", class: "fa-solid fa-clipboard"),
          " Chamados",
          content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
        ])
      end,
      submenu_chamados,
    ])
  end

  if current_user&.admin? || current_user&.operador?
    submenu_programadas = content_tag(:ul, class: "submenu", id: "submenu_programadas", style: "display: none;") do
      safe_join([
        content_tag(:li) do
          link_to(new_manutencao_programada_path) do
            safe_join([
              content_tag(:span, "", class: "fa-solid fa-plus"),
              " Adicionar",
            ])
          end
        end,
        content_tag(:li) do
          link_to(manutencao_programadas_path) do
            safe_join([
              content_tag(:span, "", class: "fa-solid fa-calendar-days"),
              " Todas",
            ])
          end
        end,
      ])
    end

    item_programadas = content_tag(:li) do
      safe_join([
        content_tag(:span, class: "submenu-toggle", data: { target: "#submenu_programadas" }) do
          safe_join([
            content_tag(:span, "", class: "fa-solid fa-clipboard"),
            " Programadas",
            content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
          ])
        end,
        submenu_programadas,
      ])
    end
  end

  submenu = content_tag(:ul, class: "submenu", id: "submenu-chamados", style: "display: none;") do
    safe_join([
      item_chamados,
      item_programadas,
    ])
  end

  items << content_tag(:li) do
    safe_join([
      content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-chamados" }) do
        safe_join([
          content_tag(:span, "", class: "fa-solid fa-clipboard"), "Manutenções",
          content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
        ])
      end,
      submenu,
    ])
  end

  submenu = content_tag(:ul, class: "submenu", id: "submenu-participants", style: "display: none;") do
    safe_join([
      content_tag(:li) do link_to(participants_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-user"),
                                                                   " Ver Usuários"])       end       end,
      if current_user&.admin? || current_user&.operador?
        content_tag(:li) do link_to(new_participant_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-plus"),
                                                                        " Adicionar Usuários"])         end         end
      end,
      if current_user&.client? 
content_tag(:li) do link_to(new_formulario_cadastro_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-id-badge"),
                                                                        " Cadastrar Acesso"])         end         end
end
    ])
  end

  items << content_tag(:li) do
    safe_join([
      content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-participants" }) do
        safe_join([
          content_tag(:span, "", class: "fa-solid fa-users"), " Usuários",
          content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
        ])
      end,
      submenu,
    ])
  end

  # Submenu de Reservas
  submenu = content_tag(:ul, class: "submenu", id: "submenu-reservas", style: "display: none;") do
    safe_join([
      content_tag(:li) do link_to(reservations_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-calendar-days"),
                                                                   " Todas Reservas"])       end       end,
      content_tag(:li) do link_to(new_reservation_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-plus"),
                                                                      " Nova Reserva"])       end       end,
    ])
  end

  items << content_tag(:li) do
    safe_join([
      content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-reservas" }) do
        safe_join([
          content_tag(:span, "", class: "fa-solid fa-calendar-days"), " Reservas",
          content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
        ])
      end,
      submenu,
    ])
  end

  if current_user&.admin? || current_user&.operador?
    submenu_portaria = content_tag(:ul, class: "submenu", id: "submenu_portaria", style: "display: none;") do
      safe_join([
        content_tag(:li) do
          link_to(items_path) do
            safe_join([
              content_tag(:span, "", class: "fa-solid fa-key"),
              " Controle de Objetos",
            ])
          end
        end,
        content_tag(:li) do
          link_to(encomendas_path) do
            safe_join([
              content_tag(:span, "", class: "fa-solid fa-box-open"),
              " Encomendas",
            ])
          end
        end,
      ])
    end

    items << content_tag(:li) do
      safe_join([
        content_tag(:span, class: "submenu-toggle", data: { target: "#submenu_portaria" }) do
          safe_join([
            content_tag(:span, "", class: "icon-rectangle"), "Portaria",
            content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
          ])
        end,
        submenu_portaria,
      ])
    end
  end

  if current_user&.admin?
    submenu = content_tag(:ul, class: "submenu", id: "submenu-device", style: "display: none;") do
      safe_join([
        content_tag(:li) do link_to(new_device_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-plus"),
                                                                   " Adicionar de Dispositivos"])         end         end,
        content_tag(:li) do link_to(devices_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-mobile-screen-button"),
                                                                " Ver Dispositivos"])         end         end,

      ])
    end

    items << content_tag(:li) do
      safe_join([
        content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-device" }) do
          safe_join([
            content_tag(:span, "", class: "fa-solid fa-mobile-screen-button"), " Dispositivos",

            content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
          ])
        end,
        submenu,
      ])
    end
  end

  submenu = content_tag(:ul, class: "submenu", id: "submenu-Configurações", style: "display: none;") do
    safe_join([
      if current_user&.admin?
        content_tag(:li) do link_to(settings_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-sliders"),
                                                                 " Definições"])         end         end
      end,
      if current_user&.admin?
        content_tag(:li) do link_to(import_logs_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-timeline"),
                                                                    " Logs de Importação"])         end         end
      end,

      content_tag(:li) do link_to(grupo_empresas_path) do safe_join([content_tag(:span, "", class: "fa-solid fa-building"),
                                                                     " Empresas Cadastradas"])       end       end,

    ])
  end

  if operador_ou_admin?
  submenu_compras = content_tag(:ul, class: "submenu", id: "submenu-compras", style: "display: none;") do
    safe_join([
      # Lista de solicitações
      content_tag(:li) do
        link_to(solicitacao_compras_path) do
          safe_join([
            content_tag(:span, "", class: "fa-solid fa-list-ul"),
            " Solicitações de compras"
          ])
        end
      end,

      # Nova solicitação
      content_tag(:li) do
        link_to(new_solicitacao_compra_path) do
          safe_join([
            content_tag(:span, "", class: "fa-solid fa-file-circle-plus"),
            " Solicitar compra"
          ])
        end
      end
    ])
  end

  items << content_tag(:li) do
    safe_join([
      content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-compras" }) do
        safe_join([
          content_tag(:span, "", class: "fa-solid fa-file-invoice-dollar"),
          " Compras",
          content_tag(:i, "", class: "fa fa-chevron-down chevron-icon",
                      style: "margin-left: 6px; transition: transform 0.3s ease;")
        ])
      end,
      submenu_compras
    ])
  end
end

  if operador_ou_admin?
    items << content_tag(:li) do
      link_to prestador_servicos_path, class: "submenu-toggle btn-exit" do
        content_tag(:i, "", class: "fa-solid fa-toolbox") + " Prestadores de Serviços"
      end
    end
  end

  if operador_ou_admin?
    items << content_tag(:li) do
      link_to announcements_path, class: "submenu-toggle btn-exit" do
        content_tag(:i, "", class: "fa-solid fa-bullhorn") + " Anúncios"
      end
    end
  end


  items << content_tag(:li) do
    safe_join([
      content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-Configurações" }) do
        safe_join([
          content_tag(:span, "", class: "fa-solid fa-gear"), " Configurações",
          content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;"),
        ])
      end,
      submenu,
    ])
  end

  items << content_tag(:li) do
    button_to destroy_user_session_path, method: :delete, class: "submenu-toggle btn-exit" do
      content_tag(:i, "", class: "fa-solid fa-right-from-bracket") + " Sair"
    end
  end

  safe_join(items)
end
