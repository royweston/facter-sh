# Facter-sh

Tested on: CentOS 5.9 (x86_64), Ubuntu 12.04 (i686) Desktop


## About

Facter-sh is an abbreviated implementation of the [Puppet Labs Inc](https://puppetlabs.com/)
[Facter](https://github.com/puppetlabs/facter) for use within a Bourne Shell.
    
The original impetus for creating this project was for use with [vagrant](http://www.vagrantup.com/)
boxes using a shell provisioner. This enables the detection of the shell environment
at runtime helping the script writer make provisions in their script for
differences between the environments.

## Usage

It is intended the script be imported in to the script writers main script. To
display all the facts to the terminal, use the function:
  
    facter_display_all
  
To initialise all the facts, use the function:

    facter

The following *readonly* variables are made available to the importing script:
  
* `kernel`
* `kernelmajrelease`
* `kernelrelease`
* `kernelversion`
* `hardwareisa`
* `hardwaremodel`
* `operatingsystem`
* `operatingsystemmajrelease`
* `operatingsystemrelease`
* `osfamily`
* `architecture`
* `fqdn`
* `hostname`
* `domain`
* `id`

Unlike Puppet Facter, the values for `$kernel`, `$operatingsystem` and `$osfamily`
are returned in lowercase.

For details of each facts meaning, please refer to the [Puppet Labs Documentation](http://docs.puppetlabs.com/)

## License

Read the [LICENSE](LICENSE) file.
