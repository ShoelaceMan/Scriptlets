#!/usr/bin/python2
from Xlib import X, display
from Xlib.ext.xtest import fake_input
import time

d = display.Display()
loc1 = d.screen().root.query_pointer()._data
delta = 0

n = 3
while n > 0:
 print(n)
 time.sleep(1)
 n = n - 1

d = display.Display()
loc1 = d.screen().root.query_pointer()._data
delta = 0

while delta < 80:
 fake_input(d, X.ButtonPress, 1)
 fake_input(d, X.ButtonRelease, 1)
 d.sync()
 time.sleep(0.02)
 loc2 = d.screen().root.query_pointer()._data
 delta = abs(loc1["root_x"] - loc2["root_x"]) + \
   abs(loc1["root_y"] - loc2["root_y"])
 loc1 = loc2
