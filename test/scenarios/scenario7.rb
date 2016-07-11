# Example taken from paper (Section 3.1, c.f. Method Shells)
$s7_popup_shown = nil

class S7_File
	def is_confidential?
		true
	end
end

class S7_WebPage
	def open(url)
		popup_requested = true
		text = "Content of Popup"
		# ...
		if popup_requested
			popup(text)
		end
	end

	def popup(text)
		$s7_popup_shown = true
	end
end

class S7_Viewer
	def check(file)
		page = S7_WebPage.new

		if file.is_confidential?
			page.popup("<b>confidential</b>")
		end
	end
end

class S7_Browser
	def open(url)
		S7_WebPage.new.open(url)
	end

	partial

	class ::S7_WebPage
		def popup(text)
			# Do nothing
			$s7_popup_shown = false
		end
	end
end

class S7_Application
	def main
		S7_Browser.new.open("http://wwww.hpi.uni-potsdam.de/")
		ok = ! $s7_popup_shown
		S7_Viewer.new.check(S7_File.new)
		ok &&= $s7_popup_shown
	end
end
