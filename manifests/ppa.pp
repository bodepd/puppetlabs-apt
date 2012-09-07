# ppa.pp

define apt::ppa(
  $release = $::lsbdistcodename,
  $https_proxy = ''
) {
  include apt::params
  include apt::update

  $sources_list_d = $apt::params::sources_list_d

  if ! $release {
    fail('lsbdistcodename fact not available: release parameter required')
  }

  $filename_without_slashes = regsubst($name, '/', '-', G)
  $filename_without_dots    = regsubst($filename_without_slashes, '\.', '_', G)
  $filename_without_ppa     = regsubst($filename_without_dots, '^ppa:', '', G)
  $sources_list_d_filename  = "${filename_without_ppa}-${release}.list"

  if ! defined(Package['python-software-properties']) {
    package { 'python-software-properties': }
  }

  if($https_proxy != '') {
      $command = "env https_proxy='${https_proxy}' /usr/bin/add-apt-repository ${name}"
  } else {
      $command = "/usr/bin/add-apt-repository ${name}"
  }

  exec { "add-apt-repository-${name}":
    command   => $command,
    creates   => "${sources_list_d}/${sources_list_d_filename}",
    logoutput => 'on_failure',
    require   => [ File[$sources_list_d],
                   Package['python-software-properties'] ],
    notify    => Exec['apt_update'],
  }

  file { "${sources_list_d}/${sources_list_d_filename}":
    ensure  => file,
    require => Exec["add-apt-repository-${name}"],
  }

  # Need anchor to provide containment for dependencies.
  anchor { "apt::ppa::${name}":
    require => Class['apt::update'],
  }
}

