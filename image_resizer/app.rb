require 'aws-sdk'
require 'mini_magick'

def lambda_handler(event:, context:)
  key = 'originals/input.jpg'
  s3 = Aws::S3::Client.new

  response = s3.get_object(bucket: ENV['AWS_PROTO_BUCKET'], key: key)
  image = MiniMagick::Image.read(response.body.read)
  image.combine_options do |img|
    img.resize '100x100>'
    img.flip
    image.format 'png'
  end
  output_key = "resized/input_#{Time.now.to_i}.png"
  s3.put_object(bucket: ENV['AWS_PROTO_BUCKET'], key: output_key, body: File.read(image.tempfile))

  {
    statusCode: 200,
    body: {
      message: "Uploaded to #{output_key}"
    }.to_json
  }
end
