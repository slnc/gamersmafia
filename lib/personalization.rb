# -*- encoding : utf-8 -*-
# This library is in charge of handling quicklinks (shortcuts to portals) and
# user forums (forums shown on the forums homepage).
module Personalization
  MAX_QUICKLINKS = 10

  def self.get_default_quicklinks
    # TODO(slnc): PERF compute this in the background
    @_cached_quicklinks_anon ||= begin
    qlinks = []
    User.db_query(
      "SELECT count(*) as cnt,
         portal_id
       FROM stats.pageviews
      WHERE created_on >= now() - '3 days'::interval
      GROUP BY portal_id
      ORDER BY cnt desc
      LIMIT 20;").collect {|dbr|
      next if dbr["portal_id"].to_i < 1
      break if qlinks.size > 15
      portal = Portal.find(dbr["portal_id"].to_i)
      qlinks.append({
        :code => portal.code,
        :url => "http://#{portal.code}.#{App.domain}",
      })
    }
    qlinks.sort_by {|qlink| qlink[:code].downcase}
    end
    @_cached_quicklinks_anon
  end
end
