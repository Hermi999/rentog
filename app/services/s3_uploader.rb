# This implementation is based on:
# http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-UsingHTTPPOST.html
class S3Uploader

  def initialize()
    @aws_access_key_id      = APP_CONFIG.AWS_ACCESS_KEY_ID
    @aws_secret_access_key  = APP_CONFIG.aws_secret_access_key
    @bucket                 = APP_CONFIG.s3_upload_bucket_name
    @region                 = APP_CONFIG.FOG_REGION
    @expiration             = 10.hours.from_now
    @acl                    = "public-read"
    @service                = 's3'
    @s3_signature_version   = 'v4'
    @algorithm              = 'AWS4-HMAC-SHA256'
    @request_type           = 'aws4_request'
  end

  def fields
    {
      :key => key,
      :acl => @acl,
      :success_action_status => 200,
      :policy => encoded_policy,
      "x-amz-algorithm" => @algorithm,
      "x-amz-credential" => credentials,
      "x-amz-date" => url_friendly_time_with_seconds,
      "x-amz-expires" => @expiration.utc.iso8601,
      "x-amz-signature" => signature
    }
  end

  def policy_data
    { expiration: @expiration.utc.iso8601,
      conditions: [
        {"bucket" => @bucket},
        {"acl" => @acl},
        ["starts-with", "$key", "uploads/listing-images/"],
        ["starts-with", "$Content-Type", "image/"],
        ["starts-with", "$success_action_status", "200"],
        ["content-length-range", 0, APP_CONFIG.max_image_filesize],
        {"x-amz-credential" => credentials},
        {"x-amz-algorithm" => @algorithm},
        {"x-amz-date" => url_friendly_time_with_seconds},
        {"x-amz-expires" => @expiration.utc.iso8601}
      ]
    }
  end

  def encoded_policy
    Base64.encode64(policy_data.to_json).gsub("\n", "")
  end

  def getSignatureKey key, dateStamp, regionName, serviceName
    kDate    = OpenSSL::HMAC.digest('sha256', "AWS4" + key, dateStamp)
    kRegion  = OpenSSL::HMAC.digest('sha256', kDate, regionName)
    kService = OpenSSL::HMAC.digest('sha256', kRegion, serviceName)
    kSigning = OpenSSL::HMAC.digest('sha256', kService, "aws4_request")

    kSigning
  end

  def signature
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'),
                            getSignatureKey(@aws_secret_access_key,
                                            short_date,
                                            @region,
                                            @service),
                            encoded_policy
    )
  end

  def url
    "https://#{@bucket}.s3.#{@region}.amazonaws.com/"
  end

  private

  def url_friendly_time
    Time.now.utc.strftime("%Y%m%dT%H%MZ")
  end

  def url_friendly_time_with_seconds
    Time.now.utc.strftime("%Y%m%dT%H%M%SZ")
  end

  def year
    Time.now.year
  end

  def month
    '%02d' % Time.now.month
  end

  def day
    '%02d' % Time.now.day
  end

  def short_date
    "#{year}#{month}#{day}"
  end

  def key
    "uploads/listing-images/#{year}/#{month}/#{url_friendly_time}-#{SecureRandom.hex}/${index}/${filename}"
  end

  def credentials
    "#{@aws_access_key_id}/#{short_date}/#{@region}/#{@service}/#{@request_type}"
  end
end
