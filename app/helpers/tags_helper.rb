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

  def top_tags_by_activity
    terms = User.db_query(
        "SELECT count(*) as cnt,
           a.term_id
         FROM contents_terms a
         JOIN terms b ON a.term_id = b.id
         JOIN contents c ON a.content_id = c.id
         WHERE c.state = #{Cms::PUBLISHED}
           AND c.created_on >= NOW() - '3 months'::interval
           AND b.taxonomy = 'ContentsTag'
         GROUP BY a.term_id
         ORDER BY cnt DESC
         LIMIT 10").collect {|row| [row['cnt'].to_i, Term.find(row['term_id'].to_i)]}
    terms.sort_by{|cnt, term| -cnt}
  end
end
