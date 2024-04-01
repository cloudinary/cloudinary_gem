# frozen_string_literal: true

module Cloudinary
  module Analytics
    extend self

    QUERY_KEY    = '_a'
    ALGO_VERSION = 'B' # The version of the algorithm
    SDK_CODE     = 'C' # Cloudinary Ruby SDK

    @product      = 'A' # Official SDK. Set to 'B' for integrations.
    @sdk_code     = SDK_CODE
    @sdk_version  = Cloudinary::VERSION
    @tech_version = "#{RUBY_VERSION[/\d+\.\d+/]}"

    CHARS           = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    BINARY_PAD_SIZE = 6

    @char_codes = nil
    @signature  = nil

    # Gets the SDK analytics signature query parameter.
    #
    # @return [String] The SDK signature query parameter.
    def sdk_analytics_query_param
      "#{QUERY_KEY}=#{self.sdk_analytics_signature}"
    end

    # Gets the SDK signature by encoding the SDK version and tech version.
    #
    # @return [String] The SDK signature.
    def sdk_analytics_signature
      return @signature unless @signature.nil?

      begin
        @signature = ALGO_VERSION + @product + @sdk_code + encode_version(@sdk_version) + encode_version(@tech_version)
      rescue RangeError
        @signature = 'E'
      end

      @signature
    end

    # Sets the product code.
    #
    # Used for integrations.
    #
    # @param [String] product The product code to set. 'A' is for the official SDK. 'B' for integrations.
    #
    # @return [void]
    #
    # @internal
    def product(product)
      @product = product
    end

    # Sets the SDK code.
    #
    # Used for integrations.
    #
    # @param [String] sdk_code The SDK code to set.
    #
    # @return [void]
    #
    # @internal
    def sdk_code(sdk_code)
      @sdk_code = sdk_code
    end

    # Sets the SDK version.
    #
    # Used for integrations.
    #
    # @param [String] sdk_version The SDK version to set (MAJOR.MINOR.PATCH), for example: "1.0.0".
    #
    # @return [void]
    #
    # @internal
    def sdk_version(sdk_version)
      @sdk_version = sdk_version
    end

    # Sets the tech version.
    #
    # Used for integrations.
    #
    # @param [String] tech_version The tech version to set (MAJOR.MINOR), for example: "1.0".
    #
    # @return [void]
    #
    # @internal
    def tech_version(tech_version)
      @tech_version = tech_version.split('.').first(2).join('.')
    end

    # Encodes a semVer-like version string.
    #
    # Example:
    #  input:      '1.24.0'
    #  explode:    ['1','24','0']
    #  pad:        ['01','24','00']
    #  reverse:    ['00', '24', '01']
    #  implode:    '002401'
    #  int:        2401
    #  binary:     '100101100001'
    #  padded:     '000000100101100001'
    #  str_split:  ['000000', '100101', '100001']
    #  getKey:     ['A', 'l', 'h']
    #  implode:    'Alh'
    #
    # @param [String] version Can be either x.y.z or x.y
    #
    # @return [String] A string built from 3 characters of the base64 table
    #
    # @raise [RangeError] when version is larger than 43.21.26
    def encode_version(version)
      parts = version.split('.')

      padded_parts  = parts.map { |part| part.rjust(2, '0') }
      number        = padded_parts.reverse.join.to_i
      padded_binary = int_to_padded_bin(number, parts.length * BINARY_PAD_SIZE)

      raise RangeError, 'Version must be smaller than 43.21.26' if padded_binary.length % BINARY_PAD_SIZE != 0

      encoded_chars = padded_binary.chars.each_slice(BINARY_PAD_SIZE).map { |slice| get_key(slice.join) }

      encoded_chars.join
    end

    # Gets the key for binary value.
    #
    # @param [String] binary_value The value.
    #
    # @return [Array, Object] The key for the binary value.
    def get_key(binary_value)
      @char_codes ||= initialize_char_codes

      @char_codes[binary_value] || ''
    end

    def initialize_char_codes
      char_codes = {}
      CHARS.chars.each_with_index { |char, idx| char_codes[int_to_padded_bin(idx, BINARY_PAD_SIZE)] = char }
      char_codes
    end

    # Converts integer to left padded binary string.
    #
    # @param [Integer] integer The input.
    # @param [Integer] pad_num  The num of padding chars.
    #
    # @return [String] The padded binary string.
    def int_to_padded_bin(integer, pad_num)
      integer.to_s(2).rjust(pad_num, '0')
    end
  end
end
