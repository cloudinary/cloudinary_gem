module Cloudinary::CloudinaryController
  protected

  def valid_cloudinary_response?
    Cloudinary::Utils.verify_api_response_signature(
      request.query_parameters.select { |key, value| [:public_id, :version].include?(key.to_sym) },
      Cloudinary.config.api_secret,
      request.query_parameters[:signature]
    )

  end
end
