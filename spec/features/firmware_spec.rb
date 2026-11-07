# frozen_string_literal: true

require "hanami_helper"

RSpec.describe "Firmware", :db do
  include_context "with temporary directory"

  let(:firmware) { Factory[:firmware, :with_model, :with_attachment] }
  let(:path) { temp_dir.join("test.bin").tap { it.binwrite [123].pack("N") } }

  it "visits new page" do
    visit routes.path(:firmwares)
    click_link "New"

    expect(page).to have_text("New Firmware")
  end

  it "visits edit page" do
    firmware
    visit routes.path(:firmwares)
    click_link "Edit"

    expect(page).to have_text("Edit Firmware")
  end

  it "deletes", :js do
    firmware
    visit routes.path(:firmwares)
    accept_prompt { click_button "Delete" }

    expect(page).to have_no_text(firmware.version)
  end
end
