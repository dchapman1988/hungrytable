require 'ansi'

module MiniTest
  module Reporters
    # A reporter identical to the standard MiniTest reporter.
    # 
    # Based upon Ryan Davis of Seattle.rb's MiniTest (MIT License).
    # 
    # @see https://github.com/seattlerb/minitest MiniTest
    class JUnitReporter
      include MiniTest::Reporter

      def before_suites(suites, type)
      end

      def before_test(suite, test)
      end

      def pass(suite, test, test_runner)
      end

      def skip(suite, test, test_runner)
      end

      def failure(suite, test, test_runner)
      end

      def error(suite, test, test_runner)
      end

      def after_suites(suites, type)
        time = Time.now - runner.start_time
        i = 0
        runner.report.each do |suite, tests|
          File.open("#{suite.to_s.gsub(" ", '_').downcase}.xml", 'w') do |out|
            out.puts '<?xml version="1.0" encoding="UTF-8" ?>'
            out.puts "<testsuite errors=\"#{runner.errors}\" failures=\"#{runner.failures}\" tests=\"#{runner.test_count}\" time=\"#{time}\" timestamp=\"#{runner.start_time.strftime('%FT%R')}\">"
            tests.each do |test, test_runner|
              out.print "<testcase classname=\"#{suite}\" name=\"#{test}\" time=\"0\">"
              message = message_for(test_runner)
              out.puts "\n#{message}" if message
              out.puts '</testcase>'
            end
            out.puts '</testsuite>'
          end
        end
      end

      private
      def location(exception)
        last_before_assertion = ''

        exception.backtrace.reverse_each do |s|
          break if s =~ /in .(assert|refute|flunk|pass|fail|raise|must|wont)/
          last_before_assertion = s
        end

        last_before_assertion.sub(/:in .*$/, '')
      end

      def message_for(test_runner)
        suite = test_runner.suite
        test = test_runner.test
        e = test_runner.exception

        case test_runner.result
        when :pass then nil
        when :skip then "<skipped message=\"\"/>"
        when :failure then "<failure message=\"#{e.message}\" type=\"failure\">#{location(e)}:\n#{e.message}\n</failure>"
        when :error then "<error message=\"#{e.message}\" type=\"error\">#{location(e)}:\n#{e.message}\n</error>"
        end
      end

      def status
        '%d tests, %d assertions, %d failures, %d errors, %d skips' %
          [runner.test_count, runner.assertion_count, runner.failures, runner.errors, runner.skips]
      end
    end
  end
end

