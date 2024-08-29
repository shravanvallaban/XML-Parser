# lib/xml_parser/xml_parser.ex
defmodule XmlParser.XmlParser do
  import SweetXml
  require Logger
  def parse(xml_content) do
    cleaned_content = remove_bom(xml_content)
    parsed_xml = SweetXml.parse(cleaned_content)

    %{
      plaintiffs: safe_extract_plaintiffs(parsed_xml),
      defendants: safe_extract_defendants(parsed_xml)
    }
  end

  defp remove_bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp remove_bom(content), do: content

  defp safe_extract_plaintiffs(xml) do
    try do
      extract_plaintiffs(xml)
    rescue
      _ -> "Error extracting plaintiff"
    end
  end

  defp extract_plaintiffs(xml) do
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

    result = find_plaintiff_content(blocks)

    Logger.debug("Extraction result: #{inspect(result)}")

    result
  end

  defp find_plaintiff_content(blocks) do
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
        extract_plaintiff(all_lines, start_index, plaintiff_index - 1)
    end
  end

  defp is_plaintiff_line?(line) do
    Enum.any?(line.formatting, fn text ->
      String.starts_with?(text, "Plaintiff,")
    end)
  end

  defp is_county_line?(line) do
    content = Enum.join(line.formatting, " ")
    String.contains?(content, "COUNTY") or String.contains?(content, "County") or String.contains?(content, "county")
  end

  defp extract_plaintiff(lines, start_index, end_index) do
    relevant_lines = Enum.slice(lines, start_index..end_index)
    content = Enum.map_join(relevant_lines, " ", &Enum.join(&1.formatting, " "))

    cond do
      result = extract_with_individual(content) -> result
      result = extract_with_inclusive(content) -> result
      true -> extract_default(content)
    end
  end

  defp extract_with_individual(content) do
    case Regex.run(~r/([A-Z][^.]*?individual(?:,|;|).*?)\s*$/i, content) do
      [_, match] -> String.trim(match)
      nil -> nil
    end
  end

  defp extract_with_inclusive(content) do
    case Regex.run(~r/([A-Z].*?inclusive(?:,|\.|).*?)\s*$/i, content) do
      [_, match] -> String.trim(match)
      nil -> nil
    end
  end

  defp extract_default(content) do
    String.trim(content)
  end

  defp safe_extract_defendants(xml) do
    try do
      extract_defendant_details(xml)
    rescue
      _ -> "Error extracting defendants"
    end
  end



  def extract_defendant_details(xml) do
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

    case find_defendant_content(blocks) do
      {:ok, content} -> parse_defendant_content(content)
      {:error, _} -> "Could not extract defendant details"
    end
  end

  defp find_defendant_content(blocks) do
    blocks
    |> Enum.reduce_while({[], false, false}, fn block, {acc, vs_found, defendant_found} ->
      block_content = extract_block_content(block)
      cond do
        defendant_found ->
          {:halt, {:ok, Enum.reverse(acc)}}
        String.contains?(block_content, "Defendants.") ->
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

  defp extract_block_content(block) do
    block.pars
    |> Enum.flat_map(fn par ->
      Enum.flat_map(par.lines, fn line ->
        line.formatting
      end)
    end)
    |> Enum.join(" ")
  end

  defp parse_defendant_content(content) do
    joined_content = Enum.join(content, " ")
    case Regex.run(~r/(?:v\.|vs\.)\s*(.*?)(?:(?=\s+Defendants\.)|$)/s, joined_content) do
      [_, match] ->
        match
        |> String.trim()
        |> extract_defendant_details_edge()
      _ -> "Could not extract valid defendant content"
    end
  end

  defp extract_defendant_details_edge(text) do
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
