# -*- encoding : utf-8 -*-
class AchmedObserver < ActiveRecord::Observer
  CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD = 5000
  observe CashMovement
  observe SlogEntry

  def after_create(object)
    case object.class.name

     when 'CashMovement' then
       if object.ammount >= CASH_MOVEMENT_SUSPICIOUSNESS_THRESHOLD
         SlogEntry.create(:headline => object.to_s,
                          :type_id => SlogEntry::TYPES[:security])
       end
      when 'SlogEntry'
        self.handle_slog_entry(object)
    end
  end

  def handle_slog_entry(slog_entry)
    reporter = slog_entry.reporter
    case slog_entry.type_id
      when SlogEntry::TYPES[:general_comment_report]
        if reporter.has_admin_permission?(:capo)
          self.moderate_comment(reporter, slog_entry)
        end

      when SlogEntry::TYPES[:faction_comment_report]
        comment = Comment.find(slog_entry.entity_id)
        if comment.content.my_faction.user_is_moderator(reporter)
          self.moderate_comment(reporter, slog_entry)
        end

      when SlogEntry::TYPES[:bazar_district_comment_report]
        comment = Comment.find(slog_entry.entity_id)
        if comment.content.bazar_district.user_is_moderator(reporter)
          self.moderate_comment(reporter, slog_entry)
        end
    end
  end

  def moderate_comment(user, slog_entry)
    comment = Comment.find(slog_entry.entity_id)
    comment.moderate(user, slog_entry.data[:moderation_reason])
    slog_entry.mark_as_resolved(Ias.MrAchmed)
  end
end
