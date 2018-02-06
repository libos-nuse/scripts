* nat-setup.sh, nat-mptcp-lkl-hijack.json

   nat-setup.sh setups lklwlanbr0/tap0 and
   lklrmnetbr0/tap0 and creates NAT rules.
   Source address of packet to lklwlanbr0 is translated with wlan0 address.
   Source address of packet to lklrmnetbr0 is translated with rmnet0 address.
   nat-mptcp-lkl-hijack.json is a configuration file
   for a mptcp lkl which uses lklwlantap0 and lklrmnettap0.
