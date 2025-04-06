local pd_obj = pd.Class:new():register("pd-obj")

-- ─────────────────────────────────────
function score:initialize(name, args)
	self.inlets = 1
	return true
end

-- ─────────────────────────────────────
function score:in_1_reload()
	self:dofilex(self._scriptname)
	self:initialize()
	--self:repaint()
end
