# -*- encoding : utf-8 -*-
module DecisionsHelper
  def pending_decisions_for_user(user)
    decisions = []
    Decision.pending.find(:all, :order => 'created_on DESC').each do |decision|
      if Authorization.can_vote_on_decision?(user, decision)
        decisions.append(decision)
      end
    end
    decisions
  end

  def decision_title(decision)
    "#{gm_translate(decision.decision_type_class)} #{decision.decision_description}"
  end

  def current_decision_user_reputations(user)
    user.decision_user_reputations.find(:all).sort_by {|r|
      gm_translate(r.decision_type_class)
    }
  end

  def decision_context(decision)
    case decision.decision_type_class
    when "CreateTag"
      out = ["Contenidos iniciales con este tag:<br /><ul>"]

      decision.context[:initial_contents].each do |content_id|
        content = Content.find_by_id(content_id.to_i)
        if content.nil?
          out.append("<li>(Contenido inválido: #{content_id.to_i})</li>")
        else
          out.append("<li><a href=\"#{Routing.gmurl(content)}\">#{content.name}</a></li>")
        end
      end
      out.append("</ul>")

      if decision.context[:tag_overlaps].size > 0
        out.append("<table><tr><th class=\"w125\">Tag</th><th>Solapamiento</th></tr>")
        sorted_overlaps = decision.context[:tag_overlaps].sort_by{|term_id, overlap|
          Term.find(term_id.to_i).name
        }
        sorted_overlaps.each do |term_id, overlap|
          out.append(
              "<tr>
                 <td>#{Term.find(term_id.to_i).name}</td>
                 <td class=\"w125\">#{draw_pcent_bar(overlap.to_f)}</td>
               </tr>")
        end
        out.append("</table>")
      end

      out.append("</ul>")
      out.join("\n")
    end
  end
end
