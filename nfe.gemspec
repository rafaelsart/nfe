# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "nfe"
  s.version     = "1.0.0"
  s.date        = '2015-05-05'
  s.authors     = ["Lucas Silvestre"]
  s.email       = ["lukas.silvestre@gmail.com"]
  s.homepage    = "https://github.com/Moobile/nfe"
  s.summary     = "Gem para envio de NF-e"
  s.description = "Nota Fiscal Eletrônica"
  s.files       = ["lib/nfe.rb"]

  s.add_runtime_dependency 'savon', '~> 2.11', '>= 2.11.0'
  s.add_runtime_dependency 'httpclient'
end