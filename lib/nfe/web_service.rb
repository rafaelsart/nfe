#coding: utf-8
require 'savon'
require 'httpclient'

module NFe

  class WebService
    def initialize(wsdl)
      @wsdl_url = wsdl
      @cert_path = NFe.configuration.cert_path
      @key_path = NFe.configuration.key_path
      @ca_path = NFe.configuration.ca_path

      # create a client for the service
      @client = Savon.client(
        :wsdl => @wsdl_url,
        :namespace => "http://www.w3.org/2003/05/soap-envelope",
        :element_form_default => :unqualified,
        :env_namespace => :soap,
        :namespace_identifier => :nfe,
        :soap_version => 2,
        :encoding => "UTF-8",
        :wsse_signature => (Akami::WSSE::Signature.new certificate),
        :ssl_cert_file => @cert_path,
        :ssl_cert_key_file => @key_path,
        :ssl_ca_cert_file => @ca_path,
        :ssl_verify_mode => :peer,
        :ssl_version => :SSLv3,
        :pretty_print_xml => true,
        :log => true,
        :log_level => :debug,
        :filters => [:BinarySecurityToken]
      )
    end

    def operations
      @client.operations
    end

    def call(operation, header, message)
      message = Nokogiri::XML(message.to_s, &:noblanks).canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)

      response = @client.call(operation, 
        soap_action: operation,
        soap_header: header,
        message: message
      )
    end


    private

      def certificate
        # instantiate the certificate to sign the message
        Akami::WSSE::Certs.new(:cert_file => @cert_path, :private_key_file => @key_path)
      end

  end

end
