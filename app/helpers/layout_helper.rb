module LayoutHelper
  def page_title
    case "#{controller_name}##{action_name}"
    when "dashboard#index"
      "RESERVAS DE SALAS"
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
       when "rooms#new"
      "Adicionar Sala"
       when "rooms#edit"
      "Editar Sala"
      when "devices#edit"
      "Editar Dispositivo"
       when "devices#index"
      "Dispositivos"
      when "devices#new"
      "Adicionar Dispositivos"
      when "participants#index"
      "USUÁRIOS"
        when "import_logs#index"
      "Logs de Importação"
      when "grupo_empresas#index"
      "EMPRESAS CADASTRADAS"
       when "grupo_empresas#new"
      "CADASTRAR EMPRESAS"
      when "settings#index"
      "CONFIGURAÇÕES"
      when "grupo_empresas#edit"
      "EDITAR EMPRESA"
      
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
        current_user&.admin? ?
        link_to(new_room_path, class: 'hide-on-mobile menu-btn') do
          content_tag(:span, "", class: "icon-rectangle-plus") + " ADICIONAR SALA"
        end : nil,
      
        link_to(participants_path, class: 'menu-btn') do
          content_tag(:i, "", class: "fa-solid fa-user") + " USUÁRIOS"
        end,
        link_to(new_reservation_path, class: 'menu-btn-destaque') do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " ADICIONAR RESERVA"
        end,
        current_user&.admin? ?
        link_to(devices_path, class: 'hide-on-mobile menu-btn') do
          content_tag(:i, "", class: "fa-solid fa-mobile-screen") + " DISPOSITIVOS"
        end : nil,
         current_user&.admin? ?
        link_to(settings_path, class: 'hide-on-mobile menu-btn') do
          content_tag(:i, "", class: "fa-solid fa-gear") + " CONFIGURAÇÃO"
        end : nil
      ])
    when "reservations#index"
      safe_join([
        dashboard_button,
        link_to(new_reservation_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " NOVA RESERVA"
        end
      ])
    when "reservations#new"
      safe_join([
        dashboard_button,
        link_to(reservations_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " RESERVAS"
        end
      ])
    when "reservations#show"
      safe_join([
        dashboard_button,
        link_to(edit_reservation_path(@reservation), class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-pen") + " EDITAR"
        end,
        link_to("VOLTAR À SALA", room_reservations_path(@reservation.room), class: "menu-btn")
      ])
    when "reservations#edit"
      safe_join([
        dashboard_button,
        link_to(reservations_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-calendar-days") + " RESERVAS"
        end
      ])
    when "reservations#by_room"
      if params[:room_id].present? && defined?(@room)
        safe_join([
          dashboard_button,
          link_to(new_reservation_path(room_id: @room.id), class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-plus") + " NOVA RESERVA"
          end
        ])
      else
        dashboard_button
      end
    when "participants#new"
      safe_join([ dashboard_button,
      link_to(participants_path, class: 'menu-btn') do
        content_tag(:i, "", class: "fa-solid fa-user") + " USUÁRIOS"
      end ])
    when "rooms#new"
      if params[:room_id].present? && defined?(@room)
        safe_join([
          dashboard_button,
          link_to(new_reservation_path(room_id: @room.id), class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-plus") + " NOVA RESERVA"
          end
        ])
      else
        safe_join([ dashboard_button ])
      end
    when "rooms#edit"
      if params[:room_id].present? && defined?(@room)
        safe_join([
          dashboard_button,
          link_to(new_reservation_path(room_id: @room.id), class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-plus") + " NOVA RESERVA"
          end
        ])
      else
        safe_join([ dashboard_button ])
      end
    when "devices#edit"
      if params[:id].present? && @device.present?
        safe_join([
          dashboard_button,
          link_to(device_path(@device), class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-plus") + " VER DISPOSITIVO"
          end
        ])
      else
        safe_join([ dashboard_button ])
      end
      when "devices#new"
      
        safe_join([
          dashboard_button,
          link_to(devices_path, class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-mobile-screen-button") + " VER DISPOSITIVOS"
          end
        ])
     
    when "devices#index"
      
        safe_join([
          dashboard_button,
          link_to(new_device_path, class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-plus") + " ADICIONAR DISPOSITIVO"
          end,
          link_to(settings_path, class: "menu-btn") do
            content_tag(:i, "", class: "fa-solid fa-gear") + " CONFIGURAÇÃO"
          end
        ])
      when "participants#index"
      
        safe_join([
          dashboard_button,
          link_to(new_participant_path, class: 'menu-btn') do
            content_tag(:i, "", class: "fa-solid fa-user") + " ADICIONAR USUÁRIOS"
          end
          
        ])
      when "participants#edit"
        safe_join([ dashboard_button,
        link_to(participants_path, class: 'menu-btn') do
          content_tag(:i, "", class: "fa-solid fa-user") + " USUÁRIOS"
        end ])
      when "rooms#new"
        if params[:room_id].present? && defined?(@room)
          safe_join([
            dashboard_button,
            link_to(new_reservation_path(room_id: @room.id), class: "menu-btn") do
              content_tag(:i, "", class: "fa-solid fa-plus") + " NOVA RESERVA"
            end
          ])
        else
          safe_join([ dashboard_button ])
        end
      when "import_logs#index"
        
        dashboard_button
           
      when "grupo_empresas#index"
       
        safe_join([
        dashboard_button,
          if current_user&.admin?
        link_to(new_grupo_empresa_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-plus") + " CADASTRAR EMPRESA"
        end
      end
          ])
          when "grupo_empresas#new"
       
        safe_join([
        dashboard_button,
          
        link_to(grupo_empresas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-building") + " EMPRESAS CADASTRADAS"
        end
          ])

          when "grupo_empresas#edit"
       
        safe_join([
        dashboard_button,
          
        link_to(grupo_empresas_path, class: "menu-btn") do
          content_tag(:i, "", class: "fa-solid fa-building") + " EMPRESAS CADASTRADAS"
        end
          ])
       when "settings#index"
      safe_join([
        dashboard_button
      ])
    end
    
    
  end
  
end

def sidebar_menu
  items = []

 
 items << content_tag(:li) do
    button_tag "🌓 Alternar tema", id: "toggle-theme", title: "Alternar tema", class: "btn-exit menu-btn", type: "button"
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


if current_user&.admin?
  submenu = content_tag(:ul, class: "submenu", id: "submenu-salas", style: "display: none;") do
    safe_join([
      content_tag(:li) do  link_to(new_room_path) do    safe_join([      content_tag(:span, "", class: "icon-rectangle-plus"),
      " Adicionar Sala"
    ])
  end
end

    ])
  end

 items << content_tag(:li) do
  safe_join([
    content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-salas" }) do
      safe_join([
        content_tag(:span, "", class: "icon-rectangle"), "Sala",
        content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;")
      ])
    end,
    submenu
  ])
end
end

 
submenu = content_tag(:ul, class: "submenu", id: "submenu-participants", style: "display: none;") do
    safe_join([
      content_tag(:li) do  link_to(participants_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-user"),
      " Ver Usuários"
    ])
  end
end,
content_tag(:li) do  link_to(new_participant_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-plus"),
      " Adicionar Usuários"
    ])
    end
    end

    ])
  end

 items << content_tag(:li) do
  safe_join([
    content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-participants" }) do
      safe_join([
        content_tag(:span, "", class: "fa-solid fa-users"), " Usuários",
        content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;")
      ])
    end,
    submenu
  ])
end

  # Submenu de Reservas
  submenu = content_tag(:ul, class: "submenu", id: "submenu-reservas", style: "display: none;") do
    safe_join([
      content_tag(:li) do  link_to(reservations_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-calendar-days"),
      " Ver Reservas"
    ])
    end
    end,
    content_tag(:li) do  link_to(new_reservation_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-plus"),
      " Nova Reserva"
    ])
    end
    end,
    ])
  end

 items << content_tag(:li) do
  safe_join([
    content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-reservas" }) do
      safe_join([
        content_tag(:span, "", class:"fa-solid fa-calendar-days")," Reservas",
        content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;")
      ])
    end,
    submenu
  ])
end

if current_user&.admin?
submenu = content_tag(:ul, class: "submenu", id: "submenu-device", style: "display: none;") do
    safe_join([
      content_tag(:li) do  link_to(new_device_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-plus"),
      " Adicionar de Dispositivos"
    ])
  end
end,
content_tag(:li) do  link_to(devices_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-mobile-screen-button"),
      " Ver Dispositivos"
    ])
    end
    end

    ])
  end

 items << content_tag(:li) do
  safe_join([
    content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-device" }) do
      safe_join([
        content_tag(:span, "", class: "fa-solid fa-mobile-screen-button"), " Dispositivos",
     
        content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;")
      ])
    end,
    submenu
  ])
end
end



submenu = content_tag(:ul, class: "submenu", id: "submenu-Configurações", style: "display: none;") do
    safe_join([
      if current_user&.admin?
      content_tag(:li) do  link_to(settings_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-sliders"),
      " Definições"
    ])
    end
  end
    end,
    if current_user&.admin?
      content_tag(:li) do  link_to(import_logs_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-timeline"),
      " Logs de Importação"
    ])
  end
end
end,

content_tag(:li) do  link_to(grupo_empresas_path) do    safe_join([      content_tag(:span, "", class: "fa-solid fa-building"),
      " Empresas Cadastradas"
    ])
    end
    end

    ])
  end

 items << content_tag(:li) do
  safe_join([
    content_tag(:span, class: "submenu-toggle", data: { target: "#submenu-Configurações" }) do
      safe_join([
        content_tag(:span, "", class: "fa-solid fa-gear"), " Configurações",
        content_tag(:i, "", class: "fa fa-chevron-down chevron-icon", style: "margin-left: 6px; transition: transform 0.3s ease;")
      ])
    end,
    submenu
  ])
end

 
 
 
items << content_tag(:li) do
  button_to(destroy_user_session_path, method: :delete, class: "submenu-toggle btn-exit") do
    content_tag(:i, "", class: "fa-solid fa-right-from-bracket") + " Sair"
  end
end



  safe_join(items)
end


