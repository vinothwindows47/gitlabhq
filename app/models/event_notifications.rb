class EventNotifications < ActiveRecord::Base
  attr_accessible :last_notification, :project_id, :user_id
end
