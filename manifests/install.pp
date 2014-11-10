# == Define: ssl_certificate::install
#
# Puppet define to install SSL certificates and keys.
#
# === Parameters
#
# [*cert*]
#   Filename of certificate to distribute.
#   Defaults to define name with ".crt" extension.
#
# [*key*]
#   Filename of key to distribute.
#   Defaults to define name with ".key" extension.
#
# [*intermediate*]
#   Filename of intermediate certificate to distribute.
#   Defaults to define name with ".intermediate.crt" extension.
#
# [*ca*]
#   Filename of CA certificate to distribute.
#   Defaults to define name with ".ca.crt" extension.
#
# [*install_cert*]
#   Whether to install the certificate.
#   Defaults to 'true'
#
# [*install_key*]
#   Defaults to 'true'
#
# [*install_intermediate*]
#   Defaults to 'false'
#
# [*install_ca*]
#   Defaults to 'false'
#
define ssl_certificate::install (
  $cert                 = "${name}.crt",
  $key                  = "${name}.key",
  $intermediate         = "${name}.intermediate.crt",
  $ca                   = "${name}.ca.crt",
  $cert_dir             = undef,
  $key_dir              = undef,
  $intermediate_dir     = undef,
  $ca_dir               = undef,
  $install_cert         = true,
  $install_key          = true,
  $install_intermediate = false,
  $install_ca           = false,
) {

  include ssl_certificate::params

  validate_bool($install_cert, $install_key, $install_ca, $install_intermediate)

  # set directories that certifiates will be installed to.
  $real_cert_dir = $cert_dir ? {
    undef   => $ssl_certificate::params::cert_dir,
    default => $cert_dir
  }

  $real_key_dir = $key_dir ? {
    undef   => $ssl_certificate::params::key_dir,
    default => $key_dir
  }

  $real_intermediate_dir = $ca_dir ? {
    undef   => $ssl_certificate::params::ca_dir,
    default => $ca_dir
  }

  $real_ca_dir = $ca_dir ? {
    undef   => $ssl_certificate::params::ca_dir,
    default => $ca_dir
  }

  # set file ensure
  $cert_ensure = $install_cert ? {
    true    => present,
    default => absent,
  }

  $key_ensure = $install_key ? {
    true    => present,
    default => absent,
  }

  $intermediate_ensure = $install_intermediate ? {
    true    => present,
    default => absent,
  }

  $ca_ensure = $install_ca ? {
    true    => present,
    default => absent,
  }

  File {
    owner => 'root',
    group => 'root',
    mode  =>  0600,
  }

  file { "${real_cert_dir}/${cert}":,
    ensure => $cert_ensure,
    source => "puppet:///ssl_certificates/${name}/${cert}",
  }

  file { "${real_key_dir}/${key}":
    ensure => $key_ensure,
    source => "puppet:///ssl_certificates/${name}/${key}",
  }

  file { "${real_intermediate_dir}/${intermediate}":
    ensure => $intermediate_ensure,
    source => "puppet:///ssl_certificates/${name}/${intermediate}",
  }

  file { "${real_ca_dir}/${ca}":
    ensure => $ca_ensure,
    source => "puppet:///ssl_certificates/${name}/${ca}",
  }

  if $::osfamily == 'Debian' {
    Exec {
      path        => '/usr/sbin',
      refreshonly => true,
    }

    exec { 'dpkg-reconfigure ca-certificates':
      subscribe => [File["${real_ca_dir}/${ca}"], File["${real_ca_dir}/${intermediate}"]],
      before    => Exec['update-ca-certificates'],
    }

    exec { 'update-ca-certificates':
      subscribe => [File["${real_ca_dir}/${ca}"], File["${real_ca_dir}/${intermediate}"]],
    }
  }
}
