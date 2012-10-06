# This module determines what actions can different users or clans take.
module Authorization
  module Users
    # TODO(slnc): migrar todas las llamadas restantes a .has_skill? a que usen
    # este sistema.
    def self.can_report_users?(user)
      user.has_skill?("ReportUsers")
    end

    def self.can_edit_faq?(user)
      user.has_skill?("EditFaq")
    end

    def self.can_edit_content?(user)
      user.has_skill?("EditContents")
    end

    def self.can_antiflood_users?(user)
      user.has_skill?("Antiflood")
    end
  end
end
