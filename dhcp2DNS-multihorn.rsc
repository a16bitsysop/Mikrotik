# Mikrotik RouterOS script for adding DHCP leases to unbound
# Author Duncan Bellamy <https://github.com/a16bitsysop/Mikrotik>
#
# Based on SmartFinn <https://gist.github.com/SmartFinn>
#
# Requires read and write permissions
#
# Mikrotik dhcp server globals
# leaseBound          -- set to "1" if bound, otherwise set to "0"
# leaseServerName -- dhcp server name
# leaseActMAC - active mac address
# leaseActIP            -- active IP address
# lease-hostname    -- client hostname

:local safeHostname;
# Delete unallowed chars from the hostname
:for i from=0 to=([:len $"lease-hostname"]-1) do={
  :local char [:pick $"lease-hostname" $i];
  :if ($char~"[a-zA-Z0-9-]") do={
    :set safeHostname ($safeHostname . $char);
  }
}

:if ([:len $safeHostname] = 0) do={
  :error "Hostname is empty";
}

:local TTLdhcp [/ip dhcp-server get $leaseServerName lease-time];
 
# Getting the domain name from DHCP server config.
:local DNSdomain
:do {
  :set DNSdomain [/ip dhcp-server network get value-name=domain number=[/ip dhcp-server find name=$leaseServerName]];
} on-error={
  :set DNSdomain "";
};

# If a domain name is not specified will use hostname only
:if ([:len $DNSdomain] > 0) do={
  :set safeHostname ($safeHostname . "." . $DNSdomain . ".");
}

:if ($leaseBound = 1) do={
# create DNS entry
  :log info "Binding lease for $safeHostname  $leaseActIP";
  /ip dns static add name=$safeHostname address=$leaseActIP;

} else={
# remove DNS entry
   :log info "Releasing lease for $safeHostname  $leaseActIP";
   /ip dns static remove [find address=$leaseActIP];
}
