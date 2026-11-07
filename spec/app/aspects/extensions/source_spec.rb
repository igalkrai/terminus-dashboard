# frozen_string_literal: true

require "hanami_helper"

RSpec.describe Terminus::Aspects::Extensions::Source do
  subject(:parser) { described_class }

  describe ".from_calendar" do
    it "answers empty array when nil" do
      expect(parser.from_calendar(nil)).to be_success([])
    end

    it "answers empty array when blank" do
      expect(parser.from_calendar("")).to be_success([])
    end

    it "answers array" do
      content = <<~CONTENT
        BEGIN:VCALENDAR
        PRODID:-//Test//Test//EN
        VERSION:2.0
        BEGIN:VEVENT
        UID:cc1fe76d-eb99-42cf-a73f-eb619b529341
        DTSTAMP:20260928T200306Z
        DTSTART:20260930T183000Z
        END:VEVENT
        END:VCALENDAR
      CONTENT

      expect(parser.from_calendar(content)).to be_success(
        JSON.parse(SPEC_ROOT.join("support/fixtures/calendars.json").read, symbolize_names: true)
      )
    end

    it "answers failure with malformed content" do
      content = <<~CONTENT
        BEGIN:VCALENDAR
        bogus
        END:VCALENDAR
      CONTENT

      expect(parser.from_calendar(content)).to be_failure("Invalid iCalendar input line: bogus")
    end
  end

  describe ".from_csv" do
    it "answers empty array when nil" do
      expect(parser.from_csv(nil)).to be_success([])
    end

    it "answers empty array when blank" do
      expect(parser.from_csv("")).to be_success([])
    end

    it "answers empty array with no headers or rows" do
      expect(parser.from_csv("bogus")).to be_success([])
    end

    it "answers array with valid headers and rows" do
      content = <<~BODY
        title,director
        Castle in the Sky,Hayao Miyazaki
      BODY

      expect(parser.from_csv(content)).to be_success(
        [{"director" => "Hayao Miyazaki", "title" => "Castle in the Sky"}]
      )
    end

    it "answers failure with invalid encoding" do
      content = "name,city\nJohn,New\xFFYork".dup.force_encoding "UTF-8"
      expect(parser.from_csv(content)).to be_failure("Invalid byte sequence in UTF-8 in line 2.")
    end

    it "answers failure with missing quote" do
      content = <<~BODY
        title,director
        "Castle in the Sky,Hayao Miyazaki
      BODY

      expect(parser.from_csv(content)).to be_failure("Unclosed quoted field in line 2.")
    end
  end

  describe ".from_image" do
    it "answers URI" do
      expect(parser.from_image("https://test.io/test.png")).to be_success(
        "https://test.io/test.png"
      )
    end
  end

  describe ".from_json" do
    it "answers empty array when nil" do
      expect(parser.from_json(nil)).to be_success([])
    end

    it "answers empty hash when blank" do
      expect(parser.from_json("")).to be_success([])
    end

    it "answers hash when hash" do
      content = {test: "example"}.to_json
      expect(parser.from_json(content)).to be_success("test" => "example")
    end

    it "answers array when array" do
      content = [1, 2, 3].to_json
      expect(parser.from_json(content)).to be_success([1, 2, 3])
    end

    it "answers failure with invalid encoding" do
      content = "test\xFF".dup.force_encoding "UTF-8"
      expect(parser.from_json(content)).to be_failure(
        "Unexpected token 'test\xFF' at line 1 column 1."
      )
    end
  end

  describe ".from_text" do
    it "answers empty array when nil" do
      expect(parser.from_text(nil)).to be_success([])
    end

    it "answers empty array when blank" do
      expect(parser.from_text("")).to be_success([])
    end

    it "answers array when single line" do
      expect(parser.from_text("test")).to be_success(["test"])
    end

    it "answers array when multiple lines" do
      expect(parser.from_text("one\ntwo\nthree")).to be_success(%w[one two three])
    end

    it "answers failure with invalid encoding" do
      content = "test\xFF".dup.force_encoding "UTF-8"
      expect(parser.from_text(content)).to be_failure("Invalid byte sequence in UTF-8.")
    end
  end

  describe ".from_xml" do
    let :content do
      <<~CONTENT
        <catalog>
          <book>
            <title>Book 1</title>
          </book>
          <book>
            <title>Book 2</title>
          </book>
        </catalog>
      CONTENT
    end

    it "answers empty array when nil" do
      expect(parser.from_xml(nil)).to be_success([])
    end

    it "answers empty array when blank" do
      expect(parser.from_xml("")).to be_success([])
    end

    it "answers hash with valid content" do
      expect(parser.from_xml(content)).to be_success(
        {
          "catalog" => {
            "book" => [
              {"title" => "Book 1"},
              {"title" => "Book 2"}
            ]
          }

        }
      )
    end

    it "answers hash with encoded characters" do
      content = "<catalog>B\xFFoks</catalog>".dup.force_encoding "UTF-8"
      expect(parser.from_xml(content)).to be_success({"catalog" => "B�oks"})
    end

    it "answers failure when malformed" do
      expect(parser.from_xml("bogus")).to be_failure(
        "Malformed XML: Content at the start of the document (got 'bogus')\n" \
        "Line: 1\nPosition: 5\nLast 80 unconsumed characters:\n"
      )
    end
  end
end
