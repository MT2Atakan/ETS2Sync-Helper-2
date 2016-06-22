class SaveSelector < Qt::GroupBox
	slots("profile_changed()", "index_changed(int)", "sync_changed()")
	signals("changed(const QString &)")

	def profile
		@parent.profile
	end

	def initialize(parent)
		@parent = parent
		super(MSG[:select_save], parent)
		@lbl = StatusLabel.new(self)
		@cbo = Qt::ComboBox.new(self)
		connect(@cbo, SIGNAL("currentIndexChanged(int)"), self, SLOT("index_changed(int)"))
		vbox = Qt::VBoxLayout.new
		vbox.add_widget(@lbl)
		vbox.add_widget(@cbo)
		set_layout(vbox)
		connect(parent, SIGNAL("profile_changed()"), self, SLOT("profile_changed()"))
		connect(parent, SIGNAL("sync_changed()"), self, SLOT("sync_changed()"))
		@icon_ok = Qt::Icon.new
		@icon_ok.add_file("res/check_ok.png", Qt::Size.new(15, 15))
		@icon_fail = Qt::Icon.new
		@icon_fail.add_file("res/check_fail.png", Qt::Size.new(15, 15))
	end

	def profile_changed
		update_status
	end

	def sync_changed
		if parent.syncing?
			@cbo.enabled = false
		else
			@cbo.enabled = true
		end
	end

	def index_changed(new_index)
		val = @cbo.item_data(@cbo.current_index).value
		val = val.force_encoding("UTF-8").encode("filesystem") if val
		emit changed(val)
	end

	def update_status
		item_data = @cbo.item_data(@cbo.current_index).value
		if item_data
			prev = Pathname(item_data.force_encoding("UTF-8").encode("filesystem"))
		end
		if profile
			saves = profile.saves
			saves.reject!(&:autosave?)
		else
			saves = []
		end
		emit @cbo.clear
		prev_new_idx = 0
		saves.reverse_each.with_index do |save, idx|
			@cbo.add_item(save.display_name, Qt::Variant.new(save.dir.to_s))
			if save.dir == prev
				prev_new_idx = idx
			end
		end
		@cbo.current_index = prev_new_idx
		if profile.nil?
			@lbl.failure("")
		elsif saves.empty?
			@lbl.failure(MSG[:no_saves])
		else
			@lbl.success(saves.length == 1 ? MSG[:one_save] : MSG[:saves] % saves.length)
		end
	end
end