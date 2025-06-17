module Cloudinary::CloudinaryController
  protected

  def valid_cloudinary_response?
    params = request.query_parameters.select { |key, value| [:public_id, :version, :signature].include?(key.to_sym) }.transform_keys(&:to_sym)
    
    Cloudinary::Utils.verify_api_response_signature(
      params[:public_id],
      params[:version],
      params[:signature]
    )
  end
end
