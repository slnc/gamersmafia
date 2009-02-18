class CompetitionsLogsEntry < LogsEntry
  belongs_to :competition

  validates_presence_of :competition_id
end
