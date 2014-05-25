class rtorrent::install {
	# install rtorrent
	$rtorrentpackages = [
			# Build deps
			'git',
			'subversion',
			'g++',
			'automake',
			'make',
			# libraries for libtorrent
			'libxmlrpc-c++8-dev', 
			'libtool',
			'libcppunit-dev',
			'zlib1g-dev',
			'libssl-dev',
			#'libsigc++-2.0-dev', (doesn't stop ./configure, guess it's nt needed?)
			# libraries for rtorrent
			'libncurses5-dev',
			'libcurl4-openssl-dev'
			]
	package { $rtorrentpackages:
		ensure => installed
	}
	file { '/home/rtorrent/rtorrent-build.sh':
		ensure  => present,
		owner   => 'rtorrent',
		group   => 'rtorrent',
		mode    => '0555',
		source  => 'puppet:///modules/rtorrent/rtorrent-build.sh',
		require => User['rtorrent']
	}
	exec { "build-rtorrent":
		command => "/home/rtorrent/rtorrent-build.sh",
		creates => "/usr/local/bin/rtorrent",
		require => [File['/home/rtorrent/rtorrent-build.sh'], Package[$rtorrentpackages]]
	} 
	
	

	# install and configure nginx with basic webserver
	class { 'nginx': 
		package_source => 'nginx'
	}
	nginx::resource::vhost { "quacknas-remote":
		ensure                => present,
		listen_port           => 80,
		www_root              => "/var/www",
		proxy                 => undef,
		location_cfg_append   => undef,
		index_files           => [ 'index.php', 'index.html' ],
	}
	file { "/etc/nginx/conf.d/default.conf":
		ensure => purged
	}

	
	# install php5
	include php
	class { ['php::fpm', 'php::cli']:
	}
	nginx::resource::location { "quacknas-remote_php":
		ensure          => present,
		vhost           => "quacknas-remote",
		location        => '~ \.php$',
		index_files     => ['index.php', 'index.html', 'index.htm'],
		proxy           => undef,
		fastcgi         => "unix:/var/run/php5-fpm.sock",
		fastcgi_script  => undef,
		location_cfg_append => {
			fastcgi_connect_timeout => '3m',
			fastcgi_read_timeout    => '3m',
			fastcgi_send_timeout    => '3m'
		}
    }
}