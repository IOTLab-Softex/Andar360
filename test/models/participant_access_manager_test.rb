require "test_helper"
require "minitest/mock"

class ParticipantAccessManagerTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "TV-only account is created without granting Andar360 access" do
    person = Participant.new(cpf: "12345678901", email: "tv-only@example.test", can_access_aponti_tv: true)
    account = User.new
    person.stub(:aponti_tv_eligible?, true) do
      person.stub(:build_user, account) do
        account.stub(:save!, true) do
          ParticipantAccessManager.call(person, {criar_usuario: "0", senha_gerada: "test-password"})
          refute account.can_access_andar360?
          assert_equal "client", account.role
          assert account.valid_password?("test-password")
        end
      end
    end
  end

  test "removing Andar360 permission keeps TV account and its password" do
    person = Participant.new(cpf: "12345678901", email: "tv-only@example.test", can_access_aponti_tv: true)
    account = User.new(id: 900, role: "client", password: "existing-password")
    person.stub(:user, account) do
      person.stub(:aponti_tv_eligible?, true) do
        account.stub(:new_record?, false) do
          account.stub(:save!, true) do
            ParticipantAccessManager.call(person, {criar_usuario: "0", manter_senha: "1"})
            refute account.can_access_andar360?
            assert account.valid_password?("existing-password")
          end
        end
      end
    end
  end
end
