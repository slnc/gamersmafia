class CodeStatistics
  TEST_TYPES = %w(Units Functionals Unit\ tests Functional\ tests Integration\ tests)
end
require 'code_statistics'
STATS_DIRECTORIES = [
  %w(Controllers        app/controllers),
  %w(Helpers            app/helpers),
  %w(Models             app/models),
  %w(Libraries          lib/),
  %w(Scripts            script),
  %w(Integration\ tests test/integration),
  %w(Functional\ tests  test/functional),
  %w(Library\ tests     test/lib),
  %w(Unit\ tests        test/unit)
]