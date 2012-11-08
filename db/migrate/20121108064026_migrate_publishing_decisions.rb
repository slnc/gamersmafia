class MigratePublishingDecisions < ActiveRecord::Migration
  def up
    # migrate_publishing_decisions
  end

  def down
  end

  def migrate_publishing_decisions
    Content.find_each(:conditions => "contents.id IN (SELECT DISTINCT(content_id) FROM publishing_decisions)", :include => :contents_type) do |content|
      decision = Decision.create({
        :decision_type_class => "Publish#{content.content_type.name}",
        :context => {
          :content_id => content.id,
          :content_name => content.name,
          :initiating_user_id => content.user_id,
        },
      })
      choice_yes = decision.decision_choices.find_by_name("Sí")
      choice_no = decision.decision_choices.find_by_name("No")
      content.publishing_decisions.find(:all).each do |pubdec|
        duc = decision.decision_user_choices.create({
          :user_id => pubdec.user_id,
          :decision_choice_id => pubdec.publish? ? choice_yes : choice_no,
          :custom_reason => pubdec.deny_reason,
        })

        duc.update_column(:probability_right, pubdec.user_weight)
        duc.update_column(:created_on, pubdec.created_on)
        duc.update_column(:updated_on, pubdec.updated_on)

        if pubdec.accept_comment.to_s != ""
          comment = decision.decision_comments.create({
            :user_id => pubdec.user_id,
            :comment => pubdec.accept_comment,
          })
          comment.update_column(:created_on, pubdec.created_on)
          comment.update_column(:updated_on, pubdec.updated_on)
        end
      end
      final_choice = (content.state == Cms::PUBLISHED) ? choice_yes : choice_no
      decision.update_column(:final_decision_choice_id, final_choice)
      decision.update_column(:state, Decision::DECIDED)
    end
    DecisionUserReputation.recalculate_all_user_reputations
  end
end
