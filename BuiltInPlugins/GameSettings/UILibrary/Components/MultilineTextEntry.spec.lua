return function()
	local Library = script.Parent.Parent
	local Roact = require(Library.Parent.Roact)

	local MockWrapper = require(Library.MockWrapper)

	local MultilineTextEntry = require(script.Parent.MultilineTextEntry)

	local function createTestMultilineTextEntry(visible)
		return  Roact.createElement(MockWrapper, {}, {
			MultilineTextEntry = Roact.createElement(MultilineTextEntry, {
				Text = "Text",
				Visible = visible,
				TextSize = 22,
			}),
		})
	end

	it("should create and destroy without errors", function()
		local element = createTestMultilineTextEntry(true)
		local instance = Roact.mount(element)
		Roact.unmount(instance)
	end)

	it("should render correctly", function ()
		local container = workspace
		local instance = Roact.mount(createTestMultilineTextEntry(true), container)
		local frame = container.Frame

		expect(frame.ScrollingFrame).to.be.ok()
		expect(frame.ScrollingFrame).to.be.ok()
		expect(frame.ScrollingFrame.Padding).to.be.ok()
		expect(frame.ScrollingFrame.Text).to.be.ok()

		Roact.unmount(instance)
	end)

	it("should hide its text when not visible", function ()
		local container = workspace
		local instance = Roact.mount(createTestMultilineTextEntry(false), container)
		local frame = container.Frame

		expect(frame.ScrollingFrame.Text.Visible).to.equal(false)

		Roact.unmount(instance)
	end)
end