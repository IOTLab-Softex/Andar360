module ApplicationHelper
   def tela_de_alteracao_de_senha?
    request.fullpath == "/users"
  end

end
