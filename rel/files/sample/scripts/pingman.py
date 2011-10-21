#!/usr/bin/env python

from multiprocessing import (
    Lock,
    Process,
)
import commands
import itertools
import json
import os
import re
import sys
import time

import pydot

IP_REGEX = r"\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b"
IP = re.compile(r"%s" % IP_REGEX)
PACKET_LOSS = re.compile(r"[0-9]{1,3}\.[0-9]")
MS = re.compile(r"[0-9]+\.[0-9]+")

IP_ALL = list()
PROCESSES = list()
ROUTE = dict()
MAX = 16384
LOCK = Lock()

def out(**kwargv):
    data = json.dumps(kwargv)
    LOCK.acquire()
    if len(data[:MAX+1]) <= MAX:
        print(data)
        sys.stdout.flush()
    else:
        print(data)
        sys.stdout.flush()
    LOCK.release()

def traceroute(host):
    output = command("traceroute -q 1 -w 1 %s" % host)
    hop = int()
    for line in output.splitlines():
        row = line.split()
        if row[0].startswith("traceroute"):
            pass
        else:
            if row[0].isalnum():
                hop = int(row[0])
            findall = IP.findall(line)
            if findall:
                address = findall[0]
            else:
                continue
            if address not in IP_ALL:
                IP_ALL.append(address)
                process = Process(target=ping, args=(address,))
                process.start()
                PROCESSES.append(process)
            ips = ROUTE.get(hop, list())
            if address not in ips:
                ips.append(address)
                ROUTE[hop] = ips
    svg = dot(ROUTE)
    out(type="traceroute", data=svg)
    with open(os.path.join(os.path.dirname(__file__), "../www/traceroute.svg"), "w") as f:
        f.write(svg)

def dot(route):
    edges = list()
    keys = sorted(route.keys())
    for hop in xrange(1, keys[-1]):
        if not route.get(hop):
            route[hop] = ["&lt;%s-hop&gt;" % hop]
    for hop in keys:
        if (hop - 1) not in keys:
            continue
        for prev_node in route[hop-1]:
            for node in route[hop]:
                edges.append((node, prev_node))
    graph = pydot.graph_from_edges(edges)
    return graph.create("dot", "svg").replace("\n", "")

def ping(ip):
    while True:
        output = command("ping -c 10 -i 3 %s" % ip)
        round_trip = {"ip": ip}
        for line in output.splitlines():
            if line.endswith("% packet loss"):
                round_trip["packet_loss"] = float(PACKET_LOSS.findall(line)[0])
            elif line.startswith("round-trip"):
                round_trip.update(dict(zip(["min", "avg", "max", "stddev"], map(float, MS.findall(line)))))
        out(type="ping", data=round_trip)

def command(cmd):
    try:
        _status, output = commands.getstatusoutput(cmd)
    except KeyboardInterrupt:
        return ""
    else:
        return output

def do():
    traceroute("google.com")
    time.sleep(30)

def loop(num):
    if num == True:
        while True:
            do()
    else:
        for i in xrange(num):
            do()

def main():
    try:
        loop(10)
    except KeyboardInterrupt:
        pass
    finally:
        [p.terminate() for p in PROCESSES]

if __name__ == "__main__":
    main()
