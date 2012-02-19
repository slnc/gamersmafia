module StatsMixings
  module GoalsMixings
    def self.included(base)
      base.extend ClassMethods
      base.class_eval do
        cattr_accessor :available_goals
        cattr_accessor :available_goals_abbrv
        self.available_goals = [:avg_pages_per_visitor, :user_registrations, :nobounce, :clickthrough, :comments, :page_clickthrough, :total_clickthrough]
        self.available_goals_abbrv = {:avg_pages_per_visitor => :appv,
          :user_registrations => :ureg,
          :nobounce => :nb,
          :clickthrough => :clck,
          :comments => :cmm,
          :page_clickthrough => :pclck,
          :total_clickthrough => :tclck}
          self.send(:after_init) if self.respond_to?(:after_init)
      end
    end

    module ClassMethods
      def custom(opts)
        raise "TODO"
      end

      def user_registrations(opts)
        clickthrough(opts.merge(
                                :append_to_from_where_sql => 'controller = \'usuarios\' AND action = \'alta\'',
        :append_to_to_where_sql => 'controller = \'usuarios\' AND action = \'create\' AND flash_error is null'))
      end

      def comments(opts)
        clickthrough(opts.merge(
                                :append_to_to_where_sql => 'controller = \'comentarios\' AND action = \'crear\' AND flash_error is null'))
      end

      def nobounce(opts)
        clickthrough(opts.merge(
                                :append_to_from_where_sql => 'id = (select min(id) from stats.pageviews where visitor_id = parent.visitor_id)'
        ))
      end


      def total_clickthrough(opts)
        clickthrough(opts.merge(:total => true))
      end

      def date_constraints(opts)
        date_constraints = "created_on >= '#{opts[:ab_test_treatment][0].created_on.strftime("%Y-%m-%d %H:%M:%S")}'"
      date_constraints << " AND created_on <= '#{opts[:ab_test_treatment][0].completed_on.strftime("%Y-%m-%d %H:%M:%S")}'" if opts[:ab_test_treatment][0].completed_on
        date_constraints
      end

      def visitor_id_constraint(opts)
      " AND visitor_id in (select visitor_id
                             from treated_visitors
                            WHERE ab_test_id = #{opts[:ab_test_treatment][0].id}
                              AND treatment = #{opts[:ab_test_treatment][1]})"
      end

      def user_id_constraint(opts)
        opts2 = {:users_field_key => 'user_id'}.merge(opts)
      " AND #{opts2[:users_field_key]} in (select user_id
                             from treated_visitors
                            WHERE ab_test_id = #{opts2[:ab_test_treatment][0].id}
                              AND treatment = #{opts2[:ab_test_treatment][1]})"
      end

      def abtest_treatment_constraint(opts)
      "AND abtest_treatment LIKE '%\"#{opts[:ab_test_treatment][0].id}\": \"#{opts[:ab_test_treatment][1]}\"%'"
      end

      def clickthrough(opts)
        out = {}
        out[:treated_visitors] = self.treated_visitors(opts)

        # constraints básicas
        from_where_sql = date_constraints(opts)
        to_where_sql = date_constraints(opts)

        # FROM
        from_where_sql << visitor_id_constraint(opts)
        from_where_sql << abtest_treatment_constraint(opts)
        from_where_sql << " AND #{opts[:append_to_from_where_sql]}" if opts[:append_to_from_where_sql]


        # TO
        to_where_sql << visitor_id_constraint(opts)
        to_where_sql << abtest_treatment_constraint(opts)
        to_where_sql << " AND campaign = 'xab#{opts[:ab_test_treatment][0].id}-#{opts[:ab_test_treatment][1]}'"

        # check adicional visitor_id en to debe estar en los que les hemos mostrado el tratamiento
        # esta query es expensive y la estamos duplicando ya que la acabamos de hacer abajo
        # comprobar si es necesaria en la vida real
        #to_where_sql << " AND visitor_id IN (SELECT distinct(visitor_id)
        #                                           FROM stats.pageviews
        #                                          WHERE #{from_where_sql})"
        # deshabilitado ya que hacemos chequeo por visitor_id

        to_where_sql << " AND #{opts[:append_to_to_where_sql]}" if opts[:append_to_to_where_sql]

        # contabilizamos impresiones y conversiones
        count_sql = opts[:total] ? 'count(visitor_id)' :  'count(distinct(visitor_id))'

        out[:impressions] = User.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{from_where_sql}")[0]['count'].to_f

        out[:conversions] = User.db_query("SELECT #{count_sql}
                                          FROM stats.pageviews as parent
                                         WHERE #{to_where_sql}")[0]['count'].to_f

        out[:rate] = out[:conversions] / (out[:impressions]  > 0 ? out[:impressions] : 1)
        out
      end


      def avg_pages_per_visitor(opts)
        # busco los visitor_id afectados
        # calculo la media de páginas servidas a cada visitante durante el tiempo que duró el experimento
        out = {}
        out[:treated_visitors] = self.treated_visitors(opts)
        dbinfo = User.db_query("SELECT avg(foo), stddev(foo) FROM (select count(*) as foo
                                    FROM stats.pageviews as parent
                                   WHERE #{date_constraints(opts)}
                                     #{visitor_id_constraint(opts)}
                                     #{abtest_treatment_constraint(opts)}
                                  GROUP BY visitor_id) as foo")[0]
        out[:rate] = dbinfo['avg'].to_f
        out[:stddev] = dbinfo['stddev'].to_f
        out
      end


      def treated_visitors(opts)
        # visitantes tratados
        # los visitantes para los que hay tratamiento configurado Y que se han pasado por la página
        # con dicho tratamiento
        User.db_query("SELECT count(distinct(visitor_id))
                      FROM treated_visitors
                     WHERE ab_test_id = #{opts[:ab_test_treatment][0].id}
                       AND treatment = #{opts[:ab_test_treatment][1]}
                       AND visitor_id in (SELECT distinct(visitor_id)
                                            FROM stats.pageviews
                                           WHERE #{date_constraints(opts)}
                                             AND abtest_treatment LIKE '%\"#{opts[:ab_test_treatment][0].id}\": \"_\"%'
                                          )")[0]['count'].to_i
      end
    end
  end

  module Metrics
    class Metric
      def get_value(opts)
        # opts[:start]
        # opts[:end]
        # Si start se da end se tiene que dar, si no se dan se calcula el total
        #
        # opts[:granularity]
        # si no se da se supone que se pide un unico valor total
        # si se da puede ser: daily, weekly y se devolverá un array
        #
        # opts[:ab_test]
        # si se da se da un array [ab_test_id, treatment_num] con lo que
        # la metrica solo devolvera info restringida al tratamiento indicado
      end
    end
  end
end
