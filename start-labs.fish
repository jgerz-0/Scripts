<details type="code_interpreter" done="false">
<summary>Analyzing...</summary>
```python
import os

def setup_lab_folder(box_name, ip):
    # Create directory structure
    os.mkdir(f"{os.getenv('HOME')}/Labs/Boxes/{box_name}")
    os.mkdir(f"{os.getenv('HOME')}/Labs/Boxes/{box_name}/loot")
    os.mkdir(f"{os.getenv('HOME')}/Labs/Boxes/{box_name}/scans")
    os.mkdir(f"{os.getenv('HOME')}/Labs/Boxes/{box_name}/screenshots")
    os.mkdir(f"{os.getenv('HOME')}/Labs/Boxes/{box_name}/notes")

    # Set environment variable for IP
    os.environ['IP'] = ip

    # Perform nmap scans
    print("Scanning ports...")
    os.system(f"nmap -p- -sS {ip}")
    os.system(f"nmap -p- --script default --script-args max-pages=1000 {ip} | grep -E 'open|closed'")

# Prompt for box name and IP
box_name = input("Enter the name of the box: ")
ip = input("Enter the IP address of the box: ")

setup_lab_folder(box_name, ip)
