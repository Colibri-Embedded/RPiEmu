#!/usr/bin/env python3

from models.components.axis import Axis

class FABTotum:
	
	def __init__(self):
		self.x_axis = Axis("X", maxv=24.0, endstop_threshold=0.5) # 24cm / 5mm
		self.y_axis = Axis("Y", maxv=24.0, endstop_threshold=0.5) # 24cm / 5mm
		self.z_axis = Axis("Z", maxv=24.0, endstop_threshold=0.5) # 24cm / 5mm
		self.e_axis = Axis("E", maxv=360.0, atype = Axis.TYPE_CIRCULAR)
		
	
