[ml2]

# Changing type_drivers after bootstrap can lead to database inconsistencies
type_drivers = vlan,vxlan
tenant_network_types = vxlan,vlan


#mechanism_drivers = aci,openvswitch,arista,asr,manila,f5ml2

mechanism_drivers = {{required "A valid .Values.ml2_mechanismdrivers required!" .Values.ml2_mechanismdrivers}}

{{- if .Values.ml2_extensiondrivers }}
extension_drivers = {{.Values.ml2_extensiondrivers}}
{{- else }}
# Designate configuration
extension_drivers = {{required "A valid .Values.dns_ml2_extension required!" .Values.dns_ml2_extension}}
{{- end }}

path_mtu = {{.Values.global.default_mtu | default 9000}}

[ml2_type_vlan]
network_vlan_ranges = {{ range $i, $aci_hostgroup := .Values.aci.aci_hostgroups.hostgroups }}
    {{- $physical_network := default $aci_hostgroup.name $aci_hostgroup.physical_network -}}
    {{- $network_ranges := default $.Values.aci.aci_hostgroups.segment_ranges $aci_hostgroup.segment_ranges -}}

    {{- if ne $i 0 }},{{ end -}}
    {{- range $x, $range := $network_ranges -}}
        {{- if ne $x 0 }},{{ end -}}
        {{ $physical_network }}:{{ $range }}
    {{- end -}}
{{- end }}
{{- if .Values.cc_fabric.enabled }}
    {{- range $i, $switchgroup := .Values.cc_fabric.driver_config.switchgroups -}}
        {{- if or (ne $i 0) ((($.Values.aci|default).aci_hostgroups|default).hostgroups|default) }},{{ end -}}
        {{- range $x, $range := $switchgroup.vlan_ranges | default $.Values.cc_fabric.driver_config.global_config.default_vlan_ranges -}}
            {{- if ne $x 0 }},{{ end -}}
            {{ default $switchgroup.name $switchgroup.override_vlan_pool }}:{{ $range }}
        {{- end -}}
    {{- end -}}
{{- end }}

[ml2_type_vxlan]
vni_ranges = 10000:20000

[ml2_f5]
supported_device_owners = network:f5listener,network:f5selfip,network:f5lbaasv2,network:f5snat,network:archer

[securitygroup]
firewall_driver = iptables_hybrid
enable_security_group=True
enable_ipset=True

[agent]
polling_interval=5
prevent_arp_spoofing = False

[vxlan]
enable_vxlan = false

{{- if .Values.ovn.enabled }}

[ovn]
{{- $ovsdb_nb := index (index .Values "ovsdb-nb") }}
{{- $ovsdb_sb := index (index .Values "ovsdb-sb") }}
ovn_nb_connection = tcp:{{ required "ovsdb-nb.EXTERNAL_IP required!" $ovsdb_nb.EXTERNAL_IP }}:{{ $ovsdb_nb.DB_PORT }}
ovn_sb_connection = tcp:{{ required "ovsdb-sb.EXTERNAL_IP required!" $ovsdb_sb.EXTERNAL_IP }}:{{ $ovsdb_sb.DB_PORT }}
{{- end }}
