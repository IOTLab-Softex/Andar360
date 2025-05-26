class Setting < ApplicationRecord

    def self.get(key)
  find_by(key: key)&.value
end


# app/models/setting.rb
after_commit :reload_schedulers, on: [:update]

def reload_schedulers
  SchedulerManager.reload_all
end


end
