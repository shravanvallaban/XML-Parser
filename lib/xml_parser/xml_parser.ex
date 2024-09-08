# lib/xml_parser/xml_parser.ex
defmodule XmlParser.XmlParser do
  import SweetXml
  require Logger

  @doc """
  Parses the XML content and extracts plaintiff and defendant information.
  """
  def parse(xml_content) do
    case validate_input(xml_content) do
      :ok ->
        try do
          cleaned_content = remove_byte_order_mark(xml_content)
          parsed_xml = SweetXml.parse(cleaned_content)

          %{
            plaintiffs: extract_plaintiff_safely(parsed_xml),
            defendants: extract_defendant_safely(parsed_xml)
          }
        rescue
          e in [SweetXml.SweetXmlException, ErlangError, ArgumentError] ->
            Logger.warning("Failed to parse XML: #{inspect(e)}")
            {:error, "Failed to parse XML"}
        catch
          :exit, reason ->
            Logger.warning("XML parsing exited unexpectedly: #{inspect(reason)}")
            {:error, "Failed to parse XML"}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Validates the input to ensure it's not nil or empty
  defp validate_input(nil), do: {:error, "Input cannot be nil"}
  defp validate_input(""), do: {:error, "Input cannot be empty"}
  defp validate_input(_), do: :ok

  # Removes the Byte Order Mark (BOM) if present
  defp remove_byte_order_mark(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp remove_byte_order_mark(content), do: content

  # Safely extracts plaintiff information, returning an error message if extraction fails
  defp extract_plaintiff_safely(xml) do
    try do
      extract_plaintiff_info(xml)
    rescue
      _ -> "Error extracting plaintiff"
    end
  end

  # Main function to extract plaintiff information from the XML
  defp extract_plaintiff_info(xml) do
    blocks = xpath(xml, ~x"//block"l,
      text: ~x"./text"o,
      pars: [
        ~x".//par"l,
        lines: [
          ~x".//line"l,
          formatting: ~x".//formatting/text()"sl
        ]
      ]
    )

    Logger.debug("Processing #{length(blocks)} blocks")

    result = locate_plaintiff_content(blocks)

    Logger.debug("Extraction result: #{inspect(result)}")

    result
  end

  # Locates and extracts the plaintiff content from the XML blocks
  defp locate_plaintiff_content(blocks) do
    all_lines = Enum.flat_map(blocks, fn block ->
      Enum.flat_map(block.pars, & &1.lines)
    end)

    plaintiff_index = Enum.find_index(all_lines, &is_plaintiff_line?/1)

    case plaintiff_index do
      nil ->
        Logger.debug("No plaintiff line found")
        "Error extracting plaintiff"
      _ ->
        county_index = Enum.take(all_lines, plaintiff_index)
                       |> Enum.reverse()
                       |> Enum.find_index(&is_county_line?/1)

        start_index = if county_index, do: plaintiff_index - county_index, else: 0
        extract_plaintiff_details(all_lines, start_index, plaintiff_index - 1)
    end
  end

  # Checks if a line contains the "Plaintiff," keyword
  defp is_plaintiff_line?(line) do
    Enum.any?(line.formatting, fn text ->
      String.starts_with?(String.trim(text), "Plaintiff,")
    end)
  end

  # Checks if a line contains any variant of "county"
  defp is_county_line?(line) do
    content = Enum.join(line.formatting, " ")
    String.contains?(content, "COUNTY") or String.contains?(content, "County") or String.contains?(content, "county")
  end

  # Extracts plaintiff details from the relevant lines
  defp extract_plaintiff_details(lines, start_index, end_index) do
    relevant_lines = Enum.slice(lines, start_index..end_index)
    IO.inspect(relevant_lines, label: "The relevant lines for the plaintiff content")
    content = Enum.map_join(relevant_lines, " ", &Enum.join(&1.formatting, " "))

    cond do
      result = extract_with_individual_keyword(content) -> result
      result = extract_with_inclusive_keyword(content) -> result
      true -> extract_default_content(content)
    end
  end

  # Extracts content with "individual" keyword
  defp extract_with_individual_keyword(content) do
    case Regex.run(~r/([A-Z][^.]*?individual(?:,|;|).*?)\s*$/i, content) do
      [_, match] -> String.trim(match)
      nil -> nil
    end
  end

  # Extracts content with "inclusive" keyword
  defp extract_with_inclusive_keyword(content) do
    case Regex.run(~r/([A-Z].*?inclusive(?:,|\.|).*?)\s*$/i, content) do
      [_, match] -> String.trim(match)
      nil -> nil
    end
  end

  # Extracts default content when no specific keyword is found
  defp extract_default_content(content) do
    String.trim(content)
  end

  # Safely extracts defendant information, returning an error message if extraction fails
  defp extract_defendant_safely(xml) do
    try do
      extract_defendant_info(xml)
    rescue
      _ -> "Error extracting defendants"
    end
  end

  # Main function to extract defendant information from the XML
  def extract_defendant_info(xml) do
    blocks = xpath(xml, ~x"//block"l,
      text: ~x"./text"o,
      pars: [
        ~x".//par"l,
        lines: [
          ~x".//line"l,
          formatting: ~x".//formatting/text()"sl
        ]
      ]
    )

    case locate_defendant_content(blocks) do
      {:ok, content} -> parse_defendant_details(content)
      {:error, _} -> "Could not extract defendant details"
    end
  end

  # Locates the defendant content within the XML blocks
  defp locate_defendant_content(blocks) do
    blocks
    |> Enum.reduce_while({[], false, false}, fn block, {acc, vs_found, defendant_found} ->
      block_content = extract_block_text(block)
      cond do
        defendant_found ->
          {:halt, {:ok, Enum.reverse(acc)}}
        String.contains?(String.trim(block_content), "Defendants.") ->
          {:halt, {:ok, Enum.reverse([block_content | acc])}}
        vs_found ->
          {:cont, {[block_content | acc], vs_found, defendant_found}}
        String.contains?(block_content, "v.") or String.contains?(block_content, "vs.") ->
          {:cont, {[block_content | acc], true, defendant_found}}
        true ->
          {:cont, {acc, vs_found, defendant_found}}
      end
    end)
    |> case do
      {:ok, content} -> {:ok, content}
      _ -> {:error, "Could not find proper sequence of v./vs. and Defendants."}
    end
  end

  # Extracts text content from a block
  defp extract_block_text(block) do
    block.pars
    |> Enum.flat_map(fn par ->
      Enum.flat_map(par.lines, fn line ->
        line.formatting
      end)
    end)
    |> Enum.join(" ")
  end

  # Parses the defendant content to extract relevant details
  defp parse_defendant_details(content) do
    joined_content = Enum.join(content, " ")
    case Regex.run(~r/(?:v\.|vs\.)\s*(.*?)(?:(?=\s+Defendants\.)|$)/s, joined_content) do
      [_, match] ->
        match
        |> String.trim()
        |> extract_defendant_details_refined()
      _ -> "Could not extract valid defendant content"
    end
  end

  # Refines the extracted defendant details
  defp extract_defendant_details_refined(text) do
    case Regex.run(~r/[A-Z][A-Z\s,;.()'-]+.*?(?:(?:inclusive[,.])|(?:individual[,.])|(?=\s+Defendants\.))/s, text) do
      [match] ->
        trimmed_match = String.trim(match)
        cond do
          String.ends_with?(trimmed_match, ["inclusive,", "inclusive.", "individual,"]) ->
            trimmed_match
          true ->
            # Remove the last word if it's incomplete (doesn't end with punctuation)
            Regex.replace(~r/\s+\S+$/, trimmed_match, "")
        end
      _ -> text  # If no match found, return the original text
    end
  end
end
