# http://www.jvoorhis.com/pages/calendar-helper
# CalendarHelper allows you to draw a databound calendar with fine-grained CSS formatting
#
# Screw the license.

module CalendarHelper
  # Returns an HTML calendar. In its simplest form, this method generates a plain
  # calendar (which can then be customized using CSS) for a given month and year.
  # However, this may be customized in a variety of ways -- changing the default CSS
  # classes, generating the individual day entries yourself, and so on.
  #
  # The following options are required:
  #  :year  # The  year number to show the calendar for.
  #  :month # The month number to show the calendar for.
  #
  # The following are optional, available for customizing the default behaviour:
  #   :table_class       => "calendar"        # The class for the <table> tag.
  #   :month_name_class  => "monthName"       # The class for the name of the month, at the top of the table.
  #   :other_month_class => "otherMonthClass" # Not implemented yet.
  #   :day_name_class    => "dayName"         # The class is for the names of the weekdays, at the top.
  #   :day_class         => "day"             # The class for the individual day number cells.
  #                                             This may or may not be used if you specify a block (see below).
  #   :abbrev            => (0..2)            # This option specifies how the day names should be abbreviated.
  #                                             Use (0..2) for the first three letters, (0..0) for the first, and
  #                                             (0..-1) for the entire name.
  #
  # For more customization, you can pass a code block to this method, that will get one argument, a Date object,
  # and return a values for the individual table cells. The block can return an array, [cell_text, cell_attrs],
  # cell_text being the text that is displayed and cell_attrs a hash containing the attributes for the <td> tag
  # (this can be used to change the <td>'s class for customization with CSS).
  # This block can also return the cell_text only, in which case the <td>'s class defaults to the value given in
  # +:day_class+. If the block returns nil, the default options are used.
  #
  # Example usage:
  #   calendar(:year => 2005, :month => 6) # This generates the simplest possible calendar.
  #   calendar({:year => 2005, :month => 6, :table_class => "calendar_helper"}) # This generates a calendar, as
  #                                                                             # before, but the <table>'s class
  #                                                                             # is set to "calendar_helper".
  #   calendar(:year => 2005, :month => 6, :abbrev => (0..-1)) # This generates a simple calendar but shows the
  #                                                            # entire day name ("Sunday", "Monday", etc.) instead
  #                                                            # of only the first three letters.
  #   calendar(:year => 2005, :month => 5) do |d| # This generates a simple calendar, but gives special days
  #     if listOfSpecialDays.include?(d)          # (days that are in the array listOfSpecialDays) one CSS class,
  #       [d.mday, {:class => "specialDay"}]      # "specialDay", and gives the rest of the days another CSS class,
  #     else                                      # "normalDay". You can also use this highlight today differently
  #       [d.mday, {:class => "normalDay"}]       # from the rest of the days, etc.
  #   end
  def calendar(options = {}, &block)
    raise ArgumentError, "No year given"  unless defined? options[:year]
    raise ArgumentError, "No month given" unless defined? options[:month]

    block                        ||= Proc.new {|d| nil}
    options[:table_class       ] ||= "calendar"
    options[:month_name_class  ] ||= "monthName"
    options[:other_month_class ] ||= "otherMonth"
    options[:day_name_class    ] ||= "dayName"
    options[:day_class         ] ||= "day"
    options[:abbrev            ] ||= (0..2)

    first = Date.civil(options[:year], options[:month], 1)
    last = Date.civil(options[:year], options[:month], -1)

    cal = <<EOF
<table class="#{options[:table_class]}">
EOF
    #
	#<thead>
	#	<tr class="#{options[:month_name_class]}">
	#		<th colspan="7">#{Date::MONTHNAMES[options[:month]]}</th>
	#	</tr>
	#	<tr class="#{options[:day_name_class]}">
#EOF
#    Date::ABBR_DAYSNAMES.each {|d| cal << "			<th>#{d[options[:abbrev]]}</th>"}
#    cal << "		</tr>
    cal << "
	</thead>
	<tbody>
		<tr>"
    1.upto((first.wday == 0) ? 6 : first.wday - 1) {|d| cal << "<td class='#{options[:other_month_class]}'></td>"} unless first.wday == 1
    first.upto(last) do |cur|
      cell_text, cell_attrs = block.call(cur)
      cell_text  ||= cur.mday
      cell_attrs ||= {:class => options[:day_class]}
      cell_attrs = cell_attrs.map {|k, v| "#{k}='#{v}'"}.join(' ')
      cal << "<td #{cell_attrs}>#{cell_text}</td> "
      cal << "</tr>\n		<tr>" if cur.wday == 0
    end
    last.wday.upto(5) {|d| cal << "			<td class='#{options[:other_month_class]}'></td>"} unless last.wday == 6
    cal << "		</tr>\n	</tbody>\n</table>"
  end
end

