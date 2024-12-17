# frozen_string_literal: true

require "forwardable"

module Pgchief
  class Config
    # Class to store s3 configuration settings
    class S3
      extend Forwardable

      def_delegators \
        :config,
        :s3_key,
        :s3_secret,
        :s3_region,
        :s3_objects_path

      PREFIX_REGEX = %r{\As3://(?<bucket>(\w|-)*)/(?<path>(\w|/)*/)\z}

      attr_reader :config

      def initialize(config)
        @config = config
      end

      def client
        @client ||= Aws::S3::Client.new(
          access_key_id: s3_key,
          secret_access_key: s3_secret,
          region: s3_region
        )
      end

      def bucket
        s3_match[:bucket]
      end

      def path
        s3_match[:path]
      end

      def configured?
        [
          s3_key,
          s3_secret,
          s3_region,
          s3_objects_path
        ].none?(&:nil?)
      end

      private

      def s3_match
        @s3_match ||= s3_objects_path.match(PREFIX_REGEX)
      end
    end
  end
end
