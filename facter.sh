# Copyright 2013 Roy Weston
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Facter-sh - An Abbreviated Host Fact Detection and Reporting 
# 
# Based on Puppet Labs Inc Facter, this is an abbreviated implementation for use
# within a Bourne Shell
#

# Uncomment the following line for debugging
#set -x 

lowercase () {
  echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

fact_kernel () {
  if [ -n "${fact_kernel_run}" ]; then
    return 0
  fi

  # $iswindows is an integer, 0 for false, 1 for true
  iswindows=`uname -s | grep -i -c -E "mswin|win32|dos|mingw|cygwin"`
  readonly iswindows
  if [ ${iswindows} -eq 1 ]; then
    kernel='windows'
  else
    kernel=`uname -s`
  fi
  kernel=`lowercase ${kernel}`
  readonly kernel

  case "${kernel}" in
    'aix')
      kernelrelease=`oslevel -s`
      ;;
    'hp-ux')
      kernelrelease=`uname -r`
      kernelrelease=${kernelrelease#??} #remove first two characters
      kernelrelease=${kernelrelease%?} #remove last character
      ;;
    *)
      kernelrelease=`uname -r`
      ;;
  esac
  readonly kernelrelease

  kernelmajrelease=`echo "${kernelrelease}" | cut -f1-2 -d'.'`
  readonly kernelmajrelease

  case "${kernel}" in
    'sunos')
      kernelversion=`uname -v`
      ;;
    *)
      kernelversion=`echo "${kernelrelease}" | cut -f1 -d'-'`
      ;;
  esac
  readonly kernelversion

  fact_kernel_run='y'
  readonly fact_kernel_run
}

fact_fqdn () {
  fqdn="${hostname}.${domain}"
  readonly fqdn
}

fact_hostname () {
  if [ -n "${fact_hostname_run}" ]; then
    return 0
  fi
  fact_kernel

  if [ ${kernel} = 'darwin' ] && [ ${kernelrelease} = 'R7' ]; then
    hostname=`/usr/sbin/scutil --get LocalHostName`
  else
    hostname=`hostname | cut -f1 -d.`
  fi
  readonly hostname
  fact_hostname_run='y'
  readonly fact_hostname_run
}

fact_domain () {
  if [ -n "${fact_domain_run}" ]; then
    return 0
  fi
  fact_kernel
  # Get the domain from various sources; the order of these
  # steps is important

  # In some OS 'hostname -f' will change the hostname to '-f'
  # We know that Solaris and HP-UX exhibit this behavior
  # On good OS, 'hostname -f' will return the FQDN which is preferable
  # Due to dangerous behavior of 'hostname -f' on old OS, we will explicitly opt-in
  # 'hostname -f' --hkenney May 9, 2012

  can_do_hostname_f=`echo ${kernel} | grep -i -c -E "linux|freebsd|darwin"`
  if [ ${can_do_hostname_f} -eq 1 ]; then
    domain=`hostname -f | cut -s -f2- -d.`
  else
    domain=`hostname | cut -s -f2- -d.`
  fi

  if [ -z ${domain} ]; then
    domain=`dnsdomainname`
  fi

  if [ -z ${domain} ] && [ -r '/etc/resolv.conf' ]; then
    domain=`grep -i -o -E "^[[:space:]]*domain[[:space:]]+([^[:space:]]+)" /etc/resolv.conf | cut -f2- -d' '`
    if  [ -z ${domain} ]; then
      domain=`grep -i -o -E "^[[:space:]]*search[[:space:]]+([^[:space:]]+)" /etc/resolv.conf | cut -f2- -d' '`
    fi
  fi

  domain=${domain%.}
  readonly domain
  fact_domain_run='y'
  readonly fact_domain_run
}

fact_hardwareisa () {
  if [ -n "${fact_hardwareisa_run}" ]; then
    return 0
  fi
  fact_kernel

  case "${kernel}" in
    'hp-ux')
      hardwareisa=`uname -m`
      ;;
    *)
      hardwareisa=`uname -p`
      ;;
  esac
  readonly hardwareisa

  fact_hardwareisa_run='y'
  readonly fact_hardwareisa_run
}

fact_hardwaremodel () {
  if [ -n "${fact_hardwaremodel_run}" ]; then
    return 0
  fi
  fact_kernel

  case "${kernel}" in
    'aix')
      hardwaremodel=`lsattr -El sys0 -a modelname | grep -i -o -E "modelname[[:space:]]([^[:space:]]+)[[:space:]]" | cut -f2 -d' '`
      ;;
    *)
      hardwaremodel=`uname -m`
      ;;
  esac
  readonly hardwaremodel

  fact_hardwaremodel_run='y'
  readonly fact_hardwaremodel_run
}

fact_lsbdistrelease () {
  if [ -n "${fact_lsbdistrelease_run}" ]; then
    return 0
  fi
  fact_kernel

  if [ "${kernel}" = "linux" ] || [ "${kernel}" = "gnu/kfreebsd" ]; then
    lsbdistrelease=`lsb_release -r -s 2>/dev/null`
  fi
  readonly lsbdistrelease

  fact_lsbdistrelease_run='y'
  readonly fact_lsbdistrelease_run
}

fact_osfamily () {
  if [ -n "${fact_osfamily_run}" ]; then
    return 0
  fi
  fact_operatingsystem

  case "${operatingsystem}" in
    `echo "${operatingsystem}" | grep -i -o -E "redhat|fedora|centos|scientific|slc|ascendos|cloudlinux|psbm|oraclelinux|ovs|oel|amazon|xenserver"`)
      osfamily="redhat"
      ;;
    `echo "${operatingsystem}" | grep -i -o -E "ubuntu|debian"`)
      osfamily="debian"
      ;;
    `echo "${operatingsystem}" | grep -i -o -E "sles|sled|opensuse|suse"`)
      osfamily="suse"
      ;;
    `echo "${operatingsystem}" | grep -i -o -E "solaris|nexenta|omnios|openindiana|smartos"`)
      osfamily="solaris"
      ;;
    'gentoo')
      osfamily="gentoo"
      ;;
    'archlinux')
      osfamily="archlinux"
      ;;
    `echo "${operatingsystem}" | grep -i -o -E "mandrake|mandriva"`)
      osfamily="mandrake"
      ;;
    *)
      fact_kernel
      osfamily="${kernel}"
      ;;
  esac
  osfamily=`lowercase ${osfamily}`
  readonly osfamily

  fact_osfamily_run='y'
  readonly fact_osfamily_run
}

fact_operatingsystemrelease () {
  if [ -n "${fact_operatingsystemrelease_run}" ]; then
    return 0
  fi
  fact_operatingsystem

  case "${operatingsystem}" in
    `echo "${operatingsystem}" | grep -i -o -E "centos|fedora|oel|ovs|oraclelinux|redhat|meego|scientific|slc|ascendos|cloudlinux|psbm"`)
      case "${operatingsystem}" in
        `echo "${operatingsystem}" | grep -i -o -E "centos|redhat|scientific|slc|ascendos|cloudlinux|psbm|xenserver"`)
          releasefile='/etc/redhat-release'
          ;;
        'fedora')
          releasefile='/etc/fedora-release'
          ;;
        'meego')
          releasefile='/etc/meego-release'
          ;;
        'oraclelinux')
          releasefile='/etc/oracle-release'
          ;;
        'oel')
          releasefile='/etc/enterprise-release'
          ;;
        'ovs')
          releasefile='/etc/ovs-release'
          ;;
      esac
      if [ -r "${releasefile}" ]; then
        if [ `grep -i -c "(rawhide)" ${releasefile}` -eq 1 ]; then 
          operatingsystemrelease='Rawhide'
        elif [ `grep -i -c -e "release [0-9][0-9.]*" ${releasefile}` -eq 1 ]; then 
          operatingsystemrelease=`grep -i -o -e "release [0-9][0-9.]*" ${releasefile} | cut -f2- -d' '`
        else
          operatingsystemrelease=`cat ${releasefile}`
        fi
      fi
      ;;
    'debian')
      if [ -r '/etc/debian_version' ]; then
        operatingsystemrelease=`cat ${releasefile} | cut -f1 -d' '`
      fi
      ;;
    'ubuntu')
      if [ -r '/etc/issue' ]; then
        # Return only the major and minor version numbers. This behavior must
        # be preserved for compatibility reasons.
        operatingsystemrelease=`grep -i -o -E "ubuntu [0-9]+.[0-9]+(\.[0-9]+)?" /etc/issue | cut -f2 -d' ' | cut -f1-2 -d'.'`
      end
      fi
      ;;
    `echo "${operatingsystem}" | grep -i -o -E "sles|sled|opensuse"`)
      if [ -r '/etc/SuSE-release' ]; then
        release=`grep -i -o -E "^VERSION[[:space:]]*=[[:space:]]*[0-9]+(\.[0-9]+)?" /etc/SuSE-release | cut -f2 -d'=' | cut -f2 -d' '`
        releasemajor=`echo "${release}" | cut -f1 -d'.'`
        releaseminor=`echo "${release}" | cut -f2 -d'.'`
        if [ -n "${releasemajor}" ]; then
          releasepatch=`grep -i -o -E "^PATCHLEVEL[[:space:]]*=[[:space:]]*[0-9]+" /etc/SuSE-release | cut -f2 -d'=' | cut -f2 -d' '`
          if [ -n "${releasepatch}" ]; then
            releaseminor="${releasepatch}"
          elif [ -z "${releaseminor}" ]; then
            releaseminor='0'
          fi
          operatingsystemrelease="${releasemajor}.${releaseminor}"
        else
          operatingsystemrelease="unknown"
        fi
      fi
      ;;
    'openwrt')
      if [ -r '/etc/openwrt_version' ]; then
        operatingsystemrelease=`grep -i -o -e "^[0-9.]*" /etc/openwrt_version`
      fi
      ;;
    'slackware')
      if [ -r '/etc/slackware-version' ]; then
        operatingsystemrelease=`grep -i -o -e "Slackware [0-9.]*" /etc/slackware-version | cut -f2 -d' '`
      fi
      ;;
    'mageia')
      if [ -r '/etc/mageia-release' ]; then
        operatingsystemrelease=`grep -i -o -e "Mageia release [0-9.]*" /etc/mageia-release | cut -f3 -d' '`
      fi
      ;;
    'bluewhite64')
      if [ -r '/etc/bluewhite64-version' ]; then
        operatingsystemrelease=`grep -i -o -E "^[[:space:]]*\w+[[:space:]]+[0-9]+\.[0-9]+" /etc/bluewhite64-version | grep -o -E "[0-9]+\.[0-9]+"`
        if [ -z "${operatingsystemrelease}" ]; then
          operatingsystemrelease="unknown"
        fi
      fi
      ;;
    'vmwareesx')
      operatingsystemrelease=`vmware -v | grep -i -o -E "VMware ESX .*[0-9].*" | grep -o -E "[0-9].*"`
      ;;
    'slamd64')
      if [ -r '/etc/slamd64-version' ]; then
        operatingsystemrelease=`grep -i -o -E "^[[:space:]]*\w+[[:space:]]+[0-9]+\.[0-9]+" /etc/slamd64-version | grep -o -E "[0-9]+\.[0-9]+"`
        if [ -z "${operatingsystemrelease}" ]; then
          operatingsystemrelease="unknown"
        fi
      fi
      ;;
    'alpine')
      if [ -r '/etc/alpine-release' ]; then
        operatingsystemrelease=`cat /etc/alpine-release | cut -f1 -d' '`
      fi
      ;;
    'amazon')
      fact_lsbdistrelease
      operatingsystemrelease="${lsbdistrelease}"
      ;;
    'solaris')
      if [ -r '/etc/release' ]; then
        operatingsystemrelease=`grep -i -o -E "[[:space:]]+s[0-9]+[sx]?(_u[0-9]+)?.*(SPARC|X86)" /etc/release | grep -i -o -E "[0-9]+[sx]?(_u[0-9]+)?" | head -n 1 | sed "s/[sx]//"`
      fi
      ;;
    *)
      operatingsystemrelease="${kernelrelease}"
      ;;
  esac
  readonly operatingsystemrelease

  fact_operatingsystemrelease_run='y'
  readonly fact_operatingsystemrelease_run
}

fact_lsbdistid () {
  if [ -n "${fact_lsbdistid_run}" ]; then
    return 0
  fi
  fact_kernel

  if [ "${kernel}" = "linux" ] || [ "${kernel}" = "gnu/kfreebsd" ]; then
    lsbdistid=`lsb_release -i -s 2>/dev/null`
    lsbdistid=`lowercase ${lsbdistid}`
  fi
  readonly lsbdistid

  fact_lsbdistid_run='y'
  readonly fact_lsbdistid_run
}

fact_operatingsystem_kernel_sunos () {
  fact_kernel
  if [ "${kernel}" != "sunos" ]; then
    exit 1
  fi

  # Use uname -v because /etc/release can change in zones under SmartOS.
  # It's apparently not trustworthy enough to rely on for this fact.
  if [ `uname -v | grep -i -c -e "^joyent_"` -eq 1]; then
    operatingsystem='SmartOS'
  elif [ `uname -v | grep -i -c -e "^oi_"` -eq 1]; then
    operatingsystem='OpenIndiana'
  elif [ `uname -v | grep -i -c -e "^omnios-"` -eq 1]; then
    operatingsystem='OmniOS'
  elif [ -f "/etc/debian_version" ]; then
    operatingsystem='Nexenta'
  else
    operatingsystem='Solaris'
  fi
  operatingsystem=`lowercase ${operatingsystem}`
  readonly operatingsystem
}

fact_operatingsystem_kernel_linux () {
  fact_kernel
  if [ "${kernel}" != "linux" ]; then
    exit 1
  fi
  fact_lsbdistid

  if [ '${lsbdistid}' = 'ubuntu' ]; then
    operatingsystem='Ubuntu'
  elif [ -f '/etc/debian_version' ]; then
    operatingsystem='Debian'
  elif [ -f '/etc/openwrt_release' ]; then
    operatingsystem='OpenWrt'
  elif [ -f '/etc/gentoo-release' ]; then
    operatingsystem='Gentoo'
  elif [ -f '/etc/fedora-release' ]; then
    operatingsystem='Fedora'
  elif [ -f '/etc/mandriva-release' ]; then
    operatingsystem='Mandriva'
  elif [ -f '/etc/mandrake-release' ]; then
    operatingsystem='Mandrake'
  elif [ -f '/etc/meego-release' ]; then
    operatingsystem='MeeGo'
  elif [ -f '/etc/arch-release' ]; then
    operatingsystem='Archlinux'
  elif [ -f '/etc/oracle-release' ]; then
    operatingsystem='OracleLinux'
  elif [ -f '/etc/enterprise-release' ]; then
    if [ -f '/etc/ovs-release' ]; then
      operatingsystem='OVS'
    else
      operatingsystem='OEL'
    fi
  elif [ -f '/etc/vmware-release' ]; then
    operatingsystem='VMWareESX'
  elif [ -r '/etc/redhat-release' ]; then
    if [ `grep -i -c "centos" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='CentOS'
    elif [ `grep -c "CERN" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='SLC'
    elif [ `grep -i -c "scientific" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='Scientific'
    elif [ `grep -i -c -e "^cloudlinux" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='CloudLinux'
    elif [ `grep -i -c -e "^Parallels Server Bare Metal" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='PSBM'
    elif [ `grep -i -c "Ascendos" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='Ascendos'
    elif [ `grep -i -c -e "^XenServer" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='XenServer'
    elif [ `grep -c "XCP" /etc/redhat-release` -eq 1 ]; then
      operatingsystem='XCP'
    else
      operatingsystem='RedHat'
    fi
  elif [ -r '/etc/SuSE-release' ]; then
    if [ `grep -i -c -e "^SUSE LINUX Enterprise Server" /etc/SuSE-release` -eq 1 ]; then
      operatingsystem='SLES'
    elif [ `grep -i -c -e "^SUSE LINUX Enterprise Desktop" /etc/SuSE-release` -eq 1 ]; then
      operatingsystem='SLED'
    elif  [ `grep -i -c -e "^openSUSE" /etc/SuSE-release` -eq 1 ]; then
      operatingsystem='OpenSuSE'
    else
      operatingsystem='SuSE'
    fi
  elif [ -f '/etc/bluewhite64-version' ]; then
    operatingsystem='Bluewhite64'
  elif [ -f '/etc/slamd64-version' ]; then
    operatingsystem='Slamd64'
  elif [ -f '/etc/slackware-version' ]; then
    operatingsystem='Slackware'
  elif [ -f '/etc/alpine-release' ]; then
    operatingsystem='Alpine'
  elif [ -f '/etc/mageia-release' ]; then
    operatingsystem='Mageia'
  elif [ -f '/etc/system-release' ]; then
    operatingsystem='Amazon'
  fi

  operatingsystem=`lowercase ${operatingsystem}`
  readonly operatingsystem
}

fact_operatingsystem () {
  if [ -n "${fact_operatingsystem_run}" ]; then
    return 0
  fi
  fact_kernel

  case "${kernel}" in
    'sunos')
      fact_operatingsystem_kernel_sunos
      ;;
    'linux')
      fact_operatingsystem_kernel_linux
      ;;
    'vmkernel')
      operatingsystem='esxi'
      ;;
    *)
      operatingsystem="${kernel}"
      operatingsystem=`lowercase ${operatingsystem}`
      ;;
  esac
  readonly operatingsystem

  # Need to mark this function as having run before calling
  # fact_operatingsystemrelease() to ensure a circular dependency is not created.
  fact_operatingsystem_run='y'
  readonly fact_operatingsystem_run

  fact_operatingsystemrelease

  operatingsystemmajrelease=`echo "${operatingsystemrelease}" | cut -f1 -d'.'`
  readonly operatingsystemmajrelease

  fact_osfamily
}

fact_architecture () {
  fact_hardwaremodel
  fact_operatingsystem

  case "${hardwaremodel}" in
    'x86_64')
      # most linuxen use "x86_64"
      case "${operatingsystem}" in
        `echo "${operatingsystem}" | grep -i -o -E "debian|gentoo|gnu/kfreebsd|ubuntu"`)
          architecture='amd64'
          ;;
        *)
          architecture="${hardwaremodel}"
          ;;
      esac
      ;;
    `echo "${hardwaremodel}" | grep -i -o -E "[3456]86|pentium"`)
      case "${operatingsystem}" in
        `echo "${operatingsystem}" | grep -i -o -E "gentoo|windows"`)
          architecture='x86'
          ;;
        *)
          architecture='i386'
          ;;
      esac
      ;;
    *)
      architecture="${hardwaremodel}"
      ;;
  esac
  readonly architecture
}

fact_id () {
  id=`id -un`
  readonly id
}

facter () {
  fact_kernel
  fact_hardwareisa
  fact_hardwaremodel
  fact_operatingsystem
  fact_architecture
  fact_hostname
  fact_domain
  fact_fqdn
  fact_id
}

facter_display_all () {
  facter
  echo "kernel => ${kernel}"
  echo "kernelmajrelease => ${kernelmajrelease}"
  echo "kernelrelease => ${kernelrelease}"
  echo "kernelversion => ${kernelversion}"

  echo "hardwareisa => ${hardwareisa}"
  echo "hardwaremodel => ${hardwaremodel}"

  echo "operatingsystem => ${operatingsystem}"
  echo "operatingsystemmajrelease => ${operatingsystemmajrelease}"
  echo "operatingsystemrelease => ${operatingsystemrelease}"
  echo "osfamily => ${osfamily}"

  echo "architecture => ${architecture}"

  echo "fqdn => ${fqdn}"
  echo "hostname => ${hostname}"
  echo "domain => ${domain}"

  echo "id => ${id}"
}
