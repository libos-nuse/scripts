#!/system/bin/sh

set -e
set -x

#prepare
mkdir /dev/net
ln -s /dev/tun /dev/net/tun
chmod 777 /dev/net
chmod 777 /dev/net/tun

#allow forwarding
sysctl -w net.ipv4.ip_forward=1

#create tap for wlan0
ip tuntap add dev lklwlantap0 mode tap user vpn group vpn
ip link set dev lklwlantap0 up

#create bridge for wlan0
ip tuntap add dev lklwlantap0 mode tap user vpn group vpn
ip link add name lklwlanbr0 type bridge
ip link set dev lklwlanbr0 up
ip addr add 192.168.1.1/24 dev lklwlanbr0

#create ip rule for wlan0
ip link set dev lklwlantap0 master lklwlanbr0
ip rule add table main
ip rule add iif lklwlanbr0 table wlan0

#create tap for rmnet0
ip tuntap add dev lklrmnettap0 mode tap user vpn group vpn
ip link set dev lklrmnettap0 up

#create bridge for rmnet0
ip link add name lklrmnetbr0 type bridge
ip link set dev lklrmnetbr0 up
ip addr add 192.168.0.1/24 dev lklrmnetbr0

#create ip rule for rmnet0
ip link set dev lklrmnettap0 master lklrmnetbr0
ip rule add table main
ip rule add iif lklrmnetbr0 table rmnet0

#iptables for wlan0 NAT
iptables -N natctrl_lkl_wlan_counters
iptables -A natctrl_lkl_wlan_counters -i lklwlanbr0 -o wlan0      -j RETURN
iptables -A natctrl_lkl_wlan_counters -i wlan0      -o lklwlanbr0 -j RETURN

iptables -I natctrl_FORWARD 1 -i wlan0      -o lklwlanbr0 -m state --state ESTABLISHED,RELATED  -g natctrl_lkl_wlan_counters
iptables -I natctrl_FORWARD 2 -i lklwlanbr0 -o wlan0      -m state --state INVALID  -j DROP
iptables -I natctrl_FORWARD 3 -i lklwlanbr0 -o wlan0      -g natctrl_lkl_wlan_counters

iptables -t nat -A natctrl_nat_POSTROUTING -o wlan0 -j MASQUERADE

#iptables for rmnet0 NAT
iptables -N natctrl_lkl_rmnet_counters
iptables -A natctrl_lkl_rmnet_counters -i lklrmnetbr0 -o rmnet0      -j RETURN
iptables -A natctrl_lkl_rmnet_counters -i rmnet0      -o lklrmnetbr0 -j RETURN

iptables -I natctrl_FORWARD 1 -i rmnet0      -o lklrmnetbr0 -m state --state ESTABLISHED,RELATED  -g natctrl_lkl_rmnet_counters
iptables -I natctrl_FORWARD 2 -i lklrmnetbr0 -o rmnet0      -m state --state INVALID  -j DROP
iptables -I natctrl_FORWARD 3 -i lklrmnetbr0 -o rmnet0      -g natctrl_lkl_rmnet_counters

iptables -t nat -A natctrl_nat_POSTROUTING -o rmnet0 -j MASQUERADE
