# == Class ssl_certificate::config
#
# This class is called from ssl_certificate
#
class ssl_certificate::config {

  include ssl_certificate::params

  file { $ssl_certificate::params::ca_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => 0755,
  }
}
