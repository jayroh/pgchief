# frozen_string_literal: true

module Pgchief
  module Command
    # Class to upload a file to S3
    class S3Upload
      attr_reader :local_location, :file_name, :bucket, :path

      def initialize(local_location)
        @local_location = local_location
        @file_name      = File.basename(local_location)
      end

      def upload!
        s3.client.put_object(
          bucket: s3.bucket,
          key: "#{s3.path}#{file_name}",
          body: File.open(local_location, "rb"),
          acl: "private",
          content_type: "application/octet-stream"
        )
        FileUtils.rm(local_location)
      end

      def s3_location
        "s3://#{s3.bucket}/#{s3.path}#{file_name}"
      end

      def configured?
        s3.configured?
      end

      private

      def s3
        Pgchief::Config.s3
      end
    end
  end
end
