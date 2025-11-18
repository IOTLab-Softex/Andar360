# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
puts "== Criando usuário admin inicial =="

admin_cpf  = "44455566611"  # defina o CPF master
admin_pass = "rxukpvo64"       # senha inicial obrigatória (mínimo 6 chars por validação)

admin_user = User.find_or_initialize_by(cpf: admin_cpf)

admin_user.email    = "root@.local"   # precisa porque Devise ainda valida email unique
admin_user.name     = "Root Admin"
admin_user.role     = "admin"
admin_user.password = admin_pass
admin_user.password_confirmation = admin_pass
admin_user.force_password_change = true  # se você quiser forçar troca no primeiro login
admin_user.save!

puts "Admin criado / já existia:"
puts "  CPF:  #{admin_user.cpf}"
puts "  Senha: #{admin_pass}"
puts "  Role: #{admin_user.role}"
puts "================================="