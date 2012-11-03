# -*- encoding : utf-8 -*-
module TagsHelper
  def tag_url(tag)
    "/tags/#{tag.slug}"
  end

  def top_tags_by_interest
    terms = User.db_query(
        "SELECT count(*) as cnt,
           entity_id
         FROM user_interests a
         JOIN terms b ON a.entity_id = b.id
         WHERE entity_type_class = 'Term' AND b.taxonomy = 'ContentsTag'
         GROUP BY entity_id
         ORDER BY cnt DESC
         LIMIT 10").collect {|row| [row['cnt'].to_i, Term.find(row['entity_id'].to_i)]}
    terms.sort_by{|cnt, term| -cnt}
  end
end
