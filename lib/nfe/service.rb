module NFe
	class Service
		METHODS = {
      nfe_status_servico_nf2: "NfeStatusServico2",
      nfe_autorizacao_lote: "NfeAutorizacao",
			nfe_consulta_lote: "NfeRetAutorizacao"
    }

    def self.status_servico
    	data = {
	      consStatServ: {
	        :@xmlns => "http://www.portalfiscal.inf.br/nfe",
	        :@versao => NFe.configuration.versao,
	        tpAmb: NFe.configuration.tpAmb,
	        cUF: NFe.configuration.cUF,
	        xServ: "STATUS",
	      },
	    }
      self.request(:nfe_status_servico_nf2, data)
    end

    def self.autorizacao(data)
    	message = sign_nfe(data)
    	request_response = request(:nfe_autorizacao_lote, message)

    	if (request_response.body[:nfe_autorizacao_lote_result])
    		resp = {
    			:requestResponse 					=> request_response,
    			:nfeAutorizacaoLoteResult => request_response.body[:nfe_autorizacao_lote_result],
    			:cStat 										=> request_response.body[:nfe_autorizacao_lote_result][:ret_envi_n_fe][:c_stat],
    			:xMotivo 									=> request_response.body[:nfe_autorizacao_lote_result][:ret_envi_n_fe][:x_motivo],
    			:nfeProc 									=> nfe_proc(message, request_response.body[:nfe_autorizacao_lote_result][:ret_envi_n_fe][:prot_n_fe]),
    		}
    	else
    		resp = {
    			:requestResponse 	=> nil,
    			:cStat 						=> nil,
    			:xMotivo 					=> nil,
    			:nfeProc 					=> nil,
    		}
    	end
    	resp
    end

		def self.consulta_nfe(data)
			message = Nokogiri::XML(data.to_s, &:noblanks)
			message.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
			request_response = request(:nfe_consulta_lote, message)
		end

    def self.calcula_dv(chave43)
	    multiplicadores = %w(2 3 4 5 6 7 8 9)
	    i = 42
	    soma_ponderada = 0
	    while (i >= 0) do
	      (0..7).each do |m|
	        if i >= 0
	          soma_ponderada += chave43[i].to_i * multiplicadores[m].to_i
	          i -= 1
	        end
	      end
	    end
	    resto = (soma_ponderada % 11).to_i
	    if (resto == 0 || resto == 1)
	        return 0
	    else
	        return (11 - resto)
	    end
	  end


    private

    def self.request(operation, message)
    	nfe_service = NFe::WebService.new NFe.configuration.wdsl_url(operation)
      nfe_service.call operation, header(operation), message
    rescue Savon::Error
    end

    def self.header(operation)
      {
        "nfeCabecMsg" => {
          :@xmlns => "http://www.portalfiscal.inf.br/nfe/wsdl/#{METHODS[operation]}",
          "cUF" => NFe.configuration.cUF,
          "versaoDados" => NFe.configuration.versao
        },
      }
  	end

  	def self.certificado
    	OpenSSL::PKCS12.new(File.read(NFe.configuration.pfx_path), NFe.configuration.cert_passwd)
    end

    def self.nfe_proc(message, prot_nfe)
    	if prot_nfe
	    	xml_nfe = Nokogiri::XML(message.to_s, &:noblanks).xpath("//xmlns:NFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)

	    	final = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
				<nfeProc versao=\"3.10\" xmlns=\"http://www.portalfiscal.inf.br/nfe\">
					#{xml_nfe}
					<protNFe versao=\"3.10\">
						<infProt>
							<tpAmb>#{prot_nfe[:inf_prot][:tp_amb]}</tpAmb>
							<verAplic>#{prot_nfe[:inf_prot][:ver_aplic]}</verAplic>
							<chNFe>#{prot_nfe[:inf_prot][:ch_n_fe]}</chNFe>
							<dhRecbto>#{prot_nfe[:inf_prot][:dh_recbto].strftime("%FT%T%:z")}</dhRecbto>
							<nProt>#{prot_nfe[:inf_prot][:n_prot]}</nProt>
							<digVal>#{prot_nfe[:inf_prot][:dig_val]}</digVal>
							<cStat>#{prot_nfe[:inf_prot][:c_stat]}</cStat>
							<xMotivo>#{prot_nfe[:inf_prot][:x_motivo]}</xMotivo>
						</infProt>
					</protNFe>
				</nfeProc>"

				resp = Nokogiri::XML(final.to_s, &:noblanks)
				resp.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
			else
				nil
			end
    end

  	def self.sign_nfe(xml)
  		xml = Nokogiri::XML(xml.to_s, &:noblanks)

  		chave43 = (xml.search('cUF').text.rjust(2, "0"))+
  							(xml.search('dhEmi').text[2..6].gsub! "-", "")+
  							(xml.search('CNPJ').text.rjust(14, "0"))+
  							(xml.search('mod').text.rjust(2, "0"))+
  							(xml.search('serie').text.rjust(3, "0"))+
  							(xml.search('nNF').text.rjust(9, "0"))+
  							(xml.search('tpEmis').text)+
  							(xml.search('cNF').text.rjust(8, "0"))

      cDV = self.calcula_dv(chave43)
      chave_acesso = "NFe#{chave43}#{cDV}"
      xml.search('cDV').first.inner_html = cDV.to_s
      xml.css("infNFe").first.attribute("Id").value = chave_acesso.to_s

	    xml_canon = xml.xpath("//xmlns:infNFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	    xml_digest = Base64.encode64(OpenSSL::Digest::SHA1.digest(xml_canon)).strip
	    signature = Nokogiri::XML::Node.new('Signature', xml)
	    signature.default_namespace = 'http://www.w3.org/2000/09/xmldsig#'
	    xml.xpath("//xmlns:NFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.add_child(signature)
	    signature_info = Nokogiri::XML::Node.new('SignedInfo', xml)
	    child_node = Nokogiri::XML::Node.new('CanonicalizationMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
	    signature_info.add_child child_node
	    child_node = Nokogiri::XML::Node.new('SignatureMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'
	    signature_info.add_child child_node
	    reference = Nokogiri::XML::Node.new('Reference', xml)
	    reference['URI'] = "##{chave_acesso.to_s}"
	    transforms = Nokogiri::XML::Node.new('Transforms', xml)
	    child_node  = Nokogiri::XML::Node.new('Transform', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature'
	    transforms.add_child child_node
	    child_node  = Nokogiri::XML::Node.new('Transform', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'
	    transforms.add_child child_node
	    reference.add_child transforms
	    child_node  = Nokogiri::XML::Node.new('DigestMethod', xml)
	    child_node['Algorithm'] = 'http://www.w3.org/2000/09/xmldsig#sha1'
	    reference.add_child child_node
	    child_node  = Nokogiri::XML::Node.new('DigestValue', xml)
	    child_node.content = xml_digest
	    reference.add_child child_node
	    signature_info.add_child reference
	    signature.add_child signature_info
	    sign_canon = signature_info.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	    signature_hash = certificado.key.sign(OpenSSL::Digest::SHA1.new, sign_canon)
	    signature_value = Base64.encode64( signature_hash ).gsub("\n", '')
	    child_node = Nokogiri::XML::Node.new('SignatureValue', xml)
	    child_node.content = signature_value
	    signature.add_child child_node
	    key_info = Nokogiri::XML::Node.new('KeyInfo', xml)
	    x509_data = Nokogiri::XML::Node.new('X509Data', xml)
	    x509_certificate = Nokogiri::XML::Node.new('X509Certificate', xml)
	    x509_certificate.content = certificado.certificate.to_s.gsub(/\-\-\-\-\-[A-Z]+ CERTIFICATE\-\-\-\-\-/, "").gsub(/\n/,"")
	    x509_data.add_child x509_certificate
	    key_info.add_child x509_data
	    signature.add_child key_info
	    xml.xpath("//xmlns:NFe", "xmlns" => "http://www.portalfiscal.inf.br/nfe").first.add_child signature
	    xml.canonicalize(Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0)
	  end

	end
end
