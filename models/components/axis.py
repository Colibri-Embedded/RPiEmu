#!/usr/bin/env python3

class Axis:
	
	TRIG_LE = 1
	TRIG_GE = 2
	TRIG_EQ = 3
	
	TYPE_LINEAR = 1
	TYPE_CIRCULAR = 2
	
	def __init__(self, name, maxv=1.0, minv=0.0, atype=TYPE_LINEAR, endstop_threshold=0.01):
		self.name = name
		self.minValue = minv
		self.maxValue = maxv
		self.curValue = (self.minValue + self.maxValue) / 2
		self.tgtValue = self.curValue
		self.speed = 1000 # 1000 millimetres/minute => 16.7mm/sec
		self.atype = atype
	
	def setSpeed(self, value):
		self.speed = value
	
	def moveTo(self, value):
		self.tgtValue = value
	
	def getPosition(self):
		return self.curValue
		
	def getMax(self):
		return self.maxValue

	def getMin(self):
		return self.minValue
		
	def getMaxEndstop(self):
		return False

	def getMinEndstop(self):
		return False
		
	def triggerOnThreshold(self, obj, fun, ttype, tval):
		trigger.obj = obj
		trigger.fun = fun
		trigger.type = ttype
		trigger.value = tval
		
	def triggerOnChange(self):
		pass

	def triggerOnMaximum(self):
		pass

	def triggerOnMinimum(self):
		pass
		
	def update(self, time):
		pass
