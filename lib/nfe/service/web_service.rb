#coding: utf-8
require 'savon'
require 'httpclient'

module NFe

  module Service

    class WebService

      def initialize(wsdl_url, cert_path, key_path, ca_path)
        # instantiate the certificate to sign the message
        certs = Akami::WSSE::Certs.new(:cert_file => cert_path, :private_key_file => key_path)

        # create a client for the service
        @client = Savon.client(
          :wsdl => wsdl_url,
          :namespace => "http://www.w3.org/2003/05/soap-envelope",
          :element_form_default => :unqualified,
          :env_namespace => :soap,
          :namespace_identifier => :nfe,
          :soap_version => 2,
          :encoding => "UTF-8",
          :wsse_signature => (Akami::WSSE::Signature.new certs),
          :ssl_cert_file => cert_path,
          :ssl_cert_key_file => key_path,
          :ssl_ca_cert_file => ca_path,
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

    end

  end

end
