$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + "/lib/"
require "sfn/version"
Gem::Specification.new do |s|
  s.name = "sfn"
  s.version = Sfn::VERSION.version
  s.summary = "SparkleFormation CLI"
  s.author = "Chris Roberts"
  s.email = "code@chrisroberts.org"
  s.homepage = "http://github.com/sparkleformation/sfn"
  s.description = "SparkleFormation CLI"
  s.license = "Apache-2.0"
  s.require_path = "lib"
  s.add_runtime_dependency "bogo-cli", ">= 0.2.5", "< 0.4"
  s.add_runtime_dependency "bogo-ui", ">= 0.1.28", "< 0.4"
  s.add_runtime_dependency "miasma", ">= 0.3.3", "< 0.4"
  s.add_runtime_dependency "miasma-aws", ">= 0.3.15", "< 0.4"
  s.add_runtime_dependency "miasma-azure", ">= 0.1.0", "< 0.3"
  s.add_runtime_dependency "miasma-open-stack", ">= 0.1.0", "< 0.3"
  s.add_runtime_dependency "miasma-rackspace", ">= 0.1.0", "< 0.3"
  s.add_runtime_dependency "miasma-google", ">= 0.1.0", "< 0.3"
  s.add_runtime_dependency "miasma-terraform", ">= 0.1.0", "< 0.2.0"
  s.add_runtime_dependency "jmespath"
  s.add_runtime_dependency "net-ssh"
  s.add_runtime_dependency "sparkle_formation", ">= 3.0.35", "< 4"
  s.add_runtime_dependency "hashdiff", "~> 0.2.2"
  s.add_runtime_dependency "graph", "~> 2.8.1"
  s.add_development_dependency "rake", "~> 10"
  s.add_development_dependency "minitest"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "rufo", "~> 0.3.0"
  s.add_development_dependency "mocha"
  s.add_development_dependency "yard"
  s.executables << "sfn"
  s.files = Dir["{lib,bin,docs}/**/*"] + %w(sfn.gemspec README.md CHANGELOG.md LICENSE)
end
