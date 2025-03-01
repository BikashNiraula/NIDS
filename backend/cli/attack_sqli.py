from scapy.all import IP, TCP, send
import time

# Configuration: adjust these as needed for your test environment.
src_ip = "8.8.8.8"         # Your testing source IP
dst_ip = "10.100.30.154"          # The destination IP where the IDS is monitoring
src_port = 54321                # Arbitrary source port
dst_port = 80                   # Destination port (HTTP)

# Design the payload: a full HTTP GET request containing an SQL injection test string.
# The payload injects: admin' OR '1'='1'--SQLiTest
payload = (
    "GET /login.php?username=admin' OR '1'='1'--SQLiTest&password=anything HTTP/1.1\r\n"
    "Host: vulnerable.example.com\r\n"
    "Connection: close\r\n"
    "\r\n"
)

# Number of packets to send (simulate multiple requests)
num_packets = 10

for i in range(num_packets):
    # Build the packet; adjust sequence numbers if necessary.
    packet = IP(src=src_ip, dst=dst_ip) / TCP(sport=src_port, dport=dst_port, flags="PA", seq=1000 + i) / payload
    
    # Send the packet.
    send(packet, verbose=False)
    print(f"Sent packet {i+1}")
    
    # Wait a short time between packets.
    time.sleep(1)
