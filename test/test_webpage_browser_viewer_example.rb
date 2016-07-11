require_relative "testcase"
require "extension_classes"
require_relative "scenarios/scenario7"

# Example taken from paper (Section 3.1, c.f. Method Shells)
class WebPageBrowserViewerExample < TestCase
	def setup
		super
		$s7_popup_shown = nil
	end

	def test_viewer_popup
		S7_Viewer.new.check(S7_File.new)
		assert_true($s7_popup_shown)
	end

	def test_browser_no_popup
		S7_Browser.new.open("http://titech.ac.jp/")
		assert_false($s7_popup_shown)
	end

	def test_application_mixed
		# Assertions in application code
		assert_true(S7_Application.new.main)
	end
end
