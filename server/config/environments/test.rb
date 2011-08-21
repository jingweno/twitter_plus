Server::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  config.after_initialize do
    ActiveRecord::ConnectionAdapters::ConnectionPool.class_eval do
      alias_method :old_checkout, :checkout

      def checkout
        @cached_connection ||= old_checkout
      end
    end

    require 'drb'
    DRb.start_service("druby://localhost:8000", ActiveRecord::Base)

    require 'factory_girl'

    class DRbActiveRecordInstanceFactory
      @@port_num = 9000

      def get_port_for_fixture_instance(factory_instance)
        port = create_port
        inst = Factory.create(factory_instance)
        DRb.start_service("druby://localhost:#{port}", inst)
        port
      end

      def create_port
        @@port_num += 1
      end
    end

    DRb.start_service('druby://localhost:9000', DRbActiveRecordInstanceFactory.new)
  end
end
