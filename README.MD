= NF-e
Nota Fiscal Eletrônica

Adicione suas configurações ao arquivo `config/initializers/nfe.rb`.

```ruby
NFe.configure do |config|
  config.cert_path 		= "YOUR_CERT_PATH"
  config.key_path 		= "YOUR_KEY_PATH"
  config.ca_path 		= "YOUR_CA_PATH"
  config.pfx_path 		= "YOUR_PFX_PATH"
  config.cert_passwd	= "YOUR_CERT_PASSWORD"
  config.versao 		= "3.10"
end
```