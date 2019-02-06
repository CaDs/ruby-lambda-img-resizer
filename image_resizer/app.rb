# frozen_string_literal: true

require 'aws-sdk'
require 'mini_magick'
require 'logger'

def lambda_handler(event:, context:)
  res = event['Records'].map do |record|
    key = record.dig('s3', 'object', 'key')
    next unless key

    process_key(key)
  end.compact

  {
    statusCode: 200,
    body: {
      message: res,
    }.to_json,
  }
end

def process_key(key)
  logger.info "Processing KEY: #{key}"

  s3 = Aws::S3::Client.new
  binary = s3.get_object(bucket: ENV['ORIGINAL_IMAGES_BUCKET'], key: key)&.body&.read
  return unless binary

  image = MiniMagick::Image.read(binary)
  image.combine_options do |img|
    img.resize '100x100>'
    img.flip
    image.format 'png'
  end

  s3.put_object(bucket: ENV['RESIZED_IMAGES_BUCKET'], key: key, body: File.read(image.tempfile))

  key
rescue Aws::S3::Errors::NoSuchKey
  logger.error("KEY: #{key} not found")
  nil
end

private

def logger
  @logger ||= Logger.new(STDOUT)
end
